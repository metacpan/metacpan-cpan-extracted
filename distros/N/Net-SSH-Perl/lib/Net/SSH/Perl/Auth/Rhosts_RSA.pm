# $Id: Rhosts_RSA.pm,v 1.13 2003/12/03 15:35:21 autarch Exp $

package Net::SSH::Perl::Auth::Rhosts_RSA;

use strict;
use warnings;

use Net::SSH::Perl::Constants qw(
    SSH_SMSG_FAILURE
    SSH_SMSG_SUCCESS
    SSH_CMSG_AUTH_RHOSTS_RSA
    SSH_SMSG_AUTH_RSA_CHALLENGE
    SSH_CMSG_AUTH_RSA_RESPONSE );

use Net::SSH::Perl::Util qw( :rsa _load_private_key );
use Net::SSH::Perl::Packet;
use Net::SSH::Perl::Auth;
use base qw( Net::SSH::Perl::Auth );

use Scalar::Util qw(weaken);
use File::Spec::Functions qw( catfile );

sub new {
    my $class = shift;
    my $ssh = shift;
    my $auth = bless { ssh => $ssh }, $class;
    weaken $auth->{ssh};
    $auth;
}

sub authenticate {
    my $auth = shift;
    my($packet);
    my $ssh = $auth->{ssh};

    $ssh->debug("Rhosts-RSA authentication is disabled by the client."), return
        unless $ssh->config->get('auth_rhosts_rsa');

    $ssh->debug("Trying rhosts or /etc/hosts.equiv with RSA host authentication.");

    my $private_key;
    eval {
        my $ssh_host_key = $^O eq 'MSWin32'
          ? catfile($ENV{WINDIR}, 'ssh_host_key')
          : '/etc/ssh_host_key';
        $private_key = _load_private_key($ssh_host_key);
    };
    $ssh->debug("Rhosts with RSA authentication failed: Can't load private host key."),
        return 0 if $@;

    my $user = $ssh->config->get('user');
    $packet = $ssh->packet_start(SSH_CMSG_AUTH_RHOSTS_RSA);
    $packet->put_str($user);
    $packet->put_int32($private_key->{rsa}{bits});
    $packet->put_mp_int($private_key->{rsa}{e});
    $packet->put_mp_int($private_key->{rsa}{n});
    $packet->send;

    $packet = Net::SSH::Perl::Packet->read($ssh);
    my $type = $packet->type;
    if ($type == SSH_SMSG_FAILURE) {
        $ssh->debug("Server refused our rhosts authentication or host key.");
        return 0;
    }

    if ($type != SSH_SMSG_AUTH_RSA_CHALLENGE) {
        $ssh->fatal_disconnect("Protocol error during RSA authentication: $type");
    }
    my $challenge = $packet->get_mp_int;

    $ssh->debug("Received RSA challenge for host key from server.");

    _respond_to_rsa_challenge($ssh, $challenge, $private_key);

    $packet = Net::SSH::Perl::Packet->read($ssh);
    $type = $packet->type;
    if ($type == SSH_SMSG_SUCCESS) {
        $ssh->debug("Rhosts or /etc/hosts.equiv with RSA host authentication accepted by server.");
        return 1;
    }
    elsif ($type != SSH_SMSG_FAILURE) {
        $ssh->fatal_disconnect("Protocol error waiting RSA auth response: $type");
    }

    $ssh->debug("Rhosts or /hosts.equiv with RSA host authentication refused.");
    return 0;
}

1;
__END__

=head1 NAME

Net::SSH::Perl::Auth::Rhosts_RSA - Perform Rhosts-RSA authentication

=head1 SYNOPSIS

    use Net::SSH::Perl::Auth;
    my $auth = Net::SSH::Perl::Auth->new('Rhosts_RSA', $ssh);
    print "Valid auth" if $auth->authenticate;

=head1 DESCRIPTION

I<Net::SSH::Perl::Auth::Rhosts_RSA> performs Rhosts with RSA
authentication with a remote sshd server. This is standard
Rhosts authentication, plus a challenge-response phase where
the server RSA-authenticates the client based on its host
key. When you create a new Rhosts_RSA auth object, you give
it an I<$ssh> object, which should contain an open connection
to an ssh daemon, as well as any data that the authentication
module needs to proceed. In this case, the I<$ssh> object
must contain the name of the user trying to open the connection.

Note that the sshd server will require two things from your
client:

=over 4

=item 1. Privileged Port

sshd will require your client to be running on a privileged port
(below 1024); this will, in turn, likely require your client to be
running as root. If your client is not running on a privileged port,
the Rhosts-RSA authentication request will be denied.

If you're running as root, I<Net::SSH::Perl> should
automatically detect that and try to start up on a privileged
port. If for some reason that isn't happening, take a look at
the I<Net::SSH::Perl> docs.

=item 2. Private Host Key

In order to do RSA-authentication on your host key, your client
must be able to read the host key. This will likely be
impossible unless you're running as root, because the private
host key file (F</etc/ssh_host_key>) is readable only by root.

=back

With that aside, to use Rhosts-RSA authentication the client
sends a request to the server to authenticate it, including
the name of the user trying to authenticate, as well as the
public parts of the host key. The server first ensures that
the host can be authenticated using standard Rhosts
authentication (I<shosts.equiv>, I<hosts.equiv>, etc.).
If the client passes this test, the server sends an encrypted
challenge to the client. The client must decrypt this
challenge using its private host key, then respond to the
server with its response.

Once the response has been sent, the server responds with
success or failure.

=head1 AUTHOR & COPYRIGHTS

Please see the Net::SSH::Perl manpage for author, copyright,
and license information.

=cut
