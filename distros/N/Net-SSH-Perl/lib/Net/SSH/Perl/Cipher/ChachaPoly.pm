package Net::SSH::Perl::Cipher::ChachaPoly;

use strict;

use Net::SSH::Perl::Cipher;
use base qw( Net::SSH::Perl::Cipher );
use Carp qw( croak );

use constant POLY1305_KEYLEN => 32;
use constant ONE => chr(1) . "\0" x 7; # NB little endian
use constant AADLEN => 4;

unless (grep /^Net::SSH::Perl$/, @DynaLoader::dl_modules) {
	use XSLoader;
	XSLoader::load('Net::SSH::Perl');
}

sub new {
    my $class = shift;
    my $ciph = bless { }, $class;
    $ciph->init(@_) if @_;
    $ciph;
}

sub keysize { 64 }
sub blocksize { 8 }
sub authlen { 16 }
sub ivlen { 0 }

sub init {
    my $ciph = shift;
    my $key = shift;

    my $size = $ciph->keysize/2;
    my $mainkey = substr($key,0,$size);
    my $headerkey = substr($key,$size,$size);
    $ciph->{main} = Crypt::OpenSSH::ChachaPoly->new($mainkey);
    $ciph->{header} = Crypt::OpenSSH::ChachaPoly->new($headerkey);
}

sub _seqnr_bytes {
    my ($ciph, $seqnr) = @_;
    pack('N',0) . pack('N',$seqnr); # seqnr is only 32-bit
}

sub encrypt {
    my($ciph, $data, $seqnr, $aadlen) = @_;
    $aadlen ||= 0;

    # run chacha20 once to generate poly1305 key
    # the iv is the packet sequence number
    $seqnr = $ciph->_seqnr_bytes($seqnr);
    $ciph->{main}->ivsetup($seqnr,'');
    my $poly_key = "\0" x POLY1305_KEYLEN;
    $poly_key = $ciph->{main}->encrypt($poly_key);

    my $aadenc;
    if ($aadlen) {
        # encrypt packet length from first four bytes of data
        $ciph->{header}->ivsetup($seqnr,'');
        $aadenc = $ciph->{header}->encrypt(substr($data,0,$aadlen));
    }

    # set chacha's block counter to 1
    $ciph->{main}->ivsetup($seqnr,ONE);
    my $enc = $aadenc . $ciph->{main}->encrypt(substr($data,$aadlen));
    $enc .= $ciph->{main}->poly1305($enc,$poly_key);
    return $enc;
}

sub decrypt {
    my($ciph, $data, $seqnr, $aadlen) = @_;

    # run chacha20 once to generate poly1305 key
    # the iv is the packet sequence number
    $seqnr = $ciph->_seqnr_bytes($seqnr);
    $ciph->{main}->ivsetup($seqnr,'');
    my $poly_key = "\0" x POLY1305_KEYLEN;
    $poly_key = $ciph->{main}->encrypt($poly_key);

    my $datalen = length($data) - $ciph->authlen;
    if ($aadlen) {
        $datalen = unpack('N', $ciph->{length} ||
            eval {
                $ciph->{header}->ivsetup($seqnr,'');
                $ciph->{header}->decrypt(substr($data,0,$aadlen))
            });
    }
    delete $ciph->{length};

    # check tag before decrypting packet
    my $expected_tag = $ciph->{main}->poly1305(substr($data,0,$aadlen+$datalen),
                                               $poly_key);
    my $tag = substr($data,$aadlen+$datalen,$ciph->authlen);
    croak "Invalid poly1305 tag"
        if $expected_tag ne $tag;

    # set chacha's block counter to 1
    $ciph->{main}->ivsetup($seqnr,ONE);
    # return payload only
    $ciph->{main}->decrypt(substr($data,$aadlen,$datalen));
}

sub get_length {
    my($ciph, $data, $seqnr) = @_;

    return if length($data) < AADLEN;
    $seqnr = $ciph->_seqnr_bytes($seqnr);
    $ciph->{header}->ivsetup($seqnr,'');
    # save it so we do not have to decrypt again later in decrypt()
    $ciph->{length} = $ciph->{header}->decrypt(substr($data,0,AADLEN));
}

1;
__END__

=head1 NAME

Net::SSH::Perl::Cipher::ChachaPoly - provides Chacha20 encryption
with Poly1305 Authentication support for I<Net::SSH::Perl>.

=head1 SYNOPSIS

    use Net::SSH::Perl::Cipher;
    my $eight_byte_iv = pack('N',0) . pack('N',1);
    my $eight_byte_counter = chr(1) . 7 x "\0"; # little endian

    my $cipher = Net::SSH::Perl::Cipher->new('ChachaPoly', $key);

    # generate poly key
    $cipher->ivsetup($eight_byte_iv,undef);
    my $poly_key = "\0" x POLY1305_KEYLEN; # 32 byte key
    $poly_key = $ciph->encrypt($poly_key);

    $cipher->ivsetup($eight_byte_iv,$eight_byte_counter);
    my $enc = $cipher->encrypt($plaintext);
    my $tag = $cipher->poly1305($enc,$poly_key);

=head1 DESCRIPTION

I<Net::SSH::Perl::Cipher::Chacha> provides Chacha20 encryption
with Poly1305 support for I<Net::SSH::Perl>.

This module requires I<Crypt::OpenSSH::ChachaPoly> which provides
a wrapper to the OpenSSH Chacha and Poly1305 functions.

=head1 AUTHOR & COPYRIGHTS

Lance Kinley E<lkinley@loyaltymethods.com>

Copyright (c) 2015 Loyalty Methods, Inc.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
