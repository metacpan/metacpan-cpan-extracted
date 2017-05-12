#!/usr/bin/perl -w

use strict;
use warnings;

use Net::SeedServe::Server;
use String::ShellQuote;
use Time::HiRes qw(usleep);
use IO::All;
use Getopt::Long;

use constant GIMP_VER => "2.3";

sub find_grand_seedserve_lib
{
    my @dirs = (qw(/usr/lib /usr/local/lib),
        split(/:/, $ENV{'LD_LIBRARY_PATH'}));
    foreach my $d (@dirs)
    {
        my $full_path = "$d/libgrand_seedserve.so";
        if (-f $full_path)
        {
            return $full_path;
        }
    }
    die "Could not find libgrand_seedserve.so!";
}

my $exit_type = "newline";
my $exit_string = "EXIT";
my $skip_tests = 0;
my $which_tests_re = "^.*\$";

sub should_skip
{
    my $fn = shift;
    return
        (($fn =~ /~$/) ||
        ($fn =~ /^\./) ||
        ($fn =~ /^__SKIP-/) ||
        ($fn !~ /$which_tests_re/o));
}

# Process the command line arguments
my $cmd_line_ok =
    GetOptions(
        "exit=s" => \$exit_type,
        "exit-string=s" => \$exit_string,
        "skip-tests" => \$skip_tests,
        "which-tests-re=s" => \$which_tests_re,
    );

if (!$cmd_line_ok)
{
    die "Incorrect command line options passed.";
}

if (!(($exit_type eq "newline") ||
      ($exit_type eq "immediate") ||
      ($exit_type eq "string")))
{
    die "Unknown --exit parameter \"$exit_type\".";
}

my $seed_server_status_file = "temp/server-status.txt";
# First of all - start the seed service.
my $seed_server =
    Net::SeedServe::Server->new(
        'status_file' => $seed_server_status_file,
    );

my $seed_server_port = $seed_server->start()->{'port'};

my $grand_ss_path = find_grand_seedserve_lib();

my $gimp_perl_server_socket_path = `perl get-socket-path.pl`;

unlink($gimp_perl_server_socket_path);
# Start the gimp
{
    local $ENV{'SEEDSERVE_PORT'} = $seed_server_port;
    local $ENV{'LD_PRELOAD'} = $grand_ss_path;
    system("gimp-".GIMP_VER(). " " .
        shell_quote("--batch=(extension-perl-server RUN-INTERACTIVE 0 0)") .
        " &"
        );
}

# Wait for the Perl server to run.
while (! -e $gimp_perl_server_socket_path)
{
    usleep(5000);
}
usleep(5000);

my (@failed, @passed);
if (! $skip_tests)
{
    # Now run the tests
    foreach my $file (io("./gen-scripts/")->all_files())
    {
        my $filename = $file->filename();
        if (should_skip($filename))
        {
            next;
        }
        my $test_name = $filename;
        $test_name =~ s/\.pl$//;
        print STDERR "Performing Test \"$filename\"\n";
        my $ret = system("perl", "run-script.pl", "$file", "--mode=check");
        if ($ret)
        {
            push @failed, $test_name;
        }
        else
        {
            push @passed, $test_name;
        }
    }
}

if ($exit_type eq "newline")
{
    print STDERR "Type <Return> to exit.\n";
    my $line = <STDIN>;
}
elsif ($exit_type eq "string")
{
    print STDERR "Type \"$exit_string\" to exit:\n";
    while (my $line = <STDIN>)
    {
        chomp($line);
        if ($line eq $exit_string)
        {
            last;
        }
    }
}

if (! $skip_tests)
{
    io("failed-report.txt")->print(map { "$_\n" }
        ("The following tests failed:", "", @failed));
    print STDERR "Passed " . scalar(@passed) .
        "; Failed " . scalar(@failed) . "\n";
    print STDERR "Report of failed tests written to failed-report.txt.\n";
}

END
{
    # Cleanup.
    system("perl", "quit-gimp.pl");
    $seed_server->stop();
}

