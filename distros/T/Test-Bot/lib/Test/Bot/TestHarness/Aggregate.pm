package Test::Bot::TestHarness::Aggregate;

use Any::Moose 'Role';
with 'Test::Bot::TestHarness';

has 'aggregate_verbosity' => (
    is => 'rw',
    isa => 'Int',
    default => -1,
);

use TAP::Harness;
use Capture::Tiny qw/tee/;

sub run_tests_for_commit {
    my ($self, $commit) = @_;

    my $success = 0;
    my $output = '';

    my $desc = "Testing commit " . $commit->id;
    $desc .= ' by ' . $commit->author if $commit->author;
    $desc .= "...\n\n";

    my $tests_dir = $self->tests_dir
        or die "tests_dir must be configured for aggregate test harness";

    # our harness
    my $harness = TAP::Harness->new({
        errors => 1,
        verbosity => $self->aggregate_verbosity,
    });
    
    # run tests, capture stderr
    my $results;
    my ($stdout, $stderr) = tee {
        $results = $harness->runtests(@{ $self->test_files });
    };    
    
    # get failed tests
    my @failed_desc  = $results->failed;
    my @exit_desc  = $results->exit;
    my @passed_desc  = $results->passed;
    $commit->passed(\@passed_desc);
    $commit->exited(\@exit_desc);
    $commit->failed(\@failed_desc);

    $success = $results->all_passed ? 1 : 0;

    unless ($success) {
        # list of unique failed tests
        my %failed;
        %failed = map { ($_ => 1) } (@failed_desc, @exit_desc);
        
        $output  = join("\n", map { " - Failed: $_" } keys %failed);
        $output .= "\n" if $output;
    }

    # append stderr capture
    if ($stderr) {
        my @errs = split("\n", $stderr);
        $output .= "Error output:\n  " . join("\n  ", @errs) if @errs;
    }
    
    $commit->test_success($success);
    $commit->test_output($output);
}

sub cleanup {
    my ($self) = @_;

}

1;
