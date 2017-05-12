#!perl -T

use Test::More tests => 1;

note ('Just test to some subroutine, as property');

ok( !eval{ First->new() } && $@, 
			"Some name protection worked");

1;

{ package First;	
	use Object::Botox qw(new);
	use constant PROTOTYPE => {
                email => undef,    
                whatever => undef
        };
        
        sub email {
            return;
        }
        
	1;
}
