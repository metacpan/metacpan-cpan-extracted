#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use OAuth2::Box;
use Test::Exception;

my $ob = OAuth2::Box->new(
    client_id     => 123,
    client_secret => 'abcdef123',
    redirect_uri  => 'http://localhost',
);

throws_ok { $ob->authorize }
    qr/Assertion \(need code\)/,
    'authorize without code should die';

done_testing();
