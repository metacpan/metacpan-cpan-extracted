use strict;
use lib qw[../lib lib t/to_load to_load];

use File::Spec ();
use Test::More 'no_plan';

BEGIN { use No::Die };
use Foo;

### force an unauthorized die from a foreign package ###
{
    my $rv = eval { Foo::bar() };
    
    is( $@, '',         'No die occurred' );
    is( $rv, 1,         '   Normal return value' );
    is( $DIE, 'blah',   '   $DIE is set correctly' );
}


### die from own package ###
{
    my $msg = 'blah';
    my $rv  = eval { die $msg };
    
    like( $@, qr/$msg/, 'Allowed die occurred' );
    is( $rv, undef,     '   No return value' );
    is( $DIE, undef,    '   $DIE is set correctly' );
}    
