use Mojo::Base -strict;
use Test::More;
use Mojo::DB::Results::Role::MoreMethods -Pg, results_class => ['Mojo::mysql::Results'];

plan skip_all => 'Mojo::Pg not installed' unless eval { require Mojo::Pg; 1 };
plan skip_all => 'Mojo::mysql not installed' unless eval { require Mojo::mysql; 1 };

can_ok('Mojo::Pg::Results', qw(get get_by_name c c_by_name collections flatten));
can_ok('Mojo::mysql::Results', qw(get get_by_name c c_by_name collections flatten));

done_testing;
