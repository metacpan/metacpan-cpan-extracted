package Object::Remote::Role::Connector;

use Module::Runtime qw(use_module);
use Object::Remote::Future;
use Object::Remote::Logging qw(:log :dlog router);
use Moo::Role;

requires '_open2_for';

has timeout => (is => 'ro', default => sub { 10 });

BEGIN { router()->exclude_forwarding; }

sub connect {
  my $self = shift;
  Dlog_debug { "Preparing to create connection with args of: $_" } @_;
  my ($send_to_fh, $receive_from_fh, $child_pid) = $self->_open2_for(@_);
  my $channel = use_module('Object::Remote::ReadChannel')->new(
    fh => $receive_from_fh
  );
  return future {
    log_trace { "Initializing connection for child pid '$child_pid'" };
    my $f = shift;
    $channel->on_line_call(sub {
      if ($_[0] eq "Shere") {
        log_trace { "Received 'Shere' from child pid '$child_pid'; setting done handler to create connection" };
        $f->done(
          use_module('Object::Remote::Connection')->new(
            send_to_fh => $send_to_fh,
            read_channel => $channel,
            child_pid => $child_pid,
          )
        );
      } else {
        log_warn { "'Shere' was not found in connection data for child pid '$child_pid'" };
        $f->fail("Expected Shere from remote but received: $_[0]");
      }
      undef($channel);
    });
    $channel->on_close_call(sub {
      log_trace { "Connection has been closed" };
      $f->fail("Channel closed without seeing Shere: $_[0]");
      undef($channel);
    });
    log_trace { "initialized events on channel for child pid '$child_pid'; creating timeout" };
    Object::Remote->current_loop
                  ->watch_time(
                      after => $self->timeout,
                      code => sub {
                        Dlog_trace {"Connection timeout timer has fired for child pid '$child_pid'; is_ready: $_" } $f->is_ready;
                        unless($f->is_ready) {
                            log_warn { "Connection with child pid '$child_pid' has timed out" };
                            $f->fail("Connection timed out") unless $f->is_ready;
                        }
                        undef($channel);

                      }
                    );
    log_trace { "connection for child pid '$child_pid' has been initialized" };
    $f;
  }
}

1;
