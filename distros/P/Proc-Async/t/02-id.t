#!perl -T

#use Test::More qw(no_plan);
use Test::More tests => 9;

# -----------------------------------------------------------------
# Tests start here...
# -----------------------------------------------------------------
ok(1);
use Proc::Async;
diag( "Job ID creation" );

# create a non-empty ID
my $jobid = Proc::Async::_generate_job_id();
ok (defined $jobid, "Job ID is empty");

# create a directory asociated with the given job ID
my $dir = Proc::Async::_id2dir ($jobid);
ok (-e $dir, "Directory '$dir' does not exist");
ok (-d $dir, "'$dir' is not a directory");
ok (-w $dir, "'$dir' is not writable");

# sub woking-dir()
is ($dir, Proc::Async->working_dir ($jobid), "working_dir() failed");
is (undef, Proc::Async->working_dir ($jobid . "XXX"), "working_dir() does not return undef");

# ...and remove that directory
Proc::Async->clean ($jobid);
ok (!-e $dir, "Directory '$dir' should not exist");

# job ID is the same as job directory
is ($jobid, $dir, "Job ID is not equal to the job directory");

# # use a specific location for the tempdir
# use File::Temp qw/ tempdir /;
# my $newdir = tempdir ( CLEANUP => 1 );
# my $another_jobid = Proc::Async::_generate_job_id ({ DIR => $newdir });
# ok (defined $another_jobid, "Job ID is empty (2)");

__END__
