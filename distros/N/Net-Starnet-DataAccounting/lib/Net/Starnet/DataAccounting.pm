package Net::Starnet::DataAccounting;

=head1 NAME

Net::Starnet::DataAccounting - interface to the SDA protocol

=head1 SYNOPSIS

    use constant SDA_UPDATE_TIME 60;
    my $sda = Net::Starnet::DataAccounting->new(
	user => $user,
	pass => $pass,
	verbose => $VERBOSE,
	login  => \&login,
	logout => \&logout,
	update => \&update,
	(defined($hostname) ? ( host => $hostname ) : ()),
	(defined($server) ? ( server => $server ) : ()),
    );
    my $connected = $sda->login();
    if ($connected)
    {
	$SIG{INT} = $SIG{TERM} = sub {
	    $sda->logout();
	    exit 0;
	};
	while ($connected)
	{
	    sleep SDA_UPDATE_TIME;
	    $connected = $sda->update();
	}
	my $disconnected = $sda->logout();
    }

=head1 DESCRIPTION

The Net::Starnet::DataAccounting module provides an interface to the
protocol used by the Starnet Data Accounting System. It allows simple
login, logout and health checking.

=cut

use 5.006001;
use strict;
use warnings;

use Carp;
use Socket;
use IO::Socket;
$|++;

use constant DEBUG => 0;
use constant SDA_HOST => '150.203.223.8:8000';

use constant SDA_LOGIN  => 1;
use constant SDA_LOGOUT => 2;
use constant SDA_UPDATE => 3;

use constant SDA_LOGIN_YES  => 1;
use constant SDA_LOGIN_NO  => 0;
use constant SDA_LOGIN_INCORRECT_USERPASS => 1;
use constant SDA_LOGIN_NO_QUOTA           => 3;
use constant SDA_LOGIN_ALREADY_CONNECTED  => 4;

use constant SDA_UPDATE_YES => 1;
use constant SDA_UPDATE_NO  => 0;

use constant SDA_UPDATE_TIME => 60;

our @ISA = qw//;
our ( $VERSION ) = '$Revision: 1.2 $ ' =~ /\$Revision:\s+([^\s]+)/;

my %defaults = (
    server	=> '150.203.223.8',
    port	=> '8000',
    client	=> "Spoon-v$VERSION",
);


# ========================================================================
#                                                                  Methods

=head1 METHODS

=over 4

=item Net::Starnet::DataAccounting->new(

    host    => $yourhostname,
    server  => $remotehostname,
    port    => $remoteport,
    user    => $username,
    pass    => $password,
    client  => $clientname,
    login   => \&login,
    logout  => \&logout,
    update  => \&update,
    verbose => $verbose,
    )

Creates a new SDA connection. Host and server should be either IPs or
hostnames. Port is a port number, user and pass are the appropriate
username and password. Client is a custom client string for the
connection to use.

Login, logout and update are routines that will be called after an
attempt to send the appropriate message. The routines in question will
be passed two parameters: the SDA object and the text response from the
server (decoded).

Verbose determines whether debugging information will be shown.

=cut

sub new
{
    my $class = shift;
    $class = ref($class) || $class;

    my %opts = @_;

    my $hostname;
    if (exists $opts{host})
    {
	$hostname = $opts{host};
    }
    else
    {
	$hostname = eval
	{
	    require Sys::Hostname;
	    Sys::Hostname::hostname();
	};
    }
    my $ip = gethostbyname($hostname) or die "Couldn't resolve $hostname.\n";
    $ip = join('.', unpack('C4', $ip));

    my $server = $opts{server} || $defaults{server};
    die "Invalid server name.\n" unless (defined $server and length $server);
    $server = gethostbyname($server) or die "Couldn't resolve $server.\n";
    $server = join('.', unpack('C4', $server));

    my $port = $opts{port} || $defaults{port};
    die "Invalid port number.\n" unless ($port < 65536 and $port > 0);
    
    die "Invalid username.\n" unless (defined $opts{user} and $opts{user} =~ /^\w+$/);
    die "Invalid password.\n" unless (defined $opts{pass} and $opts{pass} =~ /^\d+$/);

    my $self = bless {
	host	=> $ip,
	server	=> $server,
	port	=> $port,
	client  => $opts{client} || $defaults{client},
	login	=> $opts{login},
	logout	=> $opts{logout},
	update	=> $opts{update},
	user	=> $opts{user},
	pass	=> $opts{pass},
	verbose => $opts{verbose} ? 1 : 0,
    }, $class;


    return $self;
}

=item $sda->verbose($value|)

If given a parameter, sets the verbosity. Returns the verbosity in all
cases.

=cut

sub verbose
{
    my $self = shift;
    $self->{verbose} = $_[0] ? 1 : 0 if (@_);
    return $self->{verbose};
}

=item $sda->login()

Directs the SDA object to attempt to connect to the server. Calls the
login routine specified on construction after the attempt is made.

=cut

sub login
{
    my $self = shift;
    my $response = $self->_sda_send(SDA_LOGIN);
    $self->{login}($self,$response);
}

=item $sda->logout()

Directs the SDA object to attempt to disconnect to the server. Calls the
logout routine specified on construction after the attempt is made.

=cut

sub logout
{
    my $self = shift;
    my $response = $self->_sda_send(SDA_LOGOUT);
    $self->{logout}($self,$response);
}

=item $sda->update()

Directs the SDA object to attempt to update the client's status on the
server. Calls the update routine specified on construction after the
attempt is made. This function should be called every two minutes or so;
ideally more frequently.

=cut

sub update
{
    my $self = shift;
    my $response = $self->_sda_send(SDA_UPDATE);
    $self->{update}($self,$response);
}

=back

=cut

# ========================================================================
#                                                                  Private

=begin private

=head1 PRIVATE METHODS

=over 4

=cut

# ------------------------------------------------------------------------
#                                                         SDA Server stuff
# ------------------------------------------------------------------------

=item $sock = $sda->_sda_connect()

Connects to the object's server on the given port and returns the
socket.

=cut

sub _sda_connect
{
    my $self = shift;
    my ($host,$port) = @{$self}{qw/server port/};
    my $sock = IO::Socket::INET->new
	(
	 PeerAddr => $host,
	 PeerPort => $port,
	 Proto => 'tcp',
	 Type => SOCK_STREAM
	) or die "Couldn't connect to $host:$port: $@\n";

    return $sock;
}

=item $result = $sda->_sda_send(ACTION)

Where ACTION is one of SDA_UPDATE, SDA_LOGIN, SDA_LOGOUT.

Sends an appropriately encoded message to the server (does the
connection by calling _sda_connect()), waits for a response and returns
the result (decoded).

=cut

sub _sda_send
{
    my ($self, $number) = @_;
    my $sock = $self->_sda_connect();
    my ($user, $pass, $ip, $client) = @{$self}{qw/user pass host client/};
    my $line = "$number $user $pass $ip 0 $client \n";
    print ">$line" if DEBUG or $self->verbose;
    print $sock ''._encode($line);
    my $response = <$sock>;
    $response = _decode($response);
    print "<$response\n" if DEBUG or $self->verbose;
    $sock->close;
    return $response;
}

# ------------------------------------------------------------------------
#                                                         Generic Routines
# ------------------------------------------------------------------------

=item $encoded = _encode($plain)

Encodes $plain according to the SDA encoding method.

=cut

sub _encode
{
    my $i = 0;
    my ($s) = (@_);
    $s =~ s/(.)/chr ord($1)+$i++%7/eg;
    return $s;
}

=item $plain = _decode($encoded)

Decodes $plain according to the SDA encoding method.

=cut

sub _decode
{
    my $i = 0;
    my ($s) = (@_);
    $s =~ s/(.)/chr ord($1)-$i++%7/eg;
    return $s;
}

=back

=end private

=cut

1;
__END__
#
# ========================================================================
#                                                Rest Of The Documentation

=head1 PROTOCOL NOTES

At the basic level, SDA clients operate by sending a line of text to the
server and receiving a line of text in response.

=head2 Data Encoding

The lines bandied between the client and server are encoded using a very
simple algorithm. The offset of a given byte in the buffer, modulo 7, is
added to the ASCII value of the byte in question.

Decoding is thus the reverse. A suitable regular expression, assuming $i
is initialised to 0 on entry, would be:

    s/(.)/chr ord($1)-$i++%7/eg;

And, in fact, that is the regexp this program makes use of.

=head2 Request Line Contents

The general form of the request line is:

    /^$type $user $pass $ip 0 $client $/
    /^(\d) ([a-zA-Z_]) (\d{6}) ($ip_RE) 0 (\S+) $/

The type indicates the type of command the client is attempting to
execute. It is a single digit. The appropriate values are:

    1 - login
    2 - logout
    3 - update

The username is a string, typically a maximum of 8 characters and only
containing [a-zA-Z0-9]. The username is partially case sensitive. In a
given session, you should use consistent casing since the server pays
attention to it. If you attempt to use two sessions with the same casing
simultaneously, you will receive an 'Already logged on' error. Modifying
the case of arbitrary letters resolves that, thus enabling one to login
in multiple locations.

Empirically, the password is a numeric sequence, 6 digits long. This is
to enable SDA to hook into the Starnet StarCom package (the password is
also used as a phone external dial-out code).

The IP is the IP of the machine to which you would like your data quota
to be used by. This does not have to be the machine from which you run
the client, although it typically is.

It is unknown what the '0' indicates.

The client string is an arbitrary string indicating the client name and
version (typically). Think of it as the USER_AGENT variable in CGI.

These fields are all separated by a space and there is a space at the
end as well.


The client only ever sends these lines. Thus the communication protocol
can be easily abstracted to merely sending an integer to a generic
sda_send() routine and returning the response line (decoded, natch).

=head2 Response Line Contents

    /^(\d)\s(\d)\s.*$/

The response line format varies slightly according to operation.

=head3 Login Event

In the event of a login (type 1) event, the server returns:

    /^$type $success $code $msg$/
    /^(\d) (\d) (\d) (.*)$/

Type is 1 - login.

Success is either 0 or 1, indicating failure or success respectively.

The code depends on the success. If successful, then the code is 0.

In event of an error the code is one of the following values:

    1 - Incorrect username or password
    2 - unknown
    3 - No quota available
    4 - Already connected

Errors 1 and 3 are unrecoverable. In the event of error 1, you should
see your administrator, or re-enter your username and password. Error 3
indicates that your administrator needs to add more to your data limit.

Error 4 merely indicates that you're already connected and should be
regarded as identical to a successful login.

It is unknown what an error of type 2 indicates.

=head3 Logout Event

In the event of a login (type 2) event, the server returns:

    /^$type $success $quota $msg$/
    /^(\d) (\d) (-1|\d+\.\d{3}) (.*)$/

Type is 2 - logout.

Success is either 0 or 1, indicating failure or success respectively.

I am yet to be able to invoke a failure.

The only two responses I have been able to invoke are:

    %.3f Mb Quota_Remaing
    -1 Logoff_Confirmed

where $quota is the -1 or %.3f and $msg is the rest. And, yes, they did
misspell 'Remaining'.

=head3 Update Event

In the event of a update (type 3) event, the server returns:

    /^$type $success $msg$/
    /^(\d) (\d) (.*)$/

Type is 3 - update.

Success is either 0 or 1, indicating failure or success respectively.
In the event of a failure, try to logout.

In a successful update, the message is composed of:

    0 Quota 24.423Mb; Used 4.523Mb

Naturally, where the quantities are relevant to your session.

In an unsuccessful update, I have only invoked a 'User Not Found' error.
This happens when a user tries to update but isn't actually logged in
(or doesn't exist anyway). The message looks like this:

    Health Check Deny: User Not Found

Other situations are, as of yet, unknown.

=head1 AUTHOR

Iain Truskett <spoon@cpan.org> L<http://eh.org/~koschei/>

Please report any bugs, or post any suggestions, to either the mailing
list at <perl-sda@dellah.anu.edu.au> (email
<perl-sda-subscribe@dellah.anu.edu.au> to subscribe) or directly to the
author at <spoon@cpan.org>

=head1 BUGS

Probably doesn't work well on EBCDIC systems due to the
encoding/decoding process.

=head1 PLANS

I intend to have the module returning an appropriate response object
which can be queried for its contents so that parsing the response line
is rendered unnecessary. The object will either be overloaded so code
using the existing interface doesn't fall over or a parameter will be
added to the new() call.

=head1 COPYRIGHT

Copyright (c) 2001 Iain Truskett. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

    $Id: DataAccounting.pm,v 1.2 2002/02/03 14:29:05 koschei Exp $

=head1 ACKNOWLEDGEMENTS

I would like to thank TBBle for his initial research into the protocol,
Starnet for providing such a dodgy protocol, and Bruceo and JT for
providing incentive to actually bother to write this program.

=head1 SEE ALSO

L<http://www.starnetsystems.com.au/>


