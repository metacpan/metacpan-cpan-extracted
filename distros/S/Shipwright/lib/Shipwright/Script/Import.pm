package Shipwright::Script::Import;

use strict;
use warnings;

use base qw/App::CLI::Command Shipwright::Base Shipwright::Script/;
__PACKAGE__->mk_accessors(
    qw/comment no_follow build_script require_yml include_dual_lifed
      name test_script extra_tests overwrite min_perl_version skip version as
      skip_recommends skip_all_test_requires skip_all_recommends skip_installed
      no_default_build skip_all_build_requires
      /
);

use Shipwright;
use File::Spec::Functions qw/catfile catdir splitdir/;
use Shipwright::Util;
use File::Copy qw/copy move/;
use File::Temp qw/tempdir/;
use Config;
use List::MoreUtils qw/firstidx/;

sub options {
    (
        'm|comment=s'             => 'comment',
        'name=s'                  => 'name',
        'no-follow'               => 'no_follow',
        'build-script=s'          => 'build_script',
        'require-yml=s'           => 'require_yml',
        'test-script'             => 'test_script',
        'extra-tests'             => 'extra_tests',
        'overwrite'               => 'overwrite',
        'min-perl-version=s'      => 'min_perl_version',
        'skip=s'                  => 'skip',
        'version=s'               => 'version',
        'as=s'                    => 'as',
        'skip-recommends=s'       => 'skip_recommends',
        'skip-all-recommends'     => 'skip_all_recommends',
        'skip-all-test-requires'  => 'skip_all_test_requires',
        'skip-all-build-requires' => 'skip_all_build_requires',
        'skip-installed'          => 'skip_installed',
        'include-dual-lifed'      => 'include_dual_lifed',
        'no-default-build'        => 'no_default_build',
    );
}

my ( %imported, $version );

sub run {
    my $self    = shift;
    my @sources = @_;
    my $source;
    $source = $sources[0];
    confess_or_die "--name and --as args are not supported when importing multiple sources"
      if @sources > 1 && $self->name;

    {
        require version;
        my $version =
          version->new( $self->min_perl_version || $Config{version} );
        $self->min_perl_version( $version->numify );
    }

    my $shipwright = Shipwright->new( repository => $self->repository, );

    my $order      = $shipwright->backend->order || []; 
    my $installed  = { map { $_ => 1 } @$order };

    if ( $self->name && !$source ) {

        # don't have source specified, use the one in repo
        my $map        = $shipwright->backend->map    || {};

        my $source_yml = $shipwright->backend->source || {};
        my $branches   = $shipwright->backend->branches;

        my $r_map = { reverse %$map };
        if ( $r_map->{ $self->name } ) {
            $source = 'cpan:' . $r_map->{ $self->name };
        }
        elsif ($branches) {
            $source = $source_yml->{ $self->name };
            if ( ref $source ) {
                $source = $source->{ $self->as || $branches->{ $self->name }[0] };
            }
        }
        else {
            $source = $source_yml->{$self->name};
        }

        @sources = $source;
    }

    confess_or_die "we need source arg\n" unless $source;

    if ( $self->extra_tests ) {

        $self->log->info( 'going to import extra_tests' );
        $shipwright->backend->import(
            source       => $source,
            comment      => 'import extra tests',
            _extra_tests => 1,
        );
    }
    elsif ( $self->test_script ) {
        $self->log->info('going to import test_script');
        $shipwright->backend->test_script( source => $source );
    }
    else {
        $self->skip( { map { $_ => 1 } split /\s*,\s*/, $self->skip || '' } );
        $self->skip_recommends(
            { map { $_ => 1 } split /\s*,\s*/, $self->skip_recommends || '' } );

        if ( $self->name ) {
            if ( $self->name =~ /::/ ) {
                my $name = $self->name;
                $self->log->warn(
                    "$name contains '::', will treat it as '-'");
                $name =~ s/::/-/g;
                $self->name($name);
            }
            if ( $self->name !~ /^[-.\w]+$/ ) {
                confess_or_die
                  qq{name can only have alphanumeric characters, "." and "-"\n};
            }
        }

        for my $source (@sources) {
            if ( $source =~ /^(perl-[\d.]+)(?:\.tar\.gz)?$/ ) {
                $source = "http://www.cpan.org/src/$1.tar.gz";
            }
            elsif ( $source eq 'perl' ) {
                if ( $self->version ) {
                    $source =
                        "http://www.cpan.org/src/perl-"
                      . $self->version
                      . '.tar.gz';
                }
                else {
                    confess_or_die
                      "unknown perl version, please specify --version";
                }
            }

            my $shipwright = Shipwright->new(
                repository              => $self->repository,
                source                  => $source,
                name                    => $self->name,
                follow                  => !$self->no_follow,
                min_perl_version        => $self->min_perl_version,
                include_dual_lifed      => $self->include_dual_lifed,
                skip                    => $self->skip,
                version                 => $self->version,
                installed               => $installed,
                skip_recommends         => $self->skip_recommends,
                skip_all_recommends     => $self->skip_all_recommends,
                skip_all_test_requires  => $self->skip_all_test_requires,
                skip_all_build_requires => $self->skip_all_build_requires,
                skip_installed          => $self->skip_installed,
            );

            confess_or_die "cpan dists can't be branched"
              if $shipwright->source->isa('Shipwright::Source::CPAN')
                  && $self->as;

            unless ( $self->overwrite ) {

                # skip already imported dists
                $shipwright->source->skip(
                    { %{ $self->skip }, %{ $shipwright->backend->map || {} } }
                );
            }

            dump_yaml_file(
                $shipwright->source->map_path,
                $shipwright->backend->map || {},
            );

            dump_yaml_file(
                $shipwright->source->url_path,
                $shipwright->backend->source || {},
            );

            $source = $shipwright->source->run(
                copy => { '__require.yml' => $self->require_yml }, );

            next unless $source; # if running the source returned undef, we should skip

            $version =
              load_yaml_file( $shipwright->source->version_path );
            my $name = ( splitdir( $source ) )[-1];

            my $base = parent_dir($source);

            my $script_dir;
            if ( -e catdir( $base, '__scripts', $name ) ) {
                $script_dir = catdir( $base, '__scripts', $name );
            }
            else {

     # Source part doesn't have script stuff, so we need to create by ourselves.
                $script_dir = tempdir(
                    'shipwright_script_import_XXXXXX',
                    CLEANUP => 1,
                    TMPDIR  => 1,
                );

                if ( my $script = $self->build_script ) {
                    if ( $script =~ /\.pl$/ ) {
                        copy( $script, catfile( $script_dir, 'build.pl' ) );
                    }
                    else {
                        copy( $script, catfile( $script_dir, 'build' ) );
                    }
                }
                elsif ( ! $self->no_default_build ) {
                    $self->_generate_build( $source, $script_dir, $shipwright );
                }
            }

            if ( $self->no_follow ) {
                open my $fh, '>', catfile( $script_dir, 'require.yml' ) or
                    confess_or_die "can't write to $script_dir/require.yml: $!\n";
                print $fh "---\n";
                close $fh;
            }
            else {
                $self->_import_req( $source, $shipwright, $script_dir );

                if ( -e catfile( $source, '__require.yml' ) ) {
                    move(
                        catfile( $source,     '__require.yml' ),
                        catfile( $script_dir, 'require.yml' )
                    ) or confess_or_die "move __require.yml failed: $!\n";
                }
            }

            my $branches =
              load_yaml_file( $shipwright->source->branches_path );
            $branches ||= {};

            $self->log->fatal( "importing $name" );
            $shipwright->backend->import(
                source  => $source,
                comment => $self->comment || 'import ' . $source,

     # import anyway for the main dist, unless it's already imported in this run
                overwrite => $imported{$name} ? 0 : 1,
                version   => $version->{$name},
                as        => $self->as,
                branches =>
                  $shipwright->source->isa('Shipwright::Source::Shipyard')
                ? ( $branches->{$name} || [] )
                : (undef),
            );

            $shipwright->backend->import(
                source       => $source,
                comment      => 'import scripts for ' . $source,
                build_script => $script_dir,
                overwrite    => $imported{$name} ? 0 : 1,
            );
            $imported{$name}++;

            # merge new map into map.yml in repo
            my $new_map =
              load_yaml_file( $shipwright->source->map_path )
              || {};
            $shipwright->backend->map(
                { %{ $shipwright->backend->map || {} }, %$new_map } );

            my $new_url =
              load_yaml_file( $shipwright->source->url_path )
              || {};
            my $source_url = delete $new_url->{$name};

            if (   $name !~ /^cpan-/
                || $shipwright->source->isa('Shipwright::Source::Shipyard') )
            {
                my $source = $shipwright->backend->source || {};
                if ( $shipwright->source->isa('Shipwright::Source::Shipyard') )
                {
                    $source->{$name} = $source_url;
                }
                else {
                    $source->{$name}{ $self->as || 'vendor' } = $source_url;
                }
                $shipwright->backend->source($source);
            }
        }

    }

    $self->log->fatal( 'successfully imported' );

}

# _import_req: import required dists for a dist

sub _import_req {
    my $self       = shift;
    my $source     = shift;
    my $shipwright = shift;
    my $script_dir = shift;

    my $name = (splitdir( $source ))[-1];
    $self->log->info( "going to import requirements for $name" );

    my $require_file = catfile( $source, '__require.yml' );
    $require_file = catfile( $script_dir, 'require.yml' )
      unless -e catfile( $source, '__require.yml' );

    my $dir = parent_dir($source);

    my $map_file = catfile( $dir, 'map.yml' );

    if ( -e $require_file ) {
        my $req = load_yaml_file($require_file);
        my $map = {};

        if ( -e $map_file ) {
            $map = load_yaml_file($map_file);

        }

        opendir my ($d), $dir;
        my @sources = readdir $d;
        close $d;

        for my $type (qw/requires configure_requires recommends build_requires test_requires/) {
            for my $module ( keys %{ $req->{$type} } ) {
                my $dist = $map->{$module} || $module;
                $dist =~ s/::/-/g;

                unless ( $imported{$dist}++ ) {

                    my ($name) = grep { $_ eq $dist } @sources;
                    unless ($name) {
                        $self->log->warn(
                            "missing $dist in source which is for "
                              . $source );
                        next;
                    }

                    $self->log->fatal( "import $name" );
                    my $s = catdir( $dir, $name );

                    my $script_dir;
                    if ( -e catdir( $dir, '__scripts', $dist ) ) {
                        $script_dir = catdir( $dir, '__scripts', $dist );
                    }
                    else {
                        $script_dir = tempdir(
                            'shipwright_script_import_XXXXXX',
                            CLEANUP => 1,
                            TMPDIR  => 1,
                        );
                        if ( -e catfile( $s, '__require.yml' ) ) {
                            move(
                                catfile( $s,          '__require.yml' ),
                                catfile( $script_dir, 'require.yml' )
                            ) or confess_or_die "move $s/__require.yml failed: $!\n";
                        }

                        $self->_generate_build( $s, $script_dir, $shipwright );
                    }

                    $self->_import_req( $s, $shipwright, $script_dir );

                    my $branches = load_yaml_file(
                        $shipwright->source->branches_path );
                    $shipwright->backend->import(
                        comment   => 'deps for ' . $source,
                        source    => $s,
                        overwrite => $self->overwrite,
                        version   => $version->{$dist},
                        branches  => $shipwright->source->isa(
                            'Shipwright::Source::Shipyard')
                        ? ( $branches->{$dist} || [] )
                        : (undef),
                    );
                    $shipwright->backend->import(
                        source       => $s,
                        comment      => 'import scripts for ' . $s,
                        build_script => $script_dir,
                        overwrite    => $self->overwrite,
                    );
                    if (
                        $shipwright->source->isa(
                            'Shipwright::Source::Shipyard')
                      )
                    {
                        my $new_url =
                          load_yaml_file( $shipwright->source->url_path )
                          || {};
                        my $source_url = delete $new_url->{$dist};
                        my $source = $shipwright->backend->source || {};
                        $source->{$dist} = $source_url;
                        $shipwright->backend->source($source);
                    }
                }
            }
        }
    }

}

# _generate_build:
# automatically generate build script if not provided

sub _generate_build {
    my $self       = shift;
    my $source_dir = shift;
    my $script_dir = shift;
    my $shipwright = shift;

    my ($name) = $source_dir =~ /([-\w.]+)$/;

    my @commands;
    if ( $name eq 'perl' ) {
        $self->log->info( 'detected perl source' );
        @commands = (
            'configure: sh Configure -de -Dprefix=%%INSTALL_BASE%% -Dinstallstyle=lib/perl5',
            'make: %%MAKE%%',
            'test: %%MAKE%% test',
            'install: %%MAKE%% install',
            'clean: %%MAKE%% clean'
        );
    }
    elsif ( -f catfile( $source_dir, 'Build.PL' ) ) {
        $self->log->info( 'detected Module::Build build system' );
        @commands = (
            'configure: %%PERL%% %%MODULE_BUILD_BEFORE_BUILD_PL%% Build.PL --install_base=%%INSTALL_BASE%% --install_path lib=%%INSTALL_BASE%%/lib/perl5 --install_path arch=%%INSTALL_BASE%%/lib/perl5',
            'make: %%PERL%% %%MODULE_BUILD_BEFORE_BUILD%% Build',
            'test: %%PERL%% %%MODULE_BUILD_BEFORE_BUILD%% Build test',
            'install: %%PERL%% %%MODULE_BUILD_BEFORE_BUILD%% Build install',
            'clean: %%PERL%% %%MODULE_BUILD_BEFORE_BUILD%% Build realclean',
        );
    }
    elsif ( -f catfile( $source_dir, 'Makefile.PL' ) ) {
        $self->log->info( 'detected ExtUtils::MakeMaker build system or alike' );
# XXX when only support 5.8.9+, we can change it to INSTALL_BASE=%%INSTALL_BASE%%
# because LIB=.../lib/perl5 is so ugly and not so right
        @commands = (
            'configure: %%PERL%% Makefile.PL LIB=%%INSTALL_BASE%%/lib/perl5/ PREFIX=%%INSTALL_BASE%% INSTALLSITEARCH=%%INSTALL_BASE%%/lib/perl5 INSTALLARCHLIB=%%INSTALL_BASE%%/lib/perl5 %%MAKEMAKER_CONFIGURE_EXTRA%%',
            'make: %%MAKE%%',
            'test: %%MAKE%% test',
            'install: %%MAKE%% install',
            'clean: %%MAKE%% clean',
        );
    }
    elsif ( -f catfile( $source_dir, 'configure' ) ) {
        $self->log->info( 'detected autoconf build system' );
        @commands = (
            'configure: ./configure --prefix=%%INSTALL_BASE%%',
            'make: %%MAKE%%',
            'install: %%MAKE%% install',
            'clean: %%MAKE%% clean',
        );
    }
    elsif ( -f catfile( $source_dir, 'configure.cmake' ) ) {
        $self->log->info( 'detected cmake build system' );
        @commands = (
            'configure: cmake . -DCMAKE_INSTALL_PREFIX=%%INSTALL_BASE%%',
            'make: %%MAKE%%',
            'install: %%MAKE%% install',
            'clean: %%MAKE%% clean',
        );
    }
    else {
        $self->log->warn(<<EOF);
unknown build system for this dist; you MUST manually edit /scripts/$name/build 
or provide a build.pl file or this dist will not be built!
EOF
        $self->log->warn("no idea how to build $source_dir");

        # stub build file to provide the user something to go from
        @commands = (
            '# Edit this file to specify commands for building this dist.',
            '# See the perldoc for Shipwright::Manual::CustomizeBuild for more',
            '# info.',
            'configure: ',
            'make: ',
            'test: ',
            'install: ',
            'clean: ',
        );
    }

    open my $fh, '>', catfile( $script_dir, 'build' ) or confess_or_die $@;
    print $fh $_, "\n" for @commands;
    close $fh;
}

1;

__END__

=head1 NAME

Shipwright::Script::Import - Import sources and their dependencies

=head1 SYNOPSIS

 shipwright import cpan:Jifty cpan:Catalyst

=head1 OPTIONS

 -m [--comment] COMMENT         : specify the comment
 --name NAME                    : specify the source name (only alphanumeric
                                  characters, . and -)
 --as                           : the branch name
 --build-script FILENAME        : specify the build script
 --require-yml FILENAME         : specify the require.yml
 --no-follow                    : don't follow the dependency chain
 --extra-test FILENAME          : specify the extra test source
                                  (for --only-test when building)
 --test-script FILENAME         : specify the test script (for --only-test when
                                  building)
 --min-perl-version             : minimal perl version (default is the same as
                                  the one which runs this command)
 --overwrite                    : import dependency sources anyway even if they
                                  are already in the shipyard
 --version                      : specify the source's version
 --skip                         : specify a list of sources not to import
 --skip-recommends              : specify a list of sources of which recommends 
                                  not to import
 --skip-all-recommends          : skip all the recommends to import
 --skip-all-test-requires       : skip all the test requires to import
 --skip-all-build-requires      : skip all the build requires to import
 --skip-installed               : skip all the installed modules to import
 --include-dual-lifed           : include modules which live both in the perl core 
                                  and on CPAN
 --no-default-build             : don't try to detect and set build system
 
=head1 DESCRIPTION

The import command imports a new source into a shipyard from a number of
supported source types (enumerated below). If a source of the name specified
by C<--name> already exists in the shipyard, the old files for that source
in F</sources> and F</scripts> are deleted and new ones are added. This is the
recommended method for updating non-svn, svk, or CPAN sources to new versions.
(see L<Shipwright::Script::Update> for more information on the C<update>
command, which is used for updating svn, svk, and CPAN dists).

=head1 SUPPORTED SOURCE TYPES

Generally, the format is L<type:schema>; be careful, there is no blank between
type and schema, just a colon.

=over 4

=item CPAN

e.g. cpan:Jifty::DBI  cpan:File::Spec

CAVEAT: we don't support renaming CPAN sources when importing, because it
*really* is not a good idea and may hurt shipwright somewhere.

=item File

e.g. L<file:/home/sunnavy/foo-1.23.tar.gz>
L<file:/home/sunnavy/foo-1.23.tar.bz2>
L<file:/home/sunnavy/foo-1.23.tgz>

=item Directory

e.g. L<directory:/home/sunnavy/foo-1.23>
L<dir:/home/sunnavy/foo-1.23>

=item HTTP

e.g. L<http:http://example/foo-1.23.tar.gz>

You can also omit one `http', like this:

L<http://example.com/foo-1.23.tar.gz>

F<.tgz> and F<.tar.bz2> are also supported.

=item FTP

e.g. L<ftp:ftp://example.com/foo-1.23.tar.gz>
L<ftp://example.com/foo-1.23.tar.gz>

F<.tgz> and F<.tar.bz2> are also supported.

=item SVK

e.g. L<svk://public/foo-1.23> L<svk:/local/foo-1.23>

=item SVN

e.g. L<svn:file:///home/public/foo-1.23>
L<svn:http://svn.example.com/foo-1.23>

=item Git

e.g. L<git:file:///opt/foo.git>
L<git://github.com/bestpractical/shipwright.git>

=item Shipyard

e.g. L<shipyard:/tmp/fs/foo>

=back

=head1 GLOBAL OPTIONS

 -r [--repository] REPOSITORY   : specify the repository uri of our shipyard
 -l [--log-level] LOGLEVEL      : specify the log level
                                  (info, debug, warn, error, or fatal)
 --log-file FILENAME            : specify the log file


=head1 AUTHORS

sunnavy  C<< <sunnavy@bestpractical.com> >>

=head1 LICENCE AND COPYRIGHT

Shipwright is Copyright 2007-2015 Best Practical Solutions, LLC.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

