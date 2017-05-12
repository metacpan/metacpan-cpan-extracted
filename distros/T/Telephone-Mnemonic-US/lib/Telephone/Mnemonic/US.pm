=head1 NAME

Telephone::Mnemonic::US - Maps US telephone numbers from mnemonic 'easy-to-remember' words to digits, it
can also attempts the reverse and maps telephone digits to mnemonic words.

=cut

package Telephone::Mnemonic::US;

#use 5.012001;
use strict;
use warnings;
use Data::Dumper;
use Tie::DictFile;
use Telephone::Mnemonic::US::Number qw/ to_tel_digits to_digits beautify/;
use Telephone::Mnemonic::US::Math qw/ str_pairs dict_path find_valids /;
use Scalar::Util 'looks_like_number';
use List::Util qw/ first /;
use Text::Table;

use base 'Exporter';

use 5.010000;
our @EXPORT_OK = qw( to_num to_words printthem);
our $VERSION   = '0.07';

=pod

=head2 printthem
 Input: the output of to_words (a href)
 Output: displays some of the data in a table
=cut
sub printthem {
	my ($input, $res) = @_ ;
	$res || return;
	my $t = new Text::Table; 
	print "$input:\n";
    my @data;
    for (@$res) {
		last if $_->{max_seg} < 3;
	 	 push @data , [ printvalids($_->{lvalid}),  printvalids($_->{rvalid}) ];
	}	
	$t->load( @data);
	say $t;
}
=pod

=head2 printvalids
 Helper function for printthem()
 Input: the hash ref
 Output: a stings 
=cut
sub printvalids {
	my $h = shift || return '';
	@$h || return '';
	join '|', @$h;
}

=pod

=head2 to_words
 Input: a string, like '703-111-2628', and an optional search timeout
 Output: sorted set of  dictionary words that correspond to the tel number substrings
=cut
sub to_words {
    #say "to word";
	my ($num, $timeout) = @_ ;
	$timeout //=0;
	my %hash;
    $Tie::DictFile::MAX_WORD_LENGTH = 14;
	tie %hash, 'Tie::DictFile', dict_path;
	#$num = to_tel_digits($num) || die "Not a US phone number. Aborting...\n";
	$num = to_digits($num) ;
	my $pairs = str_pairs($num);
	my $res = find_valids ($pairs, \%hash, $timeout);
	# sort by max segment
	[sort {	$a->{max_seg} < $b->{max_seg} }  @$res];
}
=pod

=head2 to_num
 Translates a mnemonic tel number to digits
 Input: an alphanumeric sting, like '(g03) verison'
 Output: a string like, like '(703) 232 3333'
=cut
sub to_num {
    my $word = lc shift;
	if ($word !~ /[-\.\sa-z]+/ ) {
			warn "Expected alphabetic letters for a tel number" ;
			return ;
	}
	my $res = to_tel_digits($word) or return ;
	beautify($res);
	#$res and $res =~ s/(\d*)(\d{4})$/$1-$2/;
	#$res and $res =~ s/^(\d{3})(.*)$/$1-$2/;
}

1;

=pod

=head1 SYNOPSIS

 use Telephone::Mnemonic::US    qw/ to_words to_num /;
 to_words('(263) 748 7233');           => ameritrade   assuming it was n the dictionary
 to_words('(263) 748 7233',9);         => ameritrade   but might timeout after 9 sec of searching
 to_num('ameritrade') ;                => (263) 748 7233  

=head1 DESCRIPTION

=head2 Converting Mnemonics to Digits

The B<to_num> function converts (a well formed ) telephone mnemonic to digits, returns 
undef on failure. A well formed US number must be something reasonable, it should contain
either 7, or 10 digits. You can supply it in many format,i.g. 703.verison, verison, 
gotverison, or got-ver-ison. On success, you receive a string such as '(703) 123 4567'

=head2 Converting Digits to Mnemonics

The B<to_words> function converts (a well formatted) telephone number to one or more mnemonics.
Unless you lucky to receive one dictionary word that maps to a 10-digit number, as partial 
match, you will probably receive several answers, with each answer matching one or two dictionary words.
If you requested a match for telephone number '(703) 404 2628', some  answers are bound to 
include the words 'boat', 'coat', and 'anat' as partial match for the last 4 digits.
An optional parameter can serve as search timeout. On success it returns a hash reference
containing all possible answers or partial segments; you could also use the I<printthem> function 
to display them.

It understands telephone numbers in many formants; numbers without area code or with mixture of letters and digits are possible but it is best to  stick with the formats supported by Number::Phone .

The Dictionary must be located at /usr/share/dict/words or at /usr/dict/words with
words in dictionary order.

=head2 EXPORT

None by default.



=head1 SEE ALSO

L<Tie::Dict>

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Ioannis Tambouras E<lt>ioannis@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Ioannis Tambouras

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
