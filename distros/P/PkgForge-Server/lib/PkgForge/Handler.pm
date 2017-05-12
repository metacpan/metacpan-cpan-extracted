package PkgForge::Handler;    # -*-perl-*-
use strict;
use warnings;

# $Id: Handler.pm.in 21263 2012-07-03 14:26:32Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 21263 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge-Server/PkgForge_Server_1_1_10/lib/PkgForge/Handler.pm.in $
# $Date: 2012-07-03 15:26:32 +0100 (Tue, 03 Jul 2012) $

our $VERSION = '1.1.10';

use File::Spec ();
use Readonly;

Readonly my $CONFIGDIR    => '/etc/pkgforge';
Readonly my $BASE_CONF    => 'pkgforge.yml';
Readonly my $HANDLER_CONF => 'handlers.yml';

use Moose;
use MooseX::Types::Moose qw(Bool HashRef Str);
use PkgForge::Meta::Attribute::Trait::Directory;

with 'MooseX::LogDispatch', 'PkgForge::ConfigFile', 'MooseX::Getopt';

has '+configfile' => (
    default => sub { 
        my $class = shift @_;

        my @files = (
            File::Spec->catfile( $CONFIGDIR, $BASE_CONF ),
            File::Spec->catfile( $CONFIGDIR, $HANDLER_CONF ),
        );

        my $mod  = ( split /::/, $class->meta->name )[-1];
        my $mod_conf = lc($mod) . '.yml';

        push @files, File::Spec->catfile( $CONFIGDIR, $mod_conf );

        return \@files;
    },
);

has '+logger' => (
    traits => ['NoGetopt'],
);

has '+use_logger_singleton' => (
    traits => ['NoGetopt'],
);

# Logging Stuff

has 'debug' => (
    is            => 'ro',
    isa           => Bool,
    default       => 0,
    documentation => 'Log debug messages',
);

has 'logconf' => (
    is        => 'ro',
    isa       => 'Maybe[Str]',
    default   => '/etc/pkgforge/log-default.cfg',
    predicate => 'has_logconf',
    documentation => 'The logging configuration file',
);

has 'log_dispatch_conf' => (
    traits   => ['NoGetopt'],
    is       => 'ro',
    lazy     => 1,
    default  => sub {
        my ($self) = @_;
        if ( $self->has_logconf && -f $self->logconf ) {
            return $self->logconf;
        } else {
            return {
                class     => 'Log::Dispatch::Screen',
                min_level => $self->debug ? 'debug' : 'info',
                stderr    => 1,
                format    => '[%p] %m%n',
            };
        }
    },
    documentation => 'The configuration for Log::Dispatch',
);

# Directories

has 'logdir' => (
    is            => 'ro',
    isa           => Str,
    default       => '/var/log/pkgforge',
    required      => 1,
    documentation => 'The default directory for log files',
);

has 'incoming' => (
    traits        => ['PkgForge::Directory'],
    is            => 'ro',
    isa           => Str,
    default       => '/var/lib/pkgforge/incoming',
    required      => 1,
    documentation => 'The directory for incoming build jobs',
);

has 'accepted' => (
    traits        => ['PkgForge::Directory'],
    is            => 'ro',
    isa           => Str,
    default       => '/var/lib/pkgforge/accepted',
    required      => 1,
    documentation => 'The directory for accepted build jobs',
);

has 'tmpdir' => (
    traits        => ['PkgForge::Directory'],
    is            => 'ro',
    isa           => Str,
    default       => '/var/tmp/pkgforge',
    required      => 1,
    documentation => 'A directory for temporary files',
);

has 'results' => (
    traits        => ['PkgForge::Directory'],
    is            => 'ro',
    isa           => Str,
    default       => '/var/lib/pkgforge/results',
    required      => 1,
    documentation => 'The directory for build job results',
);

# Use this error log method as the logger eats $EVAL_ERROR if you are
# not careful.

sub log_problem {
    my ( $self, $msg, $error ) = @_;

    $self->logger->error($msg);
    if ($error) {
        $self->logger->error($error);
    }

    return;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

PkgForge::Handler - A Moose class to be used by PkgForge handlers.

=head1 VERSION

     This documentation refers to PkgForge::Handler version 1.1.10

=head1 SYNOPSIS

     package PkgForge::Handler::Foo;

     use Moose;

     extends 'PkgForge::Handler';

     sub execute { }

=head1 DESCRIPTION

This is a Moose class which pulls together all the common aspects of
Package Forge handlers. A handler is a class which does a specific
job, for example: accepting incoming jobs or firing off builds of
accepted jobs. This class requires that the sub-class implements a
method named C<execute> which actually does the work.

=head1 ATTRIBUTES

The following attributes will be part of any class which inherits from
this class:

=over

=item configfile

This is inherited from L<MooseX::ConfigFromFile> (via
L<PkgForge::ConfigFile>), if specified it can be used to initialise
the class via the C<new_with_config> method. It can be a string or a
list of strings, each file should be a YAML file, see
L<PkgForge::ConfigFile> for details.

=item debug

A boolean value to control whether or not debugging messages are
logged. The default is false. Note that when using a logging
configuration file it is better to control the minimum log level
through that file.

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

The directory into which log files will be stored by default. The
default path is C</var/log/pkgforge>. This attribute does not
currently have any direct effect on where the log files are stored. It
is solely provided so that the server initialisation script can ensure
that the correct directory exists.

=item logconf

The configuration file for the logging system. The default value is
C</etc/pkgforge/log-default.cfg>. If this is not specified (i.e. set
to undef) or does not exist then all messages will be logged directly
to stderr. For servers that is almost certainly not what you want. See
L<Log::Dispatch::Configurator::AppConfig> for details of the
configuration file format.

=item log_dispatch_conf

This is the configuration for L<Log::Dispatch>, see that module for
documentation. Also See L<MooseX::LogDispatch>. You normally control
this via the configuration file specified in the C<logconf> attribute.

=item logger

This is a reference to the logger object, you can call methods such as
C<debug> and C<error> on this object to log messages. See
L<Log::Dispatch> and L<Log::Dispatch::Config> for full details.

=back

=head1 SUBROUTINES/METHODS

A class which inherits from this class will have the following
methods. This class also requires that the sub-class implements a
method named C<execute> which actually does the work.

=over

=item new()

Create a new instance of the class. Optionally set some attributes by
passing a hash as usual.

=item new_with_config()

Create a new instance of the class with attributes set by either
entries in the configuration file or the usual hash. See
L<MooseX::ConfigFromFile> for details.

=item log_problem( $msg, $error_string )

The logger we are using has a tendency to eat the contents of the
C<$EVAL_ERROR|$@> variable when it is called. This can make formatting
error messages quite tricky. If you want your handler to print a
message on one line and then add any message that might be in
C<$EVAL_ERROR> on a following line then use this method. Underneath it
will use the C<error> method of the logger.

=back

=head1 CONFIGURATION AND ENVIRONMENT

By default Package Forge handlers can be configured via the YAML file
C</etc/pkgforge/handlers.yml> This can be overridden by any handler
class so also see the documentation for the specific class.

By default, the logging system can be configured via
C</etc/pkgforge/default.log>. If the file does not exist then the
handler will log to stderr.

=head1 DEPENDENCIES

This module is powered by L<Moose> and uses L<MooseX::ConfigFromFile>,
L<MooseX::LogDispatch> and L<MooseX::Types>.

=head1 SEE ALSO

L<PkgForge>

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

    Copyright (C) 201O University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut
