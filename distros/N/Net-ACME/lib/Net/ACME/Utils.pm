package Net::ACME::Utils;

=encoding utf-8

=head1 NAME

Net::ACME::Utils - utilities for C<Net::ACME>

=head1 SYNOPSIS

    Net::ACME::Utils::verify_token('blah/blah');     #dies
    Net::ACME::Utils::verify_token('blah-blah');     #succeeds

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

#Use this to avoid a Try::Tiny dependency.
sub thing_isa {
    my ($thing, $class) = @_;

    #cf. eval_bug.readme
    my $eval_err = $@;

    my $isa = eval { $thing->isa($class) };

    $@ = $eval_err;

    return $isa;
}

1;
