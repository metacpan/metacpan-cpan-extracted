package Plasp::Log;

use Moo;
use Types::Standard qw(InstanceOf Str ArrayRef HashRef);

has 'asp' => (
    is       => 'rw',
    isa      => InstanceOf ['Plasp'],
    weak_ref => 1,
);

=head1 NAME

Plasp::Log - Logging class for Plasp

=head1 SYNOPSIS

  package Plasp;

  has 'log' => (
    default => { Plasp::Log->new( asp => shift ) }
  );

  1;

=head1 DESCRIPTION

A class to define logger functions. Essentially send every message to logger
although prepends log level

=head1 ATTRIBUTES

=over

=item $log->level

Set or get the currently configured log level

=cut

# Assign integers to each log level for comparison
my %levels = (
    debug => 1,
    info  => 2,
    warn  => 3,
    error => 4,
    fatal => 5,
);

has 'level' => (
    is      => 'rw',
    isa     => Str,
    default => $levels{info},
);

=item $log->entries

An array ref of log entries

=cut

has 'entries' => (
    is      => 'rw',
    isa     => ArrayRef,
    default => sub { [] },
);

# Store loggers, but only define them when context is right. See _get_loggers
has '_loggers' => (
    is      => 'rw',
    isa     => HashRef,
    default => sub { {} },
);

=back

=head1 METHODS

=over

=cut

sub BUILD {
    my ( $self ) = @_;

    $self->level( $levels{debug} ) if $self->asp && $self->asp->Debug;
}

# Get the logger based on current context
sub _get_logger {
    my ( $self ) = @_;

    # Logging for while processing requests
    if ( ref $self->asp eq 'Plasp' && $self->asp->req ) {

        if ( $self->asp->req->env->{'psgix.logger'} ) {

            # If a logger is defined by PSGI, then use it
            return $self->asp->req->logger;

        } else {

            # Otherwise, write to the PSGI error stream
            return $self->_loggers->{request} ||= sub {
                my ( $entry ) = @_;
                my ( $level, $message ) = @$entry{qw(level message)};
                if ( $levels{$level} >= $self->level ) {
                    $self->asp->req->env->{'psgi.errors'}->print(
                        sprintf( "[%s] %s\n", uc( $level ), $message )
                    );
                }
            };
        }

    } else {

        # Logging other errors during startup process
        return $self->_loggers->{startup} ||= sub {
            my ( $entry ) = @_;
            my ( $level, $message ) = @$entry{qw(level message)};
            if ( $levels{$level} >= $self->level ) {
                printf STDERR "[%s] %s\n", uc( $level ), $message;
            }
        }
    }
}

=item $log->debug( $message, %context_values )

Add debug log messages into log and prints to logger

=cut

sub debug {
    my $self    = shift;
    my $message = shift;
    my $logger  = $self->_get_logger;

    my $entry = {
        level   => 'debug',
        message => $message,
        @_,
    };
    push @{ $self->entries }, $entry;
    $logger->( $entry );
}

=item $log->info( $message, %context_values )

Add info log messages into log and prints to logger

=cut

sub info {
    my $self    = shift;
    my $message = shift;
    my $logger  = $self->_get_logger;

    my $entry = {
        level   => 'info',
        message => $message,
        @_,
    };
    push @{ $self->entries }, $entry;
    $logger->( $entry );
}

=item $log->warn( $message, %context_values )

Add warn log messages into log and prints to logger

=cut

sub warn {
    my $self    = shift;
    my $message = shift;
    my $logger  = $self->_get_logger;

    my $entry = {
        level   => 'warn',
        message => $message,
        @_,
    };
    push @{ $self->entries }, $entry;
    $logger->( $entry );
}

=item $log->error( $message, %context_values )

Add error log messages into log and prints to logger

=cut

sub error {
    my $self    = shift;
    my $message = shift;
    my $logger  = $self->_get_logger;

    my $entry = {
        level   => 'error',
        message => $message,
        @_,
    };
    push @{ $self->entries }, $entry;
    $logger->( $entry );
}

=item $log->fatal( $message, %context_values )

Add fatal log messages into log and prints to logger

=cut

sub fatal {
    my $self    = shift;
    my $message = shift;
    my $logger  = $self->_get_logger;

    my $entry = {
        level   => 'fatal',
        message => $message,
        @_,
    };
    push @{ $self->entries }, $entry;
    $logger->( $entry );
}

1;

=back
