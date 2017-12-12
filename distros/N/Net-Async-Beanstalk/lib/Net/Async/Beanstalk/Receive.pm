package Net::Async::Beanstalk::Receive;

our $VERSION = '0.001';
$VERSION = eval $VERSION;

=head1 NAME

Net::Async::Beanstalk::Receive - Methods to handle responses from beanstalk

=head1 DOCUMENTED ELSEWHERE

This module's external API is documented in L<Net::Async::Beanstalk>

=cut

use v5.10;
use Moo::Role;
use strictures 2;

use Carp;
use List::Util qw(any);
use MooX::EventHandler;
use Net::Async::Beanstalk::Constant qw(:receive :state);
use YAML::Any  qw(Load);
use namespace::clean;

# TODO: Document internal API

has_event [
  'on_read',
  'on_invalid_response',
  (map { lc "on_$_" } keys %RESPONSE),
  (map { lc "on_${_}_final" } @WITHDATA),
];

sub _build_on_read {
  sub {
    my $self = shift;
    my ($buf, $eof) = @_;
    my $data;

    my $state = $self->current_command;
    if (ref $state and $state->[STATE_MOAR]) {
      my ($had, $size) = @{ $state->[STATE_MOAR] };
      return 0 unless $$buf =~ s/^(.{$size})$NL//s;
      push @{ $state->[STATE_RECEIVE] }, $data = $1;
      $buf = $had;

    } else {
      # prot.c defines NAME_CHARS as alphanum & -+/;.$_()
      return 0 unless $$buf =~ s{^([A-Za-z0-9+/;.\$_() -]+)$NL}{};
      push @{ $state->[STATE_RECEIVE] }, $buf = $1;
    }

    my ($got, @args) = split / /, $buf;

    if (not $RESPONSE{$got}) {
      $self->maybe_invoke_event(on_invalid_response => $got, $buf);
      # Can't continue; state's all screwey
      die "Protocol error";
    } else {
      $self->_assert_state($got);
      if ($data) {
        $self->maybe_invoke_event(lc "on_${got}_final", @args, $data);
      } else {
        $self->maybe_invoke_event(lc "on_$got", @args);
      }
    }

    return 1;
  }
}

# Events which are handled in unusual ways

# OK returns some YAML data
sub _build_on_ok_final {
  sub {
    # TODO: Alert when the result of list-tubes-watching or
    # whatever-finds-out-used-tube are called and differ from values
    # cached in using/watching
    my $self = shift;
    my ($data) = @_;
    my $decoded = Load($data);
    my @decoded = ref $decoded eq 'ARRAY' ? @$decoded : %$decoded;
    # Assert \@decoded {=} $self->watching if $source eq 'list-tubes-watched' ?
    $self->finish_command(@decoded);
  }
}

# using and watching events change or assert which tubes are active
sub _build_on_using {
  sub {
    my $self = shift;
    my $state = $self->current_command;
    my ($tube) = @_;
    if ($state->[STATE_COMMAND] eq 'list-tube-used') {
      # Assert $tube eq $self->using ?
      $self->finish_command($tube);
    } elsif ($state->[STATE_COMMAND] eq 'use') {
      $self->_set_using($tube);
      $self->finish_command($tube);
    }
  }
}

sub _build_on_watching {
  sub {
    my $self = shift;
    my $state = $self->current_command;
    my $tube = $state->[STATE_DATUM];
    my ($count) = @_;
    if ($state->[STATE_COMMAND] eq 'ignore') {
      delete $self->_watching->{$tube};
      $self->finish_command($tube, $count);
    } elsif ($state->[STATE_COMMAND] eq 'watch') {
      $self->_watching->{$tube} = 1;
      $self->finish_command($tube, $count);
    }
  }
}

# Repetetive responses; First define some magic ...

# ... with 1 way to wait,
sub _makesub_wantmoar {
  my ($command) = @_;
  sub {
    my $self = shift;
    my $size = pop;
    $self->current_command->[STATE_MOAR] = [join(' ', $command, @_), $size];
  };
}

# ... 3 ways to fail,

sub _makesub_fail {
  my $how = @_ >= 4 ? shift : ERROR_FAIL;
  my ($category, $message, $start) = @_; # backwards
  sub {
    my $state = $_[0]->current_command;
    $state = $_[0]->_command_stack if $start == 0;
    my @nothing = (shift @$state) x ($start // STATE_DATUM);
    my $datum = $_[1] || $state->[STATE_DATUM] || '<?>';
    $how & ERROR_FAIL  && $_[0]->fail_command(eval $message, $category, @$state);
    $how & ERROR_EVENT && $_[0]->invoke_error(     $message, $category, @$state);
  }
}
sub _makesub_error { _makesub(ERROR_EVENT, @_) }
sub _makesub_hard  { _makesub(ERROR_EVENT | ERROR_FAIL, @_) }

# ... 2 ways to be done with some data,
sub _makesub_done       { sub { $_[0]->finish_command(@_[1..$#_]) } }
sub _makesub_done_datum { sub { $_[0]->finish_command($_[0]->current_command->[STATE_DATUM]) } }

# ... and 1 way to do some combination,
sub _makesub_multi {
  my %respond = @_;
  sub {
    my $self = shift;
    my $state = $self->current_command;
    my $datum = $_[0];
    for ($state->[STATE_COMMAND]) {
      my ($sub, @args) = $respond{$_}[0] eq 'finish_with'
        # There's only actually two of these so a bit of hard-coding is fine
        ? (finish => [ $state->[STATE_DATUM], map {$_[$_]} @{ $respond{$_}[1] } ])
        : ("$respond{$_}[0]_command" => @{$respond{$_}}[1..$#{$respond{$_}}]);
      $args[0] = eval $args[0] if $_ eq 'fail';
      $self->$sub(@args);
    }
  };
}

# ... then sprinkle it on the protocol.

# Lots of ways to not be found
sub _build_on_not_found {
  _makesub_multi(
    ( map { my $verb = $_ =~ s/-job//r;
      my $message; # Isn't English fun?
           if ($_ eq 'bury')  { $verb = 'buried';
      } elsif ($_ =~ /e$/)    { $verb = $_ . 'd';
      } elsif ($_ =~ /[kh]$/) { $verb = $_ .'ed';
      } elsif ($_ eq 'stats') {                             $message = "Statistics were not found for the job: \$datum not found";
      }               $_          => [ fail => 'beanstalk-job'      => $message // "The job could not be $verb: \$datum not found" ];
    } qw(bury delete touch kick-job release stats-job) ),
                      peek        => [ fail => 'beanstalk-peek'     => "The job could not be peeked at: \$datum not found" ],
    ( map { my $adj = $_ =~ s/peek-//r; $_=> [ 'beanstalk-peek'     => "The next $adj job could not be peeked at: None found" ],
    } qw(peek-buried peek-delayed peek-ready) ),
                     'pause-tube' => [ fail => 'beanstalk-tube'     => "The tube could not be paused: \$datum not found" ],
                     'stats-tube' => [ fail => 'beanstalk-tube'     => "Statistics were not found for the tube: \$datum not found" ],
) }

# Two other responses from multiple commands
sub _build_on_buried { _makesub_multi(
                      bury        => ['finish' ],
                      put         => [ fail => 'beanstalk-put'      => "Job was inserted but buried (out of memory): ID \$datum" ],
                      release     => [ fail => 'beanstalk-job'      => "The job could not be released (out of memory): ID \$datum" ],
) }
sub _build_on_kicked { _makesub_multi(
                      kick      => [ finish_with => [0] ],
                     'kick-job' => ['finish_with' ],
) }

# 4 hard errors
# This module sent something badly-formed
sub _build_on_bad_format      { _makesub_hard ('beanstalk-internal' => "Protocol error: Bad format",       STATE_SEND) }
# The server sent something unexpected.
sub _build_on_invalid_response{ _makesub_error('beanstalk-server'   => "Protocol error: Unknown response", STATE_RECEIVE) }
# This should never happen; perhaps a version mismatch?
sub _build_on_unknown_command { _makesub_hard ('beanstalk-internal' => "Protocol error: Unknown command",  STATE_COMMAND) }
# Something broke
sub _build_on_internal_error  { _makesub_error('beanstalk-server'   => "Protocol error: Internal error",   0) }

# Everything else is boring

sub _build_on_deadline_soon   { _makesub_fail ('beanstalk-reserve'  => "No job was reserved: Deadline soon") }
sub _build_on_deleted         { _makesub_done_datum() }
sub _build_on_draining        { _makesub_fail ('beanstalk-put'      => "Job was not inserted: Server is draining") }
sub _build_on_expected_crlf   { _makesub_fail ('beanstalk-put'      => "Protocol error: Expected cr+lf") }
sub _build_on_found           { _makesub_wantmoar('FOUND') }
sub _build_on_found_final     { _makesub_done_datum() }
sub _build_on_inserted        { _makesub_done() }
sub _build_on_job_too_big     { _makesub_fail ('beanstalk-put'      => "Invalid job: too big") }
sub _build_on_not_ignored     { _makesub_fail ('beanstalk-tube'     => "The last tube cannot be ignored: \$datum") }
sub _build_on_ok              { _makesub_wantmoar('OK') }
sub _build_on_out_of_memory   { _makesub_fail ('beanstalk-server'   => "Protocol error: Out of memory") }
sub _build_on_paused          { _makesub_done_datum() }
sub _build_on_released        { _makesub_done_datum() }
sub _build_on_reserved        { _makesub_wantmoar('RESERVED') }
sub _build_on_reserved_final  { _makesub_done() }
sub _build_on_timed_out       { _makesub_fail ('beanstalk-reserve'  => "No job was reserved: Timed out") }
sub _build_on_touched         { _makesub_done_datum() }

1;
