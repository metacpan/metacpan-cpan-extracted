package Net::Async::Beanstalk::Send;

our $VERSION = '0.001';
$VERSION = eval $VERSION;

=head1 NAME

Net::Async::Beanstalk::Send - Methods to send commands to beanstalk

=head1 DOCUMENTED ELSEWHERE

This module's external API is documented in L<Net::Async::Beanstalk>

=cut

use Moo::Role;
use strictures 2;

use Carp;
use Net::Async::Beanstalk::Constant qw(:send :state);
use namespace::clean;

# TODO: Document internal API

sub _next {
  my $self = shift;
  return unless $self->count_commands >= 1;
  my @current = @{ $self->current_command };
  my $buf = join ' ', @current[STATE_COMMAND..$#current];
  $self->adopt_future($self->write($buf . $NL));
}

# TODO: Warn if reserves are pending
# TODO: Don't send if not connected
sub _send {
  my $self = shift;
  my ($cmd) = @_;
  croak "Invalid command" unless exists $COMMAND{$cmd};
  my $future = $self->loop->new_future;
  $future->on_ready(sub { $self->_next });
  $self->_push_command([ $future, undef, @_ ]);
  $self->_next if $self->count_commands == 1;
  defined wantarray ? $future : $future->get;
}

sub put {
  my $self = shift;
  my $job;
  if (@_ % 2) {
    $job = shift;
    $job = $self->encoder->($job) if ref $job and not overload::Method($job, '""');
  }
  my %opt = @_;
  my @args = (
    delete $opt{priority} || $self->default_priority,
    delete $opt{delay}    || $self->default_delay,
    delete $opt{ttr}      || $self->default_ttr,
  );
  $job //= delete $opt{raw_data} // $self->encoder->(delete $opt{data});
  croak 'Too much job data' if exists $opt{raw_data} or exists $opt{data};
  croak 'Unknown options to "put": ' . join ', ', sort keys %opt if scalar keys %opt;

  my $data = '' . $job;
  utf8::encode($data) if utf8::is_utf8($data);
  $self->_send(put => (map int, @args), length($data) . $NL . $data);
}

# TODO: raw/decode on other job-fetching commans
sub reserve {
  my $self = shift;
  my %opt = @_;
  my $no_decode = delete $opt{asis};
  my $as_raw = delete $opt{raw};
  # TODO: Warn about illogical combinations?
  my $timeout = delete $opt{timeout};
  croak 'Unknown options to "reserve": ' . join ', ', sort keys %opt if scalar keys %opt;

  my @command = defined $timeout ? ('reserve-with-timeout', $timeout) : ('reserve');
  return $self->_send(@command) if $as_raw;
  $self->_send(@command)->then(sub {
    utf8::decode($_[1]);
    Future->done($no_decode ? @_ : ($_[0], $self->decoder->($_[1])));
  });
}

sub reserve_with_timeout { $_[0]->reserve(timeout => $_[1], @_[2..$#_]) }

for my $command (keys %COMMAND) {
  no strict 'refs';
  my $sub = $command =~ s/-/_/gr;
  next if __PACKAGE__->can($sub);
  *$sub = sub { $_[0]->_send($command => @_[1..$#_]) };
}

1;
