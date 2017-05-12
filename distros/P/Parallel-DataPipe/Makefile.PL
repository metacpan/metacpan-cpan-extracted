use 5.008;
use ExtUtils::MakeMaker;
use IO::Select;
use lib 'lib';
use Parallel::DataPipe;

print "Check if fork works on the platform...\n";
my $fork_ok = eval {
    my $pid = fork();
    if ($pid == 0) {
        exit;
    }
    my $child = wait;
    die "was not able to catch child!" unless $pid == $child;
    1;
};
die "Seems like fork does not work on the platform:\n$@" unless $fork_ok;

print "Check if pipe works here as intented...\n";
eval {
    my ($pipe_read,$pipe_write) = Parallel::DataPipe::pipely();
    my $origin = 'PIPE';
    $pipe_write->syswrite($origin);
    $pipe_read->sysread(my $buf,length($origin));
    die "Pipe read/write failed: content is corrupted" unless $buf eq $origin;
    1;
}  || die "Pipes does not work as intented on this platform, sorry:\n$@";

print "Fork & pipes looks good!\n";

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Parallel::DataPipe',
    VERSION_FROM      => 'lib/Parallel/DataPipe.pm', # finds $VERSION
    PREREQ_PM         => {
        # e.g., Module::Name => 1.1
        #'IO::Pipely' => '0.002',
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005

      (ABSTRACT => 'Parallel Data Processing Conveyor',
       AUTHOR         => 'Oleksandr Kharchenko <okharch@okharch.com>') : ()),
);
