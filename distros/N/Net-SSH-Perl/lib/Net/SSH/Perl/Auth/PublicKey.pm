package Net::SSH::Perl::Auth::PublicKey;

use strict;
use warnings;

use Net::SSH::Perl::Constants qw(
    SSH2_MSG_USERAUTH_REQUEST
    SSH2_MSG_USERAUTH_PK_OK
    SSH_COMPAT_OLD_SESSIONID
    SSH_COMPAT_BUG_PKAUTH );

use Net::SSH::Perl::Util qw( _read_passphrase );
use Net::SSH::Perl::Buffer;
use Net::SSH::Perl::Key;

use Net::SSH::Perl::Auth;
use base qw( Net::SSH::Perl::Auth );

use Scalar::Util qw(weaken);

sub new {
    my $class = shift;
    my $ssh = shift;
    my $auth = bless { ssh => $ssh }, $class;
    weaken $auth->{ssh};
    $auth->enabled( $ssh->config->get('auth_dsa') );
    $auth;
}

sub enabled {
    my $auth = shift;
    $auth->{enabled} = shift if @_;
    $auth->{enabled};
}

sub authenticate {
    my $auth = shift;
    my $ssh = $auth->{ssh};

    my $sent = 0;
    if (my $agent = $auth->mgr->agent) {
        do {
            $sent = $auth->_auth_agent;
        } until $sent || $agent->num_left <= 0;
    }
    return $sent if $sent;

    my $if = $ssh->config->get('identity_files') || [];
    my $idx = $auth->{_identity_idx} || 0;
    for my $f (@$if[$idx..$#$if]) {
        $auth->{_identity_idx}++;
        return 1 if $auth->_auth_identity($f);
    }
}

sub _auth_agent {
    my $auth = shift;
    my $agent = $auth->mgr->agent;

    my($iter);
    $iter = $auth->{_identity_iter} = $agent->identity_iterator
        unless $iter = $auth->{_identity_iter};
    my($key, $comment) = $iter->();
    return unless $key;
    $auth->{ssh}->debug("Publickey: testing agent key '$comment'");
    $auth->_test_pubkey($key, \&agent_sign);
}

sub _auth_identity {
    my $auth = shift;
    my($auth_file) = @_;
    my $ssh = $auth->{ssh};
    my($packet);

	-s $auth_file or return 0;

    my($key);
    $ssh->debug("Trying pubkey authentication with key file '$auth_file'");

    $key = Net::SSH::Perl::Key->read_private_pem($auth_file, '',
        \$ssh->{datafellows}, $ssh->{'server-sig-algs'});
    if (!$key) {
        my $passphrase = "";
        if ($ssh->config->get('interactive')) {
            $passphrase = _read_passphrase("Enter passphrase for keyfile '$auth_file': ");
        }
        else {
            $ssh->debug("Will not query passphrase for '$auth_file' in batch mode.");
        }

        $key = Net::SSH::Perl::Key->read_private_pem($auth_file,
            $passphrase, \$ssh->{datafellows});
        if (!$key) {
            $ssh->debug("Loading private key failed.");
            return 0;
        }
    }

    $auth->_sign_send_pubkey($key, \&key_sign);
}

sub agent_sign { $_[0]->mgr->agent->sign($_[1], $_[2]) }
sub key_sign { $_[1]->sign($_[2]) }

sub _sign_send_pubkey {
    my $auth = shift;
    my($key, $cb) = @_;
    my $ssh = $auth->{ssh};
    my($packet);

    my $b = Net::SSH::Perl::Buffer->new( MP => 'SSH2' );
    if ($ssh->{datafellows} & SSH_COMPAT_OLD_SESSIONID) {
        $b->append($ssh->session_id);
    }
    else {
        $b->put_str($ssh->session_id);
    }
    $b->put_int8(SSH2_MSG_USERAUTH_REQUEST);
    my $skip = $b->length;

    $b->put_str($ssh->config->get('user'));
    $b->put_str("ssh-connection");
    $b->put_str("publickey");
    $b->put_int8(1);
    $b->put_str( $key->ssh_name );
    $b->put_str( $key->as_blob );

    my $sigblob = $cb->($auth, $key, $b->bytes);
    $ssh->debug("Signature generation failed for public key."), return
        unless $sigblob;
    $b->put_str($sigblob);

    $b->bytes(0, $skip, '');   ## Get rid of session ID and packet type.

    $packet = $ssh->packet_start(SSH2_MSG_USERAUTH_REQUEST);
    $packet->append($b->bytes);
    $packet->send;

    return 1;
}

sub _test_pubkey {
    my $auth = shift;
    my($key, $cb) = @_;
    my $ssh = $auth->{ssh};

    my $blob = $key->as_blob;

    ## Set up PK_OK callback; closure on $auth, $key, and $cb.
    $auth->mgr->register_handler(SSH2_MSG_USERAUTH_PK_OK, sub {
        my $amgr = shift;
        my($packet) = @_;
        my $ssh = $amgr->{ssh};
        my $alg = $packet->get_str;
        my $blob = $packet->get_str;

        $ssh->debug("PK_OK received without existing key state."), return
            unless $key && $cb;

        my $s_key = Net::SSH::Perl::Key->new_from_blob($blob, undef,
            $ssh->{'server-sig-algs'});
        $ssh->debug("Failed extracting key from blob, pkalgorithm is '$alg'"),
            return unless $s_key;
        $ssh->debug("PK_OK key != saved state key"), return
            unless $s_key->equal($key);

        $ssh->debug("Public key is accepted, signing data.");
        $ssh->debug("Key fingerprint: " .
            $key->fingerprint($ssh->config->get('fingerprint_hash')));
        my $sent = $auth->_sign_send_pubkey($s_key, $cb);
        $amgr->remove_handler(SSH2_MSG_USERAUTH_PK_OK);

        $sent;
    });

    my $packet = $ssh->packet_start(SSH2_MSG_USERAUTH_REQUEST);
    $packet->put_str($ssh->config->get('user'));
    $packet->put_str("ssh-connection");
    $packet->put_str("publickey");
    $packet->put_int8(0);   ## No signature, just public key blob.
    $packet->put_str($key->ssh_name)
        unless $ssh->{datafellows} & SSH_COMPAT_BUG_PKAUTH;
    $packet->put_str($blob);
    $packet->send;

    return 1;
}

1;
__END__

=head1 NAME

Net::SSH::Perl::Auth::PublicKey - Perform publickey authentication

=head1 SYNOPSIS

    use Net::SSH::Perl::Auth;
    my $auth = Net::SSH::Perl::Auth->new('PublicKey', $ssh);
    $auth->authenticate;

=head1 DESCRIPTION

I<Net::SSH::Perl::Auth::PublicKey> performs publickey authentication
with a remote sshd server. When you create a new PublicKey auth
object, you give it an I<$ssh> object, which should contain an open
connection to an ssh daemon, as well as any data that the
authentication module needs to proceed. In this case, for
example, the I<$ssh> object might contain a list of
identity files (see the docs for I<Net::SSH::Perl>).

The I<authenticate> method first tries to establish a connection
to an authentication agent. If the attempt is successful,
I<authenticate> loops through each of the identities returned from
the agent and tries each identity against the sshd, entering into
a dialog with the server: the client sends the public portion of
the key to determine whether the server will accept it; if the
server accepts the key as authorization, the client then asks the
agent to sign a piece of data using the key, which the client sends
to the server. If the server accepts an identity/key, authentication
is successful.

If the agent connection attempt fails, or if none of the identities
returned from the agent allow for successful authentication,
I<authenticate> then tries to load each of the user's private key
identity files (specified in the I<Net::SSH::Perl> constructor, or
defaulted to F<$ENV{HOME}/.ssh/id_dsa>). For each identity,
I<authenticate> enters into a dialog with the server. The client
sends a message to the server, giving its public key, plus a signature
of the key and the other data in the message (session ID, etc.).
The signature is generated using the corresponding private key.
The sshd receives the message and verifies the signature using the
client's public key. If the verification is successful, the
authentication succeeds.

When loading each of the private key files, the client first
tries to load the key using an empty passphrase. If this
fails, the client either prompts the user for a passphrase
(if the session is interactive) or skips the key altogether.

=head1 AUTHOR & COPYRIGHTS

Please see the Net::SSH::Perl manpage for author, copyright,
and license information.

=cut
