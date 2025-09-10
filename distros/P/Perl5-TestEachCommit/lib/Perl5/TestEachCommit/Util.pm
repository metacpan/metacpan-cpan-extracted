package Perl5::TestEachCommit::Util;
use 5.014;
use Exporter 'import';
use Carp;
use File::Spec;
use File::Spec::Unix;
use Getopt::Long;
use locale; # make \w work right in non-ASCII lands

our $VERSION = 0.05; # Please keep in synch with lib/Perl5/TestEachCommit.pm
$VERSION = eval $VERSION;
our @EXPORT_OK = qw( process_command_line );

=head1 NAME

Perl5::TestEachCommit::Util - helper functions for Perl5::TestEachCommit

=head1 SUBROUTINES

=head2 C<process_command_line()>

Process command-line switches (options).  Returns a reference to a hash.  Will
provide usage message if C<--help> switch is present or if parameters are
invalid.

=cut

sub process_command_line {
    local @ARGV = @ARGV;

    my %opts = map { $_ => '' } ( qw|
        workdir
        branch
        start
        end
        configure_command
        make_test_prep_command
        make_test_harness_command
        skip_test_harness
        verbose
    | );

    my $result = GetOptions(
        "workdir=s" =>     \$opts{workdir},
        "branch=s" =>     \$opts{branch},
        "start=s" =>     \$opts{start},
        "end=s" =>     \$opts{end},
        "configure_command=s" =>     \$opts{configure_command},
        "make_test_prep_command=s" =>     \$opts{make_test_prep_command},
        "make_test_harness_command=s" =>     \$opts{make_test_harness_command},
        "skip_test_harness" =>     \$opts{skip_test_harness},
        "verbose" =>     \$opts{verbose},
    ) or croak "Error in command line arguments";

    return \%opts;
}

1;

