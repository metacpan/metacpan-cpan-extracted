package Net::SSH::Perl::Constants;
use strict;
use warnings;

use vars qw( %CONSTANTS );
%CONSTANTS = (
    'PROTOCOL_MAJOR_1' => 1,
    'PROTOCOL_MINOR_1' => 5,
    'PROTOCOL_MAJOR_2' => 2,
    'PROTOCOL_MINOR_2' => 0,
    'PROTOCOL_SSH1_PREFERRED' => 4,
    'PROTOCOL_SSH1' => 1,
    'PROTOCOL_SSH2' => 2,

    'SSH_MSG_NONE' => 0,
    'SSH_MSG_DISCONNECT' => 1,
    'SSH_SMSG_PUBLIC_KEY' => 2,
    'SSH_CMSG_SESSION_KEY' => 3,
    'SSH_CMSG_USER' => 4,
    'SSH_CMSG_AUTH_RHOSTS' => 5,
    'SSH_CMSG_AUTH_RSA' => 6,
    'SSH_SMSG_AUTH_RSA_CHALLENGE' => 7,
    'SSH_CMSG_AUTH_RSA_RESPONSE' => 8,
    'SSH_CMSG_AUTH_PASSWORD' => 9,
    'SSH_CMSG_REQUEST_PTY' => 10,
    'SSH_CMSG_EXEC_SHELL' => 12,
    'SSH_CMSG_EXEC_CMD' => 13,
    'SSH_SMSG_SUCCESS' => 14,
    'SSH_SMSG_FAILURE' => 15,
    'SSH_CMSG_STDIN_DATA' => 16,
    'SSH_SMSG_STDOUT_DATA' => 17,
    'SSH_SMSG_STDERR_DATA' => 18,
    'SSH_CMSG_EOF' => 19,
    'SSH_SMSG_EXITSTATUS' => 20,
    'SSH_MSG_IGNORE' => 32,
    'SSH_CMSG_EXIT_CONFIRMATION' => 33,
    'SSH_CMSG_AUTH_RHOSTS_RSA' => 35,
    'SSH_MSG_DEBUG' => 36,
    'SSH_CMSG_REQUEST_COMPRESSION' => 37,
    'SSH_CMSG_AUTH_TIS' => 39,
    'SSH_SMSG_AUTH_TIS_CHALLENGE' => 40,
    'SSH_CMSG_AUTH_TIS_RESPONSE' => 41,

    'SSH_COMPAT_BUG_SIGBLOB' => 0x01,
    'SSH_COMPAT_BUG_PUBKEYAUTH' => 0x02,
    'SSH_COMPAT_BUG_HMAC' => 0x04,
    'SSH_COMPAT_BUG_X11FWD' => 0x08,
    'SSH_COMPAT_OLD_SESSIONID' => 0x10,
    'SSH_COMPAT_BUG_PKAUTH' => 0x20,
    'SSH_COMPAT_BUG_RSASIGMD5' => 0x2000,

    'SSH2_MSG_DISCONNECT' => 1,
    'SSH2_MSG_IGNORE' => 2,
    'SSH2_MSG_UNIMPLEMENTED' => 3,
    'SSH2_MSG_DEBUG' => 4,
    'SSH2_MSG_SERVICE_REQUEST' => 5,
    'SSH2_MSG_SERVICE_ACCEPT' => 6,
    'SSH2_MSG_EXT_INFO' => 7,
    'SSH2_MSG_KEXINIT' => 20,
    'SSH2_MSG_NEWKEYS' => 21,
    'SSH2_MSG_KEXDH_INIT' => 30,
    'SSH2_MSG_KEXDH_REPLY' => 31,
    'SSH2_MSG_KEX_DH_GEX_REQUEST_OLD' => 30,
    'SSH2_MSG_KEX_DH_GEX_REQUEST' => 34,
    'SSH2_MSG_KEX_DH_GEX_GROUP' => 31,
    'SSH2_MSG_KEX_DH_GEX_INIT' => 32,
    'SSH2_MSG_KEX_DH_GEX_REPLY' => 33,
    'SSH2_MSG_KEX_ECDH_INIT'  => 30,
    'SSH2_MSG_KEX_ECDH_REPLY' => 31,
    'SSH2_MSG_USERAUTH_REQUEST' => 50,
    'SSH2_MSG_USERAUTH_FAILURE' => 51,
    'SSH2_MSG_USERAUTH_SUCCESS' => 52,
    'SSH2_MSG_USERAUTH_BANNER' => 53,
    'SSH2_MSG_USERAUTH_PK_OK' => 60,
    'SSH2_MSG_USERAUTH_INFO_REQUEST' => 60,
    'SSH2_MSG_USERAUTH_INFO_RESPONSE' => 61,
    'SSH2_MSG_GLOBAL_REQUEST' => 80,
    'SSH2_MSG_REQUEST_SUCCESS' => 81,
    'SSH2_MSG_REQUEST_FAILURE' => 82,
    'SSH2_MSG_CHANNEL_OPEN' => 90,
    'SSH2_MSG_CHANNEL_OPEN_CONFIRMATION' => 91,
    'SSH2_MSG_CHANNEL_OPEN_FAILURE' => 92,
    'SSH2_MSG_CHANNEL_WINDOW_ADJUST' => 93,
    'SSH2_MSG_CHANNEL_DATA' => 94,
    'SSH2_MSG_CHANNEL_EXTENDED_DATA' => 95,
    'SSH2_MSG_CHANNEL_EOF' => 96,
    'SSH2_MSG_CHANNEL_CLOSE' => 97,
    'SSH2_MSG_CHANNEL_REQUEST' => 98,
    'SSH2_MSG_CHANNEL_SUCCESS' => 99,
    'SSH2_MSG_CHANNEL_FAILURE' => 100,

    'SSH_CHANNEL_OPENING' => 3,
    'SSH_CHANNEL_OPEN' => 4,
    'SSH_CHANNEL_INPUT_DRAINING' => 8,
    'SSH_CHANNEL_OUTPUT_DRAINING' => 9,
    'SSH_CHANNEL_LARVAL' => 10,

    'SSH_AGENTC_REQUEST_RSA_IDENTITIES' => 1,
    'SSH_AGENT_RSA_IDENTITIES_ANSWER' => 2,
    'SSH_AGENTC_RSA_CHALLENGE' => 3,
    'SSH_AGENT_RSA_RESPONSE' => 4,
    'SSH_AGENT_FAILURE' => 5,
    'SSH_AGENT_SUCCESS' => 6,

    'SSH2_AGENTC_REQUEST_IDENTITIES' => 11,
    'SSH2_AGENT_IDENTITIES_ANSWER' => 12,
    'SSH2_AGENTC_SIGN_REQUEST' => 13,
    'SSH2_AGENT_SIGN_RESPONSE' => 14,

    'SSH_COM_AGENT2_FAILURE' => 102,

    'CHAN_INPUT_OPEN' => 0x01,
    'CHAN_INPUT_WAIT_DRAIN' => 0x02,
    'CHAN_INPUT_WAIT_IEOF' => 0x04,
    'CHAN_INPUT_CLOSED' => 0x08,
    'CHAN_OUTPUT_OPEN' => 0x10,
    'CHAN_OUTPUT_WAIT_DRAIN' => 0x20,
    'CHAN_OUTPUT_WAIT_IEOF' => 0x40,
    'CHAN_OUTPUT_CLOSED' => 0x80,
    'CHAN_CLOSE_SENT' => 0x01,
    'CHAN_CLOSE_RCVD' => 0x02,

    'KEX_DH1' => 'diffie-hellman-group1-sha1',
    'KEX_DH14_SHA1' => 'diffie-hellman-group14-sha1',
    'KEX_DH14_SHA256' => 'diffie-hellman-group14-sha256',
    'KEX_DH16_SHA512' => 'diffie-hellman-group16-sha512',
    'KEX_DH18_SHA512' => 'diffie-hellman-group18-sha512',
    'KEX_DH_GEX_SHA256' => 'diffie-hellman-group-exchange-sha256',
    'KEX_DH_GEX_SHA1' => 'diffie-hellman-group-exchange-sha1',
    'KEX_CURVE25519_SHA256' => 'curve25519-sha256@libssh.org',
    'KEX_CURVE25519_SHA256_ALIAS' => 'curve25519-sha256',
    'KEX_DEFAULT_KEX' => 'curve25519-sha256@libssh.org,curve25519-sha256,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256,diffie-hellman-group14-sha256,diffie-hellman-group14-sha1',
    'KEX_ALL_KEX' => 'diffie-hellman-group1-sha1,diffie-hellman-group14-sha1,diffie-hellman-group14-sha256,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256,diffie-hellman-group-exchange-sha1,curve25519-sha256@libssh.org,curve25519-sha256',
    'KEX_DEFAULT_PK_ALG' => 'ssh-ed25519,rsa-sha2-512,rsa-sha2-256,ecdsa-sha2-nistp521,ecdsa-sha2-nistp384,ecdsa-sha2-nistp256,ssh-rsa',
    'KEX_ALL_PK_ALG' => 'ssh-ed25519,rsa-sha2-512,rsa-sha2-256,ecdsa-sha2-nistp521,ecdsa-sha2-nistp384,ecdsa-sha2-nistp256,ssh-rsa,ssh-dss',
    'KEX_DEFAULT_ENCRYPT' => 'chacha20-poly1305@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr',
    'KEX_ALL_ENCRYPT' => 'chacha20-poly1305@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr,aes256-cbc,aes192-cbc,aes128-cbc,3des-cbc,blowfish-cbc,arcfour',
    'KEX_DEFAULT_MAC' => 'hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256',
    'KEX_ALL_MAC' => 'hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,hmac-sha1,hmac-md5',
    'KEX_DEFAULT_COMP' => 'none,zlib',
    'KEX_DEFAULT_LANG' => '',

    'PROPOSAL_KEX_ALGS' => 0,
    'PROPOSAL_SERVER_HOST_KEY_ALGS' => 1,
    'PROPOSAL_CIPH_ALGS_CTOS' => 2,
    'PROPOSAL_CIPH_ALGS_STOC' => 3,
    'PROPOSAL_MAC_ALGS_CTOS' => 4,
    'PROPOSAL_MAC_ALGS_STOC' => 5,
    'PROPOSAL_COMP_ALGS_CTOS' => 6,
    'PROPOSAL_COMP_ALGS_STOC' => 7,
    'PROPOSAL_LANG_CTOS' => 8,
    'PROPOSAL_LANG_STOC' => 9,

    'HOST_OK' => 1,
    'HOST_NEW' => 2,
    'HOST_CHANGED' => 3,

    'PRIVATE_KEY_ID_STRING' => "SSH PRIVATE KEY FILE FORMAT 1.1\n",

    'MAX_PACKET_SIZE' => 256000,
);

use vars qw( %TAGS );
my %RULES = (
    '^SSH_\w?MSG'  => 'msg',
    '^SSH2_\w?MSG' => 'msg2',
    '^SSH2?_AGENT' => 'agent',
    '^KEX'         => 'kex',
    '^PROTOCOL'    => 'protocol',
    '^HOST'        => 'hosts',
    '^PROPOSAL'    => 'proposal',
    '^SSH_CHANNEL|^CHAN' => 'channels',
    '^SSH_COMPAT'  => 'compat',
);

for my $re (keys %RULES) {
    @{ $TAGS{ $RULES{$re} } } = grep /$re/, keys %CONSTANTS;
}

sub import {
    my $class = shift;

    my @to_export;
    my @args = @_;
    for my $item (@args) {
        push @to_export,
            $item =~ s/^:// ? @{ $TAGS{$item} } : $item;
    }

    no strict 'refs'; ## no critic
    my $pkg = caller;
    for my $con (@to_export) {
        warn __PACKAGE__, " does not export the constant '$con'"
            unless exists $CONSTANTS{$con};
        *{"${pkg}::$con"} = sub () { $CONSTANTS{$con} }
    }
}

1;
__END__

=head1 NAME

Net::SSH::Perl::Constants - Exportable constants

=head1 SYNOPSIS

    use Net::SSH::Perl::Constants qw( constants );

=head1 DESCRIPTION

I<Net::SSH::Perl::Constants> provides a list of common and
useful constants for use in communicating with an sshd
server, etc.

None of the constants are exported by default; you have to
explicitly ask for them. Some of the constants are grouped
into bundles that you can grab all at once, or you can just
take the individual constants, one by one.

If you wish to import a group, your I<use> statement should
look something like this:

    use Net::SSH::Perl::Constants qw( :group );

Here are the groups:

=over 4

=item * msg

All of the MSG constants. In the SSH packet layer protocol,
each packet is identified by its type; for example, you have
a packet type for starting RSA authentication, a different
type for sending a command, etc. The MSG constants are used
when creating a new packet, then:

    my $packet = $ssh->packet_start( I<msg_constant> );

See the I<Net::SSH::Perl::Packet> and I<Net::SSH::Perl> docs
for details.

I<Net::SSH::Perl> doesn't support all of the features of
the ssh client, so it doesn't need all of its MSG
constants. For a full list of such constants, and an
explanation of each, see the SSH RFC.

Here's the list of MSG constants supported by I<Net::SSH::Perl>:
SSH_MSG_NONE, SSH_MSG_DISCONNECT, SSH_SMSG_PUBLIC_KEY,
SSH_CMSG_SESSION_KEY, SSH_CMSG_USER, SSH_CMSG_AUTH_RHOSTS,
SSH_CMSG_AUTH_RSA, SSH_SMSG_AUTH_RSA_CHALLENGE,
SSH_CMSG_AUTH_RSA_RESPONSE, SSH_CMSG_AUTH_PASSWORD,
SSH_CMSG_EXEC_SHELL, SSH_CMSG_EXEC_CMD, SSH_SMSG_SUCCESS,
SSH_SMSG_FAILURE, SSH_CMSG_STDIN_DATA, SSH_SMSG_STDOUT_DATA,
SSH_SMSG_STDERR_DATA, SSH_CMSG_EOF, SSH_SMSG_EXITSTATUS,
SSH_MSG_IGNORE, SSH_CMSG_EXIT_CONFIRMATION,
SSH_CMSG_AUTH_RHOSTS_RSA, SSH_MSG_DEBUG,
SSH_CMSG_REQUEST_COMPRESSION.

=item * hosts

The HOST constants: HOST_OK, HOST_NEW, and HOST_CHANGED.
These are returned from the C<_check_host_in_hostfile>
routine in I<Net::SSH::Perl::Util>. See those docs for
that routine for an explanation of the meaning of these
constants.

=item * agent

The AGENT constants, used when talking to an authentication
agent: SSH_AGENTC_REQUEST_RSA_IDENTITIES,
SSH_AGENT_RSA_IDENTITIES_ANSWER, SSH_AGENTC_RSA_CHALLENGE,
SSH_AGENT_RSA_RESPONSE, SSH_AGENT_FAILURE, SSH_AGENT_SUCCESS,
SSH2_AGENTC_REQUEST_IDENTITIES, SSH2_AGENT_IDENTITIES_ANSWER,
SSH2_AGENTC_SIGN_REQUEST, SSH2_AGENT_SIGN_RESPONSE.

=back

Other exportable constants, not belonging to a group, are:

=over 4

=item * PROTOCOL_MAJOR

=item * PROTOCOL_MINOR

These two constants describe the version of the protocol
supported by this SSH client (ie., I<Net::SSH::Perl>).
They're used when identifying the client to the server
and vice versa.

=item * PRIVATE_KEY_ID_STRING

A special ID string written to private key files; if
the ID string in the file doesn't match this, we stop
reading the private key file.

=item * MAX_PACKET_SIZE

The maximum size of a packet in the packet layer.

=back

=head1 AUTHOR & COPYRIGHTS

Please see the Net::SSH::Perl manpage for author, copyright,
and license information.

=cut
