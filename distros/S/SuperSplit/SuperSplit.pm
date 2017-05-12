package SuperSplit;
use strict;

=head1 NAME

SuperSplit - Provides methods to split/join in two or more dimensions

=head1 SYNOPSIS

 use SuperSplit ; #or qw/!:all supersplit/ |which function you want to use
 
 #first example: split on newlines and whitespace and print
 #the same data joined on tabs and whitespace. The split works on STDIN
 #
 print superjoin( supersplit() );  #behaves like while (<>) 
{s/\s+/\t/g;print;}
 
 #second: split a table in a text file, and join it to HTML
 #
 my $array2D   = supersplit( \*INPUT )  #filehandle must be open
 my $htmltable = superjoin( '</TD><TD>', "</TD></TR>\n  <TR><TD>", 
 				 $array2D );
 $htmltable    = "<TABLE>\n  <TR><TD>" . $htmltable . 
"</TD></TR>\n</TABLE>";
 print $htmltable;
 
 #third: perl allows you to have varying number of columns in a row,
 # so don't stop with simple tables. To split a piece of text into 
 # paragraphs, than words, try this:
 #
 undef $/;
 $_ = <>;
 tr/.!();:?/ /; #remove punctiation
 my $array = supersplit( '\s+', '\n\s*\n', $_ );
 # now you can do something nifty as counting the number of words in each
 # paragraph
 my $i = 0;
 for my $rowref (@$array) {
    print "Found ".@$rowref." \twords in paragraph \t".++$i."\n";
 }
 
 #other uses:
 $a = supersplit( 2 );  #behaves like supersplit(), but stops with the 
second column
 $b = supersplit_open( "<$file", 2 ); #as before, but opens $file for 
input
 $c = supersplit_open( "<$file"); #as before, but splits as much as it can
 $d = supersplit_nolimit( 3); #Hopelessly tries to split on 3.
 $e = supersplit_limits( [ ], [2,2] ); #$a, but returns 2x2 array
 $f = supersplit_hashref( {	separators => [ ], limits => [2,2],
 	filehandle => \*STDIN }); #as before, but using anonhash to determine 
inputs

=head1 DESCRIPTION

Supersplit is just a consequence of the possibility to use 
multi-dimensional 
arrays in perl. Because that is possible, one also wants a way to 
convenienently split data into a nD-array (at least I want to).  And vice 
versa, of course.  Supersplit/join just do that.

Because I intend to use these methods in numerous one-liners and in my 
collection of handy filters, an object interface is more often than not 
cumbersome.  So, this module exports six methods 'super...', but no 
variables or globs of any kind.  If you think modules shouldn't export 
functions, period, use the object interface, SuperSplit::Obj.  TIMTOWTDT

If you don't like input magic, you can use the hashref variant.  It uses 
only little of that ;-).

=over 4

=item supersplit( @separator-list, $filehandleref || $string, $limit);

The first method, supersplit, returns a nD-array.  To do that, it needs 
data and the strings to split with.  Data may be provided as a reference 
to 
a filehandle, or as a string.  If you want use a string for the data, you 
MUST provide the strings to split with (>=3 argument mode).  If you don't 
provide data, supersplit works on STDIN. If you provide a filehandle 
(like 
\*INPUT), supersplit doesn't need the splitting strings, and 
runs in 2D-mode by default.  In both cases (STDIN or filehandle only) it 
assumes columns are separated by whitespace, and rows are separated by 
newlines.  Strings are passed directly to split.  If you provide more 
separators, they will split the higher dimensions.  If you only provide 
one, it is treated like the column-separator, the row-separator defaults 
to 
newline.

The separators are processed in reversed order, the last separator is 
processed first.  This is best explained with a simple whitespace 
delimited 
table:

1	-1	4.32	new

2	0	3.23	old

3	-1	10.11	old


The default separator list, ('\s+', '\n') first splits on newlines, 
resulting in three rows.  Each row than is splitted on whitespace, 
resulting in four columns every row.  The last element of the resulting 
array is found by $array->[2][3] (indici start at zero).

You may pass an optional last parameter that contains an integer only.  
This is passed to split as the LIMIT parameter.  See 
L<perlfunc/"split"> for more details, it just limits the number of 
times that split splits.  The LIMIT paramter is only used in the last 
dimension (aka, first delimiter).  In case your string can be an 
integer only (that means, no other characters present) and you have 
more than two dimensions, you should use supersplit_nolimit, or 
provide a bogus LIMIT like -1.

A final remark an this function: It first tries to interpret your input 
as 
a filehandle and than as a string.  Maybe you don't want that, if you are 
using L<IO::Scalar> for example.  In that case, convert your object to a 
string before passing it.

Supersplit returns a multi-dimensional array or undef if an error 
occurred. 

=item supersplit_nolimit

Behaves like supersplit, except that is does not try to interpret the 
last 
parameter as the LIMIT parameter for split.

=item supersplit_open

Behaves like supersplit (including LIMIT behavior), except that it opens 
the input string with open( INPUT, "$string" ).  If that fails, 
supersplit_open confesses, and it carps if INPUT turns out to be empty. 
See L<Carp> for more details.

=item supersplit_limits( $fh || $string, $separator_arrayref, 
$limits_arrayref)

Behaves like supersplit, but the separator list must be provided as a 
reference to an array, just as the list with LIMITs. If the LIMIT list 
has less members than the separator list, the last dimensions will be 
called
without LIMIT. Both the separators and limits are popped, that is the 
lists
will be processed from right to left, just like the separator list in 
previously descrived methods. 

This method can be used to parse tables that need a limit on
a higher dimension, I understand the .csv format is an example of that.

=item supersplit_hashref( $hashref)

This is just a wrapper around supersplit_limits. All arguments are passed
as members of the referenced hash. These members are: 'separators', 
'limits',
'string', 'filehandle' and 'open'. The members 'separators' and 'limits' 
must be
references to arrays. The method passed these references to 
supersplit_limits,
see above for a description. On the other arguments, the method tries to 
get 'string' first, than the 'filehandle' and if that fails tries to use 
the 'open' member.

=item superjoin( $colseparator, $rowseparator, $array2D );

The fourth and last method, superjoin, takes a nD-array and returns it as 
a 
string.  The default behavior assumes 2D-array.  In the string, columns 
(adjacent cells) are separated by the first argument provided.  Rows 
(normally lines) are separated by the second argument.  Alternatively, 
you 
may give the 2D-array as the only argument.  In that case, superjoin 
joins 
columns with a tab ("\t"), and rows with a newline ("\n").  If you have 
more dimensions in your array, all separators for all dimensions should 
be 
provided. If you don't, superjoin stops at the second-last dimension. 
Just as with supersplit, separators are processed in reversed order: the 
last
separator/delimiter is processed first.

Superjoin returns an undef if an error occurred, for example if you give a
ref to an hash. If your first dimension points to hashes or strings,
superjoin will return undef. Mixed arrays will break the code. 

=back

=head1 AUTHOR

Jeroen Elassaiss-Schaap, with great help from Ben Tilly, who rewrote most 
of 
the code for version 0.02.

=head1 LICENSE

Perl/ artisitic license

=head1 STATUS

Alpha

=cut

use Exporter;
use vars qw( %EXPORT_TAGS @ISA $VERSION @limit);
$VERSION = 0.06;
@ISA = qw( Exporter );
%EXPORT_TAGS = (
      all => [ qw( supersplit superjoin supersplit_open supersplit_nolimit
			  		  supersplit_limits supersplit_hashref)],
	  standard => [ 'all' ],
	  minimal => [ qw( supersplit superjoin ) ]
	  );
Exporter::export_ok_tags('all');
Exporter::export_tags('all');
@limit = ();
use Carp;

sub supersplit{
	@_ = _limit( @_);
	my $text = _text( pop );
	_supersplit( @_, $text);
}

sub supersplit_open{
	@_ = _limit( @_);
	my $text = _open( pop );
	_supersplit( @_, $text);
}

sub supersplit_nolimit{
	my $text = _text( pop);
	_supersplit( @_, $text);
}

sub supersplit_limits{
	my $limit_array = pop;
	return undef unless( ref( $limit_array) eq 'ARRAY' );
	@limit = @$limit_array;
	my $separator_array = pop;
	return undef unless( ref( $separator_array) eq 'ARRAY' );
	supersplit_nolimit( @$separator_array, @_);
}	

sub supersplit_hashref{
	my $input = shift;
	return undef unless( ref( $input) eq 'HASH' );
	my $limit_array     = $input->{ limits }     or return undef;
	my $separator_array = $input->{ separators } or return undef;
	my $string;
	for (1) {
		($string = $input->{ string } and last)
			if $input->{ string     };
		($string = _text( $input->{ filehandle }), last)  
			if $input->{ filehandle };
		($string = _open( $input->{ 'open' } ), last)
			if $input->{ 'open'     };
	}
	supersplit_limits( $string, $separator_array, $limit_array);
}

sub _supersplit{
	my $text = pop;
	$_[0] || ( $_[0] = '\s+' );
	$_[1] || ( $_[1] = '\n'  );
	_split( @_, $text );
}

sub _text{
	my $fh = pop;
	unless (defined($fh)) {   
 		$fh = \*STDIN;  
	}
	no strict;
	do{ local $/ = undef; join '', <$fh>; } || $fh;
}

sub _split{
	my $text = pop;
  	my $limit = $limit[ $#_ ]; 
  	my $re = pop;
  	my @res;
	@res = scalar( @limit) ? split( $re, $text, $limit) : 
		split( $re, $text );
  	if (@_) {
  		@res = map { _split( @_, $_) } @res;
  	}
  	\@res;
}

sub _limit{
	local $_ =  $_[$#_];
	@limit = (pop) if m/^-?\d+$/s;
	if (scalar( @limit))
	{ 
		for ( @_[0..($#_ - 1)] ) 
		{
			push( @limit, undef);
		}
	}
	@_;
}

sub _open{
	my $str = pop;
	open INPUT, "$str" || confess "Could not open $str";
	my $text = join '', <INPUT>;
	close INPUT;
	$text || carp "Opening $str did not result in any data";
}

sub superjoin{
	my $array_ref = pop;
	push ( @_, "\t") if @_ < 1;  
	push ( @_, "\n") if @_ < 2;  
	return undef unless( ref( $array_ref ) eq 'ARRAY' );
	return undef unless( ref( $array_ref->[0] ) =~ /ARRAY/ );
	my @newarray = map{ [ @$_ ] } @$array_ref;
	_join( @_, \@newarray);
}

sub _join{
	my $array_ref = pop;
	my $str = pop;  
	if (@_) {    
		@$array_ref = map {_join( @_, $_)} @$array_ref;  
	}  
	join $str, @$array_ref;
}

1;

