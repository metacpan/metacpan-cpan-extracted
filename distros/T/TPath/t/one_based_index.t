# does the one_based property work as expected?

use strict;
use warnings;
use File::Basename qw(dirname);

BEGIN {
    push @INC, dirname($0);
}

use Test::More;
use ToyXMLForester;
use ToyXML qw(parse);

my $f1 = ToyXMLForester->new( one_based => 0 );
my $f2 = ToyXMLForester->new( one_based => 1 );

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
    { path => '//*[1]',  tags => [ 'fcim',         'rootabeohplq' ] },
    { path => '//*[-1]', tags => [ 'rootadgojpnq', 'rootadgojpnq' ] },
);

plan tests => 2 * @tests;

for my $test (@tests) {
    my @n1 = $f1->path( $test->{path} )->select($p);
    my @n2 = $f2->path( $test->{path} )->select($p);
    is concat(@n1), $test->{tags}[0],
      "correct nodes in correct sequence for zero-based $test->{path}";
    is concat(@n2), $test->{tags}[1],
      "correct nodes in correct sequence for one-based $test->{path}";
}

sub concat {
    my @nodes = @_;
    my $s     = '';
    $s .= $_->tag for @nodes;
    return $s;
}
