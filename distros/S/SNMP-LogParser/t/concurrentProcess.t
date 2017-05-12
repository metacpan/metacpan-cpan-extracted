#!perl

use strict;
use warnings;
use Test::More;
use Test::SharedFork;
use IPC::Run3;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use File::Spec;

# Make sure LOGPARSER_WAIT_TIME > FORK_WAIT_TIME
use constant {
    PROC_NUMBER         => 4,
    LOGPARSER_WAIT_TIME => 5,
    FORK_WAIT_TIME      => 1,
    NO_WAIT_TIME        => 0,
    CLEAN               => 0,
    DRIVER              => 'SNMP::LogParserDriver::ExampleLog',
    CONF_FILE           => File::Spec->catfile($Bin, qw/etc logparser.conf/),
    LOG4PERL_CONF       => File::Spec->catfile($Bin, qw/etc log4perl.conf/),
    LOGPARSER           => File::Spec->catfile($Bin, qw/.. blib script logparser/),
};

plan tests => PROC_NUMBER;

# We will span PROC_NUMBER children and we will force 
# the 1st logparser to wait internally LOGPARSER_WAIT_TIME seconds
# For the rest of the children, we will sleep FORK_WAIT_TIME before
# executing, but the execution will fail as the 1st logparser will
# still be running.
my @children;
for my $ix (1 .. PROC_NUMBER) {
    my $pid = fork;
    if ($pid) {
        # parent
        push @children, $pid;
    }
    elsif ($pid == 0) {
        # child
        if ($ix == 1) {
            $ENV{TEST_VERBOSE} and diag "Child [$ix] won't wait to be executed";
            my $rc = exec_logparser(LOGPARSER_WAIT_TIME);
            ok($rc, "child [$ix] executes OK");
        }
        else {
            $ENV{TEST_VERBOSE} and 
                diag sprintf "Child [$ix] will wait %s seconds to be executed", FORK_WAIT_TIME;
            sleep FORK_WAIT_TIME;
            my $rc = exec_logparser(NO_WAIT_TIME);
            ok(!$rc, "child [$ix] executes KO");
        }

        exit 0;
    }
    else {
        die "couldn’t fork: $!\n";
    }
}

waitpid($_, 0) for @children;

sub exec_logparser {
    my $seconds = shift;
    my @cmd = (
        LOGPARSER,
        '--file',            CONF_FILE,
        '-log4perl-file',    LOG4PERL_CONF,
        '--wait-after-lock', $seconds,
    );

    my ($out, $err);
    run3(\@cmd, undef, \$out, \$err);

    if ($?) {
        $err =~ s/[\n\r]//g;
        $ENV{TEST_VERBOSE} and diag "Execution failed: [$err]";
        return 0;
    }
    else {
        return 1;
    }
}
