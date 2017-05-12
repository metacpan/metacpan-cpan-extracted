package Summerset::IsbnConverter;
require Exporter;
our @ISA = qw/Exporter/;
our @EXPORT = qw/convertToIsbn10 convertToIsbn13 generateIsbn10CheckDigit generateIsbn13CheckDigit validateIsbn10 validateIsbn13/;
our %EXPORT_TAGS = (all => [qw/convertToIsbn10 convertToIsbn13 generateIsbn10CheckDigit generateIsbn13CheckDigit validateIsbn10 validateIsbn13/]);

use 5.006;
use strict;
use warnings FATAL => 'all';

=head1 NAME

Summerset::IsbnConverter - Converts ISBN10 format to ISBN13 format and vice versa.  
This module also contains simple methods to validate ISBN10 and ISBN13 strings.

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';


=head1 SYNOPSIS

Simple module to convert ISBN10 to ISBN13 format and vice versa.


    use Summerset::IsbnConverter;

	my $isbn10 = '0395040892';
	my $isbn13 = Summerset::IsbnConverter::convertToIsbn13($isbn10);
		
	print $isnb13; # will print -> 9780395040898
    

=head1 EXPORT

convertToIsbn10 
convertToIsbn13 
generateIsbn10CheckDigit 
generateIsbn13CheckDigit 
validateIsbn10 
validateIsbn13

=head1 SUBROUTINES/METHODS

=head2 convertToIsbn10

Converts an ISBN13 format string, into ISBN10 format.

Requires a single ISBN13.  This ISBN must begin with the 978 prefix.  
Other ISBN13's are not convertable to ISBN10.  The ISBN13 may contain 
hyphens or other formatting characters/whitespace.  The ISBN13 string may not 
end with any whitespace.

Returns a string in ISBN10 format.

Returns undef on errors (eg, invalid ISBN13 provided).

=cut
sub convertToIsbn10 {	
	my $input = &_replaceNonDigitCharacters(shift);
	
	# make sure input was valid AND begins with 978 prefix 
	return undef unless &validateIsbn13($input) && $input =~ /^978/; 	
		
	# remove the prefix, then the check digit
	$input =~ s/^978//;	
	$input =~ s/\d$//;
	
	# return ISBN10 with the recalculated checkdigit
	return $input . &generateIsbn10CheckDigit($input);
}

=head2 convertToIsbn13

Converts an ISBN10 format string, into ISBN13 format.

Requires a single ISBN10.  The ISBN10 string may contain 
hyphens or other formatting characters/whitespace.  The ISBN13 string may not 
end with any whitespace.

Returns a string in ISBN13 format.

Returns undef on errors (eg, invalid ISBN10 provided).

=cut
sub convertToIsbn13 {
	my $input = &_replaceNonDigitCharacters(shift); 
			
	# make sure input was a valid ISBN10
	return undef unless &validateIsbn10($input);
	
	# remove the checkdigit, which can be an x
	$input =~ s/(\d|x)$//i;
	$input = '978' . $input; # add the isbn13 '978' prefix
	
	# return ISBN13 with the recalculated checkdigit
	return $input . &generateIsbn13CheckDigit($input);
	
}

=head2 generateIsbn10CheckDigit

Takes a single 9 character string as input.

Returns a single character check digit.  This is typically a numeric digit, however
this can occasionally be the letter 'X'. 

Returns undef on invalid input.  

=cut
sub generateIsbn10CheckDigit{
	my $input = shift;
	
	# requires a 9 digit scalar as input
	if ($input =~ /^\d{9}$/){
		my @exploded_input = split(//, $input);	
		
		my $sum 		= 0;
		my $multiplier 	= 10;
		
		# algorithm --> http://en.wikipedia.org/wiki/International_Standard_Book_Number
		for (my $i = 0; $i < scalar(@exploded_input); $i++){				
			$sum += $exploded_input[$i] * $multiplier;;						
			--$multiplier;
		}
		
		my $return_value = 11 - ($sum % 11);
		
		return $return_value == 10 ? 'X' : $return_value;		
	}
	else{
		# error occured 
		return undef;
	}	
}

=head2 generateIsbn13CheckDigit

Takes a single 12 character string as input. 

Returns a single character check digit.  This value will be a numeric digit.

Returns undef on invalid input.

=cut
sub generateIsbn13CheckDigit{	
	my $input = shift;
	
	# requires a 12 digit scalar as input
	if ($input =~ /^\d{12}$/){
		my @exploded_input = split(//, $input);	
		
		my $sum = 0;		
		
		# algorithm --> http://en.wikipedia.org/wiki/International_Standard_Book_Number
		for (my $i = 0; $i < scalar(@exploded_input); $i++){
			my $multiplier = $i % 2 == 0 ? 1 : 3;
			$sum += $exploded_input[$i] * $multiplier; 				
		}
		my $return_value = 10 - ($sum % 10);
		return $return_value;			
	}
	else{
		# error occured 
		return undef;
	}	
}

=head2 validateIsbn10

Takes a single ISBN10 string as input.  The input ISBN10 may contain extra whitespace
or formatting characters.

Returns a boolean value to indicate whether validation succeeded.

Returns undef on invalid input.

=cut
sub validateIsbn10 {		
	my $input 	= &_replaceNonDigitCharacters(shift) || '';	
	
	# 10 digits of input -- we use $1 below, so that's why we use a strange regex
	if ($input =~ /^(\d{9})(\d|X)$/i){	
		
		my $check_digit = &generateIsbn10CheckDigit($1);
		
		# validate the check digit of input, against one we calculate
		# we have to use string comparison here, because ISBN10 check digits can be 'X'
		if (&generateIsbn10CheckDigit($1) eq $2){
			return 1;
		}
		else{
			return 0;
		}		
	}
	else{					
		return 0;
	}
}

=head2 validateIsbn13

Takes a single ISBN13 string as input.  The input ISBN13 may contain extra whitespace
or formatting characters.

Returns a boolean value to indicate whether validation succeeded.

Returns undef on invalid input.

=cut
sub validateIsbn13 {
	my $input 	= &_replaceNonDigitCharacters(shift) || '';
			
	if ($input =~ /^(\d{3})(\d{9})(\d)$/){
		
		# validate the check digit of input, against one we calculate
		if (&generateIsbn13CheckDigit("${1}${2}") == $3){
			return 1;
		}
		else{
			return 0;
		}
	}
	else{
		return 0;
	}
}


# removes any non-digit characters from a single input.
# does not affect 'X' at the end of an ISBN10
sub _replaceNonDigitCharacters {
	my $input = shift || '';
	
	# hack: I forgot about the possible 'X' at the end of isbn10
	# we just check the input, and if it ends with an x.. we'll append it to our return value
	my $suffix_char = '';
	if ($input =~ /x$/i){
		$suffix_char = 'X';
	}		
	
	# strip any non-digit characters
	$input =~ s/\D//g;
	
	# hack: add 'X' back on the end, if required
	$input .= $suffix_char;	
	
	return $input;
}

=head1 AUTHOR

Derek J. Curtis, C<< <djcurtis at summersetsoftware.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-summerset-isbnconverter at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Summerset-IsbnConverter>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Summerset::IsbnConverter


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Summerset-IsbnConverter>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Summerset-IsbnConverter>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Summerset-IsbnConverter>

=item * Search CPAN

L<http://search.cpan.org/dist/Summerset-IsbnConverter/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Derek J. Curtis.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Summerset::IsbnConverter
