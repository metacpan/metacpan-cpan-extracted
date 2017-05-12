package String::Alignment;

use warnings;
use strict;
use List::Util qw(max min);

=head1 NAME

String::Alignment - Pair Sentence Alignment

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This module process string alignment.
Now it provide two kind of alignment method, Global and Local Alignment.

    use String::Alignment;

    use String::Alignment qw(do_alignment);

    # local alignment
    my $result = do_alignment($s1,$s2,1); 

    # global alignment
    my $result = do_alignment($s1,$s2); 

=head1 EXPORT

=cut 

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(do_alignment);

=head1 BUILD-IN VARIABLES

=cut 

my ($s1,$s2);	    # string1, string2
my (@sa1, @sa2);    # string array 1, string array 2

my ($len_s1, $len_s2) = (0,0); # length of s1/s2
my $is_local = 1; # 0 for global alignment

my %table;	    # Dynamic Programming Table

my $max_len;	    # for global
my %best;	    # Best path, for local

=head1 FUNCTIONS

=cut 

sub new {
#    print STDERR "I'm loaded\n";
}

sub do_alignment {
    $s1 = shift;
    $s2 = shift;
    $is_local = shift;
    $is_local = 0 unless defined($is_local);
    give_string_pair($s1,$s2);
    calculate_matrix();
#    similarity_print();
    return get_align_result();
}
=head2 give_string_pair

=cut 

sub give_string_pair {
    $s1 = shift;
    $s2 = shift;
    @sa1 = split //,$s1;
    @sa2 = split //,$s2;
    %table = ();
    %best = ();
    $best{MAX} = 0;
    $table{0}{0} = 0;
    ($len_s1, $len_s2) = (0,0);
}

=head2 cululate_matrix

=cut

sub calculate_matrix {
    if ($is_local) {
	$max_len = 0;
    } else {
	$max_len = scalar(@sa1) > scalar(@sa2) ? scalar(@sa1): scalar(@sa2); # for global
    }
#    print STDERR "max_len is ".$max_len."\n";
    while ($len_s1 <= (scalar @sa1)) {
	while ($len_s2 <= scalar @sa2) {
	    my ($candidate1, $candidate2, $candidate3) = ($max_len,$max_len,$max_len);
	    if ($len_s1 > 0 and $len_s2 > 0) {
		# if match, we add 1 for local, 0 for global
		# else (not matched), we add -1 for local, 1 for global
		$candidate1 = int($table{$len_s1-1}{$len_s2-1}) + 
		    (   $is_local ? 1: -1) *
		    ( ( $sa1[$len_s1-1] eq $sa2[$len_s2-1] )? 1+(-1+$is_local) : -1 )
		;
	    }
	    if ($len_s1 > 0) {
		$candidate2 = int($table{$len_s1-1}{$len_s2}) + 
		    ( $is_local ? (-1) : 1);
	    }
	    if ($len_s2 > 0) {
		$candidate3 = int($table{$len_s1}{$len_s2 - 1})  + 
		    ( $is_local ? (-1) : 1);
	    }
#	    print STDERR "setting ($len_s1,$len_s2)...";
#	    print STDERR "(".$candidate1."\t".$candidate2."\t".$candidate3.")\n";
	    if ($is_local) {
		$table{$len_s1}{$len_s2} = max (
		    $candidate1, $candidate2, $candidate3, 0
		) if ($len_s1 > 0 or $len_s2 > 0);
		$best{X} = $len_s1 if $best{MAX} <= $table{$len_s1}{$len_s2};
		$best{Y} = $len_s2 if $best{MAX} <= $table{$len_s1}{$len_s2};
		$best{MAX} = $table{$len_s1}{$len_s2} if $best{MAX} <= $table{$len_s1}{$len_s2};
	    } else { # global
		$table{$len_s1}{$len_s2} = min (
		    $candidate1, $candidate2, $candidate3
		) if ($len_s1 > 0 or $len_s2 > 0);
	    }
	    $len_s2 +=1;
	}
	$len_s2 = 0;
	$len_s1 +=1;
    }
}

=head2 similarity_print

=cut

sub similarity_print {
    print STDERR "\n \t \t".join("\t",@sa2)."\n";
    for my $key (sort {int($a) <=> int($b)}(keys %table)) {
	print STDERR $sa1[$key-1]."\t" if $key > 0;
	print STDERR " \t" unless $key > 0;
	for my $subkey (sort {int($a) <=> int($b)} (keys %{$table{$key}})) {
	    print STDERR $table{$key}{$subkey}."\t";
	}
	print STDERR "\n";
    }
};

=head2 get_align_result

=cut

sub get_align_result {
    my ($i, $j) = (0, 0);
    my (@as1, @as2);
    my $baseline = 0;
    if ($is_local) {
	$i = $best{X};
	$j = $best{Y};
    } else {
	$i = scalar @sa1;
	$j = scalar @sa2;
    }
    while ( $table{$i}{$j} > 0) {
	if ($is_local) { 
	    $baseline = max($table{$i-1}{$j-1},$table{$i-1}{$j},$table{$i}{$j-1});
	} else {
	    $baseline = min($table{$i-1}{$j-1},$table{$i-1}{$j},$table{$i}{$j-1});
	}
	if ($table{$i-1}{$j-1} == $baseline) {
	    push @as1, $sa1[$i-1];
	    push @as2, $sa2[$j-1];
	    $i--;
	    $j--;
	} elsif ($table{$i}{$j-1} == $baseline) {
	    push @as1, "-"; # gap
	    push @as2, $sa2[$j-1];
	    $j--;
	} elsif ($table{$i-1}{$j} == $baseline) {
	    push @as1, $sa1[$i-1];
	    push @as2, "-"; # gap
	    $i--;
	} else {
	    die $!;
	}
    }
    return ( join ("",reverse @as2)."\t".join ("",reverse @as1) );
}

=head1 AUTHOR

Cheng-Lung Sung, C<< <clsung@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-string-alignment@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=String-Alignment>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Cheng-Lung Sung, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of String::Alignment
