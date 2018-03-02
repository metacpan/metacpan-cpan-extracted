########################################################################
# housekeeping
########################################################################

# Use the lowest-version of Perl that supports
# File::Copy::Recursive & friends -- yeah, ancient.

package Module::FromPerlVer;
use 5.006;
use strict;
use version;

use NEXT;

use Cwd                     qw( cwd                     );
use File::Basename          qw( basename                );
use File::Copy::Recursive   qw( dircopy                 );
use File::Find              qw( find                    );
use FindBin                 qw( $Bin                    );
use List::Util              qw( first                   );
use Scalar::Util            qw( blessed                 );
use Symbol                  qw( qualify qualify_to_ref  );

use Module::FromPerlVer::Dir;

########################################################################
# package variables & sanity checks
########################################################################

our $VERSION    = version->parse( 'v0.0.2' )->numify;

my %defaultz = 
(
    # pick your poison

    default_use     => 'dir',
    use_dir         => '',
    use_git         => '',

    # global settings

    perl_version    => '',
    version_from    => '',
    verbose         => '',

    # directory

    version_dir     => 'version',

    # git

    git_prefix      => 'perl/',
);

########################################################################
# utility subs
########################################################################

my $extract_args
= sub
{
    my ( undef, %argz ) = @_;

    while( my ($k, $def_v) = each %defaultz )
    {
        my $env_k   = uc $k;
        my $env_v   = $ENV{ $env_k };

        for( $argz{ $k } )
        {
            if( defined $env_v )
            {
                print "# Env: $k = '$env_v' ($env_k)";

                $argz{ $k } = $env_v;
            }
            elsif( defined $argz{ $k } )
            {
                print "# Arg: $k = '$_'";
            }
            elsif( $def_v )
            {
                print "# Def: $k = '$def_v'";

                $argz{ $k } = $def_v;
            }
            else
            {
                # nothing more to do: the default
                # isn't overridden and it false,
                # no argument supplied: skip it.
            }
        }
    }

    \%argz
};

my $make_extract
= sub
{
    my $argz    = shift;

    my @found 
    = map
    {
        m{ (use_ ([a-z]+) ) }x && delete $argz->{ $1 }
        ? $2
        : ()
    }
    keys %$argz;

    local $, = ' ';

    if( @found > 1 )
    {
        die "Invalid: Multiple sources, @found\n";
    }
    elsif( @found )
    {
        # nothing more do do
    }
    else
    {
        push @found, delete $argz->{ default_use };
    }

    my $type    = ucfirst $found[0];
    my $pkg     = qualify $type;

    $argz->{ type } = $type;

    print "# Extract with: '$type' ($pkg)";

    $pkg->new( $argz )
};

my $extract_perl_v
= sub
{
    my $extract = shift;
    my $perl_v  = '';

    if( $perl_v = $extract->value( 'perl_version' ) )
    {
        eval
        {
            version->parse( $perl_v )->numify
        }
        or 
        die "Unparsable perl version: '$perl_v'\n"
    }
    elsif( my $path = $extract->{ version_from } )
    {
        -e $path or die "Bogus version_from: non-existant '$path'\n";
        -f _     or die "Bogus version_from: non-file     '$path'\n";
        -s _     or die "Bogus version_from: zero-size    '$path'\n";
        -r _     or die "Bogus version_from: non-readable '$path'\n";

        # at this point the version file seems minimally usable.

        open my $fh, '<', $path
        or
        die "Botched version_from: open '$path', $!\n";

        $perl_v
        = first
        {
            if
            (
                my ( $min_v )
                = m{ \buse \s+ (v? 5[.] +?) \s* ; }
            )
            {
                $perl_v 
                = version->parse( $min_v )->numify
                or 
                die "Invalid version string: '$_' ($path)"
            }
            elsif
            (
                my ( $max_v ) 
                = m{ \bno  \s+ (v? 5[.] +?) \s* ; }
            )
            {
                $perl_v
                = version->parse( $max_v )->numify - 0.000001
                or 
                die "Invalid version string: '$_' ($path)"
            }
            else
            {
                ''
            }
        }
        readline $fh
        or
        die "Bogus version_from: '$path' lacks '(use|no) version'.\n";
    }
    else
    {
        # this *should* always be parseable.

        $perl_v = version->parse( $^V )->numify
        or
        die "Severe weirdness: unparsable \$^V ($^V).\n";
    }

    $extract->value( perl_version => $perl_v )
};

my @handlerz = 
(
    sub
    {
        # acquire running perl version.

        my $extract = shift;
        my $perl_v  = $extract->$extract_perl_v;

        # lacking an exception, we have a perl version.

        *{ qualify_to_ref 'perl_version' }
        = sub 
        {
            $perl_v
        };

        print '# Perl version: ' . perl_version();

        return
    },

    sub
    {
        # extract source of the inputs. this will be
        # either the ./version directory or a git tag
        # prefix.

        my $extract = shift;
        my $prefix  = $extract->source_prefix;

        *{ qualify_to_ref 'source_prefix' }
        = sub
        {
            $prefix
        };

        print '# Source prefix: ' . source_prefix();

        return
    },

    sub
    {
        # locate source appropriate for perl version.

        my $extract = shift;
        my $perl_v  = perl_version();

        my @sourcz  = $extract->module_sources
        or die "Botched module_sources: empty source list.\n";

        my $found
        =first
        {
            $perl_v >= $_->[0]
        }
        sort
        {
            $b->[0] <=> $a->[0]
        }
        map
        {
            [
                version->parse( basename $_ )->numify,
                $_
            ]
        }
        @sourcz
        or do
        {
            local $,    = "\n#\t";

            die 'Botched module_source: no appropriate version',
            @sourcz, "\n";
        };

        my ( $mod_v, $path ) = @$found;

        print "# Module version: $mod_v <= $perl_v";

        $extract->value( module_source => $path );

        *{ qualify_to_ref 'module_source' }
        = sub
        {
            $path
        };

        print '# Module source: ' . module_source();

        return
    },

    sub 
    {
        # locate files to copy
        #
        # pre-assigning the hashref's simplifies dealing
        # with a collection of empty dir's.

        my $extract = shift;
        my $ref     = qualify_to_ref 'source_files';

        if( my @pathz   = $extract->source_files )
        {
            *$ref
            = sub
            {
                wantarray
                ? @pathz
                : $pathz[0]
            };

            local $,    = "\n#\t";
            print '# Source files:', @{ scalar source_files() };
        }
        else
        {
            *$ref
            = sub
            {
                # avoid returning true in scalar context

                return
            };

            print '# No source files.';
        }

        return
    },

    sub
    {
        my $ref = qualify_to_ref 'cleanup';

        if( my ( $filz, $dirz ) = source_files() )
        {
            *$ref
            = sub
            {
                unlink @$filz;

                -e $_ && warn "Failed removal: '$_'"
                for @$filz;

                # i.e., don't clobber dir's which have any
                # files we didn't copy in them. this is most
                # likely for ./t which can have common tests.

                for my $dir ( @$dirz )
                {
                    ( my @a = glob "$dir/*" )
                    or 
                    rmdir $dir;
                }

                return
            };

            print '# Install cleanup.';
        }
        else
        {
            *$ref   = sub{};

            print '# Nothing to clean up.';
        }

        return
    },

    sub
    {
        my $extract = shift;

        *{ qualify_to_ref 'get_files' }
        = sub
        {
            $extract->get_files
        };

        print "# Get files with: '$extract->{ type }'";

        return
    }
);

########################################################################
# import is where it all happens
########################################################################

sub import
{
    local $\    = "\n";

    my $argz    = &$extract_args;
    my $extract = $make_extract->( $argz );

    $extract->$_ for @handlerz;

    # at this point the args are consumed and if we are 
    # still alive the utility subs are installed.
    #
    # Note: this returns true if the handler cycle completed
    # (either no_copy value or result of making the copy).

    $extract->{ no_copy }
    or
    copy_source_dir()
}

# keep require happy
1
__END__

=head1 NAME

Module::FromPerlVer - install modules compatible with the running perl.

=head1 SYNOPSIS

    # Aside: unless anyone can find a glaring omission in 
    # the mechanism or utility sub selection this will
    # become version v1.0.

    # ./version directory has sub-dirs with basenames of 
    # parsable perl version strings.
    # 
    # when this module is used the highest numbered version
    # directory compatile with the running perl is copied 
    # into the execution directory of Makefile.PL.
    #
    # source_paths() is useful for describing what gets
    # copied, cleanup() is handy for iterating tests or
    # prior to making a bundle.

    # Makefile.PL

    use Module::FromPerlVer;

    # relative paths to files copied for this version of 
    # perl -- different versions of perl may have different
    # collections of files copied.

    my $copied_files    = Module::FromPerlVer->source_paths;

    # remove the files copied and any empty direcories they
    # were copied into (dir's with pre-copy files left in
    # them are untouched).

    my $removed_count   = Module::FromPerlVer->cleanup;

    # at this point lib, t, and friends are populated with 
    # modules compatible with the running perl. because 
    # the destination directory is $Bin this can include 
    # README, MANIFEST, or Changes files. note that 
    # overwriting  Makefile.PL will *not* work since it 
    # has already been compiled.

    # override the perl version:

    # this can be useful for regression testing earlier 
    # versions of modules against the running version 
    # (e.g., validating experimental features, benchmarking
    # older code against newer perl executables).
    #
    # arguments can be passed to use or set in the environment
    # with a variable of the option uppercased. For example:

    $ PERL_VERSION='5.024002' perl Makefile.PL;

    use Module::FromPerlVer qw( perl_version v5.24.1 );

    # use a file to determine the perl version.
    # this takes the use-ed version from the file
    # to set the expected perl version (e.g., to 
    # validate if other modules are suitable).

    use Module::FromPerlVer   qw( version_from ./lib/foobar.pm );

    VERSION_FROM='./lib/foobar.pm' use Module::FromPerlVer;

    # or a one-line datafile.
    # "use vX.Y.Z" will find up to that version, "no vX.Y.Z" will 
    # use up to that version minus '0.000001'.
    #
    # perl versions with use or no support any version
    # string avaiable (see "version" module).
    # 
    # say that v5.24.2 breaks your module:

    echo 'no v5.24.2' > ./perl-version;

    use Module::FromPerlVer   qw( version_from file_path );

    # override the source directory:

    # maybe you don't like the name 'version', you
    # prefer "history" instead.

    use Module::FromPerlVer   qw( source_prefix history );

    # maybe you don't like storing your older versions in 
    # a directory, you prefer to use git with tags to snag
    # the working directory with a default tag prefix of 
    # "perl/" (or pick your own):

    use Module::FromPerlVer qw( use_git 1 );
    use Module::FromPerlVer qw( source_prefix ThingyDotNet/ );

    # set up everything but skip making the copy.
    #
    # this reqires callig "copy_source_dir" to get the 
    # versioned files in their proper place.
    #
    # none of the utility subs take any arguments and
    # can all be called using module or object notation.

    use Module::FromPerlVer   qw( no_copy 1 );

    my ( $filz, $dirz ) = Module::FromPerlVer::source_files;

    Module::FromPerlVer->copy_source_dir;

    my $madness = 'Module::FromPerlVer';
    my $method  = 'cleanup';

    $madness->$method;



=head1 DESCRIPTION 

Basic idea: Divide up the source space for a module distro
by supporting Perl version. At that point when you want to 
start using features in a new version of Perl just start a
new directory and work with it. When you release the module
distro the module's version compatible with the running 
perl will be selected at install time. No tests in the module
for $^V are necessary.

=head2 Using the module

Using this module requires two things: The module and a source
for perl-version-speific files. With "use_dir" the files are
found in a specific local directory; with "use_git" the are
found via (guess... if you said "cvs checkout from ./attic"
you'd be wrong).

=over 4

=item Version Directory

The default directory for module versions is "version". This 
has sub-directories that are parseable as Perl versions:

    ./version/5.005_003  
    ./version/5.006001
    ./version/5.16
    ./version/v5.24

in each case the basename of the directory is processed by
version::parse.

The filesystem under each version is whatever dir's and 
files are suitable for that version of perl. Common 
examples are README, MANIFEST, Changes, ./lib, ./t,
./bin.

=item Version Tag

With git the current repository is scanned via "git tags"
with the source prefix. The versions need to look path-ish:

    perl/v5.6.1
    Perly/5.005003
    MyPerlStuff/v5.24

will all do nicely: they have a '/' with a "basename" of
a parsable perly version.

=item Basic Use

Using the module in setup code (e.g., Makefile.PL):

    use Module::FromPerlVer;
    use Module::FromPerlVer qw( use_dir 1 );

will look in the ./version directory, sort the subdir's 
in numerically decreasing order by version (see version)
and finds the highest version directory that is
less than or equal to the running perl's version. The 
contents of this directory are copied to the same directory
as the running code.

Versions derived from "use" will be less than equal to that
version, versions derived from "no" will be less than or 
equal to the version minus 0.000001.

=item Supplying the Perl Version

It may be useful in testing to choose a specific subdirectory
(e.g., regression testing older code with newer perl executables,
or testing the module itself). 

Each of these will be passed to version::parse for final 
validation. If version cannot parse the value then the code
will die with a "Bogus perl_version:..." error showing the 
version string being parsed.

In order of priority the Perl version used to select the 
module's compatible directory are:

=over 4

=item $ENV{ PERL_VERSION }

Any true value of  will be used. If this is supplied with
the "version_from" argument a warning will be issued and
the environment variable will be used. Note that "Cat"
"Dog" and "I don't know" are all true, but useless and 
will cause the code to croak.

One use of this is testing the current module with multple
versions of perl:

    #!/bin/bash

    for perl in /opt/perl5/5*/bin/perl
    do
        for i in version/*
        do
            # pick the appropriate module 
            # version from whatever is running.

            perl Makefile.PL    && 
            make all test       ;
        done
    done

or testing all the available module versions with a 
specific version of perl:
    
    #!/bin/bash

    perl='/opt/bin/perl-5.24.1';

    for i in ./version/*
    do
        COMPATIBLE_VERSION="$(basename $i)" \
        $perl Makefile.PL                   &&
        make all test                       ;
    done

=item use Module::FromPerlVer ( version_from => $path );

The path will be scanned for "use <version string>" and the first
one located will be processed. The file can be a module, executable,
or flat file with one line in it, so long as "use" followed by a
parsable version string is found Life is Good.

The main use of this is validating multiple versions of perl 
with a specific release of the module.

=item Overriding "version".

If you hate the name "version", use "version_dir" to set it:

    use Module::FromPerlVer qw( version_dir history );

=item Skipping the Copy

If you prefer to call copy_source_dir yourself (e.g., after
cleanup or pre-configuring some other part of the 
environment) use:

    use Module::FromPerlVer qw( no_copy 1 );

This will install all of the utility subs (see "Utility Subs"
below) but will not execute copy_source_dir().

=back

=back

=head2 Use Messages

The module supplies most of the information necessary to 
debug environment and configuration issues when import()
is called:

    # Def: default_use = 'dir'
    # Def: version_dir = 'version'
    # Def: git_prefix = 'perl/'
    # Extract with: 'Dir' (Module::FromPerlVer::Dir)
    # Perl version: 5.026001
    # Source prefix: ./t/version
    # Module version: 5.005003 <= 5.026001
    # Module source: ./t/version/5.005003
    # Source files:
    #   ./lib/Foo.pm
    #   ./pod/Foo.pod
    #   ./etc/version.dat
    # Install cleanup.
    # Get files with: 'Dir'


=over 4

=item Configuration

    # Def: default_use = 'dir'
    # Def: version_dir = 'version'
    # Def: git_prefix = 'perl/'

There are three variants: 'Def', 'Env', 'Arg' which 
show where the values came from. 

=item Handler

This shows which of use_* or the default_use was
chosen for the copy handler. In this case the 
default_use value of 'dir' provided the source:

    # Extract with: 'Dir' (Module::FromPerlVer::Dir)

=item Utility Installation

When the utility subs are installed they provide 
basic information about the values selected from
the arguments, perl version, and workspace.

See "Utility Subs" (below) for more information on
what these mean.

=back

=head2 Utility Subs

A few utility sub's are installed into Module::FromPerlVer 
when it is used. These are used internally to drive the 
file copy process and can be used to supply the values used
to build the module filesytem.

None of these take any arguments: they cannot be used to 
re-set the values determined at import time.

None of them are exported, they can be called usig either 
package or object notation:

    Module::FromPerlVer::copy_source_dir;   # package::subname

    Module::FromPerlVer->cleanup;           # class->method
    $module_name->cleanup;

None of them exist until import() is called: requiring 
Module::FromPerlVer will not install any of them.

The only one that is likely useful outside of the module 
itself are copy_files() and cleanup() which can be called
from Perl code for repeated testing (e.g., bash that iterates
perl versions).

=over 4

=item Calling convention.

All of these ignore any arguments, they can be 
called as class methods or via fully-qualified 
paths with the identical effect:

    Module::FromPerlVer::foobar();
    Module::FromPerlVer->foobar();

=item perl_version()

Returns the parsed, numified Perl version value (see 
version module).

=item version_source()

Returns the source of the version directory
(e.g., dir "version" or tag "perl/").

=item version_source()

The subdir or tag from which the files are sourced. This will 
be a relative path from $FindBin::Bin, including the 
version directory:

    ./version/5.006001
    ./version/v5.24.2

    perl/v5.24
    perl5.005_003

=item source_files()

For directory source only (i.e., where the files can be 
looked up easily beforehand):

Used in a scalar context this returns an arrayref of relative
paths to files copied from the source_dir into the working 
directory by copy_files().

Used in a list context it returns two arrayrefs: one of the 
files one of the directories. The former is used with unlink
in cleanup to remove only the files that were copied; the 
latter is used to rmdir empty directories.

=item get_files()

This executes the copy/checkout of source files.

Note: If import is called with "no_copy" and a true
value then this will have to be called, see examples
for calling convention, above.

=item cleanup()

For Dir this removes the files copied, empty dir's left behind. This 
approach allows for some files to be re-used across multiple releases 
without getting clobbered by cleanup.  Likely examples are common 
tests (i.e., t/*.t) or a MANIFEST for modules which have all of the 
same files in each version.

For Git this checks out whatever branch was in use when copy_files() 
was called. That's the best guess I have for what was in use at the
time a verion-specific tag was checked out.

=back

=head1 NOTES

=over 4

=item Q: Why tags, not branches?

A given brach may have un-tested updates on it. At that point it
is not safe to assume HEAD will always work; at *that* point there
isn't any good way to automatically checkout a given branch.

Tags are static, can be assigned by the developer for specific
commits, and can be re-assigned as necessary if code is updated.

This also saves a whole lot of separate branches for version-
specific generations of code. Just leave them in master -- or
wherever you work -- with the tags behind.

=back

=head1 SEE ALSO

=over 4

=item version

This does the parsing of version numbers from code and 
dirs. The POD incudes examples of both parsing and sorting
Perl versions.

=item File::Copy::Recursive

Describes how the files are copied.

=back

=head1 LICENSE

This code is licensed under the same terms as Perl-5.26 or any
later released version of Perl the user preferrs.

=head1 COPYRIGHT

Copyright 2018, Steven Lembark, all rights reserved.

=head1 AUTHOR

Steven Lembark <lembark@wrkhors.com>

