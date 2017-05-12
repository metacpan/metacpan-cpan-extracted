
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strictures 1;
use Test::More 0.98;

do {
    package MyTest::MooseClass;
    use Moose;
    use syntax qw( simple/v1 );
    fun foo ($x) { fun ($y) { $x + $y } };
    method bar ($x) { $x }
    my %modifier;
    before bar ($x) { $modifier{before} = $x }
    after  bar ($x) { $modifier{after}  = $x }
    around bar ($x) { $modifier{around} = $x; $self->$orig($x) }
    method anon { method ($x) { $x * 2 } }
    my $class = __PACKAGE__;
    ::is($class->bar(23), 23, 'method value passing');
    ::is($modifier{ $_ }, 23, "correct value in $_")
        for qw( before after around );
    ::is(foo(23)->(17), 40, 'function definitions');
    ::is($class->${\($class->anon)}(23), 46, 'anonymous methods');
};

done_testing;
