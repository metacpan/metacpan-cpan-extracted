#!/usr/bin/env perl

use Test::More;
use Test::Exception;

my $long_domain = 'zumsel.haushaltswarenabteilung.einzelhandel.de';
my $long_host = 'verylonghostnamepartcannotbeshortend.some-domain.de';

use_ok('String::ShortenHostname');

my $sh = String::ShortenHostname->new(
	length => 20,
	keep_digits_per_domain => 3,
	domain_edge => undef,
	cut_middle => 0,
	force => 0,
	force_edge => undef,
);
isa_ok($sh, 'String::ShortenHostname');

is($sh->shorten($long_domain), 'zumsel.hau.ein.de', 'shorten 3 digits per domain' );

$sh->keep_digits_per_domain(5);
is($sh->shorten($long_domain), 'zumsel.haush.einze.de', 'shorten 5 digits per domain' );

$sh->domain_edge('~');
is($sh->shorten($long_domain), 'zumsel.haus~.einz~.de', 'shorten 5 digits per domain' );

$sh->keep_digits_per_domain(3);
is($sh->shorten($long_host), 'verylonghostnamepartcannotbeshortend.so~.de', 'shorten long domain with 3 digits per domain' );

$sh->force(1);
is($sh->shorten($long_host), 'verylonghostnamepart', 'force shortening' );

$sh->force_edge('~');
is($sh->shorten($long_host), 'verylonghostnamepar~', 'force shortening with edge string' );

$sh->force(0);
$sh->keep_digits_per_domain(5);
$sh->cut_middle(1);
$sh->domain_edge(undef);
is($sh->shorten($long_domain), 'zumsel.hausg.einzl.de', 'shorten 5 digits per domain and cut_middle' );

$sh->domain_edge('~');
is($sh->shorten($long_domain), 'zumsel.hau~g.ein~l.de', 'shorten 5 digits per domain cut_middle and domain_edge' );

$sh->keep_digits_per_domain(3);
$sh->domain_edge('~~');
throws_ok { $sh->shorten($long_domain); } qr/remaining length per domain too small, adjust keep_digits_per_domain, domain_edge, cut_middle/, 'no characters left must fail';

done_testing();

