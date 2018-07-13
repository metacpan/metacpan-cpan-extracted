use strict;
use warnings;
package Plack::Middleware::LogStderr;
$Plack::Middleware::LogStderr::VERSION = '0.001';
# ABSTRACT: Everything printed to STDERR sent to psgix.logger or other logger
# KEYWORDS: plack middleware errors logging environment I/O handle stderr

use parent 'Plack::Middleware';

use Plack::Util::Accessor qw/logger callback tie_callback capture_callback no_tie log_level log_level_capture/;
use Scalar::Util ();
use Capture::Tiny 'capture_stderr';

sub prepare_app {
    my $self = shift;
    $self->{log_level} = $self->log_level || 'error';
    $self->{log_level_capture} = $self->log_level_capture || $self->{log_level} ;
        
    foreach my $cb (qw/logger callback tie_callback capture_callback/){
        if ($self->$cb) {
            if (not __isa_coderef($self->$cb)) {
                die "'$cb' is not a coderef!"
            }
        }
    }
}

sub call {
    my ($self, $env) = @_;
    my $logger = $self->logger || $env->{'psgix.logger'};

    die 'no psgix.logger in $env; cannot send STDERR to it!'
        if not $logger;
    
    my $stderr_logger = sub {
        my $message = shift;
        $message = $self->__run_tie_callback($message);
        $logger->({level => $self->{log_level}, message => $message });
    };
    
    my ($stderr, @app) = capture_stderr {
        my ($app, $err);

        tie *STDERR, 'Plack::Middleware::LogStderr::Handle2Logger', $stderr_logger
            unless $self->no_tie ;

        eval {
            $app =  $self->app->($env);
        };
        $err = $@ if $@;

        untie *STDERR
            unless $self->no_tie ;
            
        if ($err) {
            die $@;
        }
        return $app;
    };
    if ($stderr) {
        $stderr = $self->__run_capture_callback($stderr) ;
        $logger->({level => $self->{log_level_capture}, message => $stderr });
    }
    
    return $app[0];
}

sub __run_callback {
    my ($self, $msg, $extra_cb) = @_;
    $msg = $self->callback->($msg) if $self->callback;
    if ($extra_cb) {
        if ($extra_cb eq 'tie' && $self->tie_callback) {
            $msg = $self->tie_callback->($msg) ;
        }
        if ($extra_cb eq 'capture' && $self->capture_callback) {
            $msg = $self->capture_callback->($msg) ;
        }
    }
    return $msg;
}
sub __run_capture_callback {
    my ($self, $msg) = @_;
    $msg = $self->__run_callback($msg, 'capture');
    return $msg;
    
}
sub __run_tie_callback {
    my ($self, $msg) = @_;
    $msg = $self->__run_callback($msg, 'tie');
    return $msg;
}

sub __isa_coderef {
    ref $_[0] eq 'CODE'
        or (Scalar::Util::reftype($_[0]) || '') eq 'CODE'
        or overload::Method($_[0], '&{}')
}

package # hide from PAUSE
    Plack::Middleware::LogStderr::Handle2Logger;
our $VERSION = '0.001';
# ABSTRACT: Tie File Handle to a logger
use warnings::register;

sub TIEHANDLE {
    my ($pkg, $logger) = @_;
    return bless {logger => $logger}, $pkg;
}
sub PRINT {
    my ($self, @msg) = @_;
    my $message = join('', @msg);
    $self->{logger}->( $message );
}
sub PRINTF {
    my ($self, $fmt, @msg) = @_;
    my $message = sprintf($fmt, @msg);
    $self->{logger}->($message);
}
## if something tries to reopen FILEHANDLE just return true -- noop
sub OPEN {
    my ($self) = @_;
    if (warnings::enabled()) {
        warnings::warn("open called on tied handle Handle2Logger");
    }
    return 1;
}
## if something tries to set BINMODE -- noop
sub BINMODE {
    if (warnings::enabled()) {
        warnings::warn("binmode called on tied handle Handle2Logger");
    }
    return undef;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::LogStderr - Everything printed to STDERR sent to psgix.logger or other logger

=head1 VERSION

version 0.001

=head1 SYNOPSIS

Using a logger you have already configured (using L<Log::Dispatch> as an
example):

  use Log::Dispatch;
  my $logger = Log::Dispatch->new;
  $logger->add( Log::Dispatch::File->new(...) );

  builder {
      enable 'LogDispatch', logger => $logger;
      enable 'LogStderr';
      $app;
  }

Using an explicitly defined logger:

  builder {
      enable 'LogStderr', logger => sub {
          my $args = shift;
          $logger->log(%$args);
      };
      $app;
  }

Other Options:

  ...
  enable 'LogStderr',
      log_level => 'warn',
      no_tie => 1,
      callback => sub {
          my $msg = shift;
          return "STDERR:$msg\n";
  };
  ...

=head1 DESCRIPTION

This middleware intercepts all output to C<STDERR> and redirects it to a defined
logger.

Examples where C<STDERR> output would not typically be sent to a logger:

  print STDERR "foo";
  system('perl -e " print STDERR \'bar\'"');
  warnings::warn("baz");

This middleware uses two techniques to catch messages sent to C<STDERR> and
direct them to a logger.

The first ties the C<STDERR> filehandle and directs all print messages to a logger.
This method only works if the code printing to C<STDERR> is aware of the Perl
tied filehandle.

The second technique uses L<Capture::Tiny> to capture everything else written to
C<STDERR> (for example any programs run using C<system>). This method groups all
C<STDERR> output into one message. The drawback here is log messages may not be
interleaved temporally with messages generated from the tied method or other
calls to the logger.

=head1 NAME

Plack::Middleware::LogStderr - redirect STDERR output to a defined logger

=head1 CONFIGURATION

=head2 C<logger>

A code reference for logging messages, that conforms to the
L<psgix.logger|PSGI::Extensions/SPECIFICATION> specification.
If not provided, C<psgix.logger> is used, or the application will generate an
error at runtime if there is no such logger configured.

=head2 C<log_level>, C<log_level_capture>

By default the log level used is 'error' use C<log_level> to set it to another value.

Use C<log_level_capture> if you want the default log level for captured output to be different from C<log_level>

Make sure the log level used is valid for your logger!

=head2 C<callback>, C<capture_callback>, C<tie_callback>

Callbacks that take a string and return a string.

=over

=item C<callback> is applied to all messages.

=item C<capture_callback> is applied to all messages logged via the capture method.

=item C<tie_callback> is applied to messages logged via the tied C<STDERR> filehandle.

=back

=head2 C<no_tie>

Do not tie the perl file handle C<STDERR> to a logger.
When set, all output to C<STDERR> will be caught and logged in one message.

The benefit of this is all output sent to C<STDERR> is in order.
The drawback is all C<STDERR> output created during a request is grouped
together as one message and logged together after the request has finished
processesing.

=head1 SEE ALSO

=over 4

=item *

L<PSGI::Extensions> - the definition of C<psgix.logger>

=item *

L<Plack::Middleware::LogDispatch> - use a L<Log::Dispatch> logger for C<psgix.logger>

=item *

L<Plack::Middleware::Log4perl> - use a L<Log::Log4perl> logger for C<psgix.logger>

=item *

L<Capture::Tiny>

=item *

L<PSGI/"The Error Stream"> - the definition of C<psgi.errors>

=item *

L<Plack::Middleware::LogErrors> - redirect C<psgix.error> to C<psgix.logger>

=back

=head1 ACKNOWLEDGEMENTS

Karen Etheridge

=head1 SOURCE

The source code repository for Plack-Middleware-LogStderr can be found at L<https://github.com/amalek215/Plack-Middleware-LogStderr>

=head1 AUTHOR

Alex Malek <amalek@cpan.org>

=head1 AUTHOR

Alex Malek

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Alex Malek.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
