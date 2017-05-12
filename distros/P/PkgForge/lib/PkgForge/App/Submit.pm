package PkgForge::App::Submit; # -*-perl-*-
use strict;
use warnings;

# $Id: Submit.pm.in 16544 2011-03-31 16:25:38Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 16544 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge/PkgForge_1_4_8/lib/PkgForge/App/Submit.pm.in $
# $Date: 2011-03-31 17:25:38 +0100 (Thu, 31 Mar 2011) $

our $VERSION = '1.4.8';

use English qw(-no_match_vars);
use File::HomeDir ();
use File::Spec ();
use PkgForge::SourceUtils ();

use Moose;
use MooseX::Types::Moose qw(Str);

extends qw(PkgForge::Job PkgForge::App);

has 'target' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
    documentation => 'Location into which jobs should be submitted',
);

has '+directory' => (
    traits => ['NoGetopt'],
);

has '+yamlfile' => (
    traits => ['NoGetopt'],
);

has '+packages' => (
    traits => ['NoGetopt'],
);

has '+size' => (
    traits  => ['NoGetopt'],
);

has '+submitter' => (
    traits => ['NoGetopt'],
);

has '+subtime' => (
    traits => ['NoGetopt'],
);

no Moose;
__PACKAGE__->meta->make_immutable;

sub abstract { return q{Submit a set of source packages for building}; }

sub submit {
    my ($self) = @_;

    # We assume that the target is a directory in this simple case.

    my $target = $self->target;
    if ( !-d $target ) {
        die "Cannot find build job submission directory $target\n";
    }

    my $new_obj = eval { $self->transfer($target) };
    if ( !defined $new_obj || $EVAL_ERROR ) {
        die "Job submission failed: $EVAL_ERROR\n";
    }

    return $new_obj->id;
}

sub include_packages {
    my ( $self, @packages ) = @_;

    if ( scalar @packages == 0 ) {
        die "No packages specified, nothing to do.\n";
    }

    my @build;
    for my $package (@packages) {
        if ( !-f $package ) {
            die "The file '$package' does not exist\n";
        }

        my $module = PkgForge::SourceUtils::find_handler($package);

        if ( !defined $module ) {
            die "Unsupported package type for $package, is it really a source package?\n";
        }

        my $pkg = $module->new($package);

        if ( $pkg->validate() ) {
            push @build, $pkg;
        }
        else {
            die "$package is not a valid source package\n";
        }
    }

    return $self->add_packages(@build);
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my @packages = @{ $args };
    $self->include_packages(@packages);

    my $id = $self->submit();

    if ( defined $id ) {
        my $pkg_count = scalar @packages;
        print "Successfully submitted $pkg_count packages as build job $id\n";
        if ( $self->has_website && $self->website ) {
            print 'You can follow the progress at ' . $self->website . "\n";
        }
    } else {
        die "Failed to submit job\n";
    }

    return;
}

1;
__END__

=head1 NAME

PkgForge::App::Submit - Package Forge application for submitting build jobs

=head1 VERSION

This documentation refers to PkgForge::App::Submit version 1.4.8

=head1 USAGE

     % pkgforge submit --bucket devel foo-1-2.src.rpm bar-3-4.src.rpm

     % pkgforge submit --bucket devel \
                       --archs '!x86_64' foobar-1-2.src.rpm

     % pkgforge submit --bucket lcfg \
                       --platforms 'f13,sl5' foobar-1-2.src.rpm

=head1 DESCRIPTION

This is a simple command-line tool for submitting jobs for the Package
Forge software suite. This module relies on being able to do a simple
copy of the necessary files from one location in the filesystem to
another. This means you must be either using a networked filesystem,
such as AFS or NFS, to allow remote submissions or requiring users to
submit their jobs from the Package Forge master node.

A build job may consist of multiple source packages, you must supply
at least one valid source package. When multiple source packages are
provided they will be built in the order they are specified. On some
platforms, e.g. Redhat/Fedora where mock(1) is used, a build failure
in one package does not result in the whole job failing
immediately. Failed packages will be put to the end of the queue in
the hope that the failure was down to missing dependencies which can
be satisfied by building later packages in the build job. As long as
more packages keep being built the entire job will not fail due to
individual build failures.

=head1 REQUIRED ARGUMENTS

You must specify at least one valid source package for submission as a
build job.

=head1 OPTIONS

This is the list of command-line options which may be set when
submitting build jobs. Note that some of the options can take multiple
values. In all cases you can use the shortest unique name for an
option (e.g. C<plat> for C<platforms>. Some options also have
single-character alternatives. As well as specifying them each time a
job is submitted the options can be permanently set using the
configuration files for this application.

=over 4

=item C<--bucket|-B>

This is the name of the package repository bucket into which binary
packages will be submitted once they are built. This option is
required. For RPMs this will be done using the pkgsubmit(8)
command. For some platforms (e.g. those which use mock(1) to build
packages) this may also alter which build chroot configuration is
used.

=item C<--archs|-a>

This is the list of architectures (e.g. i386 and x86_64) for which you
want the binary packages to be built. If nothing is specified then
build tasks will be registered for all available architectures. 

This option may have multiple values, these can be expressed as a
comma-separated list (e.g. C<--archs i386,x86_64>) or via putting the
same option multiple times (e.g. C<--arch i386 --arch x86_64>). Note
that values can also be negated by prefixing with an C<!> (exclamation
mark). This can be useful when you want all the architectures
B<except> one specific case.

=item C<--platforms|-p>

This is the list of platforms (e.g. sl5 and f13) for which you want
the binary packages to be built. If nothing is specified then build
tasks will be registered for all available platforms.

This option may have multiple values, these can be expressed as a
comma-separated list (e.g. C<--platforms f13,sl5>) or via putting the
same option multiple times (e.g. C<--plat f13 --plat sl5>). Note that
values can also be negated by prefixing with an C<!> (exclamation
mark). This can be useful when you want all the platforms B<except>
one specific case.

=item C<--report|-r>

This option can be used to set an email address (or set of email
addresses) to which a summary report should be sent after the job has
completed.

=item C<--verbose>

Makes the output from verbose to see what is happening.

=item C<--configfile|-c>

This attribute is used to override the default configuration
files. See the B<CONFIGURATION AND ENVIRONMENT> section below for
details of how the configuration is normally loaded from files. If you
specify a particular configuration file then B<ONLY> that file will be
parsed, any others will be ignored.

=item C<--target>

This is the location (e.g. normally a directory) into which the job
should be submitted. Normally this would be specified in a
configuration file and would not need to be specified on the command
line.

=item C<--id>

This is a unique identifier used to track the job to be
submitted. Normally it is not necessary to specify the ID as a new
unique string will be selected automatically. You may specify any,
previously unused, string you like as long as all the characters match
the set C<A-Za-z0-9_-> and the string is no more than 50 characters
long.

=back

=head1 CONFIGURATION AND ENVIRONMENT

The standard C</etc/pkgforge/pkgforge.yml> file will always be
consulted, if it exists. The application-specific files in
C</etc/pkgforge> and C<$HOME/.pkgforge> are also examined, if they
exist. For the C<submit> command the following configuration files
will be examined, if the exist (in this order)

=over

=item C</etc/pkgforge/pkgforge.yml>
=item C</etc/pkgforge/submit.yml>
=item C<$HOME/.pkgforge/pkgforge.yml>
=item C<$HOME/.pkgforge/submit.yml>

=back

Settings in files later in the sequence override those earlier in the
list. So settings in a user's home directory override the common
application settings which override the system-wide settings.

The configuration format is YAML, in this case all that is required
are simple key-value pairs separated with a colon, one per-line, for
example C<bucket: lcfg>

=head1 EXIT STATUS

After successfully running a command it will exit with code zero. An
error will result in a non-zero error code.

=head1 DEPENDENCIES

This module is powered by L<Moose> and uses
L<MooseX::App::Cmd::Command> and L<MooseX::Types>.

=head1 SEE ALSO

L<PkgForge>, L<PkgForge::Job>, L<PkgForge::Source>,
L<PkgForge::SourceUtils>, L<PkgForge::ConfigFile>, L<PkgForge::App>

Normally you would not use this class directly but would use the
C<submit> command via the pkgforge(1) command.

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

