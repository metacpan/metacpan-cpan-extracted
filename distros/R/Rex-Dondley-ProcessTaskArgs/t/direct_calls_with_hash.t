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

is ref run_task('one'), 'HASH', 'returns a hash';
is_deeply run_task('one', params => {one => 'two'}), {one => 'two', three => undef}, 'returns hash with values and undefs missing non-required arg';
is_deeply run_task('one', params => { one => 'two' }), {one => 'two', three => undef}, 'returns hash with values and undefs missing non-required arg';
is_deeply run_task('one', params => {three => 'four'}), {one=> undef, three => 'four'}, 'returns same hash with correct values and undefs missing non-required args';
throws_ok { run_task('two') } qr/Missing required key/, 'reports missing key';
lives_ok { run_task('two', params => {one => 'two'}) } 'lives if required value is passed';
lives_ok { run_task('three', params => {one => 'two'}) } 'lives if unrequired value is not passed';
lives_ok { run_task('three', params => { one => 'two', two => 'seven' } ) } 'lives if unrequired value is passed';
dies_ok { run_task('three', params => { two => 'seven' } ) } 'dies if unrequired value is passed and required value is not passed';
throws_ok ( sub { run_task('three', params =>  { two => 'seven' } ) }, qr/Missing required key\(s\): 'one'/, 'throws error message' );
throws_ok ( sub { run_task('four', params => { two => 'seven' } ) }, qr/Missing required key\(s\): '(one|three), (three|one)'/, 'throws error message with all missing keys' );
throws_ok ( sub { run_task('one', params => { five => 'seven' } ) }, qr/Invalid key\(s\): 'five'/, 'throws error message for invalid keys' );
is_deeply run_task('five'), {one => 'boo', two => 'bah', three => ''}, 'processes default values';
is_deeply run_task('five', params => { one => 'baba' }), {one => 'baba', two => 'bah', three => ''}, 'default values can be overridden';
is_deeply run_task('five', params => { two => 'baba' }), {one => 'boo', two => 'baba', three => ''}, 'default values can be overridden';
is_deeply run_task('five', params => { two => 'baba', three => 'next' } ), {one => 'boo', two => 'baba', three => 'next'}, 'default values can be overridden';
is_deeply run_task('six', params => { 'one' => 3 } ), {one => 3, two => undef, three => undef}, 'recognized valueless keys as not required';

done_testing();
