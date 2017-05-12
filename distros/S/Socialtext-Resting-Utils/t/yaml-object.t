#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 7;
use lib 'lib';

BEGIN {
    use_ok 'Socialtext::WikiObject::YAML';
    use_ok 'Socialtext::Resting::Mock';
}

my $rester = Socialtext::Resting::Mock->new;

sub new_wikiobject {
    Socialtext::WikiObject::YAML->new( rester => $rester, @_ );
}

Simple_yaml: {
    $rester->put_page('Foo', "foo: bar\n");

    my $wo = new_wikiobject(page => 'Foo');
    is $wo->{foo}, 'bar';
    is_deeply $wo->as_hash, { foo => 'bar' };
}

YAML_Lists: {
    $rester->put_page('Foo', <<EOT);
Foo:
  - bar
  - baz
EOT

    my $wo = new_wikiobject(page => 'Foo');
    is_deeply $wo->{Foo}, [qw(bar baz)];
    is_deeply $wo->{foo}, $wo->{Foo};
    is_deeply $wo->as_hash, { Foo => [qw(bar baz)] };
}
