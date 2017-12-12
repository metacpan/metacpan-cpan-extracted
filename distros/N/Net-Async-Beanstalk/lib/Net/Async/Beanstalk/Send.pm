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
  my $current = $self->current_command;
  $current->[STATE_SEND] = join(' ', @$current[STATE_COMMAND..$#$current]) . $NL;
  $self->adopt_future($self->write($current->[STATE_SEND]));
}

# TODO: Warn if reserves are pending
# TODO: Don't send if not connected
sub _send {
  my $self = shift;
  my ($cmd) = @_;
  croak "Invalid command" unless exists $COMMAND{$cmd};
  my $future = $self->loop->new_future;
  $future->on_ready(sub { $self->_next });
  $self->_push_command([ $future, (undef) x (STATE_COMMAND - 1), @_ ]);
  $self->_next if $self->count_commands == 1;
  defined wantarray ? $future : $future->get;
}

around decoder => sub {
  my $orig = shift;
  my $self = shift;
  my ($no_decode) = @_;
  my $decoder = $self->$orig();
  sub {
    my $utf8 = ''.$_[0];
    utf8::decode($utf8);
    $no_decode ? $utf8 : $decoder->($utf8);
  };
};

around encoder => sub {
  my $orig = shift;
  my $self = shift;
  my $encoder = $self->$orig();
  sub {
    my $result = '' . ((not ref $_[0] or overload::Method($_[0], '""'))
                         ? $_[0]
                         : $encoder->(@_));
    utf8::encode($result) if utf8::is_utf8($result);
    $result;
  };
};

sub put {
  my $self = shift;
  my $job; $job = $self->encoder->(shift) if @_ % 2;
  my %opt = @_;

  my @args = (
    delete $opt{priority} || $self->default_priority,
    delete $opt{delay}    || $self->default_delay,
    delete $opt{ttr}      || $self->default_ttr,
  );
  $job //= delete $opt{raw_data} // $self->encoder->(delete $opt{data});
  croak 'Too much job data' if exists $opt{raw_data} or exists $opt{data};
  croak 'Unknown options to "put": ' . join ', ', sort keys %opt if scalar keys %opt;
  $self->_send(put => (map int, @args), length($job) . $NL . $job);
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
    Future->done($_[0], $self->decoder($no_decode)->($_[1]), @_[2..$#_]);
  });
}

sub reserve_with_timeout { $_[0]->reserve(timeout => $_[1], @_[2..$#_]) }

# TODO: Make void context useful
for my $command (keys %COMMAND) {
  no strict 'refs';
  my $sub = $command =~ s/-/_/gr;
  next if __PACKAGE__->can($sub);
  *$sub = sub { $_[0]->_send($command => @_[1..$#_]) };
}

1;
