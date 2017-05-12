use strictures 1;
use Test::More 0.98;

note('v1');
do {
    package MyTest::Plain::V1;
    use syntax qw( simple/v1 );
    fun foo ($x) { fun ($y) { $x + $y } };
    ::is(foo(23)->(17), 40, 'function definitions');
    my $can_method;
    BEGIN { $can_method = __PACKAGE__->can('method'); }
    ::ok(not($can_method), 'no method keyword');
};

note('v2');
do {
    package MyTest::Plain::V2;
    use syntax qw( simple/v2 );
    fun foo ($x) { fun ($y) { $x + $y } };
    ::is(foo(23)->(17), 40, 'function definitions');
    my $can_method;
    method add ($x, $y) { $x + $y }
    method bar ($x) { method ($y) { $self->add($x, $y) } }
    my $add23 = __PACKAGE__->bar(23);
    ::is __PACKAGE__->$add23(17), 40, 'method keyword works';
};

done_testing;
