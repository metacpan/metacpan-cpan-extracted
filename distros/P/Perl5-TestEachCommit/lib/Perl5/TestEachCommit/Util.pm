package Perl5::TestEachCommit::Util;
use 5.014;
use Exporter 'import';
use Carp;
use File::Spec;
use File::Spec::Unix;
use Getopt::Long;
use locale; # make \w work right in non-ASCII lands

our $VERSION = 0.07; # Please keep in synch with lib/Perl5/TestEachCommit.pm
$VERSION = eval $VERSION;
our @EXPORT_OK = qw( process_command_line );

=head1 NAME

Perl5::TestEachCommit::Util - helper functions for Perl5::TestEachCommit

=head1 SUBROUTINES

=head2 C<process_command_line()>

Process command-line switches (options).  Returns a reference to a hash.

B<Note:> This function is little more than a wrapper around
C<Getopt::Long::GetOptions()>.  As such, it performs no evaluation of any
interactions among the various command-line switches.  That evaluation is
deferred until C<Perl5::TestEachCommit::new() is called.

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
        make_minitest_prep_command
        make_minitest_command
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
        "make_minitest_prep_command=s" =>     \$opts{make_minitest_prep_command},
        "make_minitest_command=s" =>     \$opts{make_minitest_command},
    ) or croak "Error in command line arguments";

    return \%opts;
}

1;

