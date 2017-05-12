use strict;
use lib qw[../lib lib t/to_load to_load];

use File::Spec ();
use Test::More 'no_plan';

BEGIN { use No::Die packages => ['Foo'] };
use Foo;

### die from own package ###
{
    my $msg = 'blah';
    my $rv  = eval { Foo::bar() };
    
    like( $@, qr/$msg/, 'Allowed die occurred' );
    is( $rv, undef,     '   No return value' );
    is( $DIE, undef,    '   $DIE is set correctly' );
}    
