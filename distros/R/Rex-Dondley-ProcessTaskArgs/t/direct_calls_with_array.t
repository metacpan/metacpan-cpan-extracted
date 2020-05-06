use Rex::Dondley::ProcessTaskArgs;
use Rex -feature => [qw / 1.4 / ];
use Test::More;
use Test::Exception;
use strict;
use warnings;


task 'one' => sub {
  my $params = process_task_args(\@_, one => 0, three => 0);
};

task 'two' => sub {
	my $params = process_task_args(\@_, one => 1);
};

task 'three' => sub {
	my $params = process_task_args(\@_, one => 1, two => 0);
};

task 'four' => sub {
	my $params = process_task_args(\@_, one => 1, two => 0, three => 1);
};

# works with default values
task 'five' => sub {
	my $params = process_task_args(\@_, one => 1, two => 1, three => 0, [ 'boo', 'bah', '' ]);
};

task 'six' => sub {
  my $params = process_task_args(\@_, 'one', 'two', 'three');
};

is ref run_task('one', params => [ 'blah' ]), 'HASH', 'returns a hash';
is_deeply run_task('one', params => [ 'nuts' ]), {one => 'nuts', three => undef}, 'assigns args from hash reference';
is_deeply run_task('one', params => [ 'nuts', 'flour' ]),{one=> 'nuts', three => 'flour'}, 'assigns multiple args';
lives_ok { run_task('three', params => ['hi']) } 'lives if unrequired value is not passed';
lives_ok { run_task('three', params => [ 'two', 'seven' ] ) } 'lives if unrequired value is passed';
is_deeply run_task('five', params => [ 'boo', 'baba', 'next' ] ), {one => 'boo', two => 'baba', three => 'next'}, 'default values can be overridden';
is_deeply run_task('six', params => [ 3 ]), {one => 3, two => undef, three => undef}, 'recognized valueless keys as not required';

done_testing();
