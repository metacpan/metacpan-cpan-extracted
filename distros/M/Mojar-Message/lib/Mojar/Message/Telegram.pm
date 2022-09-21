package Mojar::Message::Telegram;
use Mojo::Base -base;

use Carp qw(croak);
use Mojo::URL;
use Mojo::UserAgent;
use Mojo::Util qw(dumper);

our $VERSION = 0.021;

# Attributes

has address => 'api.telegram.org';
has scheme  => 'https';
has 'token';
has ua => sub { Mojo::UserAgent->new };

has in  => sub { [] };
has out => sub { [] };

# Public methods

sub send {
  my $self = shift;
  my $cb = @_ && ref $_[-1] eq 'CODE' ? pop : undef;

  my %args = @_ % 2 == 0 ? @_
    : ref $_[0] eq 'HASH' ? %{$_[0]}
    : croak 'Bad args';

  my @param = (
    chat_id              => $args{recipient},
    disable_notification => $args{quiet},
    text                 => $args{message},
  );
  push @param, $cb if $cb;

  return $self->submit(sendMessage => @param);
}

sub submit {
  my ($self, $method) = (shift, shift);
  my $cb = @_ && ref $_[-1] eq 'CODE' ? pop : undef;
  my %payload = @_;

  my $url = Mojo::URL->new->scheme($self->scheme)
    ->host($self->address)
    ->path(sprintf 'bot%s/%s', $self->token, $method);

  my $ua = $self->ua;
  my $headers = {};
  my $tx = $ua->build_tx('POST', $url, $headers, json => \%payload);

  # blocking
  unless ($cb) {
    $tx = $ua->start($tx);
    if (my $err = $tx->error) {
      return $err;
    }
    die "Failed to send message\n" unless $tx->res->json->{ok};
    return $self;
  }

  # non-blocking
  $ua->start($tx, sub {
    my ($ua, $tx_) = @_;
    my ($err, $json);
    $json = $tx_->res->json unless $err = $tx_->error;
    ($err //= {})->{message} ||= 'Failed to send message'
      unless $tx->res->json->{ok};
    Mojo::IOLoop->next_tick(sub { $self->$cb($err, $json, $tx_) });
  });
  return $self;
}

1;
__END__

=head1 NAME

Mojar::Message::Telegram - Send messages via Telegram.

=head1 SYNOPSIS

  use Mojar::Message::Telegram;
  my $msg = Mojar::Message::Telegram->new(message => ..., recipient => ...);

  # Synchronous
  $msg->send(
    message   => q{Don't you love the bot API? \N{U+2714} },
    recipient => '111222333',
  );

  # Asynchronous
  my @error;
  $sms->send(
    message   => q{Fire and forget; with a reminder},
    recipient => '111222333',
    sub { $error[0] = $_[1] }
  );

=head1 DESCRIPTION

Sends simple messages via Telegram.  You need to know the C<chat_id> of each
recipient, and they must have initiated some interaction with your bot
beforehand.

=head1 ATTRIBUTES

=over 2

=item * address

  $msg->address;  # defaults to api.telegram.org
  $msg->address('somewhere.web.telegram.org');

=item * token

  $msg->token('123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11');

=item * ua

  $msg->ua($this_agent);
  my $ua = $msg->ua;

The user agent persists in an attribute of the object and you can supply your
own at creation time.

=back

=head1 METHODS

=over 2

=item new

  $msg = Mojar::Message::Telegram->new(token => ...);

Constructor for the Telegram agent.

=item send

  $msg->send(message => q{...}, recipient => $recipient);

Supports method chaining, and will bail-out at the first failure if no callback
is given.
Supports asynchronous calls when provided a callback as the final argument.

  $msg->send(message => q{...}, recipient => ..., sub {
    my ($agent, $error) = @_;
    ...
  });

  $sms->send(message => $m, recipient => $r, sub { ++$error_count if $_[1] });

You can also send messages without triggering a notification by including the
C<quiet => 1> parameter.

=back

=head1 REFERENCE

L<https://core.telegram.org/bots/api> shows the Bot API.

=head1 CONFIGURATION AND ENVIRONMENT

You need to create an account following L<https://core.telegram.org/bots>.

=head1 SUPPORT

See L<Mojar>.

=head1 SEE ALSO

L<WWW::Telegram::BotAPI>.
