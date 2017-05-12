use Test::More tests => 16;
# use Test::More qw(no_plan);

use Test::C2FIT::Parse;

my $p = Test::C2FIT::Parse->new(<<'_HTML_',[qw(tab row cell)]);
<tab>
  <row>
    <cell>row1 cell1</cell>
    <cell>row1 cell2</cell>
  </row>
  <row>
    <cell>row2 cell1</cell>
    <cell>row2 cell2</cell>
  </row>
  text after last row
</tab>
_HTML_

is($p->at(0,0,0)->text(),"row1 cell1", "access via at(x,y,z)");
is($p->at(0,1,1)->text(),"row2 cell2", "access via at(x,y,z)");
is($p->leaf()->text()   ,"row1 cell1", "access via leaf");

is($p->more(),undef,"no further tabs");
isnt($p->parts(),undef,"has parts");

my $rows = $p->parts();
like($rows->last()->trailer(),qr/text after last row/,"access to trailer");
is($rows->parts()->tag(),"<cell>", "access to tag name");
is($rows->at(0,0)->text(),"row1 cell1", "access via at(x,y)");
is($rows->at(0,1)->text(),"row1 cell2", "access via at(x,y)");
is($rows->at(1,0)->text(),"row2 cell1", "access via at(x,y)");

my $cells = $rows->parts();

like($cells->leader(),qr/^\s*$/s,"there is nothing more than whitespace between <row> and <cell>");
is($cells->at(0)->text(),"row1 cell1", "access via at(x)");
is($cells->at(1)->text(),"row1 cell2", "access via at(x)");

$p = Test::C2FIT::Parse->from('tagname','this is the body content',undef,undef);

like(ref($p),qr/Test::C2FIT::Parse/,"from creates an instance of Parse");

is($p->body(),"this is the body content","access to body");

my $p2 = Test::C2FIT::Parse->from('a',undef,undef,$p);

is($p2->more(),$p,"access to more() of a parse created with from()");


