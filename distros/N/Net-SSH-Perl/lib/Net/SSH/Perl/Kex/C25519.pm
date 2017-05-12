package Net::SSH::Perl::Kex::C25519;
use strict;

use Net::SSH::Perl::Buffer;
use Net::SSH::Perl::Packet;
use Net::SSH::Perl::Constants qw( :msg2 :kex );
use Net::SSH::Perl::Key;

use Carp qw( croak );
use Crypt::Digest::SHA256 qw( sha256 );
use Scalar::Util qw(weaken);
use Crypt::PRNG qw( random_bytes );
use Crypt::Curve25519 qw( curve25519_secret_key
                          curve25519_public_key
                          curve25519_shared_secret );

use base qw( Net::SSH::Perl::Kex );

use constant CURVE25519_SIZE => 32;

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

    $ssh->debug('Generating ephemeral key pair.');
    my $rand = random_bytes(CURVE25519_SIZE);
    my $c_sec_key = curve25519_secret_key($rand);
    my $c_pub_key = curve25519_public_key($c_sec_key);

    $ssh->debug('Entering Curve 25519 Key Exchange.');
    $packet = $ssh->packet_start(SSH2_MSG_KEX_ECDH_INIT);
    $packet->put_str($c_pub_key);
    $packet->send;

    $ssh->debug('Sent client public key, waiting for reply.');
    $packet = Net::SSH::Perl::Packet->read_expect($ssh,
        SSH2_MSG_KEX_ECDH_REPLY);

    my $host_key_blob = $packet->get_str;
    my $s_host_key = Net::SSH::Perl::Key->new_from_blob($host_key_blob);
    $ssh->debug("Received host key, type '" . $s_host_key->ssh_name . "'.");

    $ssh->check_host_key($s_host_key);

    my $s_pub_key = $packet->get_str;
    my $signature = $packet->get_str;
    my $shared_secret = curve25519_shared_secret($c_sec_key, $s_pub_key);

    my $hash = $kex->kex_hash(
        $ssh->client_version_string,
        $ssh->server_version_string,
        $kex->client_kexinit,
        $kex->server_kexinit,
        $host_key_blob,
        $c_pub_key,
        $s_pub_key,
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
       $c_pub_key, $s_pub_key, $shared_secret) = @_;
    my $b = Net::SSH::Perl::Buffer->new( MP => 'SSH2' );
    # version strings (V_C, V_S)
    $b->put_str($c_vs);
    $b->put_str($s_vs);
    # client,server payload of SSH_MSG_KEXINIT (I_C, I_S)
    $b->put_int32($c_kexinit->length + 1);
    $b->put_int8(SSH2_MSG_KEXINIT);
    $b->put_chars($c_kexinit->bytes);
    $b->put_int32($s_kexinit->length + 1);
    $b->put_int8(SSH2_MSG_KEXINIT);
    $b->put_chars($s_kexinit->bytes);
    # host key (K_S)
    $b->put_str($s_host_key_blob);
    # Q_C, Q_S, H
    $b->put_str($c_pub_key);
    $b->put_str($s_pub_key);
    $b->put_bignum2_bytes($shared_secret);

    sha256($b->bytes);
}

sub derive_key {
    my($kex, $id, $need, $hash, $shared_secret, $session_id) = @_;
    my $b = Net::SSH::Perl::Buffer->new( MP => 'SSH2' );
    $b->put_bignum2_bytes($shared_secret);
    my $digest = sha256($b->bytes, $hash, chr($id), $session_id);
    for (my $have = 32; $need > $have; $have += 32) {
        $digest .= sha256($b->bytes, $hash, $digest);
    }
    $digest;
}

1;
__END__

=head1 NAME

Net::SSH::Perl::Kex::C25519 - Elliptical Curve 25519 Key Exchange
using SHA256 hashing.

=head1 SYNOPSIS

    use Net::SSH::Perl::Kex;
    my $kex = Net::SSH::Perl::Kex->new;
    my $dh = bless $kex, 'Net::SSH::Perl::Kex::C25519';

    $dh->exchange;

=head1 DESCRIPTION

I<Net::SSH::Perl::Kex::C25519> implements the curve25519-sha256@libssh.org
key exchange protocol for I<Net::SSH::Perl>. It is a subclass of
I<Net::SSH::Perl::Kex>.

=head1 AUTHOR & COPYRIGHTS

Lance Kinley E<lkinley@loyaltymethods.com>

Copyright (c) 2015 Loyalty Methods, Inc.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
