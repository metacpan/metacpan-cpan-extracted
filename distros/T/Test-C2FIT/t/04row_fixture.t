use Test::More tests => 5;
# use Test::More qw(no_plan);

use Test::C2FIT::Parse;
use Test::C2FIT::Fixture;

{
    package MyRowFixture;
    use base 'Test::C2FIT::RowFixture';

    sub query { [
        { x => 'x1', y => 'y1' },
        { x => 'x2', y => 'y2' }
        ];
    }
    1;
};

my $runner = new Test::C2FIT::Fixture();

my $p = Test::C2FIT::Parse->new(<<'_HTML_',[qw(tab row cell)]);
<tab>
  <row>
    <cell>MyRowFixture</cell>
  </row>
  <row> <!-- column headings -->
    <cell>x</cell>
    <cell>y</cell>
  </row>
  <row> <!-- data values -->
    <cell>x1</cell>
    <cell>y1</cell>
  </row>
  text after second
  <row>
    <cell>x2</cell>
    <cell>y2</cell>
  </row>
</tab>
_HTML_

eval {
    $runner->doTables($p);
};
is($@,"","processing of input document ok");

is($runner->counts()->{right},4,"all cell values are ok");
is($runner->counts()->{wrong},0,"nothing wrong");
is($runner->counts()->{ignores},0,"nothing ignored");
is($runner->counts()->{exceptions},0,"no exception occured");

