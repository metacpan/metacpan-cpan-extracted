# $Id: Rhosts.pm,v 1.10 2003/12/03 15:35:21 autarch Exp $

package Net::SSH::Perl::Auth::Rhosts;

use strict;
use warnings;

use Net::SSH::Perl::Constants qw(
    SSH_SMSG_FAILURE
    SSH_SMSG_SUCCESS
    SSH_CMSG_AUTH_RHOSTS );

use Net::SSH::Perl::Packet;
use Net::SSH::Perl::Auth;
use base qw( Net::SSH::Perl::Auth );

use Scalar::Util qw(weaken);

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

    $ssh->debug("Rhosts authentication is disabled by the client."), return
        unless $ssh->config->get('auth_rhosts');

    $ssh->debug("Trying rhosts authentication.");

    $packet = $ssh->packet_start(SSH_CMSG_AUTH_RHOSTS);
    $packet->put_str($ssh->config->get('user'));
    $packet->send;

    $packet = Net::SSH::Perl::Packet->read($ssh);
    my $type = $packet->type;
    if ($type == SSH_SMSG_SUCCESS) {
        return 1;
    }
    elsif ($type != SSH_SMSG_FAILURE) {
        $ssh->fatal_disconnect("Protocol error: got $type in response to rhosts auth");
    }

    return 0;
}

1;
__END__

=head1 NAME

Net::SSH::Perl::Auth::Rhosts - Perform Rhosts authentication

=head1 SYNOPSIS

    use Net::SSH::Perl::Auth;
    my $auth = Net::SSH::Perl::Auth->new('Rhosts', $ssh);
    print "Valid auth" if $auth->authenticate;

=head1 DESCRIPTION

I<Net::SSH::Perl::Auth::Rhosts> performs Rhosts authentication
with a remote sshd server. When you create a new Rhosts auth
object, you give it an I<$ssh> object, which should contain an open
connection to an ssh daemon, as well as any data that the
authentication module needs to proceed. In this case, the
I<$ssh> object must contain the name of the user trying
to open the connection.

Rhosts authentication is fairly simple from a protocol point
of view. However, note that the sshd server will require
your client to be running on a privileged port (below 1024);
this will, in turn, likely require your client to be running
as root. If your client is not running on a privileged port,
the Rhosts authentication request will be denied.

If you're running as root, I<Net::SSH::Perl> should
automatically detect that and try to start up on a privileged
port. If for some reason that isn't happening, take a look at
the I<Net::SSH::Perl> docs.

With that aside, to use Rhosts authentication the client
sends a request to the server to authenticate it, including
the name of the user trying to authenticate. The server uses
its I<shosts.equiv>, I<hosts.equiv>, etc. files to determine
whether the user/host should be allowed access.

=head1 AUTHOR & COPYRIGHTS

Please see the Net::SSH::Perl manpage for author, copyright,
and license information.

=cut
