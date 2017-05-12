use Test::More tests=>10;
use Test::Exception;

BEGIN {
  use_ok qw(Symbol::Glob);
}

my $glob;
dies_ok { $glob = Symbol::Glob->new("I oughta be a hash") }  "non-hash not accepted";
like $@, qr/\QArgument to Symbol::Glob->new() must be hash reference\E/, "right message";

no warnings 'once';
$foo = "this is foo";
$foo_grab = Symbol::Glob->new({name=>'main::foo', scalar=>undef});
is $foo, "this is foo", "undefined overrides ignored";

%foo = map {$_=>1} qw(this is foo);
$foo_grab = Symbol::Glob->new({name=>'main::foo', scalar=>undef});
%bar = $foo_grab->hash();
is_deeply \%foo, \%bar, "same hash";

@foo = qw(this is foo);
$foo_grab = Symbol::Glob->new({name=>'main::foo', scalar=>undef});
@bar = $foo_grab->array();
is_deeply \@foo, \@bar, "same array";

%foo = map {$_=>1} qw(this is foo);
$foo_grab = Symbol::Glob->new({name=>'main::foo', scalar=>undef});
%bar = $foo_grab->hash({a=>1,new=>1,hash=>1});
is_deeply \%foo, \%bar, "same hash";
is_deeply \%foo, {a=>1, new=>1, hash=>1}, "replaced hash";

@foo = qw(this is foo);
$foo_grab = Symbol::Glob->new({name=>'main::foo', scalar=>undef});
@bar = $foo_grab->array([qw(no longer foo)]);
is_deeply \@foo, \@bar, "same array";
is_deeply \@foo, [qw(no longer foo)], "replaced array";



