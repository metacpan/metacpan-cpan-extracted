use strict;
use warnings;
use Test::More;

{
	package Local::Foo1;
	use Moo;
	has foo1 => ( is => 'ro' );
}

{
	package Local::Foo2;
	use Moo;
	use MooX::XSConstructor;
	extends 'Local::Foo1';
	has foo2 => ( is => 'ro' );
}

{
	package Local::Foo3;
	use Moo;
	extends 'Local::Foo2';
	has foo3 => ( is => 'ro' );
}

{
	package Local::Foo4;
	use Moo;
	use MooX::XSConstructor;
	extends 'Local::Foo3';
	has foo4 => ( is => 'ro' );
}

no warnings 'once';
$Data::Dumper::Deparse = 1;

my $Foo2 = Class::XSConstructor::get_metadata( 'Local::Foo2' );
ok( !$Foo2->{foreignclass} ) or diag explain( $Foo2 );

my $Foo4 = Class::XSConstructor::get_metadata( 'Local::Foo4' );
ok( !$Foo4->{foreignclass} ) or diag explain( $Foo4 );

done_testing;
