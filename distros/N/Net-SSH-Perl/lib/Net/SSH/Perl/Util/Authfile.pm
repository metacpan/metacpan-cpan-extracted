# $Id: Authfile.pm,v 1.6 2008/10/02 20:46:17 turnstep Exp $

package Net::SSH::Perl::Util::Authfile;
use strict;
use warnings;

use Net::SSH::Perl::Buffer;
use Net::SSH::Perl::Constants qw( PRIVATE_KEY_ID_STRING );
use Net::SSH::Perl::Cipher;
use Net::SSH::Perl::Key;

use Carp qw( croak );

sub _load_public_key {
    _load_private_key($_[0], '', 1);
}

sub _load_private_key {
    my($key_file, $passphrase, $want_public) = @_;
    $passphrase ||= '';

    open my $fh, '<', $key_file or croak "Can't open $key_file: $!";
    my $c = do { local $/; <$fh> };
    close $fh or die "Can't close $key_file: $!";
    ($c) = $c =~ /(.*)/s;  ## Untaint data. Anything is allowed.

    my $buffer = Net::SSH::Perl::Buffer->new( MP => 'SSH1' );
    $buffer->append($c);

    my $id = $buffer->bytes(0, length(PRIVATE_KEY_ID_STRING), "");
    croak "Bad key file $key_file." unless $id eq PRIVATE_KEY_ID_STRING;
    $buffer->bytes(0, 1, "");

    my $cipher_type = $buffer->get_int8;
    $buffer->get_int32;  ## Reserved data.

    my $key = Net::SSH::Perl::Key->new('RSA1');
    $key->{rsa}{bits} = $buffer->get_int32;
    $key->{rsa}{n} = $buffer->get_mp_int;
    $key->{rsa}{e} = $buffer->get_mp_int;

    my $comment = $buffer->get_str;

    if ($want_public) {
        return wantarray ? ($key, $comment) : ($key);
    }

    my $cipher_name = Net::SSH::Perl::Cipher::name($cipher_type);
    unless (Net::SSH::Perl::Cipher::supported($cipher_type)) {
        croak sprintf "Unsupported cipher '%s' used in key file '%s'",
            $cipher_name, $key_file;
    }

    my $ciph =
        Net::SSH::Perl::Cipher->new_from_key_str($cipher_name, $passphrase);
    my $decrypted = $ciph->decrypt($buffer->bytes($buffer->offset));
    $buffer->empty;
    $buffer->append($decrypted);

    my $check1 = ord $buffer->get_char;
    my $check2 = ord $buffer->get_char;
    if ($check1 != ord($buffer->get_char) ||
        $check2 != ord($buffer->get_char)) {
        croak "Bad passphrase supplied for key file $key_file";
    }

    $key->{rsa}{d} = $buffer->get_mp_int;
    $key->{rsa}{u} = $buffer->get_mp_int;
    $key->{rsa}{p} = $buffer->get_mp_int;
    $key->{rsa}{q} = $buffer->get_mp_int;

    wantarray ? ($key, $comment) : $key;
}

sub _save_private_key {
    my($key_file, $key, $passphrase, $comment) = @_;
    $passphrase ||= '';

    my $cipher_type = $passphrase eq '' ? 'None' : 'DES3';

    my $buffer = Net::SSH::Perl::Buffer->new( MP => 'SSH1' );
    my($check1, $check2);
    $buffer->put_int8($check1 = int rand 255);
    $buffer->put_int8($check2 = int rand 255);
    $buffer->put_int8($check1);
    $buffer->put_int8($check2);

    $buffer->put_mp_int($key->{rsa}{d});
    $buffer->put_mp_int($key->{rsa}{u});
    $buffer->put_mp_int($key->{rsa}{p});
    $buffer->put_mp_int($key->{rsa}{q});

    $buffer->put_int8(0)
        while $buffer->length % 8;

    my $encrypted = Net::SSH::Perl::Buffer->new( MP => 'SSH1' );
    $encrypted->put_chars(PRIVATE_KEY_ID_STRING);
    $encrypted->put_int8(0);
    $encrypted->put_int8(Net::SSH::Perl::Cipher::id($cipher_type));
    $encrypted->put_int32(0);

    $encrypted->put_int32($key->{rsa}{bits});
    $encrypted->put_mp_int($key->{rsa}{n});
    $encrypted->put_mp_int($key->{rsa}{e});
    $encrypted->put_str($comment || '');

    my $cipher =
        Net::SSH::Perl::Cipher->new_from_key_str($cipher_type, $passphrase);
    $encrypted->append( $cipher->encrypt($buffer->bytes) );

    open my $fh, '>', $key_file or croak "Can't open $key_file: $!";
    print $fh $encrypted->bytes;
    close $fh or croak "Can't close $key_file: $!";
}

1;
