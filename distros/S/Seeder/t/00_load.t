#!perl -T

use Test::More tests => 4;

BEGIN {
    use_ok( 'Seeder' );
    use_ok( 'Seeder::Finder' );
    use_ok( 'Seeder::Background' );
    use_ok( 'Seeder::Index' );
}
