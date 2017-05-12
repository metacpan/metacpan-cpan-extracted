package Net::SSH::Perl::Key::ECDSA;
use strict;
use warnings;

use Net::SSH::Perl::Buffer;

use base qw( Net::SSH::Perl::Key );

use Crypt::Misc qw( encode_b64 );
use Crypt::PK::ECC;
use Carp qw( croak );

sub init {
    my $key = shift;
    $key->{ecdsa} = Crypt::PK::ECC->new;

    my($blob) = @_;

    if ($blob) {
        my $b = Net::SSH::Perl::Buffer->new( MP => 'SSH2' );
        $b->append($blob);
        my $ktype = $b->get_str;
        croak __PACKAGE__, "->init: cannot handle type '$ktype'"
            unless $ktype eq $key->ssh_name;
        my $pubkey = $key->ssh_name . ' ' . encode_b64($b->bytes);
        $key->{ecdsa}->import_key( \$pubkey );
    }
}

sub keygen {
    my $class = shift;
    my($bits) = @_;
    my $key = $class->new;
    $key->{ecdsa} = Crypt::PK::ECC->new;
    my $curve = 'nistp' . $bits;
    $key->{ecdsa}->generate_key($curve) or return;
    $key;
}

sub size { eval { $_[0]->{ecdsa}->size * 8 } }

sub read_private {
    my $class = shift;
    my($key_file, $passphrase) = @_;

    my $key = $class->new;
    $key->{ecdsa}->import_key($key_file, $passphrase);
    my $bits = $key->{ecdsa}->key2hash->{curve_bits};
    my $newclass = __PACKAGE__ . $bits;
    eval "use $newclass;";
    die "Key class '$class' could not be loaded: $@" if $@;
    bless $key, $newclass;
}

sub write_private {
    my $key = shift;
    my($key_file, $passphrase) = @_;

    my $pem = $key->{ecdsa}->export_key_pem('private', $passphrase) or return;
    open my $fh, '>', $key_file or croak "Can't write to $key_file: $!";
    print $fh $pem;
    close $fh or croak "Can't close $key_file: $!";
}

sub sign {
    my $key = shift;
    my($data) = @_;
    my $sig = $key->{ecdsa}->sign_message_rfc7518($data, $key->digest); # returns a DER ASN.1 formatted r,s

    my $len = length($sig) / 2;
    my $r = substr($sig, 0, $len);
    my $s = substr($sig, $len);

    my $b = Net::SSH::Perl::Buffer->new( MP => 'SSH2' );
    my $bb = Net::SSH::Perl::Buffer->new( MP => 'SSH2' );
    $b->put_str($key->ssh_name);
    $bb->put_bignum2_bytes($r);
    $bb->put_bignum2_bytes($s);
    $b->put_str($bb->bytes);
    $b->bytes;
}

sub verify {
    my $key = shift;
    my($signature, $data) = @_;

    my $b = Net::SSH::Perl::Buffer->new( MP => 'SSH2' );
    $b->append($signature);
    my $ktype = $b->get_str;
    croak "Can't verify type ", $ktype unless $ktype eq $key->ssh_name;

    my $bb = Net::SSH::Perl::Buffer->new( MP => 'SSH2' );
    $bb->append($b->get_str);
    my $r = $bb->get_bignum2_bytes;
    my $s = $bb->get_bignum2_bytes;

    $r = "\0" x ($key->siglen - length($r)) . $r;
    $s = "\0" x ($key->siglen - length($s)) . $s;
    my $sig = $r . $s;

    $key->{ecdsa}->verify_message_rfc7518($sig, $data, $key->digest);
}

sub equal {
    my($keyA, $keyB) = @_;

    return unless $keyA->{ecdsa} && $keyB->{ecdsa};
    my $hashA = eval { $keyA->{ecdsa}->key2hash } or return;
    my $hashB = eval { $keyB->{ecdsa}->key2hash } or return;

    return $hashA->{k} eq $hashB->{k} &&
           $hashA->{pub_x} eq $hashB->{pub_x} &&
           $hashA->{pub_y} eq $hashB->{pub_y} &&
           $hashA->{curve_A} eq $hashB->{curve_A} &&
           $hashA->{curve_B} eq $hashB->{curve_B} &&
           $hashA->{curve_Gx} eq $hashB->{curve_Gx} &&
           $hashA->{curve_Gy} eq $hashB->{curve_Gy} &&
           $hashA->{curve_order} eq $hashB->{curve_order} &&
           $hashA->{curve_prime} eq $hashB->{curve_prime};
}

sub as_blob {
    my $key = shift;
    my $b = Net::SSH::Perl::Buffer->new( MP => 'SSH2' );
    my $name = $key->ssh_name;
    my $id = $name;
    $id =~ s/^ecdsa-sha2-//;
    $b->put_str($name);
    $b->put_str($id);
    $b->put_str($key->{ecdsa}->export_key_raw('public'));
    $b->bytes;
}

sub fingerprint_raw { $_[0]->as_blob }

1;
__END__

=head1 NAME

Net::SSH::Perl::Key::ECDSA - Elliptical Curve DSA key object base class

=head1 SYNOPSIS

    use Net::SSH::Perl::Key;
    my $key = Net::SSH::Perl::Key->new('ECDSA521');

=head1 DESCRIPTION

I<Net::SSH::Perl::Key::ECDSA> subclasses I<Net::SSH::Perl::Key>
to implement the base class of an elliptical curve DSA key object.
The underlying implementation is provided by I<Crypt::PK::ECC>, and
this class wraps around that module to provide SSH-specific functionality
(eg. taking in a I<Net::SSH::Perl::Buffer> blob and transforming
it into a key object).

=head1 USAGE

I<Net::SSH::Perl::Key::ECDSA> implements the interface described in
the documentation for I<Net::SSH::Perl::Key>. Any differences or
additions are described here.

=head2 $key->read_private($file [, $passphrase])

Since this class is a base class, the read_private method reblesses
to the subclass based on the key type loaded.

=head2 $key->sign($data)

Wraps around I<Crypt::PK::ECC::sign_message> to sign I<$data> using
the key I<$key>, then encodes that signature into an SSH-compatible
signature blob.

Returns the signature blob.

=head2 $key->verify($signature, $data)

Given a signature blob I<$signature> and the original signed data
I<$data>, attempts to verify the signature using the key I<$key>.
This wraps around I<Crypt::PK::ECC::verify_message> to perform the
core verification.

I<$signature> should be an SSH-compatible signature blob, as
returned from I<sign>; I<$data> should be a string of data, as
passed to I<sign>.

Returns true if the verification succeeds, false otherwise.

=head1 AUTHOR & COPYRIGHTS

Lance Kinley E<lkinley@loyaltymethods.com>

Copyright (c) 2016 Loyalty Methods, Inc.

=cut
