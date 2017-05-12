use Test::More tests=>22;

BEGIN {
  use_ok qw( Symbol::Glob);
}


use Test::Exception;

my $glob;
$glob = Symbol::Glob->new({ name => 'main::foo' });

$glob->scalar('5');

is $glob->scalar, 5, "set";
is $foo, 5, "carried over";

is undef, *foo{HASH}, "no hash";
is undef, *foo{ARRAY}, "no array";
is undef, *foo{CODE}, "no code";

$glob = Symbol::Glob->new({ name => 'main::bar' });

$glob->hash({hash=>1});

is_deeply scalar $glob->hash, {hash=>1}, "same hash";
is_deeply [keys %bar], ['hash'], "keys right";
is_deeply [values %bar], [1], "values right";

is undef, $bar, "no scalar";
is undef, *bar{ARRAY}, "no array";
is undef, *bar{CODE}, "no code";

$glob = Symbol::Glob->new({ name => 'main::baz' });

$glob->array([1..4]);

is_deeply scalar $glob->array, [1..4], "same array";
is_deeply [@baz], [1..4], "values right";

is undef, $baz, "no scalar";
is undef, *baz{HASH}, "no hash";
is undef, *baz{CODE}, "no code";

$glob = Symbol::Glob->new({ name => 'main::quux' });

my $new_sub = sub { 'quux!' };

$glob->sub( $new_sub );
is $glob->sub(), $new_sub, "same sub";
is quux(), $new_sub->(), "same value returned";

is undef, $quux, "no scalar";
is undef, *quux{HASH}, "no hash";
is undef, *quux{ARRAY}, "no array";



