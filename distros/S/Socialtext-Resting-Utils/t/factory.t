#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 3;
use Socialtext::Resting::Mock;

BEGIN {
    use_ok 'Socialtext::WikiObject::Factory';
}

my $rester = Socialtext::Resting::Mock->new;

No_magic_wikobject_tag: {
    $rester->put_page('Foo', "baz\n");
    my $wo = Socialtext::WikiObject::Factory->new(
        rester => $rester,
        page   => 'Foo',
    );
    isa_ok $wo, 'Socialtext::WikiObject';
}

Yaml_object: {
    $rester->put_page('Foo', "bar: baz\n");
    $rester->put_pagetag('Foo', '.wikiobject=YAML');

    my $wo = Socialtext::WikiObject::Factory->new(
        rester => $rester,
        page   => 'Foo',
    );
    isa_ok $wo, 'Socialtext::WikiObject::YAML';
}
