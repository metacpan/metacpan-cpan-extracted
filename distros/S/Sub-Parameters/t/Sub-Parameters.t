#!perl -w
use strict;
BEGIN {
    require Test::More;

    if ($] < 5.007002) {
        import Test::More skip_all => "need a newer perl";
        exit 0;
    }
    import Test::More tests => 17;
}

use Sub::Parameters;

sub foo : WantParam('positional') {
    my $thing : Parameter;
    my $blob  : Parameter;
    is($thing, 'test',   'positional 1');
    is($blob,  'wobble', 'positional 2');
}

foo('test', 'wobble');
foo('test', 'wobble');

my $out;
sub Foo::DESTROY { $out .= "middle\n" };
sub Foo::test    { $out .= "more\n" };

sub bar {
    my $thing = shift;
    $thing->test;
}

sub baz : WantParam('positional') {
    my $thing : Parameter;
    $thing->test;
}

$out = "start\n";
bar(bless {}, 'Foo');
$out .= "end\n";

is($out, "start\nmore\nmiddle\nend\n", "doesn't linger (control)");

$out = "start\n";
baz(bless {}, 'Foo');
$out .= "end\n";

is($out, "start\nmore\nmiddle\nend\n", "doesn't linger (attribute)");

sub quux :WantParam(positional) {
    my $foo : Parameter(rw);
    my @bar : Parameter(rw);
    my @baz : Parameter;

    $foo = 'baz';

    is_deeply( \@bar, [qw( foo bar )], "pass @ rw" );
    is_deeply( \@baz, [qw( foo bar )], "pass @" );
    @bar = qw( quux zed );
    @baz = qw( quux zed );
}

my $foo = 'bar';
my @bar = qw( foo bar );
my @baz = qw( foo bar );

quux($foo, \@bar, \@baz);

is( $foo, 'baz', "readwrite" );
is_deeply( \@bar, [qw( quux zed )], "readwrite @" );
is_deeply( \@baz, [qw( foo bar  )], "copy @" );

sub wrong_type : WantParam { my %hash : Parameter; }
eval { wrong_type([]) };
like( $@, qr/^can't assign non-hashref to '%hash' at/, "trap mistype" );

sub wrong_nodecoration { my $foo : Parameter; }
eval { wrong_nodecoration() };
like( $@, qr/^attempt to use a Parameter in an undecorated subroutine at/,
      "trap no decoration" );

sub sample : WantParam(named) {
    my $foo : Parameter;
    my $baz : Parameter(rw);

    is( $foo, 'foo value', "named foo" );
    is( $baz, 'bar',       "named baz" );
    $baz = 'baz';
}
my $value = 'bar';
sample( foo => 'foo value', baz => $value );
is( $value, 'baz', "named rw" );

sub wrong_novalue :WantParam(named) { my $foo : Parameter(rw); }
eval { wrong_novalue() };
like( $@, qr/^can't find a parameter for '\$foo' at /, "trap no named" );
