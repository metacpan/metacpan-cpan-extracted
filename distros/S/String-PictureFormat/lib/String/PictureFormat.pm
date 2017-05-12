=head1 NAME

String::PictureFormat - Functions to format and unformat strings based on a "Picture" format string

=head1 AUTHOR

Jim Turner

(c) 2015, Jim Turner under the same license that Perl 5 itself is.  All rights reserved.

=head1 SYNOPSIS

use String::PictureFormat;

print "-formatted=".fmt('@"...-..-...."', 123456789)."=\n";
#RETURNS "123-45-6789".

print "-unformatted=".unfmt('@"...-..-...."', '123-45-6789')."=\n";
#RETURNS "123456789".

print "-formatted=".fmt('@$,12.2>', 123456789)."= \n";
#RETURNS "    $123,456,789.00".

print "-format size=".fmtsiz('@$,12.2>')."= \n";
#RETURNS 18.

print "-formatted=".fmt('@$,12.2> CR', -123456789)."=\n";
#RETURNS "    $123,456,789.00 CR".

print "-formatted=".fmt('@$,12.2> CR', 123456789)."=\n";
#RETURNS "    $123,456,789.00   ".

print "-formatted=".fmt('@$,12.2>', -123456789)."=\n";
#RETURNS "   $-123,456,789.00".

print "-formatted=".fmt('@-$,12.2>', -123456789)."=\n";
#RETURNS "    -$123,456,789.00".

print "-formatted=".fmt('@$(,12.2>)', -123456789)."=\n";
#RETURNS "    $(123,456,789.00)".

$_ = fmt('=16<', 'Now is the time for all good men to come to the aid of their country');
print "-formatted=".join('|',@{$_})."=\n";
#RETURNS "Now is the time   |for all good men  |to come to the aid|of their country  =".

sub foo {
	(my $data = shift) =~ tr/a-z/A-Z/;
	return $data;
}

print "-formatted=".fmt('@foo()', 'Now is the time for all')."=\n";
#RETURNS "NOW IS THE TIME FOR ALL"

print "-formatted=".fmt('@tr/aeiou/AEIOU/', 'Now is the time for all')."=\n";
#RETURNS "NOw Is thE tImE fOr All"

exit(0);

=head1 DESCRIPTION

String::PictureFormat provides functions to format and unformat character strings according to separate 
format strings made up of special characters.  Typical usage includes left and right justification, 
centering, floating dollar signs, adding commas to numbers, formatting phone numbers, Social-Security 
numbers, converting negative numbers to accounting notations, creating text files containing tables 
of data in fixed-column format, etc.

=head1 EXAMPLES

See B<SYNOPSIS>

=head1 FORMAT STRINGS

Format strings consist of special characters, explained in detail below.  Each format string begins 
with one of the following characters:  "@", "=", or "%".  "@" indicates a standard format string that 
can be any one of several different formats as described in detail below.  "=" indicates a format 
that will "wrap" the text to be formatted into multiple rows.  "%" indicates a standard C-language 
"printf" format string.

=over 4

=item "@"-format strings:

The standard format strings that begin with an "@" sign can be in one of the following formats:

1)  @"literal-picture-string" or @'literal-picture-string' or @/literal-picture-string/ or @`literal-picture-string`

=over 4

This format does a character-by-character converstion of the data.  They can be escaped with "\" 
to include as literals, if needed.  The special characters are:

"." - return the next character in the data.
"^" - skip the next character in the data.
"+" - return all remaining characters in the string.

For example, to convert an integer number to a phone number with area code, one could do:

my $ph = fmt('@"(...) ...-.+"', '1234567890 x101');
print "-phone# $ph\n";   #-phone# (123) 456-7890 x101

Or, to format a social security number and return a string of asterisks if it is too long:

my $ss = fmt('@"...-..-...."', '123456789', {-truncate => 'error'});
print "-ssn: $ss\n"      #-ssn: 123-45-6789

Now suppose you had part numbers where the 3rd character was a letter and the rest were digits 
and you want only the digits, you could do:

my $partseq = fmt('@"..^.+"', '12N345');
print "-part# $partseq\n"  #-part# 12345

=back

2)  @justification-string

=over 4

This consists of the special characters "<", "|", and ">", with optional numbers preceeding them 
to indicate repetition, an optional decimal point, an optional prefix of "floating" characters, 
and / or an optional suffix of literal characters.  Each of the first three characters shown above 
represent a single character of data to be returned and correspond to "left-justify", "center", or 
"right-justify" the data returned.  For example, the most basic format is:

my $str = fmt('@>>>>>>>>>', 'Howdy');
print "-formatted=$str=\n";    #-formatted=     Howdy=

This returns a 10-character string right-justified (note that the "@" sign counts as one of the 
characters representing the size of the field).  This could've also been abbreviated as:

my $str = fmt('@9>', 'Howdy');

You can mix and match the three special characters, but the first one determines justification.  
The only exception to this is if a decimal point is provided and the data is numeric.  In that 
case, if ">" is used after the decimal point, trailing decimal places will be rounded and removed 
if necessary to get the string to fit, otherwise, either asterisks are returned if it won't fit 
and the "-truncate => 'error'" option is specified.  The decimal point is explicit, not implied. 
This means that a number will be returned as that value with any excess decimal places removed or 
zeros added to format it to the given format.  For example:

fmt('@6.2>', 123.456) will return "    123.46" (ten characters wide, right justified with two 
decimal places).  The total width is ten, due to the fact that there are 6 digits left of the 
decimal + 2 decimal places + the decimal point + the "@" sign = 10.  The full format could've 
been given as "@>>>>>>.>>".

Characters between the "@" sign and the first justification character are considered "floating" 
characters and anything after the last one is a literal suffix.  The main uses for the suffix 
is to specify negative numbers in accounting format.  Here's some examples:

fmt('@$6.2>', 123.456) will return "    $123.45" (eleven characters wide with a floating "$"-
sign.  The field width is eleven instead of ten due to a space being provided for the floating 
character.  

Commas are a special floating character, as they will be added to large numbers automatically 
as needed, if specified.  Consider:

fmt('@$,8.2>', 1234567) will return "  $1,234,567.00".  Fifteen characters are returned: 
9 for the whole number, 1 for the decimal point, 2 decimal places, the "@" sign, the "$" sign, 
and one for each "," added.

There are several ways to format egative numbers.  For example, the default is to just leave 
the negative number sign intact.  In the case above, the result would've been:
" $-1,234,567.00".  This could be changed to "  -$1,234,567.00" by including the "-" sign as 
a float character before the floating "$" sign, ie.  fmt('@-$,8.2>', 1234567).  Note that 
the string is now sixteen characters long with the addition of another float character.  Also 
note that had the number been positive, the "-" would've been omitted automatically from the 
returned result!  You can force a sign to be displayed (either "+" or "-" depending on 
whether the input data is a positive or negative number) by using a floating "+" instead of 
the floating "-".

If you are formatting numbers for accounting or tax purposes, there are special float and 
suffix characters for that too.  For examples:

fmt('@$,8.2>CR', -123456.7) will return "   $123,456.70CR".  The "CR" is replaced by "  " if 
the input data is zero or positive.  To get a space between the number and the "CR", simply 
add a space to the suffix, ie. "@$,8.2> CR".

Another common accounting format is parenthesis to indicate negative numbers.  This is 
accomplished by combining the special float character "(" with a suffix that starts with a 
")".  For example:

fmt('@($,8.2>)', -123456.7) will return "   ($123,456.70)".  The parenthesis will be replaced 
by spaces if the number is zero or positive.  However, the space in lieu of the "(" may 
instead be replaced by an extra digit if the number is large and just barely fits.  If one 
desires to have the "$" sign before the parenthesis, simply do "fmt('@$(,8.2>)', -123456.7)" 
instead!  Note that "+" and "-" should not be floated when using parenthesis or "CR" notation.

Since floating characters, particularly floating commas, and negative numbers can increase 
the width of the returned value causing variations in width; if you are needing to create 
columns of fixed width, an absolute width size can be specified (along with the 
"{-truncate => 'error'}" option.  This is given as a numeric value followed by a colon 
immediately following the "@" sign, for example:

fmt('@16:($,8.2>)', -123456.7, {-truncate => 'error'})

This forces the returned value to be either 16 characters right-justified or 16 "*"'s to be
returned.  You should be careful to anticipate the maximum size of your data including any 
floating characters to be added.

=back

3)  @^date/time-picture-string[^data-picture-string]^ (Date / Time Conversions):

=over 4

This format does a character-by-character converstion of date / time data based on certain 
substrings of special characters.  The list of special character strings are described in 
L<Date::Time2fmtstr>.  If this optional module is not installed, then the following are 
available:

B<yyyy> - Year in 4 digits.

B<yy>, B<rr> - Year in last 2 digits.

B<mm> - Number of month (2 digits, left padded with a zero if needed), ie. "01" for January. 

B<dd> - Day of month (2 digits, left padded with a zero if needed), ie. "01".

B<HH>, B<hh> - Hour in 24-hour format, 2 digits, left padded with a zero if needed, ie. 00-23. 

B<mi> - Minute, ie. 00-59. 

B<ss> - Seconds since start of last minute (2 digits), ie. 00-59. 

A valid date string will be formatted / unformatted based on the I<format-string>.  If 
B<Date::Fmtstr2time> and B<Date::Time2fmtstr> are installed, the "valid date string" being 
processed by B<fmt>() can be, and the output produced by B<unfmt>() will be a Perl/Unix time 
integer.  Otherwise, the other valid data strings processed by B<fmt>() are 
"yyyymmdd[ hhmmss]", "mm-dd-yyyy [hh:mm:ss]", etc.  B<unfmt>() will return 
"yyyymmdd[ hhmm[ss]" unless B<Date::Time2fmtstr> is installed, in which case, it returns 
a Perl/Unix time integer.  This can be changed specifying either B<-outfmt> or a 
I<data-picture-string>.  NOTE:  It is highly recommended that both of these modules be 
installed if formatting or unformatting date / time values, as the manual workarounds used 
do not always produce desired results.

Examples:

fmt('@^mm-dd-yy^, 20150108) will return "01-08-15".

fmt('@^mm-dd-yy hh:mi^, '01-08-2015 10:25') will return "01-08-15 10:25".

fmt('@^mm-dd-yy^, '2015/01/08') will return "01-08-15".

fmt('@^mm-dd-yy^, 1420781025) will return "01-08-15", if B<Date::Time2fmtstr> is installed.

unfmt('@^mm-dd-yy^, '01-08-15') will return "20150108" unless B<Date::Fmtstr2time> is 
installed, in which case it will return 1420696800 (equivalent to "2015/01/08 00:00:00".

unfmt('@^mm-dd-yy^, '01-08-15', {-outfmt => 'yyyymmdd'}) will always return "20150108", 
if B<Date::Time2fmtstr> is also installed.

unfmt('@^mm-dd-yy^yyyymmdd^, '01-08-15') works the same way, always returning "20150108", 
if B<Date::Time2fmtstr> is also installed.

NOTE:  If using B<unfmt>() with either a I<data-picture-string> or I<-outfmt> is specified, 
and B<Date::Time2fmtstr> is not installed, then I<data-picture-string> or I<-outfmt> must be 
set to "yyyymmdd[hhmm[ss]]" or it will fail.

=back

4)  Regex substitution:

=over 4

This format specifies a Perl "regular expression" to perform in the input data and outputs 
the result.  For example:

$s = fmt('@s/[aeiou]/\[VOWEL\]/ig;', 'Now is the time for all');
would return:
"N[VOWEL]w [VOWEL]s th[VOWEL] t[VOWEL]m[VOWEL] f[VOWEL]r [VOWEL]ll".

The new string is returned as-is regardless of length.  To truncate it to a maximum fixed 
length, specify a length constraint.  You can also specify the "-truncate => 'error' 
option to return a row of "*" of that length if the resulting string is longer, ie:
$s = fmt('@50:s/[aeiou]/\[VOWEL\]/ig;', 'Now is the time for all', {-truncate => 'error'});

Perl's Translate (tr) function is also supported, ie:

$s = fmt('@tr/aeiou/AEIOU/', 'Now is the time for all');
would return "NOw Is thE tImE fOr All".

=back

5)  User-supplied functions:

=over 4

You can write your own custum translate function for full control over the data translation.  
You can also supply any arguments to it that you wish, however two special ones are 
provided for your use:  "*" and "#".  If you do not pass any parameters to the function, 
then it will be called with "(*,#)".  "*" represents the input data string and "#" 
represents the maximum length to be returned (if not specified, it is zero, which means 
the returned string may be any length.  For example:

$s = fmt('@foo', 'Now is the time for all');
print "-s=$s=\n";
...
sub foo {
	my ($data, $maxlength) = @_;
	print "-max. length=$maxlength= just=$just= data in=$data=\n";
	$data =~ tr/a-z/A-Z/;
	return $data;
}

This would return "NOW IS THE TIME FOR ALL".  This is the same as:
$s = fmt('@foo(*,#)', 'Now is the time for all');

To call a function with just the $data parameter, do:

$s = fmt('@foo(*)', 'Now is the time for all');

To specify a maximum length, say "50" do:

$s = fmt('@50:foo', 'Now is the time for all', {-truncate => 'error'});

To append a suffix string ("suffix" in the example, not counted in the max. length) do:

$s = fmt('@foo()suffix', 'Now is the time for all');

which would return "NOW IS THE TIME FOR ALLsuffix".

=back

=item "="-format strings:

These specify text "wrapping" for long strings of characters.  Data can be wrapped at either 
character or word boundaries.  The default is to wrap by word.  Consider:

$s = fmt('=15<', 'Now is the time for all good men to come to the aid of their country');
print "-s=".join('|',@{$s})."=\n";

This will print: 
"-s=Now is the time |for all good men|to come to the  |aid of their    |country         "
The function returned the data as a reference to an array, each element containing a "row"
or "line" of 16 characters of data broken on the nearest "word boundary" and left-justified.
Each "row" is right-padded with spaces to bring it to 16 characters (the "=" sign plus the 
"15" represents a row width of 16 characters.  I use "|" to show the boundary between each 
row/line.

$s = fmt('=15>', 'Now is the time for all good men to come to the aid of their country');
would've returned (right-justified):
" Now is the time|for all good men|  to come to the|    aid of their|         country"

$s = fmt('=15|', 'Now is the time for all good men to come to the aid of their country');
would've returned (centered):
" Now is the time|for all good men| to come to the |  aid of their  |     country    "

To specify simple character wrapping (spaces remain intact), one can add "w" to the 
format string like so:

$s = fmt('=w14<', 'Now is the time for all good men to come to the aid of their country');
This would return:
"Now is the time |for all good men| to come to the |aid of their cou|ntry            "
NOTE:  The change of "15" to "14".  This is due to the fact that the "w" adds one to the 
row "size"!

With "w" (character wrapping), justification is pretty meaningless since each row (except 
the last) will always contain the full number of characters with spaces as-is (no 
spaces added).  However, the last row will be affected if spaces have to be added to fill 
it out.  To get the string represented "properly", it's usually best to use "<" (left-
justification).

The default is "word" wrapping, so a format string of "=15<" is the same as "=W14<".

=item "%" (C-language) format strings:

You can specify a C/Perl language "printf" format string by preceeding it with a "%" sign.
For example:

fmt('%-12.2d', -1234);

returns "-1234       "

There is the added capability of floating "$" sign and commas.  For example:

fmt('%$,12.2f', -1234) returns "    $-1,234.00".  Note the width is 14 instead of 12 
characters, since the two floating characters add to the width of the final results.
The "$" sign and "," are the only floating character options.

=back 

=head1 METHODS

=over 4

=item <$scalar> || <@array> = B<fmt>(I<format-string>, I<data-string> [, I<ops> ]);

Returns either a formatted string (scalar) or an array of values.  The <format-string> 
is applied to the <data-string> to convert it to a new format (see the myriad of 
examples in this documentation).  If the specified return value is in ARRAY 
context, the elements are:

[0] - The string or array reference returned in the scalar context ("wrap" formats 
return an array reference, and all others return a string).

[1] - The length (integer) of the data formatted - note that this is not always the actual 
length of the returned data.  It represents the maximum "format length", which is 
the max. no. of characters the format can return.  If the format is open-ended, 
ie. if the last character in a fixed format is "+", or the length is indeterminate, 
it will return zero.  For "wrap" formats, it is the no. of characters in a row.
If a max. length specifier is given (ie. "@50:..."), then this value is returned.

[2] - The justification (either "<", "|", ">", or "", if no justification is 
involved).

I<format-string> is the format string (required).

I<data-string> is the data to be formatted (required).

I<ops> is an optional hash-reference representing additional options.  The 
currently valid options are:

=over 4

B<-bad> => '<char>' (default '*') - The character to fill the output string if the 
output string exceeds the specified maximum length and <-truncate> => 'error' is 
specified.

B<-infmt> => I<format-string> (default '') - Alternate format to expect the incoming 
data to be in.  If a I<data-picture-string>, it overrides this option.  If specified, 
in a B<fmt>() call, it causes input data to be read in in this format layout (before 
being formatted by the I<format-string>) and returned.  Otherwise (if neither this 
option nor a I<data-picture-string> is specified), the data can be in a variety of 
layouts that B<fmt>() can recognize.  This option is not particularly useful 
except for some additional error-checking, and generally need not be used.

NOTE:  If this option is specified, and B<Date::Fmtstr2time> is not installed, then 
it must be set to "yyyymmdd[hhmm[ss]]" or the format will fail.

B<-nonnumeric> => true | false (default false or 0) - whether or not to ignore 
"numeric"-specific formatting, ie. adding commas, sign indicators, decimal places, 
etc. even if the data is "numeric".

B<-outfmt> => I<format-string> (default '') - Alternate format to return the 
"unformatted" result in.  If a I<data-picture-string>, it overrides this option.  
If specified in a B<unfmt>() call, it causes the result to be formatted according to 
this format (after being unformatted by the I<format-string>) and returned.  
Otherwise (if not specified), the result is returned as a Perl / Unix Time integer 
(if B<Date::Fmtstr2time> is installed) or in "yyyymmdd[hhmm[ss]]" format if not.

NOTE:  If this option is specified, and B<Date::Time2fmtstr> is not installed, then 
it must be set to "yyyymmdd[hhmm[ss]]" or the unformat will fail.

B<-sizefixed> => true | false (default false or 0) - If true, prevents expansion of 
certain numeric formats when the number is positive or more than one comma is added.  
What it actually does is set the format size to be fixed to the value returned by 
B<fmtsiz>() for the specified I<format-string>.  This ensures that the format 
size will be the same reguardless of what value is passed to it.

B<-suffix> => '[yes]' | 'no' (default yes) - If 'no', then any suffix string is 
ignored (not appended) when formatting and not removed when unformatting.  Specifying 
anything but "no" implies the default of yes.

B<-truncate> => '[yes]' | 'no' | 'er[ror]' - Whether or not to truncate output 
data that exceeds the maximum width.  The default is 'yes'.  Specifying 'no' means 
return the entire output string regardless of length.  'er', 'err', 'error', etc. 
means return a row of asterisks (changable by B<-bad>).  If the string does not 
begin with "no" or "er", it is assumed to be "yes".

=back

=item <$scalar> || <@array> = B<unfmt>(I<format-string>, I<data-string> [, I<ops> ]);

For the most part, this is the opposite of the B<fmt>() function.  It takes a 
string and attempts to "undo" the format and return the data as close as 
possible to what the input data string would've looked like before the 
<format-string> was applied by assuming that the input <data-string> is the 
result of having previously had that <format-string> applied to it by B<fmt>().  
It is not always possible to exactly undo the format, consider:

my $partseq = fmt('@"..^.+"', '12N345');
my $partno = unfmt('@"..^.+"', $partseq);

would return "12 345", since the original format IGNORED the third character 
"N" in the original string.  Since this is unknown, unfmt() interprets "^" as 
insert a space character.  Careful use of unfmt() can often produce desired 
results.  For example:

$s = fmt('@$,10.2> CR', '-1234567.89');
print "-s4 formatted=$s=\n";    # $s ="    $1,234,567.89 CR"
$s = unfmt('@$,10.2> CR', $s);
print "-s4 unformatted=$s=\n";  # $s ="-1234567.89" (The original number)

=item <$integer> = B<fmtsiz>(I<format-string>);

Returns the format "size" represented by the <format-string>, just like the 
second element of the array returned by B<fmt>() in array context, see above.  
If a maximum length specifier is given, it returns that.  Otherwise, attempts 
to determine the length of the data string that would be returned by applying 
the format.  For "wrap" formats, this is the length of a single row.  For 
regular expressions and user-supplied functions, it is zero (indeterminate).

=item <$character> = B<fmtjust>(I<format-string>);

Returns a character indicating the justification (if any) represented by the 
specified <format-string>, just like the third element of the array returned 
by B<fmt>() in array context, see above.  The result can be either "<", ">", 
"|", or "", if not determinable.

=item <$integer> = B<fmtsuffix>(I<format-string>, I<data-string> [, I<ops> ]);

Returns the "suffix" string, if any, included in the <format-string>.

=back

=head1 KEYWORDS

formatting, picture_clause, strings

=cut

package String::PictureFormat;

use strict;
#use warnings;
use vars qw(@ISA @EXPORT $VERSION);
$VERSION = '1.11';

use Time::Local;

require Exporter;

my $haveTime2fmtstr = 0;
my $haveFmtstr2time = 0;

@ISA = qw(Exporter);
@EXPORT = qw(fmt fmtsiz fmtjust fmtsuffix unfmt);

sub fmt {       #FORMAT INPUT DATA STRING BASED ON "PICTURE" STRING:
	my $pic = shift;
	my $v = shift;
	my $ops = shift;

	my $leni = 0;
	my $suffix;
	my $errchar = $ops->{'-bad'} ? substr($ops->{'-bad'},0,1) : '*';
	my $justify = ($pic =~ /^.*?([<|>])/o) ? $1 : '';
	my $fixedLeni = $ops->{-sizefixed} ? fmtsiz($pic) : 0;
	if ($pic =~ s/^\@//o) {               #@-strings:
		$leni = $1  if ($pic =~ s/^(\d+)\://o);
		$leni = $fixedLeni  if ($fixedLeni);
		if ($pic =~ s#^([\'\"\/\`])##o) {         #PICTURE LITERAL   (@'foo'
			my $regexDelimiter = $1;         #REPLACE EACH DOT WITH NEXT CHAR. SKIP ONES CORRESPONDING WITH "^", ALL OTHER CHARS ARE LITERAL.
			$suffix = ($pic =~ s#\Q$regexDelimiter\E(.*)$##) ? $1 : '';
			my $cnt = 0;                #EXAMPLE: fmt("@\"...-..-.+\";suffix", '123456789'); FORMATS AN SSN:
			my $frompic = '';
			my $graball = 0;
			my $charsHandled = 0;       #NO. OF CHARS IN THE INPUT STRING THAT CAN BE OUTPUT.
			$pic =~ s/\\\+/\x02/go;     #PROTECT ESCAPED METACHARACTERS.
			$pic =~ s/\\\./\x03/go;
			$pic =~ s/\\\^/\x04/go;
			my $t = $pic;
			while ($t =~ s/\^//o) {
				$charsHandled++;
			}
			$pic =~ s/([\.]+[+*?]?|[\^]+)/
				my $one = $1;
				if ($one =~ s!\^!\.!go)
				{
					$frompic .= $one;
					''
				}
				else
				{
					my $catcher = '('.$1.')';
					$graball = 1  if ($one =~ m#\+$#o);
					$frompic .= $catcher;
					++$cnt;
					'$'.$cnt
				}
			/eg;
			my $evalstr = '$v =~ s"'.$frompic.'"'.$pic.'"';
			if ($graball) {
				$charsHandled = length($v);
			} else {
				my $l = 0;
				$t = $frompic;
				while ($t =~ s/\((\.+)\)//o) {
					$l += length($1);
				}
				$charsHandled += $l;
				unless ($leni) {
					($t = $pic) =~ s/\$\d+//og;
					$l += length($t);
					$leni = $l;
				}
			}
			my $v0 = $v;
			eval $evalstr;
			$v =~ s/\x04/\^/go;   #UNPROTECT METACHARACTERS.
			$v =~ s/\x03/\./go;
			$v =~ s/\x02/\+/go;
			if ((length($v0) > $charsHandled || ($leni > 0 && length($v) > $leni)) && $ops->{'-truncate'} !~ /no/io) {
				$v = ($ops->{'-truncate'} =~ /er/io) ? $errchar x $leni : substr($v, 0, $leni);
			}
			$v .= $suffix  unless ($ops->{'-suffix'} =~ /no/io);
			return wantarray ? ($v, $leni, $justify) : $v;
		} elsif ($pic =~ s#^\^##o) {  #DATE-CONVERSION
			eval 'use Date::Time2fmtstr; $haveTime2fmtstr = 1; 1'  unless ($haveTime2fmtstr);
			$pic =~ s/\\\^/\x04/go;   #PROTECT ESCAPED "^" IN FORMAT STRING!
			$suffix = ($pic =~ s#\^([^\^]*)$##) ? $1 : '';
			$suffix =~ s/\x04/\^/go;  #UNPROTECT ESCAPED "^" IN FORMAT STRING!
			my $inpic = '';
			($pic, $inpic) = split(/\^/, $pic)  if ($pic =~ /\^/);
			$pic =~ s/\x04/\^/go;     #UNPROTECT ESCAPED "^" IN FORMAT STRING!
			$inpic ||= $ops->{'-infmt'}  if ($ops->{'-infmt'});
			my $perltime = 0;
			if ($inpic) {
				$inpic =~ s/\x04/\^/go;  #UNPROTECT ESCAPED "^" IN FORMAT STRING!
				eval 'use Date::Fmtstr2time; $haveFmtstr2time = 1; 1'  unless ($haveFmtstr2time);
				$perltime = str2time($v, $inpic)  if ($haveFmtstr2time);
				unless ($perltime || (length($v) == length($inpic) && $inpic =~ /^yyyymmdd(?:hhmm(?:ss)?)?$/i)) {
					$leni ||= $fixedLeni || length($inpic);
					$v = $errchar x $leni;
					return wantarray ? ($v, $leni, $justify) : $v;
				}
			}
			my $t;
			$perltime ||= ($v =~ /^\d{9,11}$/o) ? $v : 0;
			unless ($perltime) {  #WE HAVE A DATE STRING, IE. yyyy-dd-mm, etc. THAT CHKDATE CAN HANDLE:
				($t, $perltime) = _chkdate($v);
				unless ($t || $perltime) {       #chkdate() DID NOT RECOGNIZE THE INPUT STRING, SO PUNT.
					$leni ||= $fixedLeni || length($pic);
					$v = $errchar x $leni;
					return wantarray ? ($v, $leni, $justify) : $v;
				}
				if ($haveTime2fmtstr) {
					$v = $perltime || &timelocal(0,0,0,substr($t,6,2),
							(substr($t,4,2)-1),substr($t,0,4),0,0,0);
				}
			}
			$v = $perltime  if ($perltime);
			if ($perltime) {   #WE HAVE A PERL "TIME" (EITHER GIVEN OR RETURNED BY chkdate():
				if ($haveTime2fmtstr) {       #WE ALSO HAVE Time2fmtstr!:
					$t = time2str($v, $pic);
					$leni ||= $fixedLeni || length($t);
					if ($leni && length($t) > $leni && $ops->{'-truncate'} !~ /no/io) {
						$v = ($ops->{'-truncate'} =~ /er/io) ? $errchar x $leni 
								: substr($t, 0, $leni);
					} else {
						$v = $t;
					}
					$v .= $suffix  unless ($ops->{'-suffix'} =~ /no/io);
					return wantarray ? ($v, $leni, $justify) : $v;
				} else {    #NO Time2fmtstr, SO WE'LL CONVERT PERL "TIME" TO "yyyymmdd hhmmss" FOR MANUAL CONVERSION:
					my @tv = localtime($v);  #NOTE: MANUAL CONVERSION DOESN'T HANDLE ALL THE FORMAT PICTURES THAT Time2fmtstr DOES!:
					$t = sprintf('%4.4d',$tv[5]+1900) . sprintf('%2.2d',$tv[4]+1) . sprintf('%2.2d',$tv[3])
							. ' ' . sprintf('%2.2d',$tv[2]) . sprintf('%2.2d',$tv[1]) . sprintf('%2.2d',$tv[0]);
				}
			}
			if ($t =~ /^\d{8}(?: \d{4,6})?$/o) {    #WE HAVE A DATE/TIME STRING WE CAN (TRY) TO CONVERT MANUALLY:
				$pic =~ s/yyyy/substr($t,0,4)/ie;
				$pic =~ s/yy/substr($t,2,4)/ie;
				$pic =~ s/mm/substr($t,4,2)/ie;
				$pic =~ s/dd/substr($t,6,2)/ie;
				$pic =~ s/hh/substr($t,9,2)/ie;
				$pic =~ s/mi/substr($t,11,2)/ie;
				$pic =~ s/ss/substr($t,13,2)/ie;
				$v = $pic;
				$leni ||= $fixedLeni || length($v);
				if ($leni && length($v) > $leni && $ops->{'-truncate'} !~ /no/io) {
					$v = ($ops->{'-truncate'} =~ /er/io) ? $errchar x $leni 
							: substr($t, 0, $fixedLeni);
				}
				$v .= $suffix  unless ($ops->{'-suffix'} =~ /no/io);
				return wantarray ? ($v, $leni, $justify) : $v;
			} else {     #WE GOT NOTHING WE CAN WORK WITH, SO PUNT!
				$leni ||= $fixedLeni || length($pic);
				$v = $errchar x $leni;
				return wantarray ? ($v, $leni, $justify) : $v;
			}
		} elsif ($pic =~ m#^(?:s|tr)(\W)#) {          #REGEX SUBSTITUTION (@s/foo/bar/)
			my $regexDelimiter = $1;
			$suffix = ($pic =~ s#([^$regexDelimiter]+)$##) ? $1 : '';
			my $regexPostOp = ($suffix =~ s/^(\w+)\;//) ? $1 : '';
			my $evalstr = '$v =~ '.$pic.$regexPostOp;
			eval $evalstr;
			if ($leni && length($v) > $leni && $ops->{'-truncate'} !~ /no/io) {
				$v = ($ops->{'-truncate'} =~ /er/io) ? $errchar x $leni : substr($v, 0, $leni);
			}
			$v .= $suffix  unless ($ops->{'-suffix'} =~ /no/io);
			return wantarray ? ($v, $leni, $justify) : $v;
		} elsif ($pic =~ /^[a-zA-Z_]+/o) {     #USER-SUPPLIED FUNCTION (@foo('*'))
			$suffix = ($pic =~ s/\)([^\)]*)$/\)/) ? $1 : '';
			$pic =~ s/\\\*/\x02/og;   #PROTECT ESCAPED METACHARACTERS:
			$pic =~ s/\\\#/\x03/og;
			$pic =~ s/\\\(/\x04/og;
			$pic =~ s/\\\)/\x05/og;
			$pic =~ s/\(\s*\)/\(\*\,\#\)/o;   #WE ALWAYS PASS IT THE INPUT STRING AND LENGTH WE'RE EXPECTING (OR ZERO)
			if ($v =~ /^\d+$/o)
			{
				$pic =~ s/\*/$v/g;
			}
			else
			{
				$pic =~ s/\*/\'$v\'/g;
			}
			$pic =~ s/\#/$leni/g;    #UNPROTECT ESCAPED METACHARACTERS:
			$pic =~ s/\x05/\)/og;
			$pic =~ s/\x04/\(/og;
			$pic =~ s/\x03/\#/og;
			$pic =~ s/\x02/\*/og;
			$pic = 'main::' . $pic  unless ($pic =~ /^\w+\:\:/o);
			my $t;
			$pic =~ s/(\w)(\W*)$/$1\(\'$v\',$leni\)$2/  unless ($pic =~ /\(.*\)/o);
			eval "\$t = $pic";
			$t = $@  if ($@);
			if ($leni && length($t) > $leni && $ops->{'-truncate'} !~ /no/io) {
				$t = ($ops->{'-truncate'} =~ /er/io) ? $errchar x $leni : substr($t, 0, $leni);
			}
			$t .= $suffix  unless ($ops->{'-suffix'} =~ /no/io);
			return wantarray ? ($t, $leni, $justify) : $t;
		} else {                               #REGULAR JUSTIFY STUFF, IE. @12>.>>)
			my $leniSpecified = $leni;
			if ($pic =~ /^\*(.*)$/)	{   #WE'RE JUST AN ASTERISK, JUST RETURN THE INPUT STRING UNCHANGED:
				$suffix = $1;
				if ($leni && length($v) > $leni && $ops->{'-truncate'} !~ /no/io) {
					$v = ($ops->{'-truncate'} =~ /er/io) ? $errchar x $leni : substr($v, 0, $leni);
				}
				$v .= $1  unless ($ops->{'-suffix'} =~ /no/io);
				return wantarray ? ($v, 0, '<') : $v;
			}
			$suffix = ($pic =~ s/([^\<\|\>\.\^]+)$//o) ? $1 : '';
			my ($special, $float, $t);
			my $commatize = 0;
			while ($pic =~ s/^([^\d\<\|\>\.\^])//o) {  #STRIP OFF ALL CHARS BEFORE <, >, |, OR DIGIT AS "FLOATING CHARS".
				$special = $1;
				if ($special eq ',') {   #COMMA (@,) = ADD COMMAS EVERY 3 DIGITS:
					$commatize = 1  unless ($ops->{'-nonnumeric'});
				} else {
					$float .= $special; #OTHERS, IE. (@$) ARE FLOATERS:
				}
			}
			my $switchFloat = ($float =~ /\+\$/o) ? 1 : 0;   #SPECIAL CASE: USER WANTS SIGN *BEFORE* "$"
			if ($float =~ /\(/o)   #ONLY KEEP FLOATING "(" IF SUFFIX STARTS WITH A ")"!
			{
				$float =~ s/\(//o  unless ($suffix =~ /^\)/o);
			}
			if ($v < 0)
			{
				$float =~ s/\+//go  unless ($ops->{'-nonnumeric'});   #REMOVE FLOATING "+" IF VALUE IS NEGATIVE.
				$leni = 1 + length($float)  unless ($fixedLeni || $leniSpecified);  #COUNT FLOATING CHARS IN FIELD SIZE:
			}
			else
			{
				$leni = 1 + length($float)  unless ($fixedLeni || $leniSpecified);  #COUNT FLOATING CHARS IN FIELD SIZE:
				$float =~ s/\-//o  unless ($ops->{'-nonnumeric'});
				$leni++  if (!($fixedLeni || $leniSpecified) && $float =~ s/\(//o);   #REMOVE FLOATING "(..)" IF VALUE IS NOT NEGATIVE.
			}
			$pic =~ s/(\d+)[<|>]?([\.\^]?)(\d*)([<|>])/
					my ($one, $dec, $two, $three) = ($1, $2, $3, $4);
					$dec ||= '.';
					my $exp = ($three x $one);
					$exp .= $dec . ($three x $two)  if ($two > 0);
					$exp
			/e;        #CONVERT STUFF LIKE "@12.2>" TO "@<<<<<<<<<<<<.<<".
			#DEFAULT JUSTIFY:  RIGHT IF COMMATIZING(NUMBER) OR FLOATING$ OR PICTURE CONTAINS DECIMAL;
			#OTHERWISE, DEFAULT IS LEFT.
			$justify ||= (!($ops->{'-nonnumeric'})
					&& ($commatize || $float =~ /\$/o || $pic =~ /[\.\,\^\$]/o)) ? '>' : '<';
			#CALCULATE FIELD SIZE BASED ON NO. OF "<, >, |" AND PRECEEDING REPEATER DIGITS (UNLESS PRE-SPECIFIED BY "@##:":
			unless ($fixedLeni || $leniSpecified)
			{
				$leni += length($pic); # && $pic =~ /([<|>\.]+)/o);
			}
			my ($wholePic, $decPic) = split(/[\.\^]/o, $pic);
			my $decLeni = 0;
			my $wholeLeni = $leni;
			my $decJustify = $justify;
			if ($decPic && !$ops->{'-nonnumeric'}) {   #PICTURE CONTAINS A DECIMAL (REAL OR IMPLIED), CALCULATE SEPARATE LENGTHS, ETC.
				$decLeni = 0;
				$t = $decPic;
				$decLeni += length($1)  while ($t =~ s/([\<\|\>\.\^\,\$]+)//o);
				$decLeni += $1 - 1  while ($t =~ s/(\d+)//o);
				$decJustify = $1  if ($decPic =~ /([\<\|\>])$/o);  #WE DON'T "JUSTIFY" DECIMALS, BUT USE FOR DETERMING TRUNCATION, IF NEEDED.
				$wholeLeni = $leni - ($decLeni + 1);
				if ($pic !~ /\./o && $v !~ /\./) {  #WE HAVE AN "IMPLIED DECIMAL POINT!
					$v = sprintf("%.${decLeni}f", $v / (10**$decLeni))  if ($v =~ /^[\+\-\d\. ]+$/o);
				}
				my ($whole, $decimal) = split(/\./o, $v);   #SPLIT THE VALUE IN TWO:
				unless ($float =~ /\+/o) {
					$whole =~ s/^-//o  if ($v >= 0 || $suffix =~ /^[\_ ]*CR\s*$/io)
				}
				my $l = length($whole);
				while ($l > $wholeLeni && $float && $float ne '(') {   #FIRST REMOVE FLOAT CHARACTERS IF WON'T FIT:
					--$l  if ($float =~ s/.(\(?)$/$1/);
				}
				$t = $whole . '.' . $decimal;
				if ($decJustify eq '>') {   #CHOP RIGHT-MOST DECIMAL PLACES AS NEEDED TO FIT IFF DECIMAL PART IS "RIGHT-JUSTIFIED"
					while (length($t) > $leni && $t =~ /\./o) {   #NOTE:WE DON'T "JUSTIFY" THE DECIMAL PART!
						chop $t;
						$decLeni--;
					}
				}
				$decLeni = 0  if ($decLeni < 0);
				$pic = '%.'.$decLeni.'f';   #BUILD SPRINTF TO ADD/ROUND DECIMAL PLACES.
				$t = sprintf($pic, $v);     #JUST THE NUMBER W/PROPER # OF DECIMAL PLACES.
			} else {
				$t = $v;
				my $l = length($v);
				unless ($ops->{'-nonnumeric'}) {
					while ($l > $leni && $float) {   #FIRST REMOVE FLOAT CHARACTERS IF WON'T FIT:
						chop($float);
						--$l;
					}
					while (length($t) > $leni && $t =~ /\./o) {
						chop $t;
					}
				}
			}
			unless ($ops->{'-nonnumeric'})
			{
				if ($v >= 0)   #SPECIAL ACCOUNTING SUFFIX "CR" OR " CR":  REMOVE IF VALUE >= 0:
				{
					$suffix =~ s/^([\_ ]*)CR\s*$/' 'x(length($1)+2)/ei;
				}
				else           #INCLUDE SPECIAL SUFFIX "CR" OR " CR" IF VALUE < 0 FOR ACCOUNTING:
				{
					$t =~ s/\-//o  if ($suffix =~ s/^([\_ ]*)(CR\s*)$/(' 'x(length($1))).$2/ei);
				}
			}
			$t =~ s/^\-//o  if ($float =~ /[\(\-]/o);
			my $l = length($t);
			my $t2;
			while ($l < $leni && $float) {   #DIDN'T SPLIT ON ".", SO ONLY ADD FLOAT CHARS IF WILL STILL FIT:
				$t2 = chop($float);
				unless (!$ops->{'-nonnumeric'} && $t2 eq '(' && $v >= 0) {
					$t = $t2 . $t;
					++$l;
				}
			}
			$t =~ s/^[^ \d\<\|\>\.]([ \d\.\-\+]+)$/\($1/  if ($l == $leni && $v < 0 && $float =~ s/\(//o && !$ops->{'-nonnumeric'});
			if ($commatize) {      #ADD COMMAS TO LARGE NUMBERS EVERY PLACES, IF WILL FIT:
				$l = length($t);
				if ($decJustify eq '>') {
					while ($l > $leni && $t =~ /\./o) {   #CHOP OFF LOW-ORDER DECIMAL PLACES AS NEEDED TO FIT:
						chop $t;
					}
				}
				while ((!$leniSpecified || $l < $leni) && $t =~ s/(\d)(\d\d\d)\b/$1,$2/) {  #ADD COMMAS AS NEEDED:
					$l = length($t);
					$leni++  unless ($fixedLeni || $leniSpecified);
				}
			}
			$t =~ s/\$\-/\-\$/o  if ($switchFloat);
			if ($ops->{'-truncate'} =~ /er/io && length($t) > $leni) {  #WON'T FIT AND USER WANTS ERROR IF SO:
				$v = $errchar x $leni;
			} elsif ($ops->{'-truncate'} !~ /no/io || length($t) <= $leni) {  #USER WANTS TRUNCATED, IF WON'T FIT:
				$leni--  if (!($fixedLeni || $leniSpecified) && $float =~ /\(/o);
				if ($justify eq '|') {    #JUSTIFY:
					my $j = int(($leni - $l) / 2);
					$v = sprintf("%-${leni}s", (' ' x $j . $t));
					return wantarray ? ($v, $leni, $justify) : $v;
				} elsif ($justify eq '<') {
					$v = sprintf("%-${leni}s", $t);
				} else {
					$v = sprintf("%${leni}s", $t);
				}
			} else {   #USER WANTS EVERYTHING, EVEN IF WON'T FIT:
				$leni--  if (!($fixedLeni || $leniSpecified) && $float =~ /\(/o);
				$v = $t;
			}
			$suffix =~ s/^\)/ /o  unless ($v =~ /\(/o);
			$v .= $suffix  unless ($ops->{'-suffix'} =~ /no/io);
			return wantarray ? ($v, $leni, $justify) : $v;
		}
	} elsif ($pic =~ s/^\=//o) {    #FIELDS STARTING WITH "=" ARE TO BE WRAPPED TO MULTIPLE LINES AS NEEDED:
		$leni = $fixedLeni  if ($fixedLeni);
		my ($justify, $wrapchar) = ('<', 'W');    #DEFAULTS.
		my $j = 1;
		$suffix = ($pic =~ s/([^wW<|>\d]+)$//o) ? $1 : '';
		$wrapchar = 'w'  if ($pic =~ /w/o);         #LITTLE w=WRAP AT CHARACTER:
		$justify = $1  if ($pic =~ /^.*([<|>])/o);  #BIG W=WRAP AT WORD BOUNDARIES (Text::Wrap):
		$j += length($1)  while ($pic =~ s/([wW<|>]+)//o);
		$j += $1 - 1  while ($pic =~ s/(\d+)//o);
		$leni = $j  unless ($fixedLeni);         #WIDTH OF FIELD AREA TO WRAP WITHIN:
		my $mylines = 0;
		my $t;
		if (length $pic) {
			$suffix = ($ops->{'-suffix'} !~ /no/io) ? $pic . $suffix : $pic;
			$pic = '';
		}
		my $suffixPadding = ' ' x length($suffix);
		if ($wrapchar eq 'W') {     #WRAP BY WORD (Text::Wrap):
			require Text::Wrap; Text::Wrap->import( qw(wrap) );
#no warnings;
			$Text::Wrap::columns = $leni + 1;
#use warnings;
			eval {$t = wrap('','',$v);};
			if ($@) {
				$wrapchar = 'w';   #WRAP CRAPPED :-(, DO MANUALLY (BY CHARACTER)!
			} else {
				my @fli = split(/\n/o, $t);   #@fli ELEMENTS EACH REPRESENT A LINE:
				if ($justify eq '>') {     #JUSTIFY:
					for (my $i=0;$i<=$#fli;$i++) {
						$fli[$i] = sprintf("%${leni}s", $fli[$i]);
						unless ($ops->{'-suffix'} =~ /no/io) {
							$fli[$i] .= (!$i || $ops->{'-suffix'} =~ /all/io)
									? $suffix : $suffixPadding
						}
					}
				} elsif ($justify eq '|') {
					my $l;
					for (my $i=0;$i<=$#fli;$i++) {
						$l = length($fli[$i]);
						$j = int(($leni - $l) / 2);
						$fli[$i] = sprintf("%${leni}s", ($fli[$i] . ' 'x$j));
						unless ($ops->{'-suffix'} =~ /no/io) {
							$fli[$i] .= (!$i || $ops->{'-suffix'} =~ /all/io)
									? $suffix : $suffixPadding
						}
					}
				} else {
					my $l;
					for (my $i=0;$i<=$#fli;$i++) {
						$l = length($fli[$i]);
						$j = int(($leni - $l) / 2);
						$fli[$i] = sprintf("%-${leni}s", $fli[$i]);
						unless ($ops->{'-suffix'} =~ /no/io) {
							$fli[$i] .= (!$i || $ops->{'-suffix'} =~ /all/io)
									? $suffix : $suffixPadding
						}
					}
				}
				$t = join("\n", @fli);   #CAN RETURN #LINES AS 2ND ELEMENT:
				return wantarray ? (\@fli, $leni, $justify, scalar(@fli)) : \@fli;
			}
		}
		if ($wrapchar eq 'w') {    #WRAP BY CHARACTER (WORDS MAY BE SPLIT):
			$j = 0;
			my $l = length($v);
			my @fli = ();
			while ($j < $l)
			{
				push (@fli, substr($v,$j,$leni));
				$mylines += 1;
				unless ($ops->{'-suffix'} =~ /no/io) {
					$fli[$#fli] .= (!$j || $ops->{'-suffix'} =~ /all/io)
							? $suffix : $suffixPadding
				}
				$j += $leni;
			}
			if ($justify eq '>') {
				$fli[$#fli] = sprintf("%${leni}s", $fli[$#fli]);
			} elsif ($justify eq '|') {
				$l = length($fli[$#fli]);
				$j = int(($leni - $l) / 2);
				$fli[$#fli] = sprintf("%${leni}s", ($fli[$#fli] . ' 'x$j));
			} else {
				$fli[$#fli] = sprintf("%-${leni}s", $fli[$#fli]);
			}
			return wantarray ? (\@fli, $leni, $justify, scalar(@fli)) : \@fli;
		}
	} elsif ($pic =~ s/^\%//o) {         #C-PRINTF FORMAT STRINGS (%-STRINGS) (AS-IS, "%" NOT INCLUDED IN FIELD SIZE):
		$leni = $fixedLeni  if ($fixedLeni);
		my $float = ($pic =~ s/^\$//o) ? '$' : '';  #EXCEPTION:  FLOATING $, COMMA(COMMATIZE) ALLOWED AFTER "%":
		my $commatize = ($pic =~ s/^\,//o) ? 1 : 0;    #IE:  "%$,-14.2f":  FIELD SIZE=16!
		$suffix = ($pic =~ s/^(\-?[\d\.]+\w)(.*)$/$1/o) ? $2 : '';
		$leni = ($pic =~ /^\-?(\d+)/) ? $1 : length($v)  unless ($fixedLeni);
		my $lj = ($pic =~ /^\-/o) ? '-' : '';
		$justify = ($lj eq '-') ? '<' : '>';
		$pic = '%' . $pic;
		my $t;
		my $decimal = ($pic =~ /\.(\d+)/o) ? $1 : 0;
		if ($float) {
			$lj = '';
			$lj = '-'  if ($pic =~ s/^\%\-/\%/o);
			unless ($fixedLeni) {
				$leni += length($float)  if ($pic =~ /^\%(\d+)/o);
			}
			$v = sprintf("%.${decimal}f", $v);
		}
		my $l;
		if ($commatize) {   #USER WANTS COMMAS ADDED TO LARGE NUMBERS:
			unless ($fixedLeni) {
				$leni++  if ($pic =~ /^\%(\d+)/o);
			}
			$l = length($v);
			while ($l > $leni && $v =~ /\./o) {
				chop $v;
			}
			if ($l > $leni) {
				$v = $errchar x $leni;
				return wantarray ? ($v, $leni, $justify) : $v;
			}
			while ($l < $leni && $v =~ s/(\d)(\d\d\d)\b/$1,$2/) {
				$l = length($v);
			}
		} else {
			$v = sprintf($pic, $v)  unless ($float);
			$l = length($v);
		}
		$v = $float . $v  if ($float && $l < $leni);
		$v = sprintf("%${lj}${leni}.${leni}s", $v);
		$v .= $suffix  unless ($ops->{'-suffix'} =~ /no/io);
		return wantarray ? ($v, $leni, $justify) : $v;
	} else {
		return undef;   #INVALID PICTURE STRING:
	}
}

sub unfmt {       #UNFORMAT INPUT DATA STRING BASED ON "PICTURE" STRING (AS IF PREVIOUSLY FORMATTED BY SAME STRING:
	my $pic = shift;
	my $v = shift;
	my $ops = shift;

	my $leni = 0;
	my $leniSpecified = 0;
	my $suffix;
	my $errchar = $ops->{'-bad'} ? substr($ops->{'-bad'},0,1) : '*';
	my $justify = ($pic =~ /^.*?([<|>])/o) ? $1 : '';
	my $fixedLeni = $ops->{-sizefixed} ? fmtsiz($pic) : 0;
	if ($pic =~ s/^\@//o) {               #@-strings:
		$leni = $fixedLeni  if ($fixedLeni);
		$leni = $1  if ($pic =~ s/^(\d+)\://o);
		$leniSpecified = $leni;
		if ($pic =~ s/^([\'\"\/\`])//o) {         #PICTURE LITERAL (@'foo'
			my $regexDelimiter = $1;         #REPLACE EACH DOT WITH NEXT CHAR. SKIP ONES CORRESPONDING WITH "^", ALL OTHER CHARS ARE LITERAL.
			$v =~ s/$1$//  if ($pic =~ s#\Q$regexDelimiter\E(.*)$##);
			my $r0 = $pic;
			$r0 =~ s/\\.//gso;
			$r0 =~ s/(\.+[\+\*]*)/\($1\)/gs;
			my $r = $r0;
			$r0 =~ s/\^//gso;
			my @QS;
			my $i = 0;
			$i++  while ($r0 =~ s/(\([^\)]+\))/
					$QS[$i] = "$1"; "P$i"/e);

			$r0 = "\Q$r0\E";
			$r0 =~ s/P(\d+)/$QS[$1]/gs;
			$i = 1;
			$i++  while ($r =~ s/\(.+?\)/\$$i/s);
			$r =~ s/\^/ /gso;
			$r =~ s/[^\$\d ]//gso;
			my $evalstr = "\$v =~ s\"$r0\"$r\"";
			eval $evalstr;
			if ($leni && length($v) > $leni && $ops->{'-truncate'} !~ /no/io) {
				$v = ($ops->{'-truncate'} =~ /er/io) ? $errchar x $leni : substr($v, 0, $leni);
			}
			return wantarray ? ($v, $leni, $justify) : $v;
		} elsif ($pic =~ s#^\^##o) {  #DATE-CONVERSION
			eval 'use Date::Fmtstr2time; $haveFmtstr2time = 1; 1'  unless ($haveFmtstr2time);
			$pic =~ s/\\\^/\x04/go;   #PROTECT ESCAPED "^" IN FORMAT STRING!
			$suffix = ($pic =~ s#\^([^\^]*)$##) ? $1 : '';
			$suffix =~ s/\x04/\^/go;  #UNPROTECT ESCAPED "^" IN FORMAT STRING!
			my $outpic = '';
			($pic, $outpic) = split(/\^/o, $pic)  if ($pic =~ /\^/);
			$pic =~ s/\x04/\^/go;     #UNPROTECT ESCAPED "^" IN FORMAT STRING!
			$outpic ||= $ops->{'-outfmt'}  if ($ops->{'-outfmt'});
			$v =~ s/\Q${suffix}\E$//  unless ($ops->{'-suffix'} =~ /no/io);
			my $t = '';
			if ($haveFmtstr2time) {   #CONVERT TO A PERL "TIME" USING Fmtstr2time IF IT'S AVAILABLE:
				$t = str2time($v, $pic);
				if ($t && $outpic) {  #WE WANT THE TIME FORMATTED TO A STRING:
					eval 'use Date::Time2fmtstr; $haveTime2fmtstr = 1; 1'  unless ($haveTime2fmtstr);
					$t = ($haveTime2fmtstr) ? time2str($t, $outpic) : '';
				}
			} 
			unless ($t) {      #ATTEMPT A MANUAL TRANSLATION TO AN INTEGER FORMATTED:  yyyymmdd[hhmm[ss]]
				if ($outpic && $outpic !~ /^yyyymmdd(?:hhmm(?:ss)?)?$/i) {  #IF WE DON'T HAVE Fmtstr2time & user specified an output format other than "yyyymmdd..." then FAIL!
					$t = $errchar x length($outpic);
					return wantarray ? ($t, $leni, $justify) : $t;
				}
				foreach my $i (qw(yyyy mm dd)) {
					$t .= substr($v,index($pic,$i),length($i)) || ' ' x length($i);
				}
				$t =~ s/^    /'20'.substr($v,index($pic,'yy'),2)/e;
				$t =~ s/  $/01/;
				$t =~ s/ /$errchar/g;
				foreach my $i (qw(HH hh mi ss)) {
					$t .= substr($v,index($pic,$i),length($i))  if (index($pic,$i) > 0);
				}
				$t =~ s/[^0-9 ]/ /go;
			}
			if ($leni && length($t) > $leni && $ops->{'-truncate'} !~ /no/io) {
				$t = ($ops->{'-truncate'} =~ /er/io) ? $errchar x $leni : substr($t, 0, $leni);
			}
			return wantarray ? ($t, $leni, $justify) : $t;
		} elsif ($pic =~ m#^(?:s|tr)(\W)#) { #REGEX SUBSTITUTION (@s/foo/bar/)  #NOTE:  unfmt() SAME AS fmt()!
			my $regexDelimiter = $2;
			$v =~ s/$1$//  if ($pic =~ s#\Q$regexDelimiter\E(.*)$##);
			my $evalstr = '$v =~ '.$pic;
			eval $evalstr;
			if ($leni && length($v) > $leni && $ops->{'-truncate'} !~ /no/io) {
				$v = ($ops->{'-truncate'} =~ /er/io) ? $errchar x $leni : substr($v, 0, $leni);
			}
			return wantarray ? ($v, $leni, $justify) : $v;
		} elsif ($pic =~ /^[a-zA-Z_]+/o) {     #USER-SUPPLIED FUNCTION (@foo('*'))  #NOTE:  unfmt() SAME AS fmt()!
			$v =~ s/$1$//  if ($pic =~ s#\Q\;\E(.*)$##);
			$pic =~ s/\\\*/\x02/og;  #PROTECT ESCAPED METACHARACTERS:
			$pic =~ s/\\\*/\x02/og;
			$pic =~ s/\\\#/\x03/og;
			if ($v =~ /^\d+$/o)
			{
				$pic =~ s/\*/$v/g;
			}
			else
			{
				$pic =~ s/\*/\'$v\'/g;
			}
			$pic =~ s/\#/$leni/g;   #UNPROTECT ESCAPED METACHARACTERS:
			$pic =~ s/\x03/\#/og;
			$pic =~ s/\x02/\*/og;
			$pic = 'main::' . $pic  unless ($pic =~ /^\w+\:\:/o);
			my $t;
			$pic =~ s/(\w)(\W*)$/$1\(\'$v\',$leni\)$2/  unless ($pic =~ /\(.*\)/o);
			eval "\$t = $pic";
			$t = $@  if ($@);
#NO!			$t .= $suffix  unless ($ops->{'-suffix'} =~ /no/io);
			if ($leni && length($v) > $leni && $ops->{'-truncate'} !~ /no/io) {
				$v = ($ops->{'-truncate'} =~ /er/io) ? $errchar x $leni : substr($v, 0, $leni);
			}
			return wantarray ? ($t, $leni, $justify) : $t;
		} else {                               #REGULAR JUSTIFY STUFF, IE. @12>.>>)
			if ($pic =~ /^\*(.*)$/) {          #WE'RE JUST AN ASTERISK, JUST RETURN THE INPUT STRING UNCHANGED:
				$suffix = $1;
				if ($leni && length($v) > $leni && $ops->{'-truncate'} !~ /no/io) {
					$v = ($ops->{'-truncate'} =~ /er/io) ? $errchar x $leni : substr($v, 0, $leni);
				}
				$v .= $1  unless ($ops->{'-suffix'} =~ /no/io);
				return wantarray ? ($v, 0, '<') : $v;
			}
			$suffix = $1  if ($pic =~ s/([^<|>.]+)$//o);
			my ($special, $isneg, $t);
			my $commatize = 0;
			while ($pic =~ s/^([^\d\<\|\>\.])//o) {  #STRIP OFF ALL CHARS BEFORE <, >, |, OR DIGIT AS "FLOATING CHARS".
				$special .= $1;
			}
			$isneg = 0;
			if ($v =~ /^\D*\-/o) {
				$isneg = 1;
			} elsif ($special =~ /\(/o && $v =~ /\(/o) {
				$isneg = 1;
			} elsif ($suffix =~ /^[\_ ]*CR\s*$/o && $v =~ s/\s*CR\s*$//o) {
				unless ($ops->{-nonnumeric}) {
					$isneg = 1;
				}
			}
			$v =~ s/[\Q$special\E]//g  if ($special);
			$v =~ s/^\s+//o;
			$v =~ s/\s+$//o;
			$v =~ s/\Q${suffix}\E$//  unless ($ops->{'-suffix'} =~ /no/io);
			$v =~ s/\s+$//o;
			if ($isneg) {
				$v = '-' . $v  unless ($v =~ /^\-/o);
			}
			$pic =~ s/(\d+)[<|>]?([\.\^]?)(\d*)([<|>])/
					my ($one, $dec, $two, $three) = ($1, $2, $3, $4);
					$dec ||= '.';
					my $exp = ($three x $one);
					$exp .= $dec . ($three x $two)  if ($two > 0);
					$exp
			/e;        #CONVERT STUFF LIKE "@12.2>" TO "@>>>>>>>>>>>>.>>>".
			my $justify = ($pic =~ /^.*?([<|>])/o) ? $1 : '';
			my $decJustify;
			if ($pic =~ /^([<|>]+)[\.\^]([<|>]+)/o) {
				my $two = $2;
				$leni = length($1) + length($two) + 2;
				unless ($ops->{'-nonnumeric'}) {
					my $decLen = length($two);
					$decJustify = ($two =~ /([\<\|\>])$/o) ? $1 : '';
					if ($pic !~ /\./o && $v =~ /\./ && $v =~ /^[\+\-\d\. ]+$/o) {  #WE HAVE AN "IMPLIED DECIMAL POINT!
						$v = sprintf("%.0f", $v * (10**$decLen))  if ($v =~ /^[\+\-\d\. ]+$/o);
					} else {
						$v = sprintf("%.${decLen}f", $v);
					}
				}
			} elsif ($pic =~ /^([\[\<\|\>]+)/o) {
				$leni = length($1) + 1;
			} else {
				$leni = 1;
			}
			$leni = $leniSpecified  if ($leniSpecified && $leni > $leniSpecified);
			if ($leni && length($v) > $leni) {
				if ($decJustify eq '>' && !$ops->{'-nonnumeric'} && $v =~ /^[0-9\+\-]*\.[0-9]+/o) {   #(NUMERIC) CHOP OFF DECIMALS UNTIL IT EITHER FITS OR WE ARE A WHOLE NUMBER:
					while (length($v) > $leni) {
						chop($v);
						last  unless ($v =~ /\./o);
					}
					$v = '0'  unless (length($v));
				}
			}
			if ($leni && length($v) > $leni) {
				if ($ops->{'-truncate'} !~ /no/io) {
					if ($ops->{'-truncate'} =~ /er/io) {
						$v = $errchar x $leni;
					} else {
						if ($justify eq '>') {       #CHOP LEADING CHARACTERS UNTIL FITS IF RIGHT-JUSTIFY:
							while (length($v) > $leni) {
								$v =~ s/^.(.+)$/$1/;
							}
						} else {                          #CHOP TRAILING CHARACTERS UNTIL FITS IF LEFT-JUSTIFY|CENTER:
							while (length($v) > $leni) {
								chop $v;
							}
						}
					}
				}
			}
			my $padcnt = $leniSpecified - length($v);
			if ($padcnt > 0) {
				if ($justify eq '>') {
					$v = (' ' x $padcnt) . $v;
				} elsif ($justify eq '|') {
					for (my $i=0;$i<$padcnt;$i++) {
						$v = ($i % 2) ? ' ' . $v : $v . ' ';
					}
				} else {
					$v .= ' ' x $padcnt;
				}
			}
			return wantarray ? ($v, length($v), $justify) : $v;
		}
	} elsif ($pic =~ s/^\=//o) {    #FIELDS STARTING WITH "=" ARE TO BE WRAPPED TO MULTIPLE LINES AS NEEDED:
		my ($justify, $wrapchar) = ('<', 'W');    #DEFAULTS.
		my $j = 1;
		$suffix = ($pic =~ s/([^wW<|>\d]+)$//o) ? $1 : '';
		$wrapchar = 'w'  if ($pic =~ /w/o);         #LITTLE w=WRAP AT CHARACTER:
		$justify = $1  if ($pic =~ /^.*([<|>])/o);  #BIG W=WRAP AT WORD BOUNDARIES (Text::Wrap):
		$v =~ s/${suffix}(\r?\n)/$1/gs;
		if ($justify eq '<') {
			$v =~ s/(\S)\r?\n\s*/$1 /gs;
		} elsif ($justify eq '>') {
			$v =~ s/\s*\r?\n(\S)/ $1/gs;
		} else {
			$v =~ s/\s*\r?\n\s*/ /gs;
		}
		$v =~ s/\r?\n//gs;
		$leni = $leniSpecified  if ($leni > $leniSpecified);
		if ($leni && length($v) > $leni) {
			if ($ops->{'-truncate'} !~ /no/io) {
				$v = ($ops->{'-truncate'} =~ /er/io) ? $errchar x $leni : substr($v, 0, $leni);
			}
		} elsif ($leniSpecified && length($v) < $leniSpecified) {
			my $padcnt = $leniSpecified - length($v);
			if ($padcnt > 0) {
				$v = ($justify eq '>') ? (' ' x $padcnt) . $v : $v . (' ' x $padcnt);
			}
		}
		return wantarray ? ($v, length($v), $justify) : $v;
	} elsif ($pic =~ s/^\%//o) {         #C-PRINTF FORMAT STRINGS (%-STRINGS) (AS-IS, "%" NOT INCLUDED IN FIELD SIZE):
		my $float = ($pic =~ s/^\$//o) ? '$' : '';  #EXCEPTION:  FLOATING $, COMMA(COMMATIZE) ALLOWED AFTER "%":
		my $commatize = ($pic =~ s/^\,//o) ? 1 : 0;    #IE:  "%$,-14.2f":  FIELD SIZE=16!
		$v =~ s/$2$//  if ($pic =~ s/^(\-?[\d\.]+\w)(.*)$/$1/o);
		$leni = ($pic =~ /^\-?(\d+)/) ? $1 : length($v);
		my $lj = ($pic =~ /^\-/o) ? '-' : '';
		$justify = ($lj eq '-') ? '<' : '>';
		$pic = '%' . $pic;
		my $t;
		my $decimal = ($pic =~ /\.(\d+)/o) ? $1 : 0;
		if ($float) {
			$lj = '';
			$lj = '-'  if ($pic =~ s/^\%\-/\%/o);
			$leni += length($float)  if ($pic =~ /^\%(\d+)/o);
			$v = sprintf("%.${decimal}f", $v);
		}
		my $l;
		if ($commatize) {
			$leni++  if ($pic =~ /^\%(\d+)/o);
			$l = length($v);
			while ($l > $leni && $v =~ /\./o) {
				chop $v;
			}
			if ($l > $leni) {
				$v = '#'x$leni;
				return wantarray ? ($v, $leni, $justify) : $v;
			}
			while ($l < $leni && $v =~ s/(\d)(\d\d\d)\b/$1,$2/) {
				$l = length($v);
			}
		} else {
			$l = length($v);
			while ($l > $leni && $v =~ /\./o) {   #CHOP OFF DECIMAL PLACES IF NEEDED TO GET TO FIT:
				chop $v;
			}
		}
		$v = $float . $v  if ($float && $l < $leni);
		$v = sprintf("%${lj}${leni}.${leni}s", $v);
		return wantarray ? ($v, $leni, $justify) : $v;
	} else {
		return undef;   #INVALID PICTURE STRING:
	}
}

sub fmtsiz {   #RETURN THE "SIZE" STRING THE "PICTURE STRING" ARGUMENT REPRESENTS (NOT THE LENGTH ITSELF) - CAN BE ZERO IF VARIABLE:
	my $pic = shift;
	my $v = shift;
	my $leni;
	my $suffix;
	if ($pic =~ s/^\@//o) {               #@-strings:
		if ($pic =~ /^(\d+)\:/o) {
			return $1;
		} elsif ($pic =~ s/^([\'\"\/\`])//o) {          #PICTURE LITERAL   (@'foo'
			my $regexDelimiter = $1;         #REPLACE EACH DOT WITH NEXT CHAR. SKIP ONES CORRESPONDING WITH "^", ALL OTHER CHARS ARE LITERAL.
			$pic =~ s#\Q$regexDelimiter\E.*$##;
			my $cnt = 0;                #EXAMPLE: fmt("@\"...-..-.+\";suffix", '123456789'); FORMATS AN SSN:
			my $frompic = '';
			$pic =~ s/\\\+/\x02/go;
			$pic =~ s/\\\./\x03/go;
			$pic =~ s/\\\^/\x04/go;
			return length($pic);
		} elsif ($pic =~ s#^\^##o) {  #DATE-CONVERSION
			$pic =~ s/\\\^/\x04/go;   #PROTECT ESCAPED "^" IN FORMAT STRING!
			$pic =~ s#\^.*$##;
			(my $t = $v) =~ s/\D//go;
			return length($pic);
		} elsif ($pic =~ m#^(?:s|tr)\W#o) {         #REGEX SUBSTITUTION (@s/foo/bar/)
			return 0;
		} elsif ($pic =~ /^[a-zA-Z_]+/o) {     #USER-SUPPLIED FUNCTION (@foo('*'))
			return 0;
		} else {                               #REGULAR STUFF, IE. @12>.>>)
			return 0  if ($pic =~ /^\*(.*)$/o);
			$pic =~ s/[^\<\|\>\.\^]+$//o;
			my ($special, $float, $t);
			my $commatize = 0;
			while ($pic =~ s/^([^\d\<\|\>\.\^])//o) {  #STRIP OFF ALL CHARS BEFORE <, >, |, OR DIGIT AS "FLOATING CHARS".
				$special = $1;
				if ($special eq ',') {   #COMMA (@,) = ADD COMMAS EVERY 3 DIGITS:
					$commatize = 1;
				} else {
					$float .= $special; #OTHERS, IE. (@$) ARE FLOATERS:
				}
			}
			$leni = 1 + length($float) + $commatize;  #COUNT FLOATING CHARS IN FIELD SIZE:
			$pic =~ s/(\d+)[<|>]?([\.\^]?)(\d*)([<|>])/
					my ($one, $dec, $two, $three) = ($1, $2, $3, $4);
					$dec ||= '.';
					my $exp = ($three x $one);
					$exp .= $dec . ($three x $two)  if ($two > 0);
					$exp
			/e;        #CONVERT STUFF LIKE "@12.2>" TO "@>>>>>>>>>>>>.>>".
			$t = $pic;
			#CALCULATE FIELD SIZE BASED ON NO. OF "<, >, |" AND PRECEEDING REPEATER DIGITS:
			$leni += length($1)  while ($t =~ s/([\<\|\>\.\^\,\$]+)//o);
			$leni += $1 - 1  while ($t =~ s/(\d+)//o);
			return $leni;
		}
	} elsif ($pic =~ s/^\=//o) {    #FIELDS STARTING WITH "=" ARE TO BE WRAPPED TO MULTIPLE LINES AS NEEDED:
		my ($justify, $wrapchar) = ('<', 'W');    #DEFAULTS.
		my $j = 1;
		$suffix = $1  if ($pic =~ s/([^wW<|>\d]+)$//o);
		$wrapchar = 'w'  if ($pic =~ /w/o);         #LITTLE w=WRAP AT CHARACTER:
		$justify = $1  if ($pic =~ /^.*([<|>])/o);  #BIG W=WRAP AT WORD BOUNDARIES (Text::Wrap):
		$j += length($1)  while ($pic =~ s/([wW<|>]+)//o);
		$j += $1 - 1  while ($pic =~ s/(\d+)//o);
		return $j;         #WIDTH OF FIELD AREA TO WRAP WITHIN:
	} elsif ($pic =~ s/^\%//o) {         #C-PRINTF FORMAT STRINGS (%-STRINGS) (AS-IS, "%" NOT INCLUDED IN FIELD SIZE):
		my $float = ($pic =~ s/^\$//o) ? '$' : '';  #EXCEPTION:  FLOATING $, COMMA(COMMATIZE) ALLOWED AFTER "%":
		my $commatize = ($pic =~ s/^\,//o) ? 1 : 0;    #IE:  "%$,-14.2f":  FIELD SIZE=16!
		$suffix = ($pic =~ s/^(\-?[\d\.]+\w)(.*$)/$1/o) ? $2 : '';
		$leni = ($pic =~ /^\-?(\d+)/) ? $1 : length($v);
		my $lj = ($pic =~ /^\-/o) ? '-' : '';
		$pic = '%' . $pic;
		my $t;
		if ($float) {
			$pic =~ s/^\%\-/\%/o;
			$leni += length($float)  if ($pic =~ /^\%(\d+)/o);
		}
		if ($commatize) {
			$leni++  if ($pic =~ /^\%(\d+)/o);
		}
		return $leni;
	} else {
		return undef;   #INVALID PICTURE STRING:
	}
}

sub fmtjust {   #RETURN THE "JUSTIFICATION" DIRECTION THE "PICTURE STRING" REPRESENTS ("<", ">", "|", OR "", IN INDETERMINATE)
	my $pic = shift;
	my $v = shift;

	my $leni;
	my $suffix;
	if ($pic =~ s/^\@//o) {                  #@-strings:
		$pic =~ s/(\d+)\://o;
		if ($pic =~ s/^[\'\"\/\`]//o) {      #PICTURE LITERAL   (@'foo'
			return '<';
		} elsif ($pic =~ s#^\^##o) {         #DATE-CONVERSION
			return '<';
		} elsif ($pic =~ m#^(?:s|tr)\W#o) {  #REGEX SUBSTITUTION (@s/foo/bar/)
			return '<';
		} elsif ($pic =~ /^[a-zA-Z_]+/o) {   #USER-SUPPLIED FUNCTION (@foo('*'))
			return '<';
		} else {                             #REGULAR STUFF, IE. @12>.>>)
			return '<'  if ($pic =~ /^\*(.*)$/);
			$suffix = $1  if ($pic =~ s/([^\<\|\>\.\^]+)$//o);
			my ($special, $float, $t);
			my $commatize = 0;
			while ($pic =~ s/^([^\d\<\|\>\.\^])//o) {  #STRIP OFF ALL CHARS BEFORE <, >, |, OR DIGIT AS "FLOATING CHARS".
				$special = $1;
				if ($special eq ',') {   #COMMA (@,) = ADD COMMAS EVERY 3 DIGITS:
					$commatize = 1;
				} else {
					$float .= $special; #OTHERS, IE. (@$) ARE FLOATERS:
				}
			}
			if ($float =~ /\(/o)   #ONLY KEEP FLOATING "(" IF SUFFIX STARTS WITH A ")"!
			{
				$float =~ s/\(//o  unless ($suffix =~ s/^\)//o);
			}
			if ($v < 0)
			{
				$float =~ s/\+//go;   #REMOVE FLOATING "+" IF VALUE IS NEGATIVE.
			}
			else
			{
				$float =~ s/\(//go;   #REMOVE FLOATING "(..)" IF VALUE IS NOT NEGATIVE.
			}
			$leni = 1 + length($float) + $commatize;  #COUNT FLOATING CHARS IN FIELD SIZE:
			my $justify = ($pic =~ /^.*?([<|>])/o) ? $1 : '';
			#DEFAULT JUSTIFY:  RIGHT IF COMMATIZING(NUMBER) OR FLOATING$ OR PICTURE CONTAINS DECIMAL;
			#OTHERWISE, DEFAULT IS LEFT.
			$justify ||= ($commatize || $float =~ /\$/o || $pic =~ /[.,\$]/o) ? '>' : '<';
			return $justify;
		}
	} elsif ($pic =~ s/^\=//o) {    #FIELDS STARTING WITH "=" ARE TO BE WRAPPED TO MULTIPLE LINES AS NEEDED:
		my ($justify, $wrapchar) = ('<', 'W');    #DEFAULTS.
		my $j = 1;
		$suffix = $1  if ($pic =~ s/([^wW<|>\d]+)$//o);
		$wrapchar = 'w'  if ($pic =~ /w/o);         #LITTLE w=WRAP AT CHARACTER:
		$justify = $1  if ($pic =~ /^.*([<|>])/o);  #BIG W=WRAP AT WORD BOUNDARIES (Text::Wrap):
		return $justify;
	} elsif ($pic =~ s/^\%//o) {    #C-PRINTF FORMAT STRINGS (%-STRINGS) (AS-IS, "%" NOT INCLUDED IN FIELD SIZE):
		my $float = ($pic =~ s/^\$//o) ? '$' : '';  #EXCEPTION:  FLOATING $, COMMA(COMMATIZE) ALLOWED AFTER "%":
		my $commatize = ($pic =~ s/^\,//o) ? 1 : 0;    #IE:  "%$,-14.2f":  FIELD SIZE=16!
		$suffix = ($pic =~ s/^(\-?[\d\.]+\w)(.*$)/$1/o) ? $2 : '';
		$leni = ($pic =~ /^\-?(\d+)/) ? $1 : length($v);
		my $justify = ($pic =~ /^\-/o) ? '<' : '>';
		return $justify;
	} else {
		return undef;   #INVALID PICTURE STRING:
	}
	return '<';
}

sub fmtsuffix {       #RETURN JUST THE SUFFIX PART, IF ANY, IN THE PICTURE STRING (OR "") IF NONE.
	my $pic = shift;  #ANY CHARACTERS AFTER THE "PICTURE STRING" METACHARACTERS IS TREATED AS THE "SUFFIX"
	my $v = shift;
	my $ops = shift;

	my $leni;
	my $suffix = '';
	if ($pic =~ s/^\@//o) {            #@-strings:
		$pic =~ s/(\d+)\://o;
		if ($pic =~ s/^([\'\"\/\`])//o) {  #PICTURE LITERAL   (@'foo'
			my $regexDelimiter = $1;       #REPLACE EACH DOT WITH NEXT CHAR. SKIP ONES CORRESPONDING WITH "^", ALL OTHER CHARS ARE LITERAL.
			$suffix = $1  if ($pic =~ s#\Q$regexDelimiter\E(.*)$##);
			return $suffix;
		} elsif ($pic =~ s#^\^##o) {  #DATE-CONVERSION
			$pic =~ s/\\\^/\x04/go;   #PROTECT ESCAPED "^" IN FORMAT STRING!
			$suffix = ($pic =~ s#\^([^\^]*)$##) ? $1 : '';
			$suffix =~ s/\x04/\^/go;  #UNPROTECT ESCAPED "^" IN FORMAT STRING!
			return $suffix;
		} elsif ($pic =~ m#^(?:s|tr)(\W)#) {   #REGEX SUBSTITUTION (@s/foo/bar/)
			my $regexDelimiter = $1;
			$suffix = $1  if ($pic =~ s#([^$regexDelimiter]+)$##);
			return $suffix;
		} elsif ($pic =~ /^[a-zA-Z_]+/o) {     #USER-SUPPLIED FUNCTION (@foo('*'))
			$suffix = $1  if ($pic =~ s/\)([^\)]*)$/\)/o);
			return $suffix;
		} else {                               #REGULAR JUSTIFY STUFF, IE. @12>.>>)
			return $1  if ($pic =~ /^\*(.*)$/);
			$suffix = $1  if ($pic =~ s/([^<|>.]+)$//o);
			return $suffix;
		}
	} elsif ($pic =~ s/^\=//o) {    #FIELDS STARTING WITH "=" ARE TO BE WRAPPED TO MULTIPLE LINES AS NEEDED:
		my ($justify, $wrapchar) = ('<', 'W');    #DEFAULTS.
		my $j = 1;
		$suffix = $1  if ($pic =~ s/([^wW<|>\d]+)$//o);
		return $suffix;
	} elsif ($pic =~ s/^\%//o) {    #C-PRINTF FORMAT STRINGS (%-STRINGS) (AS-IS, "%" NOT INCLUDED IN FIELD SIZE):
		$pic =~ s/^\$//o;
		$pic =~ s/^\,//o;
		$suffix = ($pic =~ s/^(\-?[\d\.]+\w)(.*)$/$1/o) ? $2 : '';
		return $suffix;
	} else {
		return undef;   #INVALID PICTURE STRING:
	}
}

sub _chkdate#    #(INTERNAL) TRY TO PARSE OUT AND CONVERT USER-ENTERED DATE/TIME STRINGS TO "yyyymmdd [hhmm[ss]]".
{
	#### Y2K COMPLIANT UNTIL 2080.
	#### NOTE:  6-DIGIT DATES W/SEPARATORS ARE HANDLED AS mmddyy!
	#### NOTE:  6-DIGIT INTEGER DATES ARE HANDLED AS yymmdd!
	
	my ($dt) = shift;
	my ($res);
	return wantarray ? ($dt,0) : $dt  unless ($dt =~ /\S/o);
	$dt = substr($dt,0,8) . ' ' . substr($dt,8)  if ($dt =~ /\d{9,14}\D*$/o);
	if ($dt =~ s#(\d+)[\/\-\.](\d+)[\/\-\.](\d+)##o)   #DATE PART HAS SEPARATORS (ie. mm/dd/yyyy):
	{
		my $x;
		if ($1 < 1000 && $3 < 1000)    #2-DIGIT YEAR:  "mm/dd/yy"|"mm-dd-yy"|"mm.dd.yy" (MAKE ASSUMPTIONS):
		{
			my $century = ($3 < 80) ? 20 : 19;   #Y2K:80-99=19##; 00-79=20##!
			$x = sprintf '%-2.2d%-2.2d%-2.2d%-2.2d',$century,$3,$1,$2
		}
		elsif ($1 > 1000)  #4-DIGIT YEAR:  "yyyy/mm/dd"|"yyyy-mm-dd"|"yyyy.mm.dd"
		{
			$x = sprintf '%-2.2d%-2.2d%-2.2d',$1,$2,$3;
		}
		else              #4-DIGIT YEAR, ASSUME:  "mm/dd/yyyy"|"mm-dd-yyyy"|"mm.dd.yyyy"
		{
			$x = sprintf '%-2.2d%-2.2d%-2.2d',$3,$1,$2;
		}
		my $then = 0;
		if ($dt =~ s#^\D+(\d\d?)\:?(\d\d?)##o)   #STRING HAS A "TIME" PART:
		{
			$x .= ' ' . sprintf '%-2.2d%-2.2d',$1,$2;
			$x .= ($dt =~ s#\:?(\d\d?)##o) ? sprintf('%-2.2d',$1) : '00';
			if ($dt =~ m#(\s*[ap]m?)#i)   #STRING HAS AM/PM SUFFIX (12-HOUR TIME)
			{
				my $indicator = $1;
				my $hr = $1  if ($x =~ /\d (\d\d)/);
				if ($indicator =~ /a/i && $hr == 12)     #12 AM BECOMES 00:
				{
					$x =~ s/(\d) (\d\d)/$1 . ' 00'/e;
				}
				elsif ($indicator =~ /p/i && $hr != 12)  #1-11 PM BECOMES 13-23:
				{
					$x =~ s/(\d) (\d\d)/$1 . ' ' . sprintf('%-2.2d',$hr+12)/e;
				}
				$x .= $indicator;
			}
			eval   #TRY TO CONVERT DATE/TIME STRING TO A PERL/UNIX TIME INTEGER:
			{
				$then = &timelocal(substr($x,13,2),substr($x,11,2),substr($x,9,2),
						substr($x,6,2),(substr($x,4,2)-1),substr($x,0,4),0,0,0);
			};
		}		
		else   #STRING IS ONLY A DATE, WILL ASSUME MIDNITE (00:00:00) FOR THE TIME PART:
		{
			eval   #TRY TO CONVERT DATE STRING TO A PERL/UNIX TIME INTEGER:
			{
				$then = &timelocal(0,0,0,substr($x,6,2),
						(substr($x,4,2)-1),substr($x,0,4),0,0,0);
			};
		}
		$dt = $x;


		$dt = ''  unless ($then > 0);   #INVALID DATE, BLANK OUT!
		return wantarray ? ($dt, $then) : $dt;
	}
	elsif ($dt =~ s/^(\d\d\d\d\d\d+)(\D+\d+\:?\d+.*)?$/$1/o || $dt =~ s/^(\d{8})(\d{4})/$1/o)
	{   #STRING DATE PART HAS NO SEPARATORS:
		my $timepart = $2 || '';
		if (length($dt) == 6)   #2-DIGIT YEAR:  "yymmdd" (2-DIGIT YEAR, MAKE ASSUMPTIONS):
		{
			my $century = (substr($dt,0,2) < 80) ? 20 : 19;  #Y2K:80-99=19##; 00-79=20##!
			$dt = $century . $dt;
		}
		else   #4-DIGIT YEAR:  "mmddyyyy":
		{
			my ($leftpart) = substr($dt,0,4);
			if ($leftpart < 1300)    #ASSUME USER MEANT:  "mmddyyyy":
			{
				$dt = substr($dt,4,4) . $leftpart;
			}
		}
		my $then = 0;
		$timepart =~ s/^\D+//o;
		if ($timepart =~ s#^(\d\d)(\d\d)##o || $timepart =~ s#^(\d\d?)\:(\d\d?)\:?##o)
		{   #STRING INCLUDES A "TIME" PART (hhmm[ss] OR hh:mm[:ss]:
			$dt .= ' ' . sprintf('%-2.2d',$1) . sprintf('%-2.2d',$2);
			$dt .= ($timepart =~ s#(\d\d?)\s*##o) ? sprintf('%-2.2d',$1) : '00';
			if ($timepart =~ m#([ap]m?)#io)  #STRING INCLUDES A[M]|P[M], CONVERT AS 12-HOUR TO 24-HOUR:
			{
				my $indicator = $1;
				my $hr = $1  if ($dt =~ /\d (\d\d)/);
				if ($indicator =~ /a/i && $hr == 12)     #12 AM BECOMES 00:
				{
					$dt =~ s/(\d) (\d\d)/$1 . ' 00'/e;
				}
				elsif ($indicator =~ /p/i && $hr != 12)  #1-11 PM BECOMES 13-23:
				{
					$dt =~ s/(\d) (\d\d)/$1 . sprintf('%-2.2d',$hr+12)/e;
				}
			}
			eval   #TRY TO CONVERT DATE/TIME STRING TO A PERL/UNIX TIME INTEGER:
			{
				$then = &timelocal(substr($dt,13,2),substr($dt,11,2),substr($dt,9,2),
						substr($dt,6,2),(substr($dt,4,2)-1),substr($dt,0,4),0,0,0);
			};
		}
		else   #STRING IS ONLY A DATE, WILL ASSUME MIDNITE (00:00:00) FOR THE TIME PART:
		{
			eval   #TRY TO CONVERT DATE STRING TO A PERL/UNIX TIME INTEGER:
			{
				$then = &timelocal(0,0,0,substr($dt,6,2),
						(substr($dt,4,2)-1),substr($dt,0,4),0,0,0);
			};
		}
		$dt = ''  unless ($then > 0);   #INVALID DATE, BLANK OUT!
		return wantarray ? ($dt, $then) : $dt;
	}
	else
	{
		return wantarray ? ('', 0) : '';   #INVALID DATE, BLANK OUT!
	}
}

1

__END__
