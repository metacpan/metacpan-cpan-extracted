package Perl5::TestEachCommit::Util;
use 5.014;
use Exporter 'import';
use Carp;
use File::Spec;
use File::Spec::Unix;
use Getopt::Long;
use locale; # make \w work right in non-ASCII lands

our $VERSION = 0.02; # Please keep in synch with lib/Perl5/TestEachCommit.pm
$VERSION = eval $VERSION;
our @EXPORT_OK = qw(
    process_command_line
    usage
);
#prepare_repository

=head1 NAME

Perl5::TestEachCommit::Util - helper functions for Perl5::TestEachCommit

=head1 SUBROUTINES

=head2 C<process_command_line()>

Process command-line switches (options).  Returns a reference to a hash.  Will
provide usage message if C<--help> switch is present or if parameters are
invalid.

=cut

sub process_command_line {
    my %opts = @ARGV;
    my $result = GetOptions(\%opts)
        or croak "Error in command line arguments";
    #    usage("-", "invalid parameters") if not $result;
    usage("-") if defined $opts{help};  # see if the user asked for help
    $opts{help} = "";                   # just to make -w shut-up.
    return \%opts;
}

sub usage {
    say STDERR <<END_OF_USAGE;
Usage:  $0: DETAIL TO COME

END_OF_USAGE
}

1;

