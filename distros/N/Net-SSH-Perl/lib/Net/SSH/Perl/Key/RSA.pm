package Net::SSH::Perl::Key::RSA;
use strict;
use warnings;

use Crypt::PK::RSA;
use Net::SSH::Perl::Buffer;
use Net::SSH::Perl::Constants qw( SSH_COMPAT_BUG_RSASIGMD5 );
use Crypt::Misc qw( encode_b64 );
use Carp qw( croak );
use base qw( Net::SSH::Perl::Key );

my %dgst_map = (
    'ssh-rsa' => 'SHA1',
    'rsa-sha2-256' => 'SHA256',
    'rsa-sha2-512' => 'SHA512'
);

sub ssh_name {
    my $key = shift;
    my $name = shift;
    $key->{ssh_name} = $name if $name;
    return $key->{ssh_name} || 'ssh-rsa'
}

sub init {
    my $key = shift;
    $key->{rsa_priv} = Crypt::PK::RSA->new;
    $key->{rsa_pub}  = Crypt::PK::RSA->new;

    my($blob, $datafellows, $sig_algs) = @_;
    if ($blob) {
        my $b = Net::SSH::Perl::Buffer->new( MP => 'SSH2' );
        $b->append($blob);
        my $ktype = $b->get_str;
        croak __PACKAGE__, "->init: cannot handle type '$ktype'"
            unless $ktype eq $key->ssh_name;
        my $pubkey = $key->ssh_name . ' ' . encode_b64($blob);
        $key->{rsa_pub}->import_key( \$pubkey );
    }

    if ($datafellows) {
        $key->{datafellows} = $datafellows;
    }

    my @types;
    push @types, split(',',$sig_algs) if $sig_algs;
    push @types, 'ssh-rsa';
    foreach my $t (@types) {
        $key->ssh_name($t) if $key->{digest} = $dgst_map{$t};
        last if $key->{digest};
    }
}

sub keygen {
    my $class = shift;
    my($bits, $datafellows) = @_;
    my $key = __PACKAGE__->new(undef, $datafellows);
    $key->{rsa_priv} = Crypt::PK::RSA->new;
    $key->{rsa_priv}->generate_key($bits/8);
    $key->_pub_from_private;
    $key;
}

sub _pub_from_private {
    my $key = shift;

    my $hash = $key->{rsa_priv}->key2hash;
    $key->{rsa_pub}->import_key( {
        e => $hash->{e},
        N => $hash->{N}
    } );
}

sub size { eval { $_[0]->{rsa_pub}->size * 8 } }

sub read_private {
    my $class = shift;
    my($key_file, $passphrase, $datafellows, $sig_algs) = @_;

    my $key = __PACKAGE__->new(undef, $datafellows, $sig_algs);
    $key->{rsa_priv}->import_key($key_file, $passphrase);
    $key->_pub_from_private;
    $key;
}

sub write_private {
    my $key = shift;
    my($key_file, $passphrase, $cipher) = @_;

    my $pem = $key->{rsa_priv}->export_key_pem('private', $passphrase, $cipher) or return;
    open my $fh, '>', $key_file or croak "Can't write to $key_file: $!";
    print $fh $pem;
    close $fh or croak "Can't close $key_file: $!";
}

sub sign {
    my $key = shift;
    my($data) = @_;
    my $dgst ||= $key->{datafellows} && ${ $key->{datafellows} } & SSH_COMPAT_BUG_RSASIGMD5
		? 'MD5' : $key->{digest};

    my $sig = $key->{rsa_priv}->sign_message($data, $dgst,'v1.5') or return;

    my $buf = Net::SSH::Perl::Buffer->new( MP => 'SSH2' );
    $buf->put_str($key->ssh_name);
    $buf->put_str($sig);
    $buf->bytes;
}

sub verify {
    my $key = shift;
    my($signature, $data) = @_;

    my $b = Net::SSH::Perl::Buffer->new( MP => 'SSH2' );
    $b->append($signature);
    my $ktype = $b->get_str;
    my $sigblob = $b->get_str;
    my $dgst = $key->{datafellows} && ${ $key->{datafellows} } & SSH_COMPAT_BUG_RSASIGMD5 ?
        'MD5' : $dgst_map{$ktype};
    croak "Can't verify type ", $ktype unless $dgst;

    $key->{rsa_pub}->verify_message($sigblob, $data, $dgst,'v1.5');
}

sub equal {
    my($keyA, $keyB) = @_;

    return unless $keyA->{rsa_pub} && $keyB->{rsa_pub};
    my $hashA = eval { $keyA->{rsa_pub}->key2hash } or return;
    my $hashB = eval { $keyB->{rsa_pub}->key2hash } or return;

    return $hashA->{e} eq $hashB->{e} &&
           $hashA->{N} eq $hashB->{N};
}

sub as_blob {
    my $key = shift;
    my $b = Net::SSH::Perl::Buffer->new( MP => 'SSH2' );
    my $hash = defined $key->{rsa_pub} && $key->{rsa_pub}->key2hash;
    $b->put_str($key->ssh_name);
    my $e = substr('0',0,length($hash->{e}) % 2) . $hash->{e}; # prepend 0 if hex string is odd length, ie: 10001 (65537 decimal)
    $b->put_mp_int(pack('H*',$e));
    $b->put_mp_int(pack('H*',$hash->{N}));
    $b->bytes;
}

sub fingerprint_raw { $_[0]->as_blob }

1;
__END__

=head1 NAME

Net::SSH::Perl::Key::RSA - RSA key object

=head1 SYNOPSIS

    use Net::SSH::Perl::Key;
    my $key = Net::SSH::Perl::Key->new('RSA');

=head1 DESCRIPTION

I<Net::SSH::Perl::Key::RSA> subclasses I<Net::SSH::Perl::Key>
to implement a key object, SSH style. This object provides all
of the methods needed for a RSA key object; the underlying
implementation is provided by I<Crypt::PK::RSA>, and this class
wraps around that module to provide SSH-specific functionality
(eg. taking in a I<Net::SSH::Perl::Buffer> blob and transforming
it into a key object).

=head1 USAGE

I<Net::SSH::Perl::Key::RSA> implements the interface described in
the documentation for I<Net::SSH::Perl::Key>. Any differences or
additions are described here.

=head2 $key->sign($data)

Uses I<Crypt::PK::RSA> (CryptX module) to sign I<$data>
using the private key portion of I<$key>, then encodes that
signature into an SSH-compatible signature blob.

Returns the signature blob.

=head2 $key->verify($signature, $data)

Given a signature blob I<$signature> and the original signed data
I<$data>, attempts to verify the signature using the public key
portion of I<$key>. This uses I<Crypt::PK::RSA::verify_message>
to perform the core verification.

I<$signature> should be an SSH-compatible signature blob, as
returned from I<sign>; I<$data> should be a string of data, as
passed to I<sign>.

Returns true if the verification succeeds, false otherwise.

=head1 AUTHOR & COPYRIGHTS

Please see the Net::SSH::Perl manpage for author, copyright,
and license information.

=cut
