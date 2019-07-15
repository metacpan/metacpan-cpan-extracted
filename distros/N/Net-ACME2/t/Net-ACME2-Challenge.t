#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use Test::Deep;

use Net::ACME2::Challenge ();

my %challenge_h = (
    'error' => {
        'type' => 'urn:ietf:params:acme:error:unauthorized',
        'detail' => 'Invalid response from http://felipe.org/.well-known/acme-challenge/-1OjCzoZvp9SpQd5CIJpbQ_DzSABPGCbSJoteIbjWY8 [91.195.240.126]: "<!DOCTYPE html><html lang=\\"en\\" data-adblockkey=MFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBANnylWw2vLY4hUn9w06zQKbhKBfvjFUCsdFlb6TdQhxb9RXWX"',
        'status' => 403
    },
    'type' => 'http-01',
    'status' => 'invalid',
    'token' => '-1OjCzoZvp9SpQd5CIJpbQ_DzSABPGCbSJoteIbjWY8',
    'url' => 'https://acme-staging-v02.api.letsencrypt.org/acme/challenge/Buc1r4lbTyMOrzlMDxQ7PaGfPpFJyM6-6Co0IH9dslQ/329525030',
);

my $challenge = Net::ACME2::Challenge->new( %challenge_h );

my $err = $challenge->error();

cmp_deeply(
    $err,
    all(
        Isa('Net::ACME2::Error'),
        methods(
            %{ $challenge_h{'error'} },
        ),
    ),
    'error() as object',
);

cmp_deeply(
    { %$err },
    superhashof( $challenge_h{'error'} ),
    'error() as hashref',
);

done_testing();

1;
