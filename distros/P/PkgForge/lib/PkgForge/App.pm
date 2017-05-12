package PkgForge::App; # -*-perl-*-
use strict;
use warnings;

# $Id: App.pm.in 21266 2012-07-03 14:28:40Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 21266 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge/PkgForge_1_4_8/lib/PkgForge/App.pm.in $
# $Date: 2012-07-03 15:28:40 +0100 (Tue, 03 Jul 2012) $

our $VERSION = '1.4.8';

use File::HomeDir ();
use File::Spec ();
use Readonly;

Readonly my $CONFIGDIR      => '/etc/pkgforge';
Readonly my $USER_CONFIGDIR => '.pkgforge';
Readonly my $BASECONF       => 'pkgforge.yml';

use Moose;
use MooseX::Types::Moose qw(Str);

extends qw(MooseX::App::Cmd::Command);

with 'PkgForge::ConfigFile';

has '+configfile' => (
    default => sub {
        my $class = shift @_;
        my @files = ( File::Spec->catfile( $CONFIGDIR, $BASECONF ) );

        my $home = File::HomeDir->my_home;
        my $user_configdir = File::Spec->catdir( $home, $USER_CONFIGDIR );

        my $mod  = ( split /::/, $class->meta->name )[-1];
        my $mod_conf = lc($mod) . '.yml';

        push @files, File::Spec->catfile( $CONFIGDIR, $mod_conf );
        push @files, File::Spec->catfile( $user_configdir, $BASECONF );
        push @files, File::Spec->catfile( $user_configdir, $mod_conf );

        return \@files;
    },
);

has 'website' => (
    traits        => ['NoGetopt'],
    is            => 'ro',
    isa           => 'Maybe[Str]',
    predicate     => 'has_website',
    documentation => 'The local PkgForge website (if any)',
);

has 'incoming' => (
    traits        => ['NoGetopt'],
    is            => 'ro',
    isa           => Str,
    default       => '/var/lib/pkgforge/incoming',
    documentation => 'The directory for incoming build jobs',
);

has 'accepted' => (
    traits        => ['NoGetopt'],
    is            => 'ro',
    isa           => Str,
    default       => '/var/lib/pkgforge/accepted',
    documentation => 'The directory for accepted build jobs',
);

has 'results' => (
    traits        => ['NoGetopt'],
    is            => 'ro',
    isa           => Str,
    default       => '/var/lib/pkgforge/results',
    documentation => 'The directory for build job results',
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;
__END__

=head1 NAME

PkgForge::App - Package Forge application base class.

=head1 VERSION

This documentation refers to PkgForge::App version 1.4.8

=head1 SYNOPSIS

     package PkgForge::App::Foo;

     use Moose;

     extends 'PkgForge::App';


=head1 DESCRIPTION

This is a base class for user-side Package Forge command-line
applications.  It adds standardised configuration file handling and
holds some common attributes.

=head1 ATTRIBUTES

This class implements the L<PkgForge::ConfigFile> role, see the
documentation for that module for all the inherited attributes. The
following additional attributes are available:

=over

=item configfile

The default value for the configuration files list is overridden. The
standard C</etc/pkgforge/pkgforge.yml> file will always be consulted,
if it exists. The application-specific files in C</etc/pkgforge> and
C<$HOME/.pkgforge> are also examined, if they exist. For example, the
C<submit> command will examine the following configuration files, if
the exist (in this order)

=over

=item C</etc/pkgforge/pkgforge.yml>
=item C</etc/pkgforge/submit.yml>
=item C<$HOME/.pkgforge/pkgforge.yml>
=item C<$HOME/.pkgforge/submit.yml>

=back

Settings in files later in the sequence override those earlier in the
list. So settings in a user's home directory override the common
application settings which override the system-wide settings.

=item website

The location of the local installation of the Package Forge
website. This is mainly used for printing out helpful links to the
user. If not set the links are not printed.

=item incoming

The location of the incoming jobs directory.

=item accepted

The location of the accepted jobs directory.

=item results

The location of the results directory for the finished build jobs.

=back

=head1 SUBROUTINES/METHODS

This class implements the L<PkgForge::ConfigFile> role, see the
documentation for that module for all the inherited methods. This
class does not add any methods.

=head1 DEPENDENCIES

This module is powered by L<Moose>, L<MooseX::Types> and uses
L<MooseX::App::Cmd>. It also requires the L<File::HomeDir> and
L<Readonly> modules.

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

