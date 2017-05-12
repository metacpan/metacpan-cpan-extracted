package SVN::Deploy::Utils;

use strict;
use warnings;

our $VERSION = '0.11';

use Carp;
use SVN::Client;

use Cwd;
use Digest::MD5;
use File::Spec::Functions qw/:ALL/;
use File::Copy;
use File::Temp qw/tempdir/;

use Data::Dumper;
 $Data::Dumper::Indent=1;


our $Cleanup = 1;
our $Verbose = 0;
our $LastErr = '';


my %arg_check = (
    connect_cached  => {qw/username o password o pwd_sub o/},
    import_synch    => {qw/
        dir m url m log o
        checkout o ctx o
    /},
);


sub _vlog($@) { print join(' ', @_), "\n" if $Verbose; };


sub _getargs {
    my $caller = (caller(1))[3];
    croak "odd number of arguments for $caller()"
        unless @_ % 2 == 0;

    $caller =~ s/.*::(\w+)$/$1/;
    my %tmp = @_;

    for my $arg ( keys( %{ $arg_check{$caller} } ) ) {
        next if $arg_check{$caller}{$arg} ne 'm';
        croak "$caller: mandatory parameter '$arg' missing or empty"
            unless $tmp{$arg};
    }

    for my $arg ( keys( %tmp ) ) {
        croak "$caller: unknown parameter '$arg'"
            unless exists($arg_check{$caller}{$arg});
    }

    return(@_);
}


sub _getmd5 {
    my($fn) = @_;

    open(my $fh, '<', $fn)
       or croak "couldn't read '$fn', $!";
    binmode($fh);
    my $md5 = Digest::MD5->new()->addfile($fh)->hexdigest();
    close($fh);

    return($md5);
}


sub _svn {
    my $ctx  = shift;
    my $call = shift;

    my @ret = $ctx->$call(@_);

    if ( ref($ret[0]) eq '_p_svn_error_t' ) {
        $LastErr = "svn call $call(" . join(', ', @_) . ') failed, '
                 . $ret[0]->expanded_message();
        return;
    }

    return(wantarray ? @ret : ($ret[0] || 1) );
};


sub _simple_prompt {
    my($realm) = @_;
    my %cred;
    print "Logon information for $realm\n";
    for my $par ( qw/username password/ ) {
        print ucfirst($par), ": ";
        $cred{$par} = <STDIN>;
        chomp($cred{$par});
    }
    return(@cred{qw/username password/});
}


sub connect_cached {
    my %args = _getargs(@_);

    my $ctx = SVN::Client->new(
        auth => [
            SVN::Client::get_simple_provider(),
            SVN::Client::get_simple_prompt_provider(sub {
                unless ( $args{username} and $args{password} ) {
                    my $subref = ref($args{pwd_sub}) eq 'CODE'
                               ? $args{pwd_sub}
                               : \&_simple_prompt;
                    @args{qw/username password/} = $subref->($_[1]);
                }
                $_[0]->username($args{username});
                $_[0]->password($args{password});
                $_[0]->may_save(1);
            }, 2),
            SVN::Client::get_username_provider()
        ],
    );

    return($ctx);
}


sub import_synch {
    my %args = _getargs(@_);

    my $ctx = $args{ctx} || connect_cached();

    $args{dir} = rel2abs($args{dir});

    my $tempdir = tempdir(
        'SVN-Deploy-Utils-XXXXXX',
        CLEANUP => $Cleanup,
        TMPDIR  => 1,
    );

    my $origdir = getcwd();

    if ( $args{log} ) {
        _svn($ctx, 'log_msg', sub { ${$_[0]} = $args{log}; })
            or return;
    }

    # iterating over svn dir
    #  - locally missing -> delete in svn
    #  - locally name matches, type differs -> delete in svn
    _vlog "pass 1: check for deleted items";
    my @dstack;
    my %todo;
    my %ent_cache;
    my $last_commit_revnum = -1;
    do {{
        my $suburl = join('/', @dstack);
        $suburl    = ' ' unless length($suburl);
        my $url    = join('/', $args{url}, @dstack);
        my $subdir = catdir(@dstack);
        my $dir    = catdir($args{dir}, $subdir);

        # get entries for $url unless already done
        unless ( $todo{$suburl} ) {

            _vlog "getting entries for $url";

            my $entries_href = _svn($ctx, 'ls', $url, 'HEAD', 0)
                or return;

            _vlog Dumper($entries_href);

            $todo{$suburl} = [
                map { {
                    name => $_,
                    kind => $entries_href->{$_}->kind,
                    time => $entries_href->{$_}->time,
                    size => $entries_href->{$_}->size,

                } } keys(%$entries_href)
            ];

            # cache entries for later
            $ent_cache{ join('/', $url, $_) }
                = $entries_href->{$_} for keys(%$entries_href);
        }

        my $node = shift(@{$todo{$suburl}});

        # all nodes processed -> one up
        unless ( defined($node) ) {
            _vlog "  --> no more nodes in $suburl, going back";
            pop(@dstack);
            delete($todo{$suburl}) unless $suburl eq ' ';
            next;
        }

        my $locfile  = catfile($dir, $node->{name});
        my $svnfile  = join('/', $url, $node->{name});
        my $svnshort = join('/', @dstack, $node->{name});

        _vlog "  --> processing node '$svnshort'";

        # process node
        if ( $node->{kind} == $SVN::Node::dir ) {
            if ( -d $locfile ) {
                _vlog "   --> dir: pushing on stack";
                push(@dstack, $node->{name});
            } else {
                _vlog "   --> locally deleted or type changed -> deleting";
                my $info = _svn($ctx, 'delete', $svnfile, 1)
                    or return;
                $last_commit_revnum = $info->revision;
                delete($ent_cache{$svnfile});
            }
        } else {
            next if -e $locfile and !-d $locfile;
            _vlog "   --> locally deleted or type changed -> deleting";
            my $info = _svn($ctx, 'delete', $svnfile, 1)
                or return;
            $last_commit_revnum = $info->revision;
            delete($ent_cache{$svnfile});
        }

    }} while @dstack or @{$todo{' '}};


    # iterating over external dir
    #  - new dirs  -> mkdir in repo
    #  - new files -> add to repo, add MD5 property
    #  - external file time > repo file time
    #    or external file size != repo file size
    #    or external file MD5 != MD5 property
    #     -> commit, set md5 property
    _vlog "pass 2: check for new or changed items";
    @dstack = ();
    %todo   = ();
    my %to_commit;
    do {{
        my $suburl = join('/', @dstack);
        my $url    = join('/', $args{url}, @dstack);
        my $subdir = catdir(@dstack);
        $subdir    = ' ' unless length($subdir);
        my $dir    = catdir($args{dir}, @dstack);

        # get entries for $dir unless already done
        unless ( $todo{$subdir} ) {
            opendir(my $dh, $dir)
               or croak "couldn't open dir '$dir', $!";
            $todo{$subdir} = [grep {not /^\.{1,2}$/} readdir($dh)];
        }

        my $node = shift(@{$todo{$subdir}});

        # all nodes processed -> one up
        unless ( defined($node) ) {
            _vlog "  --> no more nodes in $subdir, going back";
            pop(@dstack);
            delete($todo{$subdir}) unless $subdir eq ' ';
            next;
        }

        my $locfile  = catfile($dir, $node);
        my $svnfile  = join('/', $url, $node);
        my $locshort = catfile(@dstack, $node);

        _vlog "  --> processing node '$locshort'";

        # process node
        my $svnent = $ent_cache{$svnfile};

        if ( -d $locfile ) {

            unless ( defined($svnent) ) {
               _vlog "   --> dir: creating in svn";
               _svn($ctx, 'mkdir', $svnfile) or return;
            }
            _vlog "   --> dir: pushing on stack";
            push(@dstack, $node);

        } else {

            my($svn_md5, $loc_md5);
            my $state = 'new';

            if ( defined($svnent) ) {

                # exists in svn -> compare
                my $svn_time = $svnent->time;
                my $svn_size = $svnent->size;
                $svn_md5
                    = _svn($ctx, 'propget', 'md5', $svnfile, 'HEAD', 0);
                $svn_md5 = ($svn_md5 && $svn_md5->{$svnfile})
                         ? $svn_md5->{$svnfile}
                         : '';
                substr($svn_time, -6) = '';

                my $loc_time = (stat($locfile))[9];
                my $loc_size = -s $locfile;
                $loc_md5     = _getmd5($locfile);

                next if $loc_size == 0 and $svn_size == 0;

                my $changed
                    = (
                           $loc_size != $svn_size
                        or $loc_time >  $svn_time
                        or $loc_md5  ne $svn_md5
                    );

                if ( $changed ) {
                    $state = 'changed';
                } else {
                    next;
                }
            } else {
                $loc_md5 = _getmd5($locfile);
            }

            _vlog "   --> $state file: adding to svn";

            # copying file to workdir
            unless ( $to_commit{$subdir} and -d $to_commit{$subdir} ) {
                my $tempsub = catdir($tempdir, join('-', @dstack) || 'root' );
                _vlog "   --> checkout '$url' to '$tempsub'";
                _svn($ctx, 'checkout', $url, $tempsub, 'HEAD', 0)
                    or return;
                $to_commit{$subdir} = $tempsub;
            }
            my $workfile = catfile($to_commit{$subdir}, $node);
            copy($locfile, $workfile)
               or croak "couldn't copy '$locfile' to '$workfile', $!";

            chdir($to_commit{$subdir});
            if ( $state eq 'new' ) {
                _svn($ctx, 'add', $node, 0)
                    or return;
            }
            _svn($ctx, 'propset', 'md5', $loc_md5, $node, 0)
                or return;
        }

    }} while @dstack or @{$todo{' '}};

    for my $v ( values(%to_commit) ) {
        my $info = _svn($ctx, 'commit', $v, 0)
            or return;
        $last_commit_revnum = $info->revision
           if $info->revision != $SVN::Core::INVALID_REVNUM;
    }

    chdir($origdir);

    return($last_commit_revnum);
}


1;

## POD
=head1 NAME

SVN::Deploy::Utils - utility functions for SVN::Deploy

=head1 SYNOPSIS

  use SVN::Deploy::Utils;

  my $rev = import_synch(
    dir => '/my/local/dir',
    url => 'svn://myrepo/trunk/mypath',
    log => 'my import logmessage',
  ) or die $SVN::Deploy::Utils::LastErr;

=head1 DESCRIPTION

SVN::Deploy::Utils provides two high level utility functions
encapsuling SVN::Client methods.

=head1 FUNCTIONS

All functions return undef on error. $SVN::Deploy::Utils::LastErr will
contain a printable error message.

=head2 connect_cached

  my $ctx = connect_cached(
    [username => <name>,]
    [password => <password>,]
    [pwd_sub  => <code_ref>,]
  );

Returns an SVN::Client context object caching the authorization
information for later use. pwd_sub must reference a sub returning
username and password for e.g. user interaction.

=head2 import_synch

  my $rev = import_synch(
      dir => <local_dir>,
      url => <repo URL>,
      [log => <log message>,]
      [ctx => <SVN::Client context>,]
  )

Imports a local directory into a subversion repository. Adds or
deletes files and directories when neccessary, so that repeating calls
after changes in the local unversioned directory will result in
corresponding changes in the repository path.

If ctx is specified import_synch will use this context, otherwise it
will call connect_cached() without parameters.

=head1 AUTHOR

Thomas Kratz E<lt>tomk@cpan.orgE<gt>

Copyright (c) 2008 Thomas Kratz. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
