#!/usr/bin/perl

package Net::Server::Framework::Crypt;

use strict;
use warnings;
use Carp;
use Switch;
use Crypt::CBC;
use MIME::Base64;
use Digest::MD5 qw(md5_hex);

our ($VERSION) = '1.0';

sub encrypt {
    my ( $message, $key, $type, $ascii ) = @_;

    my $cipher;
    $key = 'CHANGE THIS KEY TO SOMETHING SECRET!'
      unless defined $key;
    $type = 'blowfish' unless defined $type;
    switch ($type) {
        case "blowfish" { $cipher = 'Blowfish'; }
    }
    my $c = Crypt::CBC->new(
        -key    => $key,
        -cipher => $cipher,
    );
    my $enc = $c->encrypt($message);
    return $enc
      unless defined $ascii;
    return encode_base64($enc);

}

sub decrypt {
    my ( $message, $key, $type, $ascii ) = @_;

    my $cipher;
    $type = 'blowfish' unless defined $type;
    $key = 'CHANGE THIS KEY TO SOMETHING SECRET!'
      unless defined $key;
    switch ($type) {
        case "blowfish" { $cipher = 'Blowfish'; }
    }
    my $c = Crypt::CBC->new(
        -key    => $key,
        -cipher => $cipher,
    );
    return $c->decrypt($message)
      unless defined $ascii;
    return $c->decrypt( decode_base64($message) );
}

sub hash {
    my $message = shift;

    return md5_hex($message);
}

1;

=head1 NAME

Net::Server::Framework::Crypt - a wrapper for several encryption libs


=head1 VERSION

This documentation refers to C<Net::Server::Framework::Crypt> version 1.0.


=head1 SYNOPSIS

A typical invocation looks like this:
    my $token = Net::Server::Framework::Crypt::encrypt( $string, $pass, 'blowfish', 'a' );

=head1 DESCRIPTION

This library currently supports only blowfish as encryption algorithm
but extending it is easy. It is used to hash passwords and en/decrypt
information that should be stored securely.

=head1 BASIC METHODS

The commands accepted by the lib are: 

=head2 encrypt

Encrypts a string.

=head2 decrypt

Decrypts a string

=head2 hash

Hashes a string

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Please report problems to 
Lenz Gschwendtner ( <lenz@springtimesoft.com> )
Patches are welcome.

=head1 AUTHOR

Lenz Gschwendtner ( <lenz@springtimesoft.com> )



=head1 LICENCE AND COPYRIGHT

Copyright (c) 
2007 Lenz Gschwerndtner ( <lenz@springtimesoft.comn> )
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
