package TAP::Formatter::JUnit::PrintTxtStdout;
# ABSTRACT: ...

use strict;
use warnings;
use Moose;
use Path::Tiny;
extends qw(TAP::Formatter::JUnit);

our $VERSION = '0.001';

=head1 NAME

TAP::Formatter::JUnit::PrintTxtStdout - improve TAP::Formatter::JUnit to print txt result to stdout

=head1 SYNOPSIS

   prove --formatter TAP::Formatter::JUnit::PrintTxtStdout ...

=head1 DESCRIPTION

=cut

=head1 METHODS

=head1 summary

Prints the summary report (in txt) after all tests are run.

=cut

sub summary {
    my $self = shift;
    return if $self->silent();

    my @suites = @{$self->testsuites};
    if ($ENV{PERL_TEST_HARNESS_DUMP_TAP}) {
        my $iter = path($ENV{PERL_TEST_HARNESS_DUMP_TAP})->iterator({recurse => 1});
        while (my $f = $iter->()) {
            next if $f->is_dir;
            next unless $f->basename =~ /\.t$/;
            print {$self->stdout} "-" x 80, "\n";
            print {$self->stdout} "$f\n";
            print {$self->stdout} $f->slurp_utf8;
        }

    } else {
        print {$self->stdout} $self->xml->testsuites(@suites);
    }
}

1;

=head1 SEE ALSO

=over 4

=item *

=back

