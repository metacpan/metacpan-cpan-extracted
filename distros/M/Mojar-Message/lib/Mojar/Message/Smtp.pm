package Mojar::Message::Smtp;
use Mojo::Base -base;

our $VERSION = 0.031;

use Carp ();
use MIME::Entity;
use Mojar::Cron::Util 'tz_offset';
use Mojar::Log;
use POSIX 'strftime';

require Mojar::Util;

# Attributes

# Protocol
has ssl => 0;
has host => '127.0.0.1';
has port => sub { shift->ssl ? 465 : 25 };
has [qw(user secret agent)];  # SASL username, password
has domain => 'localhost.localdomain';  # for helo handshake
has timeout => 120;
has debug => 1;
has date_pattern => '%a, %d %b %Y %H:%M:%S';

# Message
has From => sub { ($ENV{USER} // $ENV{USERNAME} // '_') .'@'. shift->domain };
has [qw(To Cc Bcc attachments)];
has [qw(Subject body)] => '';

sub headers {  # virtual attribute
  my $self = shift;
  return $self->set(@_) if @_;
  map +($_ => $self->{$_}), grep +(/^[A-Z]/), keys %$self  # Titlecase fields
}
sub param {  # virtual attribute
  my $self = shift;
  return $self->set(@_) if @_;
  return (
    Host => $self->agent // $self->host,
    Port => $self->port,
    Hello => $self->domain,
    Debug => $self->debug,
    Timeout => $self->timeout
  );
}

has log => sub { Mojar::Log->new };

# Public methods

sub attach {
  my ($self, %param) = @_;
  my $fail = sub { $self->fail('Failed to attach', @_) };
  %param = (
    Disposition => 'attachment',
    Encoding => '-SUGGEST',
    %param  # override defaults
  );
  if (exists $param{Path} and my $file = $param{Path}) {
    $fail->('Failed to find attachment') unless -f $file or -l $file;
    $fail->('Failed to read attachment') unless -r $file;
  }
  push @{ $self->{attachments} //= [] }, \%param;

  return $self;
}

sub set {
  my ($self, %param) = @_;
  %$self = (%$self, %param);
  return $self;
}

sub reset {
  my $self = shift;
  delete @$self{ grep +(/^[A-Z]/), keys %$self };  # Titlecase fields
  delete @$self{'body', 'attachments'};
  return $self;
}

sub connect {
  my ($self, %param) = @_;
  my $fail = sub { $self->fail('Failed to connect', @_) };

#TODO: consider testing/reusing existing agent
  $self->disconnect if $self->agent;

  my $class = $self->ssl ? 'Net::SMTP::SSL' : 'Net::SMTP';
  (my $file = $class) =~ s{::}{/}g;
  require "${file}.pm" or $fail->("Failed to load $class", $!);
  my $agent = $class->new($self->param(%param))
    or $self->fail('Connection rejected', $!);

  if ($self->user) {
    $fail->('Missing required auth secret') unless defined $self->secret;
    unless ($agent->auth($self->user, $self->secret)) {
      my $msg = $agent->message // '';
      $fail->('Missing MIME::Base64 (AUTH)') if $msg =~ /MIME::Base64/;
      $fail->('Missing Authen::SASL (AUTH)') if $msg =~ /Authen::SASL/;
      $fail->("Failed authentication\n$!\n$msg");
    }
  }
  return $self->agent($agent);
}

sub disconnect {
  my ($self, %param) = @_;
  $self->agent->quit if $self->agent;
  delete $self->{agent};
  return $self;
}

sub send {
  my ($self, %param) = @_;
  my $fail = sub { $self->fail('Failed to send', @_) };

  $self->{Date} = $self->date;
  $self->{Sender} //= $self->{From};
  $self->{'X-Mailer'} //= "Mojar::Message::Smtp/$VERSION";

  my $mime;
  if ($self->attachments) {
    $mime = MIME::Entity->build(
      Type => 'multipart/mixed',
      $self->headers
    );
    $mime->attach(
      Type => 'text/plain',
      Disposition => 'inline',
      Encoding => '-SUGGEST',
      Data => $self->body
    );
    $mime->attach(%$_) for @{$self->attachments};
  }
  else {
    $mime = MIME::Entity->build(
      Type => 'text/plain',
      Disposition => 'inline',
      Encoding => '-SUGGEST',
      $self->headers,
      Data => $self->body
    );
  }

  my @sent = $mime->smtpsend($self->param, MailFrom => $self->From, %param);
  $self->log->info(sprintf 'Sent email to %s', join q{,}, @sent);
  return $self;
}

sub date { strftime($_[0]->date_pattern, localtime) .' '. tz_offset }

sub fail {
  my $self = shift;
  $self->log->error($_) for @_;
  Carp::croak(join("\n", @_) ."\n");
}

1;
__END__

=head1 NAME

Mojar::Message::Smtp - Lightweight email sender.

=head1 SYNOPSIS

  use Mojar::Message::Smtp;
  my $email = Mojar::Message::Smtp->new(
    domain => 'example.com',
    log => $app_log
  );

  $email->To('myteam@example.com')
      ->From('manager@example.com')
      ->Subject(q{Team, is your inbox full?})
      ->body(q{Otherwise, consider this JPG your reward.})
      ->attach({Path => '/tmp/random.jpg',
          Encoding => 'base64',
          Type => 'image/jpeg'})
      ->send;
  $email->To('otherteam@example.com')->send;

=head1 DESCRIPTION

=head1 USAGE

Sends a plain email, possibly with attachments, via an SMTP mailserver.

There are two distinct ways of using this module.  The common simple way is to
just let connections be handled implicitly.  The second way is to connect and
disconnect explicitly.

=head2 Implicit Connections

  Mojar::Message::Smtp->new(domain => 'example.com', log => ...)
      ->From('me@example.com')
      ->To(['someone@example.com', 'shadow@example.com'])
      ->Subject('Using an open mailserver without SSL')
      ->body('This is a common situation and the easiest to navigate.')
      ->send;

=head2 Explicit Connections

If you want to use SSL you will need to have L<Net::SMTP::SSL> installed and you
then call C<connect> and C<disconnect> explicitly.  Explicit connections also
suit people who want to use the C<Timeout> attribute or want to hold a
connection open across multiple emails.

  Mojar::Message::Smtp->new(ssl => 1, domain => 'example.com', log => ...)
      ->host('secure.mail.server')
      ->From('me@example.com')
      ->To('someone@example.com')
      ->Subject('Using a secure mailserver over SSL')
      ->body('This is growing in popularity and is not difficult at all.')
      ->timeout(300)
      ->connect
      ->send
      ->To('someone.else@example.com')
      ->Subject('Balancing bananas on your head')
      ->send
      ->disconnect;

=head1 ATTRIBUTES

=over 4

=item log

A L<Mojo::Log> compatible logger, eg L<Mojar::Log>.

  $email->log($logger);
  $email->log->debug('Making progress');

=item debug

Whether to show debug information.  Defaults to false.

  $email->debug(1)->send;

=item ssl

Whether to use SSL.  Defaults to false.

  $email->ssl(1);
  say $email->ssl ? 'secure' : 'insecure';

=item timeout

The SMTP connection timeout in seconds.  This attribute only takes effect if you
call C<connect> explicitly.  Defaults to 120 seconds.

  $email->timeout(120)->connect;
  $current_timeout = $email->timeout;

=item domain

The domain the client is connecting from.

  $email->domain('my.domain');

=item host

The SMTP host address to connect to.  Defaults to '127.0.0.1' (localhost).

  $email->host('my.mail.server');
  $email->host('192.168.0.2');
  $email->log->debug("Using host $(\ $email->host )");

=item port

The SMTP port to connect to on the host.  Defaults to 25 for standard and 465
for SSL.

  $email->port(3025);
  $email->log->debug("Using port $(\ $email->port )");

=item user

The username for authentication; only effective if C<connect> is called
explicitly.

  $email->user('hax3r')->connect->send->disconnect;

=item secret

The password for authentication; only effective if C<user> is set.

  $email->user('hax3r')->secret('s3crt')->connect->send->disconnect;

=item From

The sender address.

=item To

The recipient address(es).

  $email->To('single@example.com');
  $email->To(['first@example.com', 'second@example.com']);

=item Cc

The carbon copy recipient address(es); similar to C<To>.

=item Bcc

The blind carbon copy recipient address(es); similar to C<To>.

=item body

The text body of the email.

  $email->body('Some text');

=back

=head1 METHODS

=over 4

=item new

  $email = Mojar::Message::Smtp->new(domain => ..., ...);

Constructor for the email, accepting all attributes listed above.

=item attach

  $email->attach({
    Path => 'vi/NpBT78YQOms/maxresdefault.jpg',
    Type => 'image/jpeg',
    Encoding => 'base64'
  });

Configures an attachment.  This can be chained:

  $email->attach({Path => 'a.jpg'})->attach({Path => 'b.jpg'});

See L<MIME::Entity> for notes on the available parameters.

Note that attaching happens at send-time, so if the file might change before
then, you should consider copying the file to a temporary static location and
attaching from there.

=item send

  $email->send;

Sends an SMTP message.  Can be passed call-specific overriding parameters.

  $email->send(host => q{mailserver2});

=item other methods

See the source code for other methods you can override when subclassing this.

=back

=head1 SUPPORT

See L<Mojar>.

=head1 SEE ALSO

L<MIME::Entity>, L<Mail::Internet>.
