use Test::More tests => 8;
# use Test::More qw(no_plan);

use Test::C2FIT::Parse;
use Test::C2FIT::Fixture;

our($resetCnt,$setRedCnt,$executeCnt,$lastX,$lastY, $avgCount) = (0,0,0,undef,undef,undef);

{
    package MyColumnFixture;
    use base 'Test::C2FIT::ColumnFixture';

    sub reset {
        my $self = shift;
        $self->{x} = "x is not set!";
        $self->{y} = "y is not set!";
        $self->{avgCount} = "avgCount is not set!";
        $resetCnt++;
    }

    sub execute {
        my $self = shift;
        $lastX = $self->{x};
        $lastY = $self->{y};
        $avgCount = $self->{avgCount};
        $executeCnt++;
    }

    sub setRed {
        $setRedCnt++;
    }

    1;
};

my $runner = new Test::C2FIT::Fixture();

my $p = Test::C2FIT::Parse->new(<<'_HTML_',[qw(tab row cell)]);
<tab>
  <row>
    <cell>MyColumnFixture</cell>
  </row>
  <row> <!-- column headings -->
    <cell>x</cell>
    <cell>y</cell>
    <cell>avg count</cell>
    <cell>set red ()</cell>
  </row>
  <row>
    <cell>a</cell>
    <cell>b</cell>
    <cell>1</cell>
    <cell>0</cell>
  </row>
  text after second
  <row>
    <cell>c</cell>
    <cell>d</cell>
    <cell>10</cell>
    <cell>1</cell>
  </row>
</tab>
_HTML_

eval {
    $runner->doTables($p);
};
is($@,"","processing of input document ok");

is($resetCnt,2,"reset() was called twice, since there are 2 data rows in the input");
is($setRedCnt,2,"setRed() was called twice, since there are 2 data rows in the input");
is($executeCnt,2,"execute() was called twice, since there are 2 data rows in the input");
is($lastX,"c", "content of the 'x' column in the last row was 'c'");
is($lastY,"d", "content of the 'y' column in the last row was 'd'");
is($avgCount,10, "content of the avgCount column in the last row");
is($runner->counts()->{exceptions},0,"no exception occured") or diag($p->asString());


