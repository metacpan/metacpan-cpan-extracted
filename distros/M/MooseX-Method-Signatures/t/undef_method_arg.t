use strict;
use warnings;
use Test::More;
use Test::Fatal;

{
    package Foo;
    use Moose;
    use MooseX::Method::Signatures;

    method m1(:$bar!) { }
    method m2(:$bar?) { }
    method m3(:$bar ) { }

    method m4( $bar!) { }
    method m5( $bar?) { }
    method m6( $bar ) { }
}

my $foo = Foo->new;

is(exception { $foo->m1(bar => undef) }, undef, 'Explicitly pass undef to named required arg');
is(exception { $foo->m2(bar => undef) }, undef, 'Explicitly pass undef to named explicit optional arg');
is(exception { $foo->m3(bar => undef) }, undef, 'Explicitly pass undef to named implicit optional arg');

is(exception { $foo->m4(undef) }, undef, 'Explicitly pass undef to required arg');
is(exception { $foo->m5(undef) }, undef, 'Explicitly pass undef to explicit required arg');
is(exception { $foo->m6(undef) }, undef, 'Explicitly pass undef to implicit required arg');

done_testing;
