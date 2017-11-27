package Net::Async::Beanstalk::Receive;

our $VERSION = '0.001';
$VERSION = eval $VERSION;

=head1 NAME

Net::Async::Beanstalk::Receive - Methods to handle responses from beanstalk

=head1 DOCUMENTED ELSEWHERE

This module's external API is documented in L<Net::Async::Beanstalk>

=cut

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

sub _want_data {
  my $self = shift;
  my $size = pop;
  $self->current_command->[STATE_MOAR] = [join(' ', @_), $size];
}

sub _build_on_read {sub{
  my $self = shift;
  my ($buf, $eof) = @_;
  my $data;

  my $state = $self->current_command;
  if (ref $state and $state->[STATE_MOAR]) {
    my ($had, $size) = @{ $state->[STATE_MOAR] };
    return 0 unless $$buf =~ s/^(.{$size})$NL//s;
    $data = $1;
    $buf = $had;

  } else {
    # prot.c defines NAME_CHARS as alphanum & -+/;.$_()
    return 0 unless $$buf =~ s{^([A-Za-z0-9+/;.\$_() -]+)$NL}{};
    $buf = $1;
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
}}

sub _build_on_bad_format {sub{
  my $self = shift;
  my $state = $self->current_command;
  $self->error_command(invalid => "Protocol error: Bad format",
		       @$state[STATE_COMMAND..$#$state]);
}}

sub _build_on_buried {sub{
  my $self = shift;
  my $state = $self->current_command;
  if ($state->[STATE_COMMAND] eq 'bury') {
    $self->finish_command(on_job_bury => $state->[STATE_DATUM]);
  } elsif ($state->[STATE_COMMAND] eq 'put') {
    my ($id) = @_; # Assert $id == $state->[STATE_DATUM] ?
    $self->fail_command(on_job_insert_fail => 'insert-bury' => $state->[STATE_DATUM]);
  } elsif ($state->[STATE_COMMAND] eq 'release') {
    # ie. Server ran out of memory trying to release; job is still buried.
    $self->fail_command(on_job_release_fail => 'release-bury' => $state->[STATE_DATUM]);
  }
}}

sub _build_on_deadline_soon {sub{
  my $self = shift;
  # In response to reserve and reserve-with-timeout
  # Does it matter which?
  my $state = $self->current_command;
  $self->fail_command(on_ttr_soon => 'insert-ttr-soon' => $state->[STATE_DATUM]);
}}

sub _build_on_deleted {sub{
  my $self = shift;
  my $state = $self->current_command;
  $self->finish_command(on_job_delete => $state->[STATE_DATUM]);
}}

sub _build_on_draining {sub{
  my $self = shift;
  my $state = $self->current_command;
  $self->fail_command(on_draining => 'insert-draining' => $state->[STATE_DATUM]);
}}

sub _build_on_expected_crlf {sub{
  my $self = shift;
  my $state = $self->current_command;
  $self->error_command(invalid => "Protocol error: Expected cr+lf",
		       @$state[STATE_COMMAND..$#$state]);
}}

sub _build_on_found {sub{
  my $self = shift;
  $self->_want_data(FOUND => @_);
}}

sub _build_on_found_final {sub{
  my $self = shift;
  my ($id, $data) = @_;
  my $state = $self->current_command;
  my $source = $state->[STATE_COMMAND] =~ s/-/_/gr;
  $source =~ s/buried/bury/;
  $self->finish_command("on_job_$source" => $id, $data);
}}

sub _build_on_inserted {sub{
  my $self = shift;
  my ($id) = @_; # Assert $id == $state->[STATE_DATUM] ?
  $self->finish_command(on_job_insert => $id);
}}

sub _build_on_internal_error {sub{
  my $self = shift;
  my $state = $self->current_command;
  $self->error_command('server-error' => "Protocol error: Internal error",
		       @$state[STATE_COMMAND..$#$state]);
}}

sub _build_on_invalid_response {sub{
  my $self = shift;
  my $state = $self->current_command;
  $self->error_command(unknown => "Protocol error: Unknown response",
		       @$state[STATE_COMMAND..$#$state]);
}}

sub _build_on_job_too_big {sub{
  my $self = shift;
  my $state = $self->current_command;
  $self->error_command(invalid => "Protocol error: Job too big",
		       @$state[STATE_COMMAND..$#$state]);
}}

sub _build_on_kicked {sub{
  my $self = shift;
  my $state = $self->current_command;
  if ($state->[STATE_COMMAND] eq 'kick') {
    my ($count) = @_;
    $self->finish_command(on_tube_kick => $state->[STATE_DATUM], $count);
  } elsif ($state->[STATE_COMMAND] eq 'kick-job') {
    $self->finish_command(on_job_kick => $state->[STATE_DATUM]);
  }
}}

sub _build_on_not_found {sub{
  my $self = shift;
  my $state = $self->current_command;

  my $source = $state->[STATE_COMMAND];
  if (any { $source eq $_ } qw(bury delete touch kick-job release stats-job)
	or $source =~ /^peek(-buried|-delayed|-ready)?$/) {
    $source =~ s/-job//r =~ tr/-/_/r;
    $self->fail_command("on_job_${source}_not_found",
			'job-not-found' => $state->[STATE_DATUM]);

  } elsif ($source =~ /^(pause|stats)-tube$/) {
    $self->fail_command("on_tube_${1}_not_found",
			'tube-not-found' => $state->[STATE_DATUM]);
  }
}}

sub _build_on_not_ignored {sub{
  my $self = shift;
  $self->fail_command(on_tube_ignore_fail =>
		      'ignore-fail' => $self->_state->[STATE_DATUM]);
}}

sub _build_on_ok {sub{
  my $self = shift;
  $self->_want_data(OK => @_);
}}

sub _build_on_ok_final {sub{
  my $self = shift;
  my ($data) = @_;
  my $state = $self->current_command;
  my $source = $state->[STATE_COMMAND] =~ s/-/_/gr;
  $source = 'server_stats' if $source eq 'stats';
  my $decoded = Load($data);
  my @decoded = ref $decoded eq 'ARRAY' ? @$decoded : %$decoded;
  # Assert \@decoded {=} $self->watching if $source eq 'list-tubes-watched' ?
  $self->finish_command("on_$source" => @decoded);
}}

sub _build_on_out_of_memory {sub{
  my $self = shift;
  my $state = $self->current_command;
  $self->error_command('server-error' => "Protocol error: Out of memory",
		       @$state[STATE_COMMAND..$#$state]);
}}

sub _build_on_paused {sub{
  my $self = shift;
  $self->finish_command(on_tube_pause => $self->_state->[STATE_DATUM]);
}}

sub _build_on_released {sub{
  my $self = shift;
  my $state = $self->current_command;
  $self->finish_command(on_job_release => $state->[STATE_DATUM]);
}}

sub _build_on_reserved {sub{
  my $self = shift;
  $self->_want_data(RESERVED => @_);
}}

sub _build_on_reserved_final {sub{
  my $self = shift;
  my ($id, $data) = @_;
  $self->finish_command(on_job_reserve => $id, $data);
}}

sub _build_on_timed_out {sub{
  my $self = shift;
  my $state = $self->current_command;
  $self->fail_command(on_time_out =>
		      'reserve-time-out' => $state->[STATE_DATUM]);
}}

sub _build_on_touched {sub{
  my $self = shift;
  my $state = $self->current_command;
  $self->finish_command(on_job_touch => $state->[STATE_DATUM]);
}}

sub _build_on_unknown_command {sub{
  my $self = shift;
  my $state = $self->current_command;
  $self->error_command(invalid => "Protocol error: Unknown command",
		       @$state[STATE_COMMAND..$#$state]);
}}

sub _build_on_using {sub{
  my $self = shift;
  my $state = $self->current_command;
  my ($tube) = @_;
  if ($state->[STATE_COMMAND] eq 'list-tube-used') {
    # Assert $tube eq $self->using ?
    $self->finish_command(on_list_use => $tube);
  } elsif ($state->[STATE_COMMAND] eq 'use') {
    $self->_set_using($tube);
    $self->finish_command(on_tube_use => $tube);
  }
}}

sub _build_on_watching {sub{
  my $self = shift;
  my $state = $self->current_command;
  my $tube = $state->[STATE_DATUM];
  my ($count) = @_;
  if ($state->[STATE_COMMAND] eq 'ignore') {
    delete $self->_watching->{$tube};
    $self->finish_command(on_tube_ignore => $tube, $count);
  } elsif ($state->[STATE_COMMAND] eq 'watch') {
    $self->_watching->{$tube} = 1;
    $self->finish_command(on_tube_watch => $tube, $count);
  }
}}

1;
