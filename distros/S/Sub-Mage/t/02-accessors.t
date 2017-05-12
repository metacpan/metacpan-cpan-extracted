#!perl
use Test::More;
use FindBin;
use lib "$FindBin::Bin";
use MyTest;
can_ok 'MyTest' => 'has';
my $ob = MyTest->new;
is $ob->x, 7 => 'Returned a value of 7 from MyClass->x';
$ob->x( 'World' );
is $ob->x, 'World' => 'Updated MyClass->x to World';

done_testing;




