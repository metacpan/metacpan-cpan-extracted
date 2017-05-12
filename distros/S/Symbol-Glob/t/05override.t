use Test::More tests=>10;

BEGIN {
  use_ok qw(Symbol::Glob);
}

no warnings 'once';
$foo = "foo is set";
@bar = qw(bar is set);
%baz = map {$_=>1} qw(baz is set);
sub quux { 'quux!' }

my $foo_capture = Symbol::Glob->new({name=>'main::foo', scalar=>'reset'});
my $bar_capture = Symbol::Glob->new({name=>'main::bar', array=>['reset']});
my $baz_capture = Symbol::Glob->new({name=>'main::baz', hash=>{ 'reset'=>0 } });
my $quux_capture = Symbol::Glob->new({name=>'main::quux', sub => sub { 'ZORCH' } });

ok defined $foo_capture->scalar(), "\$foo caught";
is $foo, 'reset', "reset at init";

ok defined $bar_capture->array(), "\@bar caught";
is_deeply [@bar], ['reset'], 'reset at init';

ok defined $baz_capture->hash(), "%baz caught";
is_deeply [keys %baz], ['reset'], 'keys set at init';
is_deeply [values %baz], [0], 'values set at init';

ok defined $quux_capture->sub(), "&quux caught";
is quux(), 'ZORCH', 'reset at init';
