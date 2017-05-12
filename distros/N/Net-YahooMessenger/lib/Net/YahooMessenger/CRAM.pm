package Net::YahooMessenger::CRAM;

use Digest::MD5 qw(md5);
use vars qw($VERSION);
$VERSION = '0.02';
use strict;

use constant MD5_CRYPT_MAGIC_STRING => '$1$';
use constant I_TO_A64 =>
  './0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';

sub new {
    my $class = shift;
    bless {
        challenge_string => '',
        id               => '',
        password         => '',
    }, $class;
}

sub set_challenge_string {
    my $self = shift;
    $self->{challenge_string} = shift;
}

sub set_id {
    my $self = shift;
    $self->{id} = shift;
}

sub set_password {
    my $self = shift;
    $self->{password} = shift;
}

sub get_response_strings {
    my $self             = shift;
    my $id               = $self->{id};
    my $password         = $self->{password};
    my @challenge_string = split //, $self->{challenge_string};

    return undef unless scalar @challenge_string;

    my $password_hash = _to_yahoo_base64( md5($password) );
    my $crypt_hash =
      _to_yahoo_base64( md5( _md5_crypt( $password, '_2S43d5f' ) ) );

    my $hash_string_p;
    my $hash_string_c;

    my $sv = ord( $challenge_string[15] ) % 8;
    if ( $sv == 1 || $sv == 6 ) {
        my $checksum = $challenge_string[ ord( $challenge_string[9] ) % 16 ];
        $hash_string_p = sprintf '%s%s%s%s',
          $checksum, $id, join( '', @challenge_string ), $password_hash;
        $hash_string_c = sprintf '%s%s%s%s',
          $checksum, $id, join( '', @challenge_string ), $crypt_hash;
    }
    elsif ( $sv == 2 || $sv == 7 ) {
        my $checksum = $challenge_string[ ord( $challenge_string[15] ) % 16 ];
        $hash_string_p = sprintf '%s%s%s%s',
          $checksum, join( '', @challenge_string ), $password_hash, $id;
        $hash_string_c = sprintf '%s%s%s%s',
          $checksum, join( '', @challenge_string ), $crypt_hash, $id;
    }
    elsif ( $sv == 3 ) {
        my $checksum = $challenge_string[ ord( $challenge_string[1] ) % 16 ];
        $hash_string_p = sprintf '%s%s%s%s',
          $checksum, $id, $password_hash, join( '', @challenge_string );
        $hash_string_c = sprintf '%s%s%s%s',
          $checksum, $id, $crypt_hash, join( '', @challenge_string );
    }
    elsif ( $sv == 4 ) {
        my $checksum = $challenge_string[ ord( $challenge_string[3] ) % 16 ];
        $hash_string_p = sprintf '%s%s%s%s',
          $checksum, $password_hash, join( '', @challenge_string ), $id;
        $hash_string_c = sprintf '%s%s%s%s',
          $checksum, $crypt_hash, join( '', @challenge_string ), $id;
    }
    elsif ( $sv == 0 || $sv == 5 ) {
        my $checksum = $challenge_string[ ord( $challenge_string[7] ) % 16 ];
        $hash_string_p = sprintf '%s%s%s%s',
          $checksum, $password_hash, $id, join( '', @challenge_string );
        $hash_string_c = sprintf '%s%s%s%s',
          $checksum, $crypt_hash, $id, join( '', @challenge_string );
    }

    my $result6  = _to_yahoo_base64( md5($hash_string_p) );
    my $result96 = _to_yahoo_base64( md5($hash_string_c) );
    return ( $result6, $result96 );
}

sub _to_yahoo_base64 {
    pos( $_[0] ) = 0;

    my $res = join '',
      map( pack( 'u', $_ ) =~ /^.(\S*)/, ( $_[0] =~ /(.{1,45})/gs ) );
    $res =~ tr{` -_}{AA-Za-z0-9\._};

    my $padding = ( 3 - length( $_[0] ) % 3 ) % 3;
    $res =~ s/.{$padding}$/'-' x $padding/e if $padding;
    return $res;
}

sub _to64 {
    my ( $v, $n ) = @_;
    my $ret = '';
    while ( --$n >= 0 ) {
        $ret .= substr( I_TO_A64, $v & 0x3f, 1 );
        $v >>= 6;
    }
    $ret;
}

sub _md5_crypt {
    my $pw   = shift;
    my $salt = shift;

    my $Magic = MD5_CRYPT_MAGIC_STRING;
    $salt =~ s/^\Q$Magic//;
    $salt =~ s/^(.*)\$.*$/$1/;
    $salt = substr $salt, 0, 8;

    my $ctx = new Digest::MD5;
    $ctx->add($pw);
    $ctx->add($Magic);
    $ctx->add($salt);

    my $final = new Digest::MD5;
    $final->add($pw);
    $final->add($salt);
    $final->add($pw);
    $final = $final->digest;

    for ( my $pl = length($pw) ; $pl > 0 ; $pl -= 16 ) {
        $ctx->add( substr( $final, 0, $pl > 16 ? 16 : $pl ) );
    }

    for ( my $i = length($pw) ; $i ; $i >>= 1 ) {
        if ( $i & 1 ) {
            $ctx->add( pack( "C", 0 ) );
        }
        else {
            $ctx->add( substr( $pw, 0, 1 ) );
        }
    }

    $final = $ctx->digest;

    for ( my $i = 0 ; $i < 1000 ; $i++ ) {
        my $ctx1 = new Digest::MD5;
        if ( $i & 1 ) {
            $ctx1->add($pw);
        }
        else {
            $ctx1->add( substr( $final, 0, 16 ) );
        }
        if ( $i % 3 ) {
            $ctx1->add($salt);
        }
        if ( $i % 7 ) {
            $ctx1->add($pw);
        }
        if ( $i & 1 ) {
            $ctx1->add( substr( $final, 0, 16 ) );
        }
        else {
            $ctx1->add($pw);
        }
        $final = $ctx1->digest;
    }

    my $passwd = '';
    $passwd .= _to64(
        int( unpack( "C",   ( substr( $final, 0,  1 ) ) ) << 16 ) |
          int( unpack( "C", ( substr( $final, 6,  1 ) ) ) << 8 ) |
          int( unpack( "C", ( substr( $final, 12, 1 ) ) ) ),
        4
    );
    $passwd .= _to64(
        int( unpack( "C",   ( substr( $final, 1,  1 ) ) ) << 16 ) |
          int( unpack( "C", ( substr( $final, 7,  1 ) ) ) << 8 ) |
          int( unpack( "C", ( substr( $final, 13, 1 ) ) ) ),
        4
    );
    $passwd .= _to64(
        int( unpack( "C",   ( substr( $final, 2,  1 ) ) ) << 16 ) |
          int( unpack( "C", ( substr( $final, 8,  1 ) ) ) << 8 ) |
          int( unpack( "C", ( substr( $final, 14, 1 ) ) ) ),
        4
    );
    $passwd .= _to64(
        int( unpack( "C",   ( substr( $final, 3,  1 ) ) ) << 16 ) |
          int( unpack( "C", ( substr( $final, 9,  1 ) ) ) << 8 ) |
          int( unpack( "C", ( substr( $final, 15, 1 ) ) ) ),
        4
    );
    $passwd .= _to64(
        int( unpack( "C",   ( substr( $final, 4,  1 ) ) ) << 16 ) |
          int( unpack( "C", ( substr( $final, 10, 1 ) ) ) << 8 ) |
          int( unpack( "C", ( substr( $final, 5,  1 ) ) ) ),
        4
    );
    $passwd .= _to64( int( unpack( "C", substr( $final, 11, 1 ) ) ), 2 );

    return $Magic . $salt . '$' . $passwd;
}

1;
__END__

=head1 NAME

Net::YahooMessenger::CRAM - Yahoo Messenger Challenge-Response Authentication Mechanism.

=head1 SYNOPSIS

  my $cram = Net::YahooMessenger::CRAM->new();
  $cram->set_id($your_yahoo_id);
  $cram->set_password($your_password);
  $cram->set_challenge_string($string_from_server);

  my ($response_type6, $response_type96) = $cram->get_response_strings();

=head1 DESCRIPTION

Net::YahooMessenger::CRAM is Challenge-Response Authentication Mechanism for Yahoo Messenger protocol version 9.

=head1 DEPENDENCIES

This module requires these other modules:

=over 4

=item * Digest::MD5;

=back

=head1 AUTHOR

Hiroyuki OYAMA <oyama@crayfish.co.jp> http://ymca.infoware.ne.jp/

=head1 COPYRIGHT

Copyright (C) 2002 Hiroyuki OYAMA. Japan. All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
Please refer to the use agreement of Yahoo! about use of the Yahoo!Messenger serice.

=cut
