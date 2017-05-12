package Peptide::Kmers;
# Peptide::Kmers - provides log_prop_kmers and kmers methods.

use Carp;
use warnings;
use strict;

=head2 new

  Args        : none
  Example     : my $pk = Peptide::Kmers->new(verbose => 2);
  Description : bare constructor
  Returns     : TRUE if successful, FALSE otherwise.

=cut

sub new {
    my $class = shift;
    my $self = bless { verbose => 1, @_ }, ref($class) || $class;
    return $self;
}

=head2 log_prop_kmers

  Args        : %named_parameters:
		k : length of the k-mer. Allowed values: positive integer. Mandatory.
		in_fh : filehandle for the input file. If missing, STDIN is used. 
		min : min number of occurrences. Allowed values: non-negative real number. Mandatory. Suggested values: 1 (equivalent to assuming that the k-mer occurred once even if it actually did not occur) or 0.5.
		maxtotal : max total number of occurrences. Allowed values: positive integer. Optional.
  Example     : my %log_prop = $pk->log_prop_kmers(k => 3, min => 1, text => [ qw(aecaecaecd aecd xyz123) ]);
  Description : For all overlapping k-mers (words of length k) in the input, computes the frequency of occurrence within the input text. Only allowed k-mers (those returned by kmers()) are counted. If the k-mer does not occur, min number of occurrences (eg, 0.5 or 1) is used as default threshold. Computes log10(proportion(k-mer)), where proportion(k-mer) = frequency(k-mer) / sum( all frequencies). For example, if input has 2 words: 'fooo' and 'bar', and k=2, the k-mers are: 'fo', 'oo', 'oo', 'ba', 'ar'. The frequencies are: 2 for 'oo', and 1 for the rest of the k-mers. Prints sum( all frequencies) into STDERR. If maxtotal is defined, input processing is stopped if sum( all frequencies) >= maxtotal. If this prevents any input from being processed, a warning is printed into STDERR. All warning can be suppressed by setting verbose arg to 1 or below). For comparing log10(proportion(k-mer)) from 2 different text sources, for example sequences and non-sequences, it is best to compute using the same sum( all frequencies). Thus, execute the code twice. First time, execute using undefined maxtotal, just to compute the sum( all frequencies) for the entire text from each of the sources. Second time, execute using the same maxtotal = min sum( all frequencies) for each source.
  Returns     : hash with keys = k-mers and values = log10(proportion(k-mer)) if successful, FALSE otherwise.

=cut

sub log_prop_kmers {
    my ($self, %args) = @_;
    $args{k} > 0 or carp "not ok: got k = $args{k}, expected > 0" and return;
    $args{min} >= 0 or carp "not ok: got min = $args{min}, expected >= 0" and return;
    not defined $args{maxtotal} or $args{maxtotal} > 0 or 
      carp "not ok: got maxtotal = $args{maxtotal}, expected undefined or > 0" and return;
    my $in_fh = $args{in_fh} || *STDIN;
    my $re = qr/(?=(.{$args{k}}))/;
    my %freq = map { $_ => 0 } $self->kmers(%args);
    # min $freq_total, if all k-mers did not occur:
    my $num_kmers = keys %freq;
    my $freq_total = $args{min} * $num_kmers; 
    if ($self->{verbose} > 1) {
	carp "WARNING: min * num_kmers >= maxtotal ",
	  "($args{min} * $num_kmers >= $args{maxtotal}), ",
	    "no input is processed" 
	      if defined $args{maxtotal} and $freq_total >= $args{maxtotal};
    }
    my $i = 0;
  INPUT: while (<$in_fh>) {
	chomp;
	if ($self->{verbose} > 1) {
	    if (not ++$i % 10_000) {
		print STDERR "log_prop_kmers: processing input line $i\n";
	    } 
	}
	foreach (/$re/g) {
	    last INPUT if defined $args{maxtotal} and $freq_total >= $args{maxtotal};
	    # count only allowed k-mers:
	    next unless defined $freq{$_};
	    # For the first occurrence of the k-mer, $freq{$_} is changed from $args{min} 
	    # to 1. Thus, subtract $args{min} from $freq_total.
	    # $freq{$_} is assigned to $args{min} separately, below,
	    # because testing if $freq{$_} is not ambiguous, and $freq{$_} == $args{min} 
	    # is ambiguous for $args{min} = 1 and for k-mer that actually occurred once.
	    # Note that k-mers that occur only once do not increase $freq_total 
	    # if $args{min} = 1
	    $freq_total -= $args{min} unless $freq{$_}; 
	    $freq_total++;
	    $freq{$_}++;
	}
    }
    print STDERR "freq_total=$freq_total" if $self->{verbose} > 1;
    foreach (keys %freq) {
	$freq{$_} = $args{min} if $freq{$_} < $args{min};
    }
    #warn 'log_prop_kmers: all: ', join "; ", map { "$_ => $freq{$_}" } sort keys %freq;
    #warn 'log_prop_kmers: freq: ', join "; ", map { "$_ => $freq{$_}" } qw(acc ppp 123);
    $freq_total ||= 1; # prevent division by 0
    #warn "freq_total=$freq_total";
    return unless keys %freq;
    my %log_prop = map { ( $_ => 
			   sprintf("%.2f", 
				   ( log($freq{$_} / $freq_total) / log(10) )
				  ) 
			 ) 
		     } keys %freq;
    #warn 'log_prop_kmers: log_prop: ', join "; ", map { "$_ => $log_prop{$_}" } qw(acc ppp 123);
    return %log_prop;
}

=head2 kmers

  Args        : %named_parameters:
		mandatory:
		k : length of the k-mer. Allowed values: positive integer.
  Example     : $pk->kmers(k => 3))[0,1,-1] # returns qw(aaa aab zzz)
  Description : Creates a list of different allowed k-mers (words of length k, using lowercase chars a-z). 
  Returns     : resulting list

=cut

sub kmers {
    my ($self, %args) = @_;
    $args{k} > 0 or carp "not ok: got k = $args{k}, expected > 0" and return;
    my @kmers = ('');
    # grow @kmers by adding to each existing el 1 char from the list of allowed chars 
    for my $i (1..$args{k}) { 
	my @kmers_new;
	foreach my $kmer (@kmers) {
	    # keep allowed chars in kmers(): 'a'..'z' in sync with 
	    # WordPropProtein() args : lc of tr/A-Za-z//cd;
	    foreach my $char ( 'a'..'z' ) {
		push @kmers_new, "$kmer$char";
	    }
	}
	@kmers = @kmers_new;
    }
    #warn "@kmers";
    return @kmers;
}

1;
