use Rex::Dondley::ProcessTaskArgs;
use Rex -feature => [qw / 1.4 / ];
use Test::More;
use Test::Exception;
use strict;
use warnings;

my $one;
my $two;

task 'three' => sub {
	($one, $two) = process_task_args(\@_, one => 1, two => 0);
};


my @array = ();
run_task('three', params => { one => 'two', two => 'seven' });
is ($one, 'two', 'returns first array of value');
is $two, 'seven', 'returns second array of value';




done_testing();
