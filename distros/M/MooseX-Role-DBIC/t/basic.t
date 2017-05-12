use strict;
use warnings;

use Test::More tests => 10;

my $t = Tester->new( dbic_class => 'MockSchema', dbic_dsn => 'DSN, baby!' );
isa_ok( $t, 'Tester' );
is( $t->dbic_dsn, 'DSN, baby!' );
isa_ok( $t->dbic_schema, 'MockSchema' );

# test the clearing trigger, should call connect() again (which is
# checked by the test count)
$t->dbic_schema_options( { foo => 'bar' } );
isa_ok( $t->dbic_schema, 'MockSchema' );
is_deeply( $t->dbic_schema_options, { foo => 'bar' } );

my $herp = Tester2->new;
is( $herp->herp_dsn, 'herpdsn!', 'accessor options work' );
isa_ok( $herp->herp_schema, 'MockSchema' );

exit;


BEGIN {
    package Tester;
    use Moose;
    with 'MooseX::Role::DBIC' => { schema_class => 'MockSchema' };

    package Tester2;
    use Moose;
    with 'MooseX::Role::DBIC' => {
        schema_name  => 'herp',
        accessor_options => {
            herp_dsn   => [ default => 'herpdsn!'   ],
            herp_class => [ default => 'MockSchema' ],
        },
    };

    with 'MooseX::Role::DBIC' => {
        schema_name  => 'derp',
        accessor_options => {
            derp_dsn   => [ default => 'foo!'   ],
            derp_class => [ default => 'zumba' ],
        },
    };

    package MockSchema;

    sub connect {
        my ( $class, @info ) = @_;
        Test::More::ok( 1, 'connect called!' );
        return bless {}, $class;
    }

}
