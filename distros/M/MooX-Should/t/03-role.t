BEGIN {
    $ENV{PERL_STRICT} = 1;
}

use Test::Most;

use lib 't/lib';
use TestClass;
use Moo::Role ();

lives_ok {
    my $class_with_role = Moo::Role->create_class_with_roles( 'TestClass', 'TestRole' );
    $class_with_role->new( c => 1 );
} 'use role with MooX::Should';

done_testing;
