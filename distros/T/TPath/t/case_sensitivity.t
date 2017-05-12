# to test setting a forester to be case insensitive

use strict;
use warnings;
use File::Basename qw(dirname);

BEGIN {
    push @INC, dirname($0);
}

use Test::More;
use ToyXMLForester;
use ToyXML qw(parse);

my $f1 = ToyXMLForester->new;
my $f2 = ToyXMLForester->new(case_insensitive => 1);

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
    { path => '//a',            tags => [qw(a a)] },
    { path => '//A',            tags => [ '', 'a' ] },
    { path => '//~[aeiou]~[0]', tags => [qw(aeo aeo)] },
    { path => '//~[AEIOU]~[0]', tags => [ '', 'aeo' ] },
);

plan tests => 2 * @tests;

for my $test (@tests) {
    my @n1   = $f1->path( $test->{path} )->select($p);
    my @n2   = $f2->path( $test->{path} )->select($p);
    my @tags = @{ $test->{tags} };
    my ( $s1, $s2 ) = map { stringify($_) } \@n1, \@n2;
    is $s1, $tags[0],
      "correct nodes in correct sequence for case sensitive $test->{path}";
    is $s2, $tags[1],
      "correct nodes in correct sequence for case insensitive $test->{path}";
}

sub stringify {
my $ar = shift;
    my $s     = '';
    $s .= $_->tag for @$ar;
return $s;
}
