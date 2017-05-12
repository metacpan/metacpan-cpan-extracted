# to test the inner versus outer index predicates

use strict;
use warnings;
use File::Basename qw(dirname);

BEGIN {
    push @INC, dirname($0);
}

use Test::More;
use ToyXMLForester;
use ToyXML qw(parse);

my $f = ToyXMLForester->new;

my $p = parse(<<'END');
<a>
  <b>
    <d/>
    <e/>
    <f/>
    <g/>
    <h/>
    <i/>
  </b>
  <c>
    <j/>
    <k/>
    <l/>
    <m/>
    <n/>
    <o/>
    <p/>
    <q/>
    <r/>
    <s/>
    <t/>
    <u/>
    <v/>
    <w/>
    <x/>
    <y/>
    <z/>
  </c>
</a>
END

my @tests = (
    { path => '//~[aeiou]~[0]',                       tags => 'aeo' },
    { path => '(//~[aeiou]~)[0]',                     tags => 'a' },
    { path => '//~[aeiou]~[-1]',                      tags => 'aiu' },
    { path => '(//~[aeiou]~)[-1]',                    tags => 'u' },
    { path => '/descendant-or-self::~[aeiou]~[0]',    tags => 'a' },
    { path => '(/descendant-or-self::~[aeiou]~)[0]',  tags => 'a' },
    { path => '/descendant-or-self::~[aeiou]~[-1]',   tags => 'u' },
    { path => '(/descendant-or-self::~[aeiou]~)[-1]', tags => 'u' },
);

plan tests => scalar @tests;

for my $test (@tests) {
    my @nodes = $f->path( $test->{path} )->select($p);
    my $s     = '';
    $s .= $_->tag for @nodes;
    is $s, $test->{tags}, "correct nodes in correct sequence for $test->{path}";
}
