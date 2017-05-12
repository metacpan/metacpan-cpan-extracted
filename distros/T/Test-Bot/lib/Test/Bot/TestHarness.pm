package Test::Bot::TestHarness;

use Any::Moose 'Role';
use File::Find;

requires 'run_tests_for_commit';

has 'test_files' => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    lazy_build => 1,
    clearer => 'reset_test_files',
);

# dig up all .t files in tests_dir
sub _build_test_files {
    my ($self) = @_;

    # get path to tests
    my $repo_dir = $self->source_dir;
    my $dir = $self->tests_dir;

    # assume $dir is under $repo_dir unless it's an absolute path
    $dir = "$repo_dir/$dir" unless $dir =~ /^\//;

    # find .t files
    my @found;
    find(sub { /\.t$/ && push @found, $File::Find::name; }, $dir);
    
    return \@found;
}

# run unit tests for each commit, notify on failure
sub test_and_notify {
    my ($self, @commits) = @_;

    foreach my $commit (@commits) {
        # check out commit, make sure that is what we are testing
        unless ($self->checkout($commit)) {
            $commit->test_success(0);
            $commit->test_output("Failed to check out commit");
            next;
        }

        # run the tests
        $self->run_tests_for_commit($commit);

        # done with test files, should regenerate them for each commit
        $self->reset_test_files;
    }

    # send notifications of tests
    $self->notify(@commits);
}

# checkout $commit into $source_dir
sub checkout {
    my ($self, $commit) = @_;

    my $source_dir = $self->source_dir;
    die "Source directory $source_dir does not exist" unless -e $source_dir;
    die "You do not have write access to $source_dir" unless -w $source_dir;

    # this will have to change, obviously
    my $id = $commit->id;
    my $force = $self->force ? '-f' : '';
    my $clean = $self->force ? "git clean -df; git reset --hard HEAD;" : '';
    `cd $source_dir; git fetch; $clean git checkout $force $id`;
    print "Checked out $id\n";

    return 1;
}

1;
