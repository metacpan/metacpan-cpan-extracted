# $Id: Agent.pm,v 1.6 2009/01/26 01:09:40 turnstep Exp $

package Net::SSH::Perl::Agent;
use strict;
use warnings;

use IO::Socket;
use Carp qw( croak );
use Net::SSH::Perl::Constants qw( :agent SSH_COM_AGENT2_FAILURE );
use Net::SSH::Perl::Buffer;

sub new {
    my $class = shift;
    my $agent = bless {}, $class;
    $agent->init(@_);
}

sub init {
    my $agent = shift;
    my($version) = @_;
    $agent->{sock} = $agent->create_socket or return;
    $agent->{version} = $version;
    $agent;
}

sub create_socket {
    my $agent = shift;
    my $authsock = $ENV{"SSH_AUTH_SOCK"} or return;

    $agent->{sock} = IO::Socket::UNIX->new(
                    Type => SOCK_STREAM,
                    Peer => $authsock
        ) or return;
}

sub request {
    my $agent = shift;
    my($req) = @_;
    my $len = pack "N", $req->length;
    my $sock = $agent->{sock};
    (syswrite($sock, $len, 4) == 4 and
      syswrite($sock, $req->bytes, $req->length) == $req->length) or
        croak "Error writing to auth socket.";
    $len = 4;
    my $buf;
    while ($len > 0) {
        my $l = sysread $sock, $buf, $len;
        croak "Error reading response length from auth socket." unless $l > 0;
        $len -= $l;
    }
    $len = unpack "N", $buf;
    croak "Auth response too long: $len" if $len > 256 * 1024;

    $buf = Net::SSH::Perl::Buffer->new( MP => "SSH$agent->{version}" );
    while ($buf->length < $len) {
        my $b;
        my $l = sysread $sock, $b, $len;
        croak "Error reading response from auth socket." unless $l > 0;
        $buf->append($b);
    }
    $buf;
}

sub num_left { $_[0]->{num} }

sub num_identities {
    my $agent = shift;
    my($type1, $type2) = $agent->{version} == 2 ?
        (SSH2_AGENTC_REQUEST_IDENTITIES, SSH2_AGENT_IDENTITIES_ANSWER) :
        (SSH_AGENTC_REQUEST_RSA_IDENTITIES, SSH_AGENT_RSA_IDENTITIES_ANSWER);

    my $r = Net::SSH::Perl::Buffer->new( MP => "SSH$agent->{version}" );
    $r->put_int8($type1);
    my $reply = $agent->{identities} = $agent->request($r);

    my $type = $reply->get_int8;
    if ($type == SSH_AGENT_FAILURE || $type == SSH_COM_AGENT2_FAILURE) {
        return;
    }
    elsif ($type != $type2) {
        croak "Bad auth reply message type: $type != $type2";
    }

    $agent->{num} = $reply->get_int32;
    croak "Too many identities in agent reply: $agent->{num}"
        if $agent->{num} > 1024;

    $agent->{num};
}

sub identity_iterator {
    my $agent = shift;
    return sub { } unless $agent->num_identities;
    sub { $agent->next_identity };
}

sub first_identity {
    my $agent = shift;
    $agent->next_identity if $agent->num_identities;
}

sub next_identity {
    my $agent = shift;
    return unless $agent->{num} > 0;

    my($ident, $key, $comment) = ($agent->{identities});
    if ($agent->{version} == 1) {
        $key = Net::SSH::Perl::Key->new('RSA1');
        $key->{rsa}{bits} = $ident->get_int32;
        $key->{rsa}{e} = $ident->get_mp_int;
        $key->{rsa}{n} = $ident->get_mp_int;
        $comment = $ident->get_str;
    }
    else {
        my $blob = $ident->get_str;
        $comment = $ident->get_str;
        $key = Net::SSH::Perl::Key->new_from_blob($blob);
    }
    $agent->{num}--;
    wantarray ? ($key, $comment) : $key;
}

sub sign {
    my $agent = shift;
    my($key, $data) = @_;
    my $blob = $key->as_blob;
    my $r = Net::SSH::Perl::Buffer->new( MP => "SSH$agent->{version}" );
    $r->put_int8(SSH2_AGENTC_SIGN_REQUEST);
    $r->put_str($blob);
    $r->put_str($data);
    $r->put_int32(0);

    my $reply = $agent->request($r);
    my $type = $reply->get_int8;
    if ($type == SSH_AGENT_FAILURE || $type == SSH_COM_AGENT2_FAILURE) {
        return;
    }
    elsif ($type != SSH2_AGENT_SIGN_RESPONSE) {
        croak "Bad auth response: $type != ",  SSH2_AGENT_SIGN_RESPONSE;
    }
    else {
        return $reply->get_str;
    }
}

sub decrypt {
    my $agent = shift;
    my($key, $data, $session_id) = @_;
    my $r = Net::SSH::Perl::Buffer->new( MP => "SSH$agent->{version}" );
    $r->put_int8(SSH_AGENTC_RSA_CHALLENGE);
    $r->put_int32($key->{rsa}{bits});
    $r->put_mp_int($key->{rsa}{e});
    $r->put_mp_int($key->{rsa}{n});
    $r->put_mp_int($data);
    $r->put_chars($session_id);
    $r->put_int32(1);

    my $reply = $agent->request($r);
    my $type = $reply->get_int8;
    my $response = '';
    if ($type == SSH_AGENT_FAILURE || $type == SSH_COM_AGENT2_FAILURE) {
        return;
    }
    elsif ($type != SSH_AGENT_RSA_RESPONSE) {
        croak "Bad auth response: $type";
    }
    else {
        $response .= $reply->get_char for 1..16;
    }
    $response;
}

sub close_socket {
    my $agent = shift;
    close($agent->{sock}) or warn qq{Could not close socket: $!\n};
}

1;
__END__

=head1 NAME

Net::SSH::Perl::Agent - Client for agent authentication

=head1 SYNOPSIS

    use Net::SSH::Perl::Agent;
    my $agent = Net::SSH::Perl::Agent->new(2);  ## SSH-2 protocol
    my $iter = $agent->identity_iterator;
    while (my($key, $comment) = $iter->()) {
        ## Do something with $key.
    }

=head1 DESCRIPTION

I<Net::SSH::Perl::Agent> provides a client for agent-based
publickey authentication. The idea behind agent authentication
is that an auth daemon is started as the parent of all of your
other processes (eg. as the parent of your shell process); all
other processes thus inherit the connection to the daemon.

After loading your public keys into the agent using I<ssh-add>, the
agent listens on a Unix domain socket for requests for identities.
When requested it sends back the public portions of the keys,
which the SSH client (ie. I<Net::SSH::Perl>, in this case) can
send to the sshd, to determine if the keys will be accepted on
the basis of authorization. If so, the client requests that the
agent use the key to decrypt a random challenge (SSH-1) or sign
a piece of data (SSH-2).

I<Net::SSH::Perl::Agent> implements the client portion of the
authentication agent; this is the piece that interfaces with
I<Net::SSH::Perl>'s authentication mechanism to contact the
agent daemon and ask for identities, etc. If you use publickey
authentication (I<RSA> authentication in SSH-1, I<PublicKey>
authentication in SSH-2), an attempt will automatically be
made to contact the authentication agent. If the attempt
succeeds, I<Net::SSH::Perl> will try to use the identities
returned from the agent, in addition to any identity files on
disk.

=head1 USAGE

=head2 Net::SSH::Perl::Agent->new($version)

Constructs a new I<Agent> object and returns that object.

I<$version> should be either I<1> or I<2> and is a mandatory
argument; it specifies the protocol version that the agent
client should use when talking to the agent daemon.

=head2 $agent->identity_iterator

This is probably the easiest way to get at the identities
provided by the agent. I<identity_iterator> returns an iterator
function that, when invoked, will returned the next identity
in the list from the agent. For example:

    my $iter = $agent->identity_iterator;
    while (my($key, $comment) = $iter->()) {
         ## Do something with $key.
    }

If called in scalar context, the iterator function will return
the next key (a subclass of I<Net::SSH::Perl::Key>). If called
in list context (as above), both the key and the comment are
returned.

=head2 $agent->first_identity

Returns the first identity in the list provided by the auth
agent.

If called in scalar context, the iterator function will return
the next key (a subclass of I<Net::SSH::Perl::Key>). If called
in list context, both the key and the comment are returned.

=head2 $agent->next_identity

Returns the next identity in the list provided by the auth
agent. You I<must> call this I<after> first calling the
I<first_identity> method. For example:

    my($key, $comment) = $agent->first_identity;
    ## Do something.

    while (($key, $comment) = $agent->next_identity) {
        ## Do something.
    }

If called in scalar context, the iterator function will return
the next key (a subclass of I<Net::SSH::Perl::Key>). If called
in list context, both the key and the comment are returned.

=head2 $agent->sign($key, $data)

Asks the agent I<$agent> to sign the data I<$data> using the
private portion of I<$key>. The key and the data are sent to
the agent, which returns the signature; the signature is then
sent to the sshd for verification.

This method is only applicable in SSH-2.

=head2 $agent->decrypt($key, $data, $session_id)

Asks the agent to which I<$agent> holds an open connection to
decrypt the data I<$data> using the private portion of I<$key>.
I<$data> should be a big integer (I<Math::GMP> object), and
is generally a challenge to a request for RSA authentication.
I<$session_id> is the SSH session ID:

    $ssh->session_id

where I<$ssh> is a I<Net::SSH::Perl::SSH1> object.

This method is only applicable in SSH-1.

=head1 AUTHOR & COPYRIGHTS

Please see the Net::SSH::Perl manpage for author, copyright,
and license information.

=cut
