use strict;
use utf8;
use Test::More;
use Parse::JCONF;
use Parse::JCONF::Boolean qw(TRUE FALSE);

unless (eval "require $Parse::JCONF::HashClass") {
	plan skip_all => "$Parse::JCONF::HashClass not installed";
}

my $parser = Parse::JCONF->new(autodie => 1, keep_order => 1);
my $res = $parser->parse_file('t/files/object_ordered.jconf');

my @root_keys = keys %$res;
is_deeply(\@root_keys, ['a', 'b', 'c'], "root keys order");

my @a_keys = keys %{$res->{a}};
is_deeply(\@a_keys, ["foo", "bar", "baz"], "a keys");

my @a_baz_keys = keys %{$res->{a}{baz}};
is_deeply(\@a_baz_keys, ["x", "y", "z"], "a->baz keys");

is_deeply($res->{c}, ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q"], "c value");

done_testing;
