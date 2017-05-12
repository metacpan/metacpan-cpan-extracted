package SVN::Deploy;

use strict;
use warnings;

our $VERSION = '0.11';
use Carp;

use Cwd;
use File::Temp qw/tempdir/;
use File::Spec::Functions qw/:ALL/;
use File::Copy::Recursive;
use File::Path;
use Storable qw/dclone nfreeze thaw/;
use MIME::Base64;

use SVN::Deploy::Utils;
$SVN::Error::handler = undef;

use Data::Dumper;
 $Data::Dumper::Indent=1;

=head1 NAME

SVN::Deploy - audit conform building/deploying releases to/from an SVN deploy repository

=head1 SYNOPSIS

    use SVN::Deploy;

    # creating a SVN::Deploy object
    my $obj = SVN::Deploy->new(
        repo        => 'svn:://deploy_srv/deploy_repo',
        cleanup_tmp => 1,
    );

    # adding a category
    $obj->category_add(category => 'Cat1')

    # defining a product
    my %cfg = (
        build  => [
            '[os]perl build1.pl',
            '[os]perl build2.pl',
        ],
        source => [
            'svn://source_srv/source_repo/trunk/mypath1',
            'svn://source_srv/source_repo/trunk/mypath2',
        ],
        qa => {
            dest => [
                '[none]',
                '/mypath/to/qa/environment',
            ],
            pre  => ['[os]perl pre.pl'],
            post => ['[os]perl post.pl'],
        },
        prod => {
            dest => [
                '[none]',
                '/mypath/to/prod/environment',
            ],
            pre  => ['[os]perl pre.pl'],
            post => ['[os]perl post.pl'],
        },
    );

    $obj->product_add(
        category => 'Cat1',
        product  => 'Prod1',
        [cfg      => \%cfg,]
    );


    # exporting data from source repos
    # and importing into deploy repo
    my $rev = $obj->build_version(
        category => 'Cat1',
        product  => 'Prod1',
        versions => {
            "svn://source_srv/source_repo/trunk/mypath1" => 42,
            "svn://source_srv/source_repo/trunk/mypath2" => 42,
        },
        comment => 'some log message',
    );

    print "Built version has revision $rev in deploy repo\n";

    # deploying the newly created release
    # to the specified target
    $obj->deploy_version(
        category        => 'Cat1',
        product         => 'Prod1',
        version         => $rev,
        target          => 'qa',
        reference_id    => 'Version 1.02',
        reference_data  => {
            requested_from => 'Bill',
            tested_by      => 'Bob',
            pumpking       => 'Beth',
        },
        comment         => "Lets hope it'll work :-)",
    );

=head1 DESCRIPTION

SVN::Deploy implements an interface to handle release data held within
a separate SVN repository. You can define categorized products where
each product consists of multiple sources (SVN repositories and
directories or files from a filesystem) and multiple destinations
(filesystem directories).

It was designed for situations where the build and deploy steps should
not be performed by the developers of a product but by operators with
only read access to the developers repository, while the developers
have no access to the deploy repository.

The overall outline looks like this:

  (dev:developers, op:operating, usr:users/testers):

    - (dev) define a product
            (location of sources from the devel repo and/or files,
            providing build procedures, etc)
    - (op)  define the product in the deploy repository
    - (dev) order a new release (give source revision numbers to op)
    - (op)  build the release
            (resulting in a new revision in the deploy repo)
    - (op)  deploy the new release to QA environment giving
            release revision info to testers
    - (usr) approve/reject the release
    - (op)  on approval deploy the new release to
            production environment

All information and the build/deploy history is held in the deploy
repository and can be easily exported for auditing purposes.

The deploy repository will look like this:

    repo_root
      \-- Category1
      \-- Category2
        \-- Product1
          \-- 0
            \-- subdir1
              \-- file1
              \-- file2
            \--file1
        \-- Product2
          \-- 0
          \-- 1
          \-- 2
      ...

All product information is saved as properties of the product nodes.
So an:

    svn proplist -v <repo>/Category2/Product1

will show the product properties. If the latest commit was a result
of a deployment task, deployment information will be visible (properties
with a leading 'D:').

To get full deployment information you have to retrieve the properties
for all revisions of the product.

There are of course history methods provided to automate the process.

=cut


our $Debug = 0;
sub _log (@) { print @_, "\n" if $Debug }

# hash for checking subroutine arguments
# m mandatory, o optional
my %arg_check = (
    _init            => {qw/repo m cleanup_tmp o debug o pwd_sub o/},
    build_version    => {qw/category m product m versions o comment o/},
    category_add     => {qw/category m/},
    category_delete  => {qw/category m/},
    category_history => {qw/
        category    m from        m
        to          m  csv        o
        build       o
    /},
    category_list    => {qw/category o/},
    category_update  => {qw/category m new_name m/},
    deploy_version   => {qw/
        category m product m version m target m
        reference_id o reference_data o comment o
    /},
    product_add      => {qw/category m product m cfg o/},
    product_delete   => {qw/category m product m/},
    product_history  => {qw/category m product m from m to m csv o build o/},
    product_list     => {qw/category m product o/},
    product_update   => {qw/category m product m cfg o new_name o/},
);


# check named arguments against %arg_check
sub _getargs {
    my $self = shift;

    $self->{lasterr} = '';

    my $caller = (caller(1))[3];

    unless ( @_ % 2 == 0 ) {
        $self->{lasterr} = "odd number of arguments for $caller()";
        return;
    }

    $caller =~ s/.*::(\w+)$/$1/;
    my %tmp = @_;

    for my $arg ( keys( %{ $arg_check{$caller} } ) ) {
        next if $arg_check{$caller}{$arg} ne 'm';
        unless ( $tmp{$arg} ) {
            $self->{lasterr}
                = "$caller: mandatory parameter '$arg' missing or empty";
            return;
        }
    }

    for my $arg ( keys( %tmp ) ) {
        unless ( exists($arg_check{$caller}{$arg}) ) {
            $self->{lasterr} = "$caller: unknown parameter '$arg'";
            return;
        }
    }

    return(@_);
}


=head2 Constructor new

    my $obj = SVN::Deploy->new(
        repo         => <repo_url>,
        [cleanup_tmp => <0|1>,]
        [debug       => <0|1>,]
        [pwd_sub     => <code_ref>,]
    );

C<'repo'>, C<'cleanup_tmp'> and C<'debug'> should be obvious. C<'pwd_sub'> can
point to a reference to a subroutine returning username and password
for the repository. It will only be called when credentials for a user
cannot be obtained from the svn cache. A successful logon will be
cached.

Returns the created object.

=cut

sub new {
    my($class, %args) = @_;

    my $self = bless({}, $class);
    $self->_init(%args);
    return($self);
}


# initialise object with svn client context
sub _init {
    my $self = shift;
    my %args = $self->_getargs(@_)
        or croak "init failed, ", $self->{lasterr};

    my $cleanup = defined($args{cleanup_tmp})
                ? $args{cleanup_tmp}
                : 1;

    $self->{tempdir} = tempdir(
        'SVN-Deploy-XXXXXX',
        CLEANUP => $cleanup,
        TMPDIR  => 1,
    );

    $SVN::Deploy::Utils::Cleanup = $cleanup;
    $SVN::Deploy::Utils::Verbose = $args{debug};

    $self->{ctx}  = SVN::Deploy::Utils::connect_cached(
        map { $_ => $args{$_} } qw/username password pwd_sub/
    );
    $self->{repo} = $args{repo};
    $Debug        = $args{debug};
}


=head2 METHODS

All methods will return undef on errors. They will return 1 on
success unless another return value is documented.
Calling the C<lasterr()> method will return a printable error description.


=cut

# wrapper for SVN::Client methods
# hook for debugging, sets lasterr, unifies return values
sub _svn {
    my $self = shift;
    my $call = shift;

    _log "calling $call(", join(', ', @_), ')';

    my @ret = $self->{ctx}->$call(@_);

    _log "return:", Dumper(\@ret);

    if ( ref($ret[0]) eq '_p_svn_error_t' ) {
        $self->{lasterr} = "svn call $call(" . join(', ', @_) . ') failed, '
                         . $ret[0]->expanded_message();
        return;
    }

    return(wantarray ? @ret : ($ret[0] || 1) );
};


# running actions
# implemented:
#   - [os] -> run with system()/backticks
sub _run_scripts {
    my($self, $act_ref, $work_dir, $add_args_ref) = @_;

    my $add_args = '';
    if ( ref($add_args_ref) eq 'ARRAY' ) {
       $add_args .= qq("$_" ) for @$add_args_ref;
    }

    my $ret_sum = 0;
    my $output = '';
    for my $act ( @$act_ref ) {
        my($type, $action) = $act =~ /^\[(\w+)\](.*)$/;
        unless ( $action ) {
            _log "no action given in >>$act<<";
            $output .= "no action given in >>$act<<, should be [<type>]<action>\n";
            next;
        }
        if ( $type eq 'os' ) {
            _log "running >>$action $add_args<<";
            my $dir_save = getcwd();
            chdir($work_dir);
            $output .= `$action $add_args 2>&1`;
            my $ret     = $? >> 8;
            _log ">>$action $add_args<< finished, exit code:", $ret;
            $ret_sum   += $ret;
            chdir($dir_save);
        } else {
            _log "unknown type >>$type<< in >>$act<<";
            $output .= "unknown type >>$type<< in >>$act<<, should be [os]<action>\n";
        }
    }
    return($ret_sum, $output);
}


# getting data from filesystem
# creating dir for single files
sub _export_fs {
    my $self = shift;
    my(%args) = @_;

    if ( -d $args{source} ) {
        File::Copy::Recursive::dircopy($args{source}, $args{dir})
            or do {
                $self->{lasterr}
                    = "dircopy($args{source}, $args{dir}) failed, $!";
                return;
            }
    } else {
        my $file = (splitpath($args{source}))[-1];
        unless ( -d $args{dir} ) {
            unless ( mkdir($args{dir}) ) {
                $self->{lasterr} = "mkdir($args{dir}) failed, $!";
                return;
            }
        }
        my $dest = catdir($args{dir}, $file);
        _log "copy >$args{source}< to >$dest<";
        unless ( File::Copy::copy($args{source}, $dest) ) {
            $self->{lasterr} = "copy($args{source}, $dest) failed, $!";
            return;
        }
    }

    return($args{source});
}


# exporting data from source SVN
# creating dir for single files first
sub _export_svn {
    my $self = shift;
    my(%args) = @_;

    my $kind;
    $self->_svn(
        'info', $args{source}, $args{version}, $args{version},
        sub { $kind = $_[1]->kind }, 0,
    ) or return;

    my $dest;
    if ( $kind == $SVN::Node::file ) {
        my $file = (split('/', $args{source}))[-1];
        unless ( mkdir($args{dir}) ) {
            $self->{lasterr} = "mkdir($args{dir}) failed, $!";
            return;
        }
        $dest = catdir($args{dir}, $file);
    } else {
        $dest = $args{dir};
    }

    $self->_svn('export', $args{source}, $dest, $args{version}, 0)
        or return;

    return("$args{source}\[$args{version}\]");
}


=head3 build_version

    $obj->build_version(
        category  => <category_name>,
        product   => <product_name>,
        [versions => {
            [<svn_source> => <svn_version>,]
            [...,]
        },]
        [comment      => <log_message>,]
    );

Export the sources defined by a product to a temporary directory,
run optional build scripts and import everything as new
version for the product in the deploy repository. Each defined
source will result in a numbered subdirectory (starting at 0) of the
product node.

Build scripts can create additional numbered directories in the
temporary directory (e.g. for putting created binaries into).
The build script will be run with the temporary directory as
working directory.

For sources from SVN repositories (beginning with 'svn://' or
'file://'), providing the revision number is mandatory.

Returns the revision number of the last commit to the deploy
repository (every subdirectory is committed separately).

=cut

sub build_version {
    my $self = shift;
    my %args = $self->_getargs(@_) or return;

    # check parameters
    my $root_href = $self->_svn('ls', $self->{repo}, 'HEAD', 0)
        or return;

    unless ( exists($root_href->{$args{category}}) ) {
        $self->{lasterr} = "Category $args{category} does not exist";
        return;
    }

    my $cat_url  = join('/', $self->{repo}, $args{category});
    my $cat_href = $self->_svn('ls', $cat_url, 'HEAD', 0)
        or return;

    unless ( exists($cat_href->{$args{product}}) ) {
        $self->{lasterr} = "Product $args{product} does not exist";
        return;
    }

    # check that version numbers exist for svn sources
    my $plist = $self->product_list(
        category => $args{category},
        product  => $args{product},
    )->{$args{product}};
    foreach my $entry ( @{ $plist->{source} } ) {
        if ( $entry =~ m!^svn://! ) {
            unless (
                ref($args{versions}) eq 'HASH'
                and $args{versions}{$entry}
            ) {
                $self->{lasterr}
                    = "no version specified for source '$entry'";
                return;
            }
        }
    }

    # create dir in tmpdir
    my $prod_tmp = catdir(
        $self->{tempdir},
        join('-', $args{category}, $args{product}),
    );

    unless ( -d $prod_tmp ) {
        unless ( mkdir($prod_tmp) ) {
            $self->{lasterr} = "mkdir($prod_tmp) failed, $!";
            return;
        }
    }

    # get files to subdirs 0, 1 ,...
    my $i = 0;
    my @exported;
    foreach my $entry ( @{ $plist->{source} } ) {
        my $dir = catdir($prod_tmp, $i);
        if ( $entry =~ m!^(?:svn|file)://! ) {
            my $ex_str = $self->_export_svn(
                source  => $entry,
                version => $args{versions}{$entry},
                dir     => $dir,
            ) or return;
            push @exported, $ex_str;
        } else {
            my $ex_str = $self->_export_fs(
                source  => $entry,
                dir     => $dir,
            ) or return;
            push @exported, $ex_str;
        }
        $i++;
    }

    # run build scripts
    $ENV{DEPLOY_CATEGORY} = $args{category};
    $ENV{DEPLOY_PRODUCT}  = $args{product};
    my($ret, $output)
        = $self->_run_scripts($plist->{build}, $prod_tmp);
    if ( $ret ) {
        $self->{lasterr} = "build had errors, output:$output";
        return;
    }
    $self->{output} = "BUILD_OUTPUT:\n" . $output;

    # import into deploy repo
    my $prod_url = join('/', $cat_url, $args{product});
    my $last_revnum = SVN::Deploy::Utils::import_synch(
        dir     => $prod_tmp,
        url     => $prod_url,
        log     => join("\n", 'build:', @exported, $args{comment} || ''),
    ) or do {
        $self->{lasterr}
            = "import_synch failed, $SVN::Deploy::Utils::LastErr";
        return;
    };

    return($last_revnum);
}


=head3 category_add

    $obj->category_add(
        category => <category_name>,
    );

Trying to add an already existing category will result in an error.

=cut

sub category_add {
    my $self = shift;
    my %args = $self->_getargs(@_) or return;

    my $root_href = $self->_svn('ls', $self->{repo}, 'HEAD', 0)
        or return;

    for my $cat ( keys(%$root_href) ) {
        if ( uc($cat) eq uc($args{category}) ) {
            $self->{lasterr} = "Category $args{category} already exists";
            return;
        }
    }

    my $url = join('/', $self->{repo}, $args{category});

    _log "creating >>$url<<";
    $self->_svn('mkdir', $url) or return;

    return(1);
}


=head3 category_delete

    $obj->category_delete(
        category => <category_name>,
    );

Trying to delete a non existing category or deleting a category
with defined products will result in an error.

=cut

sub category_delete {
    my $self = shift;
    my %args = $self->_getargs(@_) or return;

    my $root_href = $self->_svn('ls', $self->{repo}, 'HEAD', 0)
        or return;

    unless ( exists($root_href->{$args{category}}) ) {
        $self->{lasterr} = "Category $args{category} does not exist";
        return;
    }

    my $cat_url  = join('/', $self->{repo}, $args{category});
    my $cat_href = $self->_svn('ls', $cat_url, 'HEAD', 0)
        or return;

    if ( keys(%$cat_href) ) {
        $self->{lasterr} = "Category $args{category} is not empty";
        return;
    }

    _log "deleting >>$cat_url<<";
    $self->_svn('delete', $cat_url, 1)
        or return;

    return(1);
}


=head3 category_history

    $obj->category_history(
        category => <category_name>,
        from     => <revision>,
        to       => <revision>,
        [csv     => <separator>,]
        [build   => <0|1>,]
    );

Returns a reference to an array with history data. If the paramter
C<'csv'> evaluates to false the elemets of the array will be hash
references looking like this:

  {
    'props' => {
      'source' => 'svn://source_srv/source_repo/trunk/mypath1',
      'prod_post' => '[os]perl post.pl',
      'qa_dest' => '/mypath/to/qa/environment',
      'qa_pre' => '[os]perl pre.pl',
      'D:version' => '11',
      'D:target' => 'qa',
      'prod_pre' => '[os]perl pre.pl',
      'D:action' => 'deploy start',
      'prod_dest' => '/mypath/to/prod/environment',
      'build' => '[os]perl build.pl',
      'qa_post' => '[os]perl post.pl',
      'D:reference_id' => '08/15',
      'D:reference_data' => {
        'requested_from' => 'Bill',
        'tested_by'      => 'Bob',
        'pumpking'       => 'Beth',
      },
    },
    'time' => '11:06:33',
    'date' => '2008-05-06',
    'rev' => 12,
    'log' => 'first qa rollout',
    'category' => 'Cat1',
    'product' => 'Product1',
  }

When C<'csv'> is specified the array will contain strings with
concatenated data (with the value of C<'csv'> as concatenator).

The first string will contain concatenated header
names.

The C<'from'> and C<'to'> parameters will acept all the formats the
commandline svn client accepts.

When C<'build'> is set the build instead of the deploy history will be
returned.

=cut

sub category_history {
    my $self = shift;
    my %args = @_;

    $self->{lasterr} = '';

    my $catlist = $self->category_list(category => $args{category})
        or return;

    my @hist;
    for my $p ( sort @{ $catlist->{$args{category}} } ) {
        $args{product} = $p;
        my $hist_ref = $self->product_history(%args) or return;
        push @hist, @$hist_ref;
    }

    return(\@hist);
}


=head3 category_list

    $obj->category_list(
        [category => <category_name>,]
    );

Returns a hashref with category names as keys and a reference to an
array of products as values. Specifying a category will return
information for this category only.

=cut


sub category_list {
    my $self = shift;
    my %args = $self->_getargs(@_);

    my $root_href = $self->_svn('ls', $self->{repo}, 'HEAD', 0)
        or do {
            $self->{lasterr} = "couldn't get categories from repo";
            return;
        };

    if ( $args{category} and !exists($root_href->{$args{category}}) ) {
        $self->{lasterr} = "Category $args{category} does not exist";
        return;
    }

    my @cat_list = $args{category} ? ($args{category}) : keys(%$root_href);

    my %cat_hash;
    foreach my $cat ( @cat_list ) {
        my $cat_url  = join('/', $self->{repo}, $cat);
        my $cat_href = $self->_svn('ls', $cat_url, 'HEAD', 0)
            or return;
        $cat_hash{$cat} = [keys(%$cat_href)];
    }

    return(\%cat_hash);
}


=head3 category_update

    $obj->category_update(
        category => <category_name>,
        new_name => <new_name>,
    );

Rename a category. Defined products will not be touched.

=cut

sub category_update {
    my $self = shift;
    my %args = $self->_getargs(@_) or return;

    my $root_href = $self->_svn('ls', $self->{repo}, 'HEAD', 0)
        or return;

    unless ( exists($root_href->{$args{category}}) ) {
        $self->{lasterr} = "Category $args{category} does not exist";
        return;
    }

    my $old = join('/', $self->{repo}, $args{category});
    my $new = join('/', $self->{repo}, $args{new_name});

    _log "renaming >>$old<< to >>$new<<";
    $self->_svn('move', $old, 'HEAD', $new, 1)
        or return;

    return(1);
}


# add entry to history log
# an entry consists of a set of properties:
my @hist_values = qw/
    target version reference_id reference_data action
/;
sub _hist_add {
    my($self, %args) = @_;

    my $cat_url  = join('/', $self->{repo}, $args{category});
    my $prod_url = join('/', $cat_url, $args{product});

    my $prod_tmp = catdir(
        $self->{tempdir},
        join('-', $args{category}, $args{product}, 'props'),
    );

    if ( -e $prod_tmp ) {
        _log "updating $prod_tmp";
        $self->_svn('update', $prod_tmp, 'HEAD', 0);
    } else {
        _log "checking out '$prod_url' to $prod_tmp";
        $self->_svn('checkout', $prod_url, $prod_tmp, 'HEAD', 0)
            or return;
    }

    my $dir_save = getcwd();
    chdir($prod_tmp);

    $args{reference_id} ||= '';

    # serialize arbitrary external data
    if ( ref($args{reference_data}) ) {
        $args{reference_data}
            = encode_base64(nfreeze($args{reference_data}));
    }

    # setting svn properties
    for my $hv ( @hist_values ) {
        _log "setting property for $hv";
        $self->_svn('propset', "D:$hv", $args{$hv}, $prod_tmp, 0)
            or return;
    }

    _log "committing property changes";

    $self->_svn('log_msg', sub { ${$_[0]} = $args{comment} } )
        if $args{comment};

    $self->_svn('commit', $prod_tmp, 0)
        or return;

    chdir($dir_save);

    return(1);
}


=head3 deploy_version

    $obj->deploy_version(
        category       => <category_name>,
        product        => <product_name>,
        version        => <revision>,
        target         => 'qa'|'prod',
        [reference_id   => <string data>,]
        [reference_data => <reference to serialize>,]
        [comment        => <log message>,]
    );

Deploy a previously build revision of a product to the specified
target.

Defined pre and post scripts (see L</"product_add">) are run before
respectively after deploy.

The reference parameters exist for storing external references
that can later be retrieved by the history functions for auditing
purposes. Typicaly this would be information on who did what on
whose request.

=cut

sub deploy_version {
    my $self = shift;
    my %args = $self->_getargs(@_) or return;

    # get release props
    my $props = $self->product_list(
        category => $args{category},
        product  => $args{product},
    )->{$args{product}};

    my $cat_url  = join('/', $self->{repo}, $args{category});
    my $prod_url = join('/', $cat_url, $args{product});

    unless ( exists($props->{$args{target}}) ) {
        $self->{lasterr} = "unknown target '$args{target}'";
        return;
    }

    $self->_hist_add(%args, action => "deploy start")
        or return;

    $ENV{DEPLOY_CATEGORY} = $args{category};
    $ENV{DEPLOY_PRODUCT}  = $args{product};

    # running pre actions
    my($ret, $output)
        = $self->_run_scripts(
            $props->{$args{target}}{pre},
            $self->{tempdir},
          );
    if ( $ret ) {
        $self->{lasterr} = "pre had errors, output:$output";
        return;
    }
    $self->{output} = "PRE_OUTPUT:\n" . $output;

    # exporting data
    my $i = 0;
    for my $node ( @{ $props->{$args{target}}{dest} } ) {

        next if $node =~ /^\[none\]$/i;

        if ( -e $node ) {
            unless ( -d $node ) {
                $self->{lasterr}
                    = ">>$node<< exists and is not a directory";
                return;
            }
        } else {
            eval { mkpath($node) };
            if ( $@ ) {
                $self->{lasterr} = "mkpath($node) failed, $@";
                return;
            };
        }

        my $url  = join('/', $prod_url, $i);
        $self->_svn('export', $url, $node, $args{version}, 1)
            or return;
    } continue {
        ++$i;
    }

    # running post actions
    ($ret, $output)
        = $self->_run_scripts(
            $props->{$args{target}}{post},
            $self->{tempdir},
            $props->{$args{target}}{dest},
          );
    if ( $ret ) {
        $self->{lasterr} = "post had errors, output:$output";
        return;
    }

    $self->{output} .= "POST_OUTPUT:\n" . $output;

    $self->_hist_add(%args, action => 'deploy end')
        or return;

    return(1);
}


=head3 get_methods

    $obj->get_methods();

Returns a reference to a hash with all available method names as keys
and a hashref for the parameters as values. The parameter hashes have
the parameters as keys and the value will consist of 'm' for mandatory
and 'o' for optional parameters.

=cut

sub get_methods { return(dclone(\%arg_check)) }


=head3 lasterr

    $obj->lasterr();

Returns the text error message for the last encountered error.

=cut

sub lasterr { return($_[0]->{lasterr} || '') }


=head3 output

   $obj->output();

Returns the output from external scripts after a call to
$obj->build_version() or $obj->deploy_version.

=cut

sub output  { return($_[0]->{output}  || '') }


# relocated check for product_* methods
sub _product_args_check {
    my $self = shift;
    my %args = @_;

    my $root_href = $self->_svn('ls', $self->{repo}, 'HEAD', 0)
        or return;

    unless ( exists($root_href->{$args{category}}) ) {
        $self->{lasterr} = "Category $args{category} does not exist";
        return;
    }

    return(1) unless $args{cfg};

    # source is mandatory
    unless (
        $args{cfg}{source} and ref($args{cfg}{source}) eq 'ARRAY'
        and @{ $args{cfg}{source} }
    ) {
        $self->{lasterr} = "no source specified";
        return;
    }

    # optional build scripts
    if (
        exists($args{cfg}{build})
        and ref($args{cfg}{build}) ne 'ARRAY'
    ) {
        $self->{lasterr}
            = "parameter 'build' must contain an array ref";
        return;
    }

    for my $env (qw/qa prod/) {

        for my $key (qw/dest pre post/) {

            if (
                exists($args{cfg}{$env}{$key})
                and ref($args{cfg}{$env}{$key}) ne 'ARRAY'
            ) {
                $self->{lasterr}
                    = "$env: parameter '$key' must contain an array ref";
                return;
            }
        }

        if (
            exists($args{cfg}{$env}{dest})
            and @{ $args{cfg}{$env}{dest} } )
        {
            if ( @{ $args{cfg}{$env}{dest} } < @{ $args{cfg}{source} } ) {
                $self->{lasterr}
                    = "$env: destination for one ore more sources missing";
                return;
            }
        }
    }

    return(1);
}


# relocated set function for product_* methods
sub _product_set_params {
    my $self = shift;
    my %args = @_;

    my $prod_tmp = catdir(
        $self->{tempdir},
        join('-', $args{category}, $args{product}, 'props'),
    );

    if ( -e $prod_tmp ) {
        _log "updating $prod_tmp";
        $self->_svn('update', $prod_tmp, 'HEAD', 0)
            or return;
    } else {
        _log "checking out '$args{prod_url}' to $prod_tmp";
        $self->_svn('checkout', $args{prod_url}, $prod_tmp, 'HEAD', 0)
            or return;
    }

    my $dir_save = getcwd();
    chdir($prod_tmp);

    for my $param ( qw/build source/ ) {
        next unless $args{cfg}{$param};
        $self->_svn(
            'propset',
            $param,
            join("\n", @{ $args{cfg}{$param} }),
            $prod_tmp,
            0,
        ) or return;
    }

    for my $env (qw/qa prod/) {
        for my $key (qw/dest pre post/) {
            if ( $args{cfg}{$env}{$key} ) {
                $self->_svn(
                    'propset',
                    "${env}_$key",
                    join("\n", @{ $args{cfg}{$env}{$key} }),
                    $prod_tmp,
                    0,
                ) or return;
            }
        }
    }

    _log "committing property changes";
    $self->_svn('commit', $prod_tmp, 0) or return;

    chdir($dir_save);

    return(1);
}


=head3 product_add

    my %cfg = (
        build  => [
            '[os]perl build1.pl',
            '[os]perl build2.pl',
        ],
        source => [
            'svn://source_srv/source_repo/trunk/mypath1',
            'svn://source_srv/source_repo/trunk/mypath2',
        ],
        qa => {
            dest => [
                '[none]',
                '/mypath/to/qa/environment',
            ],
            pre  => ['[os]perl pre.pl'],
            post => ['[os]perl post.pl'],
        },
        prod => {
            dest => [
                '[none]',
                '/mypath/to/prod/environment',
            ],
            pre  => ['[os]perl pre.pl'],
            post => ['[os]perl post.pl'],
        },
    );

    $obj->product_add(
        category => <category_name>,
        product  => <product_name>,
        [cfg      => \%cfg,]
    );

Add a new product to a category. When specifying a destination, you
have to provide a destination for each specified source. '[none]' is a
valid destination, meaning the corresponding path of the deploy
repository will not be exported when calling $obj->deploy_version. You
can have more destinations than sources, e.g. when the build scripts
create additional directories.

You can create a product without a configuration, but you have to call
$obj->product_update with a valid configuration before calling build
or deploy methods.

The C<'pre'>, C<'post'> and C<'build'> parameters have to be references to arrays with commands.
The commands must be prefixed by C<'[os]'> and will be run with C<qx//> (backticks).
This is to be able to add other types of commands in later versions.

=cut

sub product_add {
    my $self = shift;
    my %args = $self->_getargs(@_) or return;

    $self->_product_args_check(%args) or return;

    my $cat_url  = join('/', $self->{repo}, $args{category});
    my $cat_href = $self->_svn('ls', $cat_url, 'HEAD', 0)
        or return;
    my $prod_url = join('/', $cat_url, $args{product});

    for my $prod ( keys(%$cat_href) ) {
        if ( uc($prod) eq uc($args{product}) ) {
            $self->{lasterr} = "Product $args{product} already exists";
            return;
        }
    }

    _log "creating >>$prod_url<<";
    $self->_svn('mkdir', $prod_url) or return;

    $args{prod_url} = $prod_url;

    if ( $args{cfg} ) {
        $self->_product_set_params(%args) or return;
    }

    return(1);
}


=head3 product_delete

    $obj->product_add(
        category => <category_name>,
        product  => <product_name>,
    );

Deletes an existing product.

=cut

sub product_delete {
    my $self = shift;
    my %args = $self->_getargs(@_) or return;

    my $root_href = $self->_svn('ls', $self->{repo}, 'HEAD', 0)
        or return;

    unless ( exists($root_href->{$args{category}}) ) {
        $self->{lasterr} = "Category $args{category} does not exist";
        return;
    }

    my $cat_url  = join('/', $self->{repo}, $args{category});
    my $cat_href = $self->_svn('ls', $cat_url, 'HEAD', 0)
        or return;

    unless ( exists($cat_href->{$args{product}}) ) {
        $self->{lasterr} = "Product $args{product} does not exist";
        return;
    }

    my $prod_url = join('/', $cat_url, $args{product});

    _log "deleting >>$prod_url<<";
    $self->_svn('delete', $prod_url, 0)
        or return;

    return(1);
}


=head3 product_history

    $obj->product_history(
        category => <category_name>,
        product  => <product_name>,
        from     => <revision>,
        to       => <revision>,
        [csv     => <separator>,]
        [build   => <0|1>,]
    );

See L</"category_history"> for a description. product_history just returns
the history for one product.

=cut

my @base_headers   = qw/Date Time Category Product Revision/;
my @deploy_headers = qw/Action ReferenceID ReferenceData Comment/;
my @build_headers  = qw/Built_From/;
sub product_history {
    my $self = shift;
    my %args = $self->_getargs(@_) or return;

    my $root_href = $self->_svn('ls', $self->{repo}, 'HEAD', 0)
        or return;

    unless ( exists($root_href->{$args{category}}) ) {
        $self->{lasterr} = "Category $args{category} does not exist";
        return;
    }

    my $cat_url  = join('/', $self->{repo}, $args{category});
    my $cat_href = $self->_svn('ls', $cat_url, 'HEAD', 0);

    unless ( exists($cat_href->{$args{product}}) ) {
        $self->{lasterr} = "Product $args{product} does not exist";
        return;
    }

    my $prod_url = join('/', $cat_url, $args{product});

    # get all selected revisions for $prod_url
    my @revisions;
    $self->_svn(
        'log', [$prod_url], $args{from}, $args{to}, 0, 0,
        sub {
            my($date, $time) =
                $_[3] =~ /(\d\d\d\d-\d\d-\d\d)T(\d\d:\d\d:\d\d)/;
            $_[4] =~ s/\n/ /g;
            push @revisions, {
                category => $args{category},
                product  => $args{product},
                rev      => $_[1],
                date     => $date,
                time     => $time,
                log      => $_[4]
            };
        },
    ) or return;

    my @out_revs;
    if ( $args{build} ) {

        # filter for log messages beginning with "build:\n"
        my %seen;
        @out_revs = map {
            $seen{$_->{log}} ? () : do { $seen{$_->{log}} = 1; $_ }
        } sort {
            $b->{rev} <=> $a->{rev}
        } grep {
            $_->{log} =~ /^build:/
        } @revisions;

    } else {

        # filter for deploy information properties
        for my $r ( @revisions ) {
            # get properties for the revision
            my $props = $self->_svn('proplist', $prod_url, $r->{rev}, 0)
                or return;
            next unless @$props;
            $r->{props} = $props->[0]->prop_hash;

            if ( $r->{props}{'D:reference_data'} ) {
                $r->{props}{'D:reference_data'}
                    = thaw(decode_base64($r->{props}{'D:reference_data'}));
            }
        }

        @out_revs = grep {
            $_->{props}{'D:version'}
        } @revisions;

    }

    return(\@out_revs) unless $args{csv};

    # csv output

    my @headers = ( @base_headers, $args{build} ? @build_headers : @deploy_headers );

    push(my @csv, join($args{csv}, @headers));

    push(
        @csv,
        join(
            $args{csv},
            @$_{qw/date time/},
            $_->{category},
            $_->{product},
            $args{build}
                ? ()
                : @{$_->{props}}{qw/
                    D:version       D:action
                    D:reference_id  D:reference_data
                  /},
            $_->{log},
        )
     ) for @out_revs;

     return(\@csv);
}


=head3 product_list

    $obj->product_list(
        category => <category_name>,
        [product  => <product_name>,]
    );

Returns a reference to a hash with product names as keys and a
reference to the product's configuration hash as values. The structure
is the same as the one specified for the parameter cfg in
$obj->product_add or $obj->product_update.

=cut

sub product_list {
    my $self = shift;
    my %args = $self->_getargs(@_) or return;

    my $root_href = $self->_svn('ls', $self->{repo}, 'HEAD', 0)
        or return;

    unless ( exists($root_href->{$args{category}}) ) {
        $self->{lasterr} = "Category $args{category} does not exist";
        return;
    }

    my $cat_url  = join('/', $self->{repo}, $args{category});
    my $cat_href = $self->_svn('ls', $cat_url, 'HEAD', 0);

    if ( $args{product} and !exists($cat_href->{$args{product}}) ) {
        $self->{lasterr} = "Product $args{product} does not exist";
        return;
    }

    my @prod_list = $args{product} ? ($args{product}) : keys(%$cat_href);

    my %prod_hash;
    foreach my $prod ( @prod_list ) {
        my $prod_url = join('/', $cat_url, $prod);
        my $prop_ref = $self->_svn(
            'proplist', $prod_url, 'HEAD', 0
        ) or return;
        my $props = $prop_ref->[0]
                  ? $prop_ref->[0]->prop_hash
                  : {};

        for my $prop ( qw/build source/ ) {
            $props->{$prop}
            = [split(/\n/, $props->{$prop} || '')];
        }

        for my $env (qw/qa prod/) {
            for my $key (qw/dest pre post/) {
                $props->{$env}{$key}
                    = [split(/\n/, $props->{"${env}_$key"} || '')];
                delete($props->{"${env}_$key"});
            }
        }

        $prod_hash{$prod} = $props;
    }

    return(\%prod_hash);
}


=head3 product_update

    $obj->product_update(
        category => <category_name>,
        product  => <product_name>,
        [cfg      => \%cfg,]
        [new_name => <product_name>,]
    );

Rename an existing Product and/or change its configuration. See
$obj->product_add for the description of the configuration hash.

=cut

sub product_update {
    my $self = shift;
    my %args = $self->_getargs(@_) or return;

    $self->_product_args_check(%args) or return;

    my $cat_url  = join('/', $self->{repo}, $args{category});
    my $cat_href = $self->_svn('ls', $cat_url, 'HEAD', 0)
        or return;
    my $prod_url = join('/', $cat_url, $args{product});

    unless ( exists($cat_href->{$args{product}}) ) {
        $self->{lasterr} = "Product $args{product} does not exist";
        return;
    }

    if ( $args{new_name} ) {

        my $old = join('/', $self->{repo}, $args{category}, $args{product});
        my $new = join('/', $self->{repo}, $args{category}, $args{new_name});

        _log "renaming >>$old<< to >>$new<<";
        $self->_svn('move', $old, 'HEAD', $new, 1)
            or return;

        $args{product} = $args{new_name};
        delete($args{new_name});
    }

    $args{prod_url} = $prod_url;

    if ( $args{cfg} ) {
        $self->_product_set_params(%args) or return;
    }

    return(1);
}


1;


=head1 AUTHOR

Thomas Kratz E<lt>tomk@cpan.orgE<gt>

Copyright (c) 2008 Thomas Kratz. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
