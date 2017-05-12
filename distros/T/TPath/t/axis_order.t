# make sure the axes select the expected children and return them in the expected order

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
<root>
  <a>
    <b>
      <e/>
      <f>
        <o/>
      </f>
      <g/>
    </b>
    <c>
      <h/>
      <i>
        <p/>
      </i>
      <j/>
    </c>
    <d>
      <l/>
      <m>
        <q/>
      </m>
      <n/>
    </d>
  </a>
</root>
END

my @tests = (
    { path => '//c/sibling::*',            tags => 'bd' },
    { path => '//c/ancestor::*',           tags => 'roota' },
    { path => '//c/ancestor-or-self::*',   tags => 'rootac' },
    { path => '//c/child::*',              tags => 'hij' },
    { path => '//c/descendant::*',         tags => 'hipj' },
    { path => '//c/descendant-or-self::*', tags => 'chipj' },
    { path => '//c/following::*',          tags => 'dlmqn' },
    { path => '//c/following-sibling::*',  tags => 'd' },
    { path => '//c/leaf::*',               tags => 'hpj' },
    { path => '//c/parent::*',             tags => 'a' },
    { path => '//c/preceding::*',          tags => 'befog' },
    { path => '//c/preceding-sibling::*',  tags => 'b' },
    { path => '//c/previous::*',           tags => 'root' },
    { path => '//c/self::*',               tags => 'c' },
    { path => '//c/sibling-or-self::*',    tags => 'bcd' },
);

plan tests => scalar @tests;

for my $test (@tests) {
    my @nodes = $f->path( $test->{path} )->select($p);
    my $s     = '';
    $s .= $_->tag for @nodes;
    is $s, $test->{tags}, "correct nodes in correct sequence for $test->{path}";
}
