package PkgForge::Builder::RPM;    # -*-perl-*-
use strict;
use warnings;

# $Id: RPM.pm.in 16775 2011-04-22 08:16:00Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 16775 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge-Server/PkgForge_Server_1_1_10/lib/PkgForge/Builder/RPM.pm.in $
# $Date: 2011-04-22 09:16:00 +0100 (Fri, 22 Apr 2011) $

our $VERSION = '1.1.10';

use Cwd ();
use English qw(-no_match_vars);
use File::Copy ();
use File::Find::Rule ();
use File::Path ();
use File::Spec ();
use File::Temp ();
use IPC::Run ();
use PkgForge::Source::SRPM ();
use PkgForge::Utils ();
use Readonly;

Readonly my $MOCK_BIN     => '/usr/bin/mock';
Readonly my $MOCK_DIR     => '/etc/mock';
Readonly my $MOCK_QUERY   => '/usr/bin/mock_config_query';
Readonly my $PKGSUBMIT    => '/usr/sbin/pkgsubmit';
Readonly my $RPMBUILD_BIN => '/usr/bin/rpmbuild';
Readonly my $RPM_BIN      => '/bin/rpm';

use overload q{""} => sub { shift->stringify };

use Moose;
use MooseX::Types::Moose qw(Bool Str);

with 'PkgForge::Builder';

has '+architecture' => (
    required => 1,
);

has '+accepts' => (
    default => 'SRPM',
);

has 'use_mock' => (
    is      => 'ro',
    isa     => Bool,
    default => 1,
    documentation => 'Use mock to build packages',
);

has 'rpm_api_version' => (
    is      => 'ro',
    isa     => Str,
    default => sub { require RPM2; return RPM2->rpm_api_version },
    lazy    => 1,
    documentation => 'The RPM API version',
);

no Moose;
__PACKAGE__->meta->make_immutable;

sub mock_chroot_name {
    my ( $self, $topic ) = @_;

    my $chroot = join q{-}, $self->platform, $topic->bucket, $self->architecture;

    return $chroot;
}

sub mock_query {
    my ( $self, $chroot, $key ) = @_;

    my $value = `$MOCK_QUERY -r $chroot $key`;
    if ( $CHILD_ERROR != 0 || !defined $value ) {
        die "Failed to query the mock config for $chroot\n";
    }
    chomp $value;

    return $value;
}

sub mock_clear_resultsdir {
    my ( $self, $chroot ) = @_;

    my $resultdir = $self->mock_query( $chroot, 'resultdir' );

    my @errors;
    PkgForge::Utils::remove_tree( $resultdir, { error     => \@errors,
                                                keep_root => 1 } );

    if ( scalar @errors > 0 ) {
        die "Could not clear $resultdir: failed on @errors\n";
    }

    return;
}

sub mock_createrepo {
    my ( $self, $chroot ) = @_;

    my $createrepo = $self->mock_query( $chroot, 'createrepo_on_rpms' );
    if ( $createrepo !~ m/true/i ) {
        return;
    }

    my $resultdir = $self->mock_query( $chroot, 'resultdir' );
    if ( !-d $resultdir ) {
        my $ok = eval { File::Path::mkpath($resultdir) };
        if ( !$ok || $EVAL_ERROR ) {
            die "Failed to create directory $resultdir: $EVAL_ERROR\n";
        }
    }

    my $command = $self->mock_query( $chroot, 'createrepo_command' );

    my @command = split q{ }, $command;
    push @command, $resultdir;

    my $output;
    my $ok = eval { IPC::Run::run( \@command, \undef, '>&', \$output ) };

    if ( !$ok || $EVAL_ERROR ) {
        die "Failed to run createrepo: @command: $output\n";
    }

    return;
}

sub mock_init {
    my ( $self, $chroot ) = @_;

    $self->mock_clear_resultsdir($chroot);

    $self->mock_createrepo($chroot);

    return 1;
}

sub mock_run {
    my ( $self, $topic ) = @_;

    my $logger = $topic->logger;

    my $chroot = $self->mock_chroot_name($topic);

    if ( $self->debug ) {
        $logger->debug("Using mock chroot $chroot");
    }

    my $init_ok = eval { $self->mock_init($chroot) };
    if ( !$init_ok || $EVAL_ERROR ) {
        $logger->log_and_die(
            level   => 'critical',
            message => "mock initialisation failed: $EVAL_ERROR",
        );
    }

    my $timeout = $self->timeout;
    my @cmd_base = ( $MOCK_BIN,
                     '--root', $chroot,
                     '--rpmbuild_timeout', $timeout );

    my @todo = $topic->sources_list;

    my @failed;
    my $failure = 0;

    while ( !$failure && scalar @todo > 0 ) {
        @failed = ();
        for my $pkg (@todo) {
            my $path = $pkg->fullpath;
            if ( !-f $path ) {
                $logger->log_and_die(
                    level   => 'critical',
                    message => "Cannot find source package '$path'",
                );
            }
            my $cmd = [ @cmd_base, $path ];

            if ( $self->debug ) {
                $logger->debug("Will run command '@{$cmd}'");
            }

            my $mock_out;
            my $ok = eval { IPC::Run::run(
                                $cmd, \undef,
                                '>&', \$mock_out,
                            ) };
            my $error = $EVAL_ERROR; # ensure it's not eaten by logger

            $logger->info($mock_out) if $mock_out;

            if ( !$ok || $error ) {
                $logger->error("Failed to build $path");
                $logger->error($error) if $error;
                push @failed, $pkg;
                if ( $self->error_policy eq 'immediate' ) {
                    $logger->error('Giving up as the policy is to fail immediately');
                    $failure = 1;
                    last;
                } else {
                    $logger->error('Might retry later');
                }
            }

        }

        if ( !$failure ) {
            if ( scalar @failed > 0 ) {
                # Retry if something has built since the last run.

                if ( scalar @failed < scalar @todo ) {
                    @todo = @failed;
                } else {
                    $failure = 1;
                }
            } else {
                @todo = ();
            }
        }

    }

    $self->mock_store_logs( $chroot, $topic );

    if ($failure) {
        $logger->error("Failed to build: @failed");
        return 0;
    }

    $self->mock_store_results( $chroot, $topic );

    return 1;
}

sub mock_store_logs {
    my ( $self, $chroot, $topic ) = @_;

    my $mock_results = $self->mock_query( $chroot, 'resultdir' );

    my @files =
      File::Find::Rule->file()->name('*.log')->maxdepth(1)->in($mock_results);

    return $topic->store_logs(@files);
}

sub mock_store_results {
    my ( $self, $chroot, $topic ) = @_;

    my $mock_results = $self->mock_query( $chroot, 'resultdir' );

    my @files =
      File::Find::Rule->file()->name('*.rpm')->maxdepth(1)->in($mock_results);

    return $topic->store_results(@files);
}

sub verify_environment {
    my ($self) = @_;

    for my $tool ( $MOCK_BIN, $MOCK_QUERY, $PKGSUBMIT,
                   $RPM_BIN, $RPMBUILD_BIN ) {
        if ( !-x $tool ) {
            die "Cannot find $tool\n";
        }
    }

    return 1;
}

sub submit_packages {
    my ( $self, $topic ) = @_;

    my $logger = $topic->logger;

    my $resultsdir = $topic->resultsdir;
    if ( !-d $resultsdir ) {
        $logger->log_and_die(
            level   => 'critical',
            message => "Could not find results directory '$resultsdir'",
        );
    }

    my $bucket = $topic->bucket;
    my $config = $self->name . '.conf';

    my @files =
      File::Find::Rule->file()->name('*.rpm')->maxdepth(1)->relative()->in($resultsdir);

    if ( scalar @files > 0 ) {
        my @cmd = ( $PKGSUBMIT, '-x', '-f', $config, '-B', $bucket, @files );

        if ( $self->debug ) {
            $logger->debug("Will run command '@cmd'");
        }

        my $prev_dir = Cwd::getcwd();
        chdir $resultsdir
          or $logger->log_and_die(
            level   => 'critical',
            message => "Could not change to directory '$resultsdir': $OS_ERROR",
        );

        my $pkgsubmit_out;
        my $ok = eval { IPC::Run::run( \@cmd, \undef, '>&', \$pkgsubmit_out ) };

        chdir $prev_dir;

        if ( !$ok || $EVAL_ERROR ) {
            $logger->error($EVAL_ERROR) if $EVAL_ERROR;
            $logger->log_and_die(
                level   => 'error',
                message => "Failed to run pkgsubmit: $pkgsubmit_out",
            );
        }
    }

    return 1;
}

# This is one big ugly horrid hack to work around not being able to
# directly build from SRPMs on SL5 if they were created with newer
# versions of rpmlib.

sub rebuild_sources {
    my ( $self, $topic ) = @_;

    my $logger = $topic->logger;

    my $resultsdir = $topic->resultsdir;
    my @rebuilt;

    for my $source ($topic->sources_list) {

        my $srpm = $source->fullpath;

        my $tempdir = File::Temp->newdir( 'pkgforge-XXXXX',
                                          TMPDIR  => 1,
                                          CLEANUP => 1 );
        my %dirs;
        for my $dir (qw/BUILD BUILDROOT RPMS SOURCES SPECS SRPMS/) {
            $dirs{$dir} = File::Spec->catdir( $tempdir, $dir );
            my $ok = eval { File::Path::mkpath($dirs{$dir}) };
            if ( !$ok || $EVAL_ERROR ) {
                $logger->log_and_die(
                    level   => 'error',
                    message => "Failed to create $dirs{$dir}: $EVAL_ERROR",
                );
            }
        }

        my @defs = ( '--define', "_topdir $tempdir",
                     '--define', "_builddir $dirs{BUILD}",
                     '--define', "_specdir $dirs{SPECS}",
                     '--define', "_sourcedir $dirs{SOURCES}",
                     '--define', "_srcrpmdir $dirs{SRPMS}",
                     '--define', "_rpmdir $dirs{RPMS}",
                     '--define', "_buildrootdir $dirs{BUILDROOT}" );

        # Install the SRPM so we can get the specfile and sources

        my $rpm_out;
        my $rpm_ok = eval { 
            IPC::Run::run(
                [ $RPM_BIN, @defs, '--nomd5', '--install', $srpm ],
                \undef, '>&', \$rpm_out )
        };
        if ( !$rpm_ok || $EVAL_ERROR ) {
            $logger->error($EVAL_ERROR) if $EVAL_ERROR;
            $logger->log_and_die(
                level   => 'error',
                message => "rpm install failed: $rpm_out",
            );
        }

        my $specfile = ( glob "$dirs{SPECS}/*.spec" )[0];

        if ( !defined $specfile ) {
            die "Failed to find specfile\n";
        }

        # Rebuild the SRPM

        my $rpmbuild_output;
        my $rpmbuild_ok = eval { 
            IPC::Run::run(
                [ $RPMBUILD_BIN, '-bs', '--nodeps', @defs, $specfile ],
                \undef, '>&', \$rpmbuild_output )
        };

        if ( !$rpmbuild_ok || $EVAL_ERROR ) {
            $logger->error($EVAL_ERROR) if $EVAL_ERROR;
            $logger->log_and_die(
                level   => 'error',
                message => "rpmbuild failed: $rpmbuild_output",
            );
        }

        my $new_srpm = ( glob "$dirs{SRPMS}/*.src.rpm" )[0];

        if ( !defined $new_srpm ) {
            $logger->log_and_die(
                level   => 'error',
                message => "Failed to find the rebuilt SRPM"
            );
        }

        File::Copy::copy( $new_srpm, $resultsdir ) or
          $logger->log_and_die(
              level   => 'error',
              message => "Could not copy $new_srpm to $resultsdir: $OS_ERROR",
          );

        my $new_srpm_file = ( File::Spec->splitpath($new_srpm) )[2];

        my $new_source = eval {
            PkgForge::Source::SRPM->new( file    => $new_srpm_file,
                                         basedir => $resultsdir )
        };

        if ( !defined $new_source || $EVAL_ERROR ) {
            $logger->log_and_die(
                level   => 'error',
                message => "Failed to load $new_srpm_file as PkgForge::Source::SRPM object: $EVAL_ERROR",
            );
        }

        push @rebuilt, $new_source;
    }

    $topic->sources(\@rebuilt);

    return;
}

sub run {
    my ( $self, $topic ) = @_;

    if ( $self->rpm_api_version < 4.6 ) {
        $self->rebuild_sources($topic);
    }

    my $result;
    if ( $self->use_mock ) {
        $result = $self->mock_run($topic);
    } else {
        die "Only mock supported right now\n";
    }

    return $result;
}

1;
__END__

=head1 NAME

PkgForge::Builder::RPM - A PkgForge class for building RPMs

=head1 VERSION

This documentation refers to PkgForge::Builder::RPM version 1.1.10

=head1 SYNOPSIS

     use PkgForge::Job;
     use PkgForge::Builder::RPM;

     my $builder = PkgForge::Builder::RPM->new( platform     => 'f13',
                                                architecture => 'x86_64' );

     my $verified = eval { $self->builder->verify_environment };
     if ( $verified && !$@ ) {

       my $job = PkgForge::Job->new_from_dir($job_dir);

       $builder->build( $job, $results_dir );

     }

=head1 DESCRIPTION

This is a Package Forge builder class for building RPMs from source
using mock.

=head1 ATTRIBUTES

This inherits most attributes from the L<PkgForge::Builder> role. This
class has the following extra attributes:

=over

=item use_mock

This is a boolean value which controls whether mock should be used to
build packages. Currently this is the only supported build tool so the
default is true.

=item rpm_api_version

This is a string which contains the rpmlib version number. This is
discovered using the C<rpm_api_version> method in the L<RPM2> Perl
module.

=back

=head1 SUBROUTINES/METHODS

This inherits some methods from the L<PkgForge::Builder> role. The
class has the following extra methods:

=over

=item run($topic)

This is the main method which drives the building of RPMs. It takes a
L<PkgForge::BuildTopic> object. Currently, only the mock build method
is supported so the build topic is passed into the C<mock_run>
method. 

=item verify_environment()

This method ensures that the C<mock> and C<pkgsubmit> tools are
available. If anything is missing this method will die. This is not
called automatically, if you need to run this check you need to do
that yourself before calling C<build>.

=item submit_packages($topic)

This method takes a L<PkgForge::BuildTopic> object. It uses the
C<pkgsubmit> tool to submit the built packages. There must be a
configuration file named like C<platform-arch.conf>
(e.g. C</etc/pkgsubmit/f13-i386.conf> for each supported build
environment. The packages will be submitted into the bucket specified
in the job. If anything fails this method will die.

=item mock_run($topic)

This is the main mock build method. It takes a L<PkgForge::BuildTopic>
object. It will attempt to build each source package in turn. If
createrepo is being used then packages can be used as
build-dependencies for later packages in the job as soon as they are
successfully built. After all the package builds have been attempted
the log files will be stored (using C<mock_store_logs>). If the job
was successful, then the built packages will also be stored (using
C<mock_store_results>). If any packages fail to build the job will be
considered a failure and this method will die.

=item mock_query( $chroot, $key )

This will query the specified configuration option for the specified
mock chroot and return the value. It does this using a rather hacky
python script, named C<mock_config_query>, which relies on loading the
mock python code in a slightly odd way (BE WARNED, this might explode
at any moment). This method will die if it cannot find a value for the
specified key.

=item mock_chroot_name($topic)

This returns the name of the mock chroot based on the builder
platform, architecture and the bucket being used for the job. The
chroot name will be formed like C<platform-bucket-arch>,
e.g. f13-lcfg-i386.

=item mock_clear_resultsdir($chroot)

This will remove all files and directories in the results directory
for the specified chroot. Normally this is called before actually
running mock so that it starts with a clean environment. This makes it
easy to collect the build products and log files. This method will die
if it cannot remove all files and directories.

=item mock_createrepo($chroot)

If the C<createrepo_on_rpms> mock configuration option is set for the
specified chroot then this method will run the command which is
specified in the mock C<createrepo_command> configuration option. This
method will die if anything fails whilst running createrepo.

=item mock_init($chroot)

This method will initialise the specified mock chroot. Currently this
consists of calling C<mock_clear_resultsdir> and C<mock_createrepo>.

=item mock_store_logs( $chroot, $topic )

This finds all the log files (i.e. C<*.log>) in the mock results
directory for the chroot and copies them into the results directory
for the job.

=item mock_store_results( $chroot, $topic )

This finds all the packages (i.e. C<*.rpm>) in the mock results
directory for the chroot and copies them into the results directory
for the job.

=item rebuild_sources($topic)

This is a big ugly horrid hack to work around the fact that SRPMs
created on newer platforms with a recent version of rpmlib (4.6 and
newer) cannot be used on older platforms. This is, for example,
particularly a problem when needing to build from the same source
packages on SL5 and F13. 

The SRPM is installed and unpacked, using C<rpm>, into a temporary
directory using the C<--nomd5> option. The SRPM is then regenerated
using C<rpmbuild> and copied back into the results directory for the
job. A new L<PkgForge::Source::SRPM> object is created for each
package and the sources list for the topic is updated.

=back

=head1 CONFIGURATION AND ENVIRONMENT

This module does not directly use any configuration files.

You will need to ensure you have mock installed and the chroots
correctly configured. The mock chroots are expected to be named like
C<platform-bucket-arch> (e.g. there might be a
C</etc/mock/f13-lcfg-i386.cfg> file). If you use LCFG to manage your
configuration you can use the mock component to do this for you.

You will also need the C<pkgsubmit> tool for submitting the built
packages. There should be a pkgsubmit configuration for each supported
platform/architecture combination, they must be named like
C<platform-arch.conf>, e.g. C</etc/pkgsubmit/f13-i386.conf>

=head1 DEPENDENCIES

This module is powered by L<Moose> and uses L<MooseX::Types>. It also
requires L< File::Find::Rule>, L<IPC::Run>, L<RPM2> and L<Readonly>. 

=head1 SEE ALSO

L<PkgForge>, L<PkgForge::Builder>, L<PkgForge::BuildTopic>

=head1 PLATFORMS

This is the list of platforms on which we have tested this
software. We expect this software to work on any Unix-like platform
which is supported by Perl.

ScientificLinux5, Fedora13

=head1 BUGS AND LIMITATIONS

Please report any bugs or problems (or praise!) to bugs@lcfg.org,
feedback and patches are also always very welcome.

=head1 AUTHOR

    Stephen Quinney <squinney@inf.ed.ac.uk>

=head1 LICENSE AND COPYRIGHT

    Copyright (C) 2010-2011 University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut
