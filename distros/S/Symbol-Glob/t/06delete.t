use Test::More tests=>25;

BEGIN {
  use_ok qw(Symbol::Glob);
}

no warnings 'once';
$foo = "foo is set";
@bar = qw(bar is set);
%baz = map {$_=>1} qw(baz is set);
sub quux { 'quux!' }

my $foo_capture = Symbol::Glob->new({name=>'main::foo'});
my $bar_capture = Symbol::Glob->new({name=>'main::bar'});
my $baz_capture = Symbol::Glob->new({name=>'main::baz'});
my $quux_capture = Symbol::Glob->new({name=>'main::quux'});

ok defined $foo_capture->scalar(), "\$foo caught";
$foo_capture->delete('scalar');
ok !defined $foo, "\$foo undefined";

ok defined $bar_capture->array(), "\@bar caught";
$bar_capture->delete('array');
ok !@bar, "\@bar undefined";

ok defined $baz_capture->hash(), "%baz caught";
$baz_capture->delete('hash');
ok !keys %baz, "%baz undefined";

ok defined $quux_capture->sub(), "&quux caught";
$quux_capture->delete('sub');
ok !defined &quux, "&quux undefined";

$bar_capture = $baz_capture = $quux_capture = undef;

$foo = "foo is set";
@foo = qw(foo is set);
%foo = map {$_=>1} qw(foo is set);
sub foo { 'foo!' }
$foo_capture = Symbol::Glob->new({name=>'main::foo'});

$foo_capture->delete('scalar');
ok !defined $foo, "\$foo undefined";
ok @foo, "\@foo defined";
ok keys %foo, "%foo defined";
ok defined &foo, "&foo defined";

$foo = "foo is set";
@foo = qw(foo is set);
%foo = map {$_=>1} qw(foo is set);
{
  no warnings 'redefine';
  sub foo { 'foo!' }
}
$foo_capture = Symbol::Glob->new({name=>'main::foo'});

$foo_capture->delete('array');
ok defined $foo, "\$foo defined";
ok !@foo, "\@foo undefined";
ok keys %foo, "%foo defined";
ok defined &foo, "&foo defined";

$foo = "foo is set";
@foo = qw(foo is set);
%foo = map {$_=>1} qw(foo is set);
{
  no warnings 'redefine';
  sub foo { 'foo!' }
}
$foo_capture = Symbol::Glob->new({name=>'main::foo'});

$foo_capture->delete('hash');
ok defined $foo, "\$foo defined";
ok @foo, "\@foo defined";
ok !keys %foo, "%foo undefined";
ok defined &foo, "&foo defined";

$foo = "foo is set";
@foo = qw(foo is set);
%foo = map {$_=>1} qw(foo is set);
{
  no warnings 'redefine';
  sub foo { 'foo!' }
}
$foo_capture = Symbol::Glob->new({name=>'main::foo'});

$foo_capture->delete('sub');
ok defined $foo, "\$foo defined";
ok @foo, "\@foo defined";
ok keys %foo, "%foo defined";
ok !defined &foo, "&foo undefined";
