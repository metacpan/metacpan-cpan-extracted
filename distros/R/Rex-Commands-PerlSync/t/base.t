use Test2::V0;
use Rex::Commands::PerlSync;

use autodie;

use File::Find;
use File::Temp qw(tempdir);
use Rex::Task;

################################################################################
# This tests whether the command works
################################################################################

subtest 'should sync_up' => sub {
	my $source = 't/sync';
	my $target = prepare_directory();

	run_task(
		sub {
			sync_up $source, $target;
		}
	);

	compare_contents($source, $target);
};

subtest 'should sync_up with excludes' => sub {
	my $source = 't/sync';
	my $target = prepare_directory();

	# NOTE: file4 should not be excluded, as it is nested
	run_task(
		sub {
			sync_up $source, $target,
				{exclude => ['dir/file2', 'file4', 'dir2']};
		}
	);

	compare_contents(
		$source, $target,
		['/dir/file2', '/dir2', '/dir2/file3']
	);
};

subtest 'should sync_down' => sub {
	my $source = 't/sync';
	my $target = prepare_directory();

	run_task(
		sub {
			sync_down $source, $target;
		}
	);

	compare_contents($source, $target);
};

subtest 'should sync_down with excludes' => sub {
	my $source = 't/sync';
	my $target = prepare_directory();

	# NOTE: file4 should not be excluded, as it is nested
	run_task(
		sub {
			sync_down $source, $target,
				{exclude => ['dir/file2', 'file4', 'dir2']};
		}
	);

	compare_contents(
		$source, $target,
		['/dir/file2', '/dir2', '/dir2/file3']
	);
};

sub prepare_directory
{
	my $target = tempdir(CLEANUP => 1);
	die unless -d $target;

	return $target;
}

sub run_task
{
	my ($func) = @_;

	my $task = Rex::Task->new(
		name => 'sync_test',
		func => $func,
	);

	$task->run('<local>');
}

sub compare_contents
{
	my ($source, $target, $excluded) = @_;
	$excluded //= [];
	my %excluded_map = map { $_ => 1 } @{$excluded};

	# test sync results
	my (@expected, @result);

	# expected results
	find(
		{
			wanted => sub {
				s/^\Q$source\E//;
				return unless length;
				return if $excluded_map{$_};
				push @expected, $_;
			},
			no_chdir => 1
		},
		$source
	);

	# actual results
	find(
		{
			wanted => sub {
				s/^\Q$target\E//;
				return unless length;
				push @result, $_;
			},
			no_chdir => 1
		},
		$target
	);

	is(
		\@result,
		bag {
			item $_ for @expected;
			end;
		},
		'synced dir matches'
	);
}

done_testing;

