=head1 NAME

Telephone::Mnemonic::US::Math - Helper module that for combinatorics pertaining to mnemonic calculations
=cut

package Telephone::Mnemonic::US::Math;

use 5.010000;
use strict;
use Data::Dumper;
use warnings;
use List::Util 'first';
our $VERSION = '0.07';
use base 'Exporter';
use Telephone::Mnemonic::US::Number 'to_digits';


our @EXPORT_OK = qw(  
	combinethem  
    sets2candidates
	str_pairs str_3sets 
	seg_words 
	find_valids 
	dict_path 
);
=pod

=head1 FUNCTIONS

=head2 str_paris

 Input: a string of variable length, like "1234"
 Output: set of substrings, like: '1' '234', '12' '34', '123' '4', '1234' ''
=cut

sub str_pairs {
	my $str = shift || return;
	my $len = length $str;
	my $stop = $len-2;
	my (@pairs,$parts);
	for (1..length $str) {
		my $lpart = substr $str, 0 , $_;
		my $rpart = substr $str, length ($lpart) ;
		push @pairs, [$lpart, $rpart];
		#$pairs{$lpart} = $rpart;
	}
	[@pairs];
}
=pod

=head2 seg_words

 Finds dictionary words that correspond to a number of any length
 Input: a tel number or mnemonic, a dictionary handler, and the search timeout 
 Output: a set of dictionary words  
=cut
sub seg_words {
	my ($num, $dict, $timeout) = @_ ;
	$timeout //=0;
	my $letters = _sets_of_letters( to_digits $num ) || return;
	my ($candidates, @valid)  ;
	local $SIG{ALRM} = sub {die};
	eval {
		alarm $timeout ;
		$candidates = sets2candidates( $letters ) || return;
		for (@$candidates) {
			push @valid, $_ if exists $dict->{$_};
		}
		alarm 0;
	};
    #say Dumper $letters; exit;
    #say Dumper @valid; #exit;
    @valid ;
}
=pod

=head2 dict_path

 Input: None
 Output: a string representing the filepath for the system dictionary 
=cut
sub dict_path {
	  first {-f $_} (qw{ /usr/share/dict/words /usr/lib/dict/words});
}
=pod

=head2 find_valids

 Finds dictionary words for substrings 
 Input: a tel number, a dictionary handler, and search timeout 
 Output: a set of word pairs, with each pair represents a set of valid dictionary 
        words for it's substrings
=cut
sub find_valids {
	my ($pairs, $dict, $timeout) = @_;
	return unless @$pairs;
	my $res;
	for (@$pairs) {
		my $h;
		$h->{lpart} = $_->[0];
        $h->{rpart} = $_->[1];
		my $llen =  length($_->[0])||0;
		my $rlen =  length($_->[1])||0;
        $h->{max_seg} = ($llen > $rlen) ? $llen : $rlen ;
		#TODO rewrite it the 4 lines bellow
		$h->{lvalid} = [seg_words( $_->[0], $dict, $timeout)];
		$h->{rvalid} = [seg_words( $_->[1], $dict, $timeout)];
		$h->{l_nval} = @{$h->{lvalid}};
		$h->{r_nval} = @{$h->{rvalid}};
		$h->{max_valid} = ($h->{l_nval} > $h->{r_nval}) ? $h->{l_nval} : $h->{r_nval} ;
		push @$res, $h;
	}
	$res;
}
=pod

=head2 sets2candidates

 Input: a string like '123'
 Output: a set of substrings 
=cut

sub sets2candidates {
	my $sets = shift;
    my $fragments=[];
    #TODO sanity checks

	#say Dumper $sets; exit;
	#$fragments = combinethem($sets->[1], $fragments) ;
	#$fragments = combinethem($sets->[0], $fragments) ;
	#say Dumper $fragments; exit;

	$fragments =  combinethem($_,$fragments) for reverse (@$sets); 
	$fragments;
}
=pod

=head2 str_paris

 Input:
 Output:
=cut
sub combinethem {
	my ($chars, $fragments) = @_ ;
	return $chars unless @$fragments ;
	my @res;
	push @res, @{combine_one($_,$fragments)} for @$chars;
	[@res];
}
=pod

=head2 str_paris

 Input:
 Output:
=cut
sub combine_one {
	my ($char, $fragments) = @_ ;
	 [ map { $_=$char . $_}  @{[@$fragments]}  ]
	
}
=pod

=head2 str_paris
 Input:
 Output:
=cut

sub _sets_of_letters {
    my $num = shift ||return;
    # error checking
    $num =~ s/[-\s]+//g;
    my @letters ;
    # filter input
    $num =~ s/\D+//;
    for (split //, $num ) {
        given (lc $_) {
            when ('2')   { push @letters,  [qw/a b c/]   }
            when ('3')   { push @letters,  [qw/d e f/]   }
            when ('4')   { push @letters,  [qw/g h i/]   }
            when ('5')   { push @letters,  [qw/j k l/]   }
            when ('6')   { push @letters,  [qw/m n o/]   }
            when ('7')   { push @letters,  [qw/p q r s/]  }
            when ('8')   { push @letters,  [qw/t u v/]   }
            when ('9')   { push @letters,  [qw/w x y z/]  }
            when (/[01]/)   { warn "can't map tel numbers containing 0 or 1\n";return}
            default:   { warn qq(seg_words: "$_" should not happen)}
        }
    }
    [@letters];
}
1;
=pod

=head1 SYNOPSIS

  use Telephone::Mnemonic::US::Math;

=head1 DESCRIPTION


=head1 EXPORT

None by default.


=head1 SEE ALSO

=head1 AUTHOR

ioannis, E<lt>ioannis@248.218.218.dial1.washington2.level3.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by ioannis

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
