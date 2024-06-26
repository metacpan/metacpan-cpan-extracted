#!/usr/bin/perl
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Spec;
use File::Slurp;
use Test::More;
use URI;
use JSON::XS;
use File::Slurp;
use strict;

require_ok 'Net::RDAP::JCard';

my $json = JSON::XS->new->utf8->decode(join('', read_file(File::Spec->catfile(abs_path(dirname(__FILE__)), q{jcard.json}))));

is(ref($json), 'ARRAY');
is(scalar(@{$json}), 2);
is($json->[0], 'vcard');
is(ref($json->[1]), 'ARRAY');

my $jcard = Net::RDAP::JCard->new($json->[1]);
isa_ok($jcard, q{Net::RDAP::JCard});

foreach my $method (qw(properties first addresses first_address TO_JSON)) {
    ok($jcard->can($method), "jCard object has the '$method' method");
}

foreach my $property ($jcard->properties) {
    isa_ok($property, q{Net::RDAP::JCard::Property});

    foreach my $method (qw(type params param value_type value TO_JSON)) {
        ok($property->can($method), "Property object has the '$method' method");
    }
}

my $fn = $jcard->first('fn');
isa_ok($fn, q{Net::RDAP::JCard::Property});

is($fn->type,       'fn');
is($fn->value_type, 'text');
is($fn->value,      'John Doe');

is($jcard->first('email')->value, 'john.doe@example.com');

is($jcard->first('email')->value, $jcard->first('EmAiL')->value);

foreach my $addr ($jcard->addresses) {
    isa_ok($addr, q{Net::RDAP::JCard::Address});

    foreach my $method (qw(structured address pobox extended street locality region code cc country)) {
        ok($addr->can($method), "Address object has the '$method' method");
    }
}

my $addr = $jcard->first_address;
isa_ok($addr, q{Net::RDAP::JCard::Address});

ok($addr->structured);

is($addr->extended,     'Suite 100');

is('ARRAY', ref($addr->street));
is($addr->street->[0],  '123 Example Dr.');

is($addr->locality,     'Dulles');
is($addr->region,       'VA');
is($addr->code,         '20166-6503');
is($addr->cc,           'US');
is($addr->country,      'United States of America');

is($addr->param('type'), $addr->param('TyPe'));

like($addr->address, sprintf('/%s/', quotemeta($addr->extended)));
like($addr->address, sprintf('/%s/', quotemeta($addr->street->[0])));
like($addr->address, sprintf('/%s/', quotemeta($addr->locality)));
like($addr->address, sprintf('/%s/', quotemeta($addr->region)));
like($addr->address, sprintf('/%s/', quotemeta($addr->code)));
like($addr->address, sprintf('/%s/', quotemeta($addr->cc || $addr->country)));

done_testing;
