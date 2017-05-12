use strict;
use warnings;

use lib 't';

use Test::More 'tests' => 12;

package Foo; {
    use Object::InsideOut;
}

package Bar; {
    use Object::InsideOut q/:Restricted(Zork, '')/, 'Foo';
}

package Baz; {
    use Object::InsideOut qw/:Private('Zork') Bar/;

    sub bar :Sub { return (Bar->new()); }
    sub baz :Sub { return (Baz->new()); }
}

package Ork; {
    use Object::InsideOut qw/:Public Baz/;
}

package Zork; {
    sub bar { return (Bar->new()); }
    sub baz { return (Baz->new()); }
}


package Responder; {
    use Object::InsideOut qw( :Restricted );

    my @response :Field :All( 'response' );
}

package Asker; {
    use Object::InsideOut qw( :Public Responder );

    my @question :Field
                 :Arg( 'question' )
                 ;

    sub ask {
        my ( $self ) = @_;

        Test::More::is($question[ $$self ], 'say wha?', 'Data in public class');

        Responder->new( 'response' => 'kapow!' )->response;
    }
}


package main;

MAIN:
{
    isa_ok(Foo->new(), 'Foo'            => 'Public class');

    eval { my $obj = Bar->new(); };
    like($@, qr/restricted method/      => 'Restricted class');

    eval { my $obj = Baz->new(); };
    like($@, qr/private method/         => 'Private class');
    isa_ok(Baz::bar(), 'Bar'            => 'Restricted class in hierarchy');
    isa_ok(Baz::baz(), 'Baz'            => 'Private class in class');

    isa_ok(Zork::bar(), 'Bar'           => 'Restricted class exemption');
    isa_ok(Zork::baz(), 'Baz'           => 'Private class exemption');

    isa_ok(Ork->new(), 'Ork'            => 'Public class');

    eval { my $obj = Responder->new(); };
    like($@, qr/restricted method/      => 'Restricted class');

    my $obj = Asker->new( 'question' => 'say wha?' );
    isa_ok($obj, 'Asker'                => 'Public class');
    is($obj->ask, 'kapow!'              => 'Access to restricted class');
}

exit(0);

# EOF
