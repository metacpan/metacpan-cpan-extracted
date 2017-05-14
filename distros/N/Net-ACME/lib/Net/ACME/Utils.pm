package Net::ACME::Utils;

=encoding utf-8

=head1 NAME

Net::ACME::Utils - utilities for C<Net::ACME>

=head1 SYNOPSIS

    Net::ACME::Utils::verify_token('blah/blah');     #dies
    Net::ACME::Utils::verify_token('blah-blah');     #succeeds

    my $jwk_hr = Net::ACME::Utils::get_jwk_data($rsa_key_pem);

=head1 DESCRIPTION

This module is a home for “miscellaneous” functions that just aren’t
in other modules. Think carefully before expanding this module; it’s
probably better, if possible, to put new functionality into more
topic-specific modules rather than this “catch-all” one.

=cut

use strict;
use warnings;

use MIME::Base64 ();
*_to_base64url = \&MIME::Base64::encode_base64url;

use Net::ACME::Crypt ();
use Net::ACME::X ();

my %KEY_OBJ_CACHE;

#Clear out the cache prior to global destruction.
END {
    %KEY_OBJ_CACHE = ();
}

sub verify_token {
    my ($token) = @_;

    #cf. eval_bug.readme
    my $eval_err = $@;

    eval {

        die Net::ACME::X::create('Empty') if !defined $token || !length $token;
        die Net::ACME::X::create('Empty') if $token =~ m<\A\s*\z>;

        if ( $token =~ m<[^0-9a-zA-Z_-]> ) {
            die Net::ACME::X::create( 'InvalidCharacters', "“$token” contains invalid Base64-URL characters.", { value => $token } );
        }

    };

    if ($@) {
        my $message = $@->to_string();

        die Net::ACME::X::create( 'InvalidParameter', "“$token” is not a valid ACME token. ($message)" );
    }

    $@ = $eval_err;

    return;
}

sub thing_isa {
    my ($thing, $class) = @_;

    #cf. eval_bug.readme
    my $eval_err = $@;

    my $isa = eval { $thing->isa($class) };

    $@ = $eval_err;

    return $isa;
}

sub get_jwk_data {
    my ($key_pem_or_der) = @_;

    return Net::ACME::Crypt::get_rsa_public_jwk($key_pem_or_der);
}

sub get_jwk_thumbprint {
    my ($key_jwk) = @_;

    return Net::ACME::Crypt::get_rsa_jwk_thumbprint( $key_jwk );
}

1;
