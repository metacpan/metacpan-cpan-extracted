package Net::Gnats::Session;
use v5.10.00;
use strictures;
BEGIN {
  $Net::Gnats::Session::VERSION = '0.22';
}
use vars qw($VERSION);

use Net::Gnats qw(verbose_level);
use IO::Socket::INET;
use Net::Gnats::Command qw(user quit);
use Net::Gnats::Constants qw(LF CODE_GREETING CODE_PR_READY CODE_SEND_PR CODE_SEND_TEXT CODE_SEND_CHANGE_REASON CODE_INFORMATION);
use Net::Gnats::Schema;

$| = 1;

=head1 NAME

Net::Gnats::Session

=head1 DESCRIPTION

Represents a specific connection to Gnats.

When constructing a new session, it resets $Net::Gnats::current_session.

=cut

sub new {
  my ($class, %o ) = @_;
  my ($self);
  $self = bless {}, $class if not %o;
  $self = bless \%o, $class;

  #set the current session to Net::Gnats so we can ref it throughout
  Net::Gnats->current_session($self);

  return $self;
}

=head1 ACCESSORS

=head2 name

The name is a combination of database and username, a friendly handle.

It does not mean anything to GNATS.

=cut

sub name {
  my $self = shift;
  return $self->hostname . '-' . $self->username;
}


=head2 access

Retrieves the access for the current database.

=cut

sub access { shift->{access}; }

=head2 database

Sets and retrieves the current database.  If a value is given then
a change to the given database is made.

=cut

sub database {
  my ($self, $value) = @_;
  $self->{database} = 'default' if not defined $self->{database};
  if ( defined $value ) {
    return $self->{database} if $self->{database} eq $value;
    $self->{database} = $value if
      $self->issue(Net::Gnats::Command->chdb( database => $value))
      ->is_ok;

    # initialize schema for changed database
    $self->{schema} = Net::Gnats::Schema->new($self);
  }
  return $self->{database};
}

=head2 hostname

The hostname of the Gnats daemon process.

Default: localhost

=cut

sub hostname {
  my ( $self, $value ) = @_;
  $self->{hostname} = $value if defined $value;
  $self->{hostname} = 'localhost' if not defined $self->{hostname};
  $self->{hostname};
}

sub is_authenticated {
  my ( $self ) = @_;
  $self->{authenticated} = 0 if not defined $self->{authenticated};
  $self->{authenticated};
}

sub is_connected {
  my ( $self ) = @_;
  $self->{connected} = 0 if not defined $self->{connected};
  $self->{connected};
}



=head2 password

The password for the user connecting to the Gnats daemon process.

Most commands require authentication.

=cut

sub password {
  my ( $self, $value ) = @_;
  $self->{password} = $value if defined $value;
  $self->{password};
}

=head2 port

The port of the Gnats daemon process.

Default: 1529

=cut

sub port {
  my ( $self, $value ) = @_;
  $self->{port} = $value if defined $value;
  $self->{port} = 1529 if not defined $self->{port};
  $self->{port};
}

=head2 schema

Get the schema for this session.  Readonly.

=cut

sub schema { shift->{schema} }

=head2 skip_version

Set skip_version to override Gnats version checking. By default,
Net::Gnats supports v4 only.

You use this at your own risk.

=cut

sub skip_version {
  my ($self, $value) = @_;
  $self->{skip_version} = 0 if not defined $self->{skip_version};
  $self->{skip_version} = $value if defined $value;
  $self->{skip_version};
}

=head2 username

The user connecting to the Gnats daemon process.

Most commands require authentication.

=cut

sub username {
  my ( $self, $value ) = @_;
  $self->{username} = $value if defined $value;
  $self->{username};
}

=head2 version

The Gnats daemon process version.  The version will only be set after connecting.

=cut

sub version { return shift->{version} }

=head1 METHODS


=head2 authenticate

Return:

0 if failue
1 if success

=cut

sub authenticate {
  my ( $self ) = @_;
  my ($c);

  $c = $self->issue(Net::Gnats::Command->user( username => $self->username,
                                               password => $self->password ));
  $self->{authenticated} = $c->is_ok;
  return $self if not $c->is_ok;

  $self->{schema} = Net::Gnats::Schema->new($self) if not defined $self->schema;

  _trace('AUTH: ' . $c->is_ok);

  $c->is_ok;
}

=head2 gconnect

Connects to Gnats.  If the username and password is set, it will
attempt authentication.

Connecting an already connected session infers reconnect.

=cut

sub gconnect {
  my ( $self ) = @_;
  my ( $sock, $iaddr, $paddr, $proto );

  _trace ('disconnecting sock if it exists');
  $self->disconnect if defined $self->{gsock};

  _trace ('constructing socket');
  _trace ('host: ' . $self->hostname);
  _trace ('port: ' . $self->port);

  $self->{gsock} = IO::Socket::INET->new( PeerAddr => $self->hostname,
                                          PeerPort => $self->port,
                                          Proto    => 'tcp');

  return $self if not defined $self->{gsock};

  my $response = $self->_read;

  _trace('Connection response: ' . $response->as_string);

  return undef if not defined $response->code;
  return undef if $response->code != CODE_GREETING;

  _trace('Is Connected.');
  $self->{connected} = 1;

  # Grab the gnatsd version
  $self->gnatsd_version( $response->as_string );

  print "? Error: GNATS Daemon version $self->{version} at $self->{hostname} $self->{port} is not supported by Net::Gnats\n" if not $self->check_gnatsd_version;
  if ( not  $self->check_gnatsd_version ) {
    $self->issue(Net::Gnats::Command->quit);
    $self->{connected} = 0;
    return undef;
  }

  # issue USER to get current access level
  $self->{access} = $self->issue(Net::Gnats::Command->user)->level;

  $self->authenticate if defined $self->{username} and defined $self->{password};

  return $self if not $self->is_authenticated;

  return $self if $self->access eq 'none' or $self->access eq 'deny' or $self->access eq 'listdb';

  return $self;
}

=head2 disconnect

Disconnects from the current session, either authenticated or not.

=cut

sub disconnect {
  my ( $self ) = @_;
  $self->issue( Net::Gnats::Command->quit );
  $self->{connected} = 0;
  $self->{authenticated} = 0;
  $self->{schema} = undef;
}

=head2 issue

Issues a command using a Command object.  The Command object is
returned to the caller.

The Command object composes a Response, whose value(s) carry error
codes and the literal values retrived from Gnats.

=cut

sub issue {
  my ( $self, $command ) = @_;

  # if the command cannot be formed, the as_string method will return
  # undef.
  return $command if not defined $command->as_string;

  $command->response( $self->_run( $command->as_string ) );

  # In case we received the an undefined response code, return here.
  # This could happen when the network response gets broken.
  return $command if not defined $command->response->code;

  # Check CODE_SEND_TEXT or CODE_SEND_PR
  # This will be a field object value.
  if ($command->response->code == CODE_SEND_TEXT) {
    $command->response( $self->_run( $command->field->value . "\n." ) );
    $command->response( $self->_run( $command->field_change_reason->value . "\n." ))
      if $command->response->code == CODE_SEND_CHANGE_REASON;
  }
  # This will be a whole serialized PR.
  elsif ($command->response->code == CODE_SEND_PR) {
    $command->response( $self->_run( $command->pr->asString  . "\n." ) );
  }
  return $command;
}

=head2 run

Runs a RAW command using this session.  Returns RAW output.

=cut


# PRIVATE METHODS HERE - DO NOT EXPORT

sub gnatsd_version {
  my ($self, $value) = @_;
  if (defined $value) {
    $value =~ s/.*(\d+.\d+.\d+).*/$1/;
    $self->{version} = $1;
  }
  return $self->{version};
}

# "legally" use v4 daemon only
sub check_gnatsd_version {
  my ($self) = @_;
  my $rmajor = 4;
  my $min_minor = 1;
  return 1 if $self->skip_version;

  my ($majorv, $minorv, $patchv) = split /\./, $self->version;

  return 0 if $majorv != $rmajor;
  return 0 if $minorv < $min_minor;
  return 1;
}


sub _run {
  my ( $self, $cmd ) = @_;

  #$self->_clear_error();

  _trace('SENDING: [' . $cmd . ']');

  $self->{gsock}->print( $cmd . LF );

  return $self->_read;
}

sub _read {
  my ( $self ) = @_;
  my $response = Net::Gnats::Response->new(type => 0);

  until ( $response->is_finished == 1 ) {
    my $line = $self->_read_clean($self->{gsock}->getline);

    # We didn't get anyting from the socket, it could mean a broken
    # connection or malformed response.
    last if not defined $line;

    # Process the line normally.
    $response->raw( $line );
    _trace('RECV: [' . $line . ']');
  }
  return $response;
}

sub _read_clean {
  my ( $self, $line ) = @_;
  if ( not defined $line ) { return; }

  $line =~ s/\r|\n//gsm;
#  $line =~ s/^[.][.]/./gsm;
  return $line;
}

sub _read_decompose {
  my ( $self, $raw ) = @_;
  my @result = $raw =~ /^(\d\d\d)([- ]?)(.*$)/sxm;
  return \@result;
}

sub _trace {
  my ( $message ) = @_;
  return if Net::Gnats->verbose_level() != 3;
  print 'TRACE: [' . $message . ']' . LF;
  return;
}

1;
