# -*-perl-*-

#use Test::More qw(no_plan);
use Test::More tests => 5;

use Peptide::Kmers;
use Data::Dumper;
use Carp;
use warnings;
use strict;

my $verbose = defined $ENV{TEST_VERBOSE} ? $ENV{TEST_VERBOSE} : 1;

my $pk = Peptide::Kmers->new(verbose => $verbose );
ok($pk, 'Peptide::Kmers->new');

is(join(" ", ($pk->kmers(k => 3))[0,1,-1]), 'aaa aab zzz', 'kmers');

my %log_prop_kmers; 

my $log_prop_kmers;

# perl -le 'print join " ", map sprintf("%.1f", $_), (26**3), (1/26**3), ( log(1*1/26**3)/log(10) ), ( log(2*1/26**3)/log(10) ), ( log(3*1/26**3)/log(10) ), ( log(4*1/26**3)/log(10) );'
# 17576.0 0.0 -4.2 -3.9 -3.8 -3.6

# number of the k-mers in text
# 12345678---90---1----
# aecaecaecd aecd xyz123

my $in_fname = 't/tmp.04kmers.txt';
my $in_fh;
open $in_fh, ">$in_fname" or carp "not ok: open $in_fname: $!";
print $in_fh <<EOF;
aecaecaecd aecd
xyz123
EOF
close $in_fh or carp "not ok: close $in_fname: $!";

open $in_fh, $in_fname or carp "not ok: open $in_fname: $!";
is(
   to_string( $pk->log_prop_kmers(k => 3, in_fh => $in_fh, min => 1 ) ),
   'aec => -3.6; ecd => -3.9; xyz => -4.2; 123 => -9999.0; aed => -4.2; Aec => -9999.0',
   'log_prop_kmers without maxtotal: all k-mers of text are processed'
  );
close $in_fh or carp "not ok: close $in_fname: $!";

open $in_fh, $in_fname or carp "not ok: open $in_fname: $!";
is(
   to_string( $pk->log_prop_kmers(k => 3, in_fh => $in_fh, min => 1, maxtotal => 17576 ) ),
   'aec => -4.2; ecd => -4.2; xyz => -4.2; 123 => -9999.0; aed => -4.2; Aec => -9999.0',
   'log_prop_kmers with maxtotal <= min * number of k-mers: no k-mers of text are processed'
  );
close $in_fh or carp "not ok: close $in_fname: $!";

open $in_fh, $in_fname or carp "not ok: open $in_fname: $!";
is(
   to_string( $pk->log_prop_kmers(k => 3, in_fh => $in_fh, min => 1, maxtotal => (17576+1) ) ),
   'aec => -3.9; ecd => -4.2; xyz => -4.2; 123 => -9999.0; aed => -4.2; Aec => -9999.0',
   'log_prop_kmers with maxtotal = min * number of k-mers + 1: only first min + 1 = 2 k-mers of text are processed'
  );
close $in_fh or carp "not ok: close $in_fname: $!";

sub to_string {
    my (%log_prop_kmers) = @_;
    join "; ", 
      map { "$_ => " . sprintf("%.1f", defined $log_prop_kmers{$_} ? $log_prop_kmers{$_} : -9999) } qw(aec ecd xyz 123 aed Aec);
}
