package PkgForge::Handler::Initialise; # -*-perl-*-
use strict;
use warnings;

# $Id: Initialise.pm.in 15409 2011-01-12 17:25:17Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 15409 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge-Server/PkgForge_Server_1_1_10/lib/PkgForge/Handler/Initialise.pm.in $
# $Date: 2011-01-12 17:25:17 +0000 (Wed, 12 Jan 2011) $

our $VERSION = '1.1.10';

use English qw(-no_match_vars);
use File::Path ();
use File::Spec ();
use PkgForge::Utils ();

use Moose;
use MooseX::Types::Moose qw(Bool);

extends 'PkgForge::Handler';

has 'zap' => (
    is            => 'rw',
    isa           => Bool,
    default       => 0,
    documentation => 'Delete existing directory contents',
);

no Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ($self) = @_;

    # Before anything else we MUST ensure that the log directory exists.

    my $logdir = $self->logdir;
    if ( !-d $logdir ) {
        my $created = eval { File::Path::mkpath($logdir) };
        if ( $EVAL_ERROR || $created == 0 ) {
            $self->logger->log_and_die( level   => 'critical',
                                        message => "Failed to create $logdir: $EVAL_ERROR" );
        }
    }

    $self->logger->info('Initialising server environment');

    for my $attr ( $self->meta->get_all_attributes ) {
        if ( !$attr->does('PkgForge::Meta::Attribute::Trait::Directory') ) {
            next;
        }

        my $dir = $attr->get_value($self);

        if ( -d $dir && $self->zap ) {
            $self->logger->info("Wiping directory $dir");
            my ( @errors, @results );
            my $options = { error => \@errors, keep_root => 1 };
            if ( $self->debug ) {
                $options->{result} = \@results;
            }

            PkgForge::Utils::remove_tree($dir, $options);

            if ( $self->debug ) {
                $self->logger->debug("Removed @results");
            }

            if ( scalar @errors > 1 ) {
                $self->logger->log_and_die( level   => 'critical',
                                            message => "Failed to wipe $dir: @errors" );
            }
        }

        if ( !-d $dir ) {
            $self->logger->info("Creating directory $dir");
            my $created = eval { File::Path::mkpath($dir) };
            if ( $EVAL_ERROR || $created == 0 ) {
                $self->logger->log_and_die( level   => 'critical',
                                            message => "Failed to create $dir: $EVAL_ERROR" );
            }
        }
    }

    return 1;
}

1;
__END__

=head1 NAME

PkgForge::Handler::Initialise - Package Forge class for initialising the server

=head1 VERSION

This documentation refers to PkgForge::Handler::Initialise version 1.1.10

=head1 SYNOPSIS

    use PkgForge::Handler::Initialise ();

    my $init = PkgForge::Handler::Initialise->new_with_config();

    $init->execute;

=head1 DESCRIPTION

This class provides a method for initialising the Package Forge
server. It creates any necessary directories and, optionally, wipes
them to return them to a pristine starting position.

=head1 ATTRIBUTES

This class inherits from L<PkgForge::Handler>, see the documentation
for that module for full details of inherited attributes.

=over

=item zap

Controls whether the contents of Package Forge directories which
already exist should be wiped. Defaults to false.

=item configfile

This is inherited from L<MooseX::ConfigFromFile> (via
L<PkgForge::ConfigFile>), if specified it can be used to initialise
the class via the C<new_with_config> method. It can be a string or a
list of strings, each file should be a YAML file, see
L<PkgForge::ConfigFile> for details.

=item debug

A boolean value to control whether or not debugging messages are
logged. The default is false.

=item incoming

The directory into which incoming package forge jobs will be
submitted. The default is C</var/lib/pkgforge/incoming>

=item accepted

The directory into which package forge jobs will be transferred if
they are accepted as valid. The default is C</var/lib/pkgforge/accepted>

=item results

The directory into which the results of finished package forge jobs
will be stored. The default is C</var/lib/pkgforge/results>.

=item logdir

The directory into which log files will be stored by default. You can
override the path to a log file to have any absolute path you wish so
this attribute may have no effect on the log file used. The default is
C</var/log/pkgforge>.

=item logfile

The file into which messages will be logged. The default value is
C<default.log> within the directory specified in the C<logdir>
attribute. You probably want a different log file for each handler.

=item logger

This is the logger object, you can call methods such as C<debug> and
C<error> on this object to log messages. See L<Log::Dispatch> and
L<Log::Dispatch::Config> for full details.

=back

=head1 SUBROUTINES/METHODS

This class inherits from L<PkgForge::Handler>, see the documentation
for that module for full details of inherited methods.

=over

=item new_with_config

This uses L<PkgForge::ConfigFile>, which in turn uses
L<MooseX::ConfigFromFile>, to set the attributes for the module from
configuration files.

=item execute

This method does the actual work of initialising the Package Forge
server environment. It will create the required directories if they do
not exist. If the C<zap> attribute has been set to true then it will
also wipe the contents of the directories if they already exist.

=back

=head1 DEPENDENCIES

This module is powered by L<Moose> and uses L<MooseX::ConfigFromFile>
and L<MooseX::Types>.

=head1 SEE ALSO

L<PkgForge>, L<PkgForge::Handler>, L<PkgForge::Utils>

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

