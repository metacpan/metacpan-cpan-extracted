package Net::SSH::Perl::Kex::DH;
use strict;
use warnings;

use Net::SSH::Perl::Buffer;
use Net::SSH::Perl::Packet;
use Net::SSH::Perl::Constants qw( :msg2 :kex );
use Net::SSH::Perl::Key;

use Carp qw( croak );
use Scalar::Util qw(weaken);

use base qw( Net::SSH::Perl::Kex );

sub new {
    my $class = shift;
    my $ssh = shift;
    my $kex = bless { ssh => $ssh }, $class;
    weaken $kex->{ssh};
    $kex;
}

sub exchange {
    my $kex = shift;
    my $ssh = $kex->{ssh};
    my $packet;

    $ssh->debug('Generating new Diffie-Hellman Group ' . $kex->group . ' keys');
    my $dh = $kex->_dh_new_group();

    $ssh->debug('Entering Diffie-Hellman Group ' . $kex->group . ' key exchange.');
    $packet = $ssh->packet_start(SSH2_MSG_KEXDH_INIT);
    my $pub_key = $dh->export_key_raw('public');
    $packet->put_mp_int($pub_key);
    $packet->send;

    $ssh->debug("Sent DH public key, waiting for reply.");
    $packet = Net::SSH::Perl::Packet->read_expect($ssh,
        SSH2_MSG_KEXDH_REPLY);

    my $host_key_blob = $packet->get_str;
    my $s_host_key = Net::SSH::Perl::Key->new_from_blob($host_key_blob,
        \$ssh->{datafellows});
    $ssh->debug("Received host key, type '" . $s_host_key->ssh_name . "'.");

    $ssh->check_host_key($s_host_key);

    my $dh_server_pub = $packet->get_mp_int;
    my $signature = $packet->get_str;

    my $dh_server_pub_key = Crypt::PK::DH->new;
    # create public key object (which will also check the public key for validity)
    $dh_server_pub_key->import_key_raw($dh_server_pub, 'public', $dh->params2hash);

    $ssh->debug("Computing shared secret key.");
    my $shared_secret = $dh->shared_secret($dh_server_pub_key);

    my $hash = $kex->kex_hash(
        $ssh->client_version_string,
        $ssh->server_version_string,
        $kex->client_kexinit,
        $kex->server_kexinit,
        $host_key_blob,
        $pub_key,
        $dh_server_pub,
        $shared_secret);

    $ssh->debug("Verifying server signature.");
    croak "Key verification failed for server host key"
        unless $s_host_key->verify($signature, $hash);

    $ssh->session_id($hash);

    $kex->derive_keys($hash, $shared_secret, $ssh->session_id);
}

sub kex_hash {
    my $kex = shift;
    my($c_vs, $s_vs, $c_kexinit, $s_kexinit, $s_host_key_blob,
       $c_dh_pub, $s_dh_pub, $shared_secret) = @_;
    my $b = Net::SSH::Perl::Buffer->new( MP => 'SSH2' );
    $b->put_str($c_vs);
    $b->put_str($s_vs);

    $b->put_int32($c_kexinit->length + 1);
    $b->put_int8(SSH2_MSG_KEXINIT);
    $b->put_chars($c_kexinit->bytes);
    $b->put_int32($s_kexinit->length + 1);
    $b->put_int8(SSH2_MSG_KEXINIT);
    $b->put_chars($s_kexinit->bytes);

    $b->put_str($s_host_key_blob);
    $b->put_mp_int($c_dh_pub);
    $b->put_mp_int($s_dh_pub);
    $b->put_mp_int($shared_secret);

    $kex->hash($b->bytes);
}

sub derive_key {
    my($kex, $id, $need, $hash, $shared_secret, $session_id) = @_;
    my $b = Net::SSH::Perl::Buffer->new( MP => 'SSH2' );
    $b->put_mp_int($shared_secret);
    my $digest = $kex->hash($b->bytes, $hash, chr($id), $session_id);
    for (my $have = $kex->hash_len; $need > $have; $have += $kex->hash_len) {
        $digest .= $kex->hash($b->bytes, $hash, $digest);
    }
    $digest;
}

1;
__END__

=head1 NAME

Net::SSH::Perl::Kex::DH - Diffie-Hellman Group Agnostic Key Exchange

=head1 SYNOPSIS

    # This class should not be used directly, but rather as a base for DH1,
    # DH14SHA1, DH16SHA512, etc

    use Net::SSH::Perl::Kex::DH;
    use base qw( Net::SSH::Perl::Kex::DH );

    # Simply implement _dh_new_group and return the Crypt::DH group
    sub _dh_new_group {
        my $kex = shift;
        ...
        $dh;
    }

=head1 DESCRIPTION

I<Net::SSH::Perl::Kex::DH> implements Diffie-Hellman Group Agnostic
Exchange for I<Net::SSH::Perl>. It is a subclass of
I<Net::SSH::Perl::Kex>.

Key Exchange uses the Diffie-Hellman key exchange algorithm
to produce a shared secret key between client and server, without
ever sending the shared secret over the insecure network. All that is
sent are the client and server public keys.

=head1 AUTHOR & COPYRIGHTS

Please see the Net::SSH::Perl manpage for author, copyright, and
license information.

=cut
