package Net::SSH::Perl::Key::DSA;
use strict;
use warnings;

use Net::SSH::Perl::Buffer;
use Net::SSH::Perl::Constants qw( SSH_COMPAT_BUG_SIGBLOB );

use Net::SSH::Perl::Key;
use base qw( Net::SSH::Perl::Key );

use Crypt::Misc qw( encode_b64 );
use Crypt::PK::DSA;
use Carp qw( croak );

use constant INTBLOB_LEN => 20;

sub ssh_name { 'ssh-dss' }

sub init {
    my $key = shift;
    $key->{dsa} = Crypt::PK::DSA->new;

    my($blob, $datafellows) = @_;

    if ($blob) {
        my $b = Net::SSH::Perl::Buffer->new( MP => 'SSH2' );
        $b->append($blob);
        my $ktype = $b->get_str;
        croak __PACKAGE__, "->init: cannot handle type '$ktype'"
            unless $ktype eq $key->ssh_name;
        my $pubkey = $key->ssh_name . ' ' . encode_b64($b->bytes);
        $key->{dsa}->import_key( \$pubkey );
    }

    if ($datafellows) {
        $key->{datafellows} = $datafellows;
    }
}

sub keygen {
    my $class = shift;
    my($bits, $datafellows) = @_;
    my $key = __PACKAGE__->new(undef, $datafellows);
    $key->{dsa} = Crypt::PK::DSA->new;
    $key->{dsa}->generate_key($bits/8);
    $key;
}

sub size { eval { $_[0]->{dsa}->size * 8 } }

sub read_private {
    my $class = shift;
    my($key_file, $passphrase, $datafellows, $keytype) = @_;
    $keytype ||= 'PEM';

    my $key = __PACKAGE__->new(undef, $datafellows);
    $key->{dsa}->import_key($key_file, $passphrase);
    $key;
}

sub write_private {
    my $key = shift;
    my($key_file, $passphrase) = @_;

    my $pem = $key->{dsa}->export_key_pem('private', $passphrase) or return;
    open my $fh, '>', $key_file or croak "Can't write to $key_file: $!";
    print $fh $pem;
    close $fh or croak "Can't close $key_file: $!";
}

sub sign {
    my $key = shift;
    my($data) = @_;
    my $dersig = $key->{dsa}->sign_message($data); # returns a DER ASN.1 formatted r,s
    # decode DER ASN.1 signature
    return unless ord(substr($dersig,0,1,'')) == 48; # type SEQUENCE
    my $derlen = ord(substr($dersig,0,1,''));
    return unless ord(substr($dersig,0,1,'')) == 2; # Type INTEGER
    my $intlen = ord(substr($dersig,0,1,''));
    my $r = substr($dersig,0,$intlen,'');
    # numbers with highest bit set are padded with leading zero so strip it
    $r = substr($r,$intlen - INTBLOB_LEN) if $intlen > INTBLOB_LEN;
    return unless ord(substr($dersig,0,1,'')) == 2; # Type INTEGER
    $intlen = ord(substr($dersig,0,1,''));
    my $s = substr($dersig,0,$intlen,'');
    $s = substr($s,$intlen - INTBLOB_LEN) if $intlen > INTBLOB_LEN;

    $r = "\0" x (INTBLOB_LEN-length($r)) . $r;
    $s = "\0" x (INTBLOB_LEN-length($s)) . $s;
    my $sigblob = $r . $s;

    if ($key->{datafellows} && ${$key->{datafellows}} & SSH_COMPAT_BUG_SIGBLOB) {
        return $sigblob;
    }
    my $b = Net::SSH::Perl::Buffer->new( MP => 'SSH2' );
    $b->put_str($key->ssh_name);
    $b->put_str($sigblob);
    $b->bytes;
}

sub verify {
    my $key = shift;
    my($signature, $data) = @_;
    my $sigblob;

    if ($key->{datafellows} && ${$key->{datafellows}} & SSH_COMPAT_BUG_SIGBLOB) {
        $sigblob = $signature;
    }
    else {
        my $b = Net::SSH::Perl::Buffer->new( MP => 'SSH2' );
        $b->append($signature);
        my $ktype = $b->get_str;
        croak "Can't verify type ", $ktype unless $ktype eq $key->ssh_name;
        $sigblob = $b->get_str;
    }
    # convert to ASN.1 DER format
    my $r = substr($sigblob,0,INTBLOB_LEN);
    # remove leading zeros
    substr($r,0,1,'') until ord(substr($r,0,1));
    # pad $r with leading zero if highest bit set
    $r = "\0" . $r if ord(substr($r,0,1)) & 0x80;
    my $s = substr($sigblob,INTBLOB_LEN);
    # remove leading zeros
    substr($s,0,1,'') until ord(substr($s,0,1));
    # pad $s with leading zero if highest bit set
    $s = "\0" . $s if ord(substr($s,0,1)) & 0x80;
    my $ints = chr(2) . chr(length($r)) . $r .
               chr(2) . chr(length($s)) . $s;
    my $dersig = chr(48) . chr(length($ints)) . $ints;

    $key->{dsa}->verify_message($dersig, $data);
}

sub equal {
    my($keyA, $keyB) = @_;

    return unless $keyA->{dsa} && $keyB->{dsa};
    my $hashA = eval { $keyA->{dsa}->key2hash } or return;
    my $hashB = eval { $keyB->{dsa}->key2hash } or return;

    return $hashA->{p} eq $hashB->{p} &&
           $hashA->{q} eq $hashB->{q} &&
           $hashA->{g} eq $hashB->{g} &&
           $hashA->{y} eq $hashB->{y};
}

sub as_blob {
    my $key = shift;
    my $b = Net::SSH::Perl::Buffer->new( MP => 'SSH2' );
    my $hash = $key->{dsa}->key2hash or return;
    $b->put_str($key->ssh_name);
    $b->put_bignum2_bytes(pack('H*',$hash->{p}));
    $b->put_bignum2_bytes(pack('H*',$hash->{q}));
    $b->put_bignum2_bytes(pack('H*',$hash->{g}));
    $b->put_bignum2_bytes(pack('H*',$hash->{y}));
    $b->bytes;
}

sub fingerprint_raw { $_[0]->as_blob }

1;
__END__

=head1 NAME

Net::SSH::Perl::Key::DSA - DSA key object

=head1 SYNOPSIS

    use Net::SSH::Perl::Key;
    my $key = Net::SSH::Perl::Key->new('DSA');

=head1 DESCRIPTION

I<Net::SSH::Perl::Key::DSA> subclasses I<Net::SSH::Perl::Key>
to implement a key object, SSH style. This object provides all
of the methods needed for a DSA key object; the underlying
implementation is provided by I<Crypt::PK::DSA>, and this class
wraps around that module to provide SSH-specific functionality
(eg. taking in a I<Net::SSH::Perl::Buffer> blob and transforming
it into a key object).

=head1 USAGE

I<Net::SSH::Perl::Key::DSA> implements the interface described in
the documentation for I<Net::SSH::Perl::Key>. Any differences or
additions are described here.

=head2 $key->sign($data)

Wraps around I<Crypt::PK::DSA::sign_message> to sign I<$data> using
the key I<$key>, then encodes that signature into an SSH-compatible
signature blob.  The output of I<Crypt::PK::DSA::sign_message> is a
DER ASN.1 binary structure, so that must be decoded to extract the
components of the signature.

Returns the signature blob.

=head2 $key->verify($signature, $data)

Given a signature blob I<$signature> and the original signed data
I<$data>, attempts to verify the signature using the key I<$key>.
This wraps around I<Crypt::PK::DSA::verify_message> to perform the
core verification.  Since I<Crypt::PK::DSA::verify_message> requires
a signature in DER ASN.1 format, the signature is reconfigured to
that before being passed.

I<$signature> should be an SSH-compatible signature blob, as
returned from I<sign>; I<$data> should be a string of data, as
passed to I<sign>.

Returns true if the verification succeeds, false otherwise.

=head1 AUTHOR & COPYRIGHTS

Please see the Net::SSH::Perl manpage for author, copyright,
and license information.

=cut
