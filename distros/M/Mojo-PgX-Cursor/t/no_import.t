use Mojo::Base -strict;

use Test::More;

plan skip_all => 'set TEST_ONLINE to enable this test' unless $ENV{TEST_ONLINE};

use Mojo::PgX::Cursor;

ok !Mojo::Pg::Database->can('cursor'), 'Mojo::Pg::Database can cursor';

done_testing();
