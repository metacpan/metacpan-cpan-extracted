use Mojo::Base -strict;
use Test::More;
use Mojo::DB::Results::Role::MoreMethods -Pg;

plan skip_all => 'Mojo::Pg not installed' unless eval { require Mojo::Pg; 1 };

can_ok('Mojo::Pg::Results', qw(get get_by_name c c_by_name collections flatten));

done_testing;
