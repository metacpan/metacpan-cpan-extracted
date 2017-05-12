use Test::More tests=>5;

BEGIN {
  use_ok qw(Symbol::Glob);
}

no warnings 'once';
$foo = "foo is set";
@bar = qw(bar is set);
%baz = map {$_=>1} qw(baz is set);
sub quux { 'quux!' }

my $foo_capture = Symbol::Glob->new({name=>'main::foo'});
ok defined $foo_capture->scalar(), "\$foo caught";

my $bar_capture = Symbol::Glob->new({name=>'main::bar'});
ok defined $bar_capture->array(), "\@bar caught";

my $baz_capture = Symbol::Glob->new({name=>'main::baz'});
ok defined $baz_capture->hash(), "%baz caught";

my $quux_capture = Symbol::Glob->new({name=>'main::quux'});
ok defined $quux_capture->sub(), "&quux caught";
