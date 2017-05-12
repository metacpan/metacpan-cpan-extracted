use strict;
use warnings;
use Test::More;
use Test::Exception;

{
    package Foo;

    use Moose;
    use MooseX::MultiMethods;
    use MooseX::Types::Moose 'Int';

    multi method bar (Int $baz, Int $quux)  { }
    multi method bar (Int $baz, Int $quux?) { }
}

my $foo = Foo->new;

throws_ok(sub {
    $foo->bar(42, 23);
}, qr/^Ambiguous match for multi method bar: \(Int \$baz, Int \$quux.* with value /);

done_testing;
