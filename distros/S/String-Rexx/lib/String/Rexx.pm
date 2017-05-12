package String::Rexx;

use 5.006;
use strict;
use warnings;
use Carp;
use Params::Validate ':all' ;
use Regexp::Common;

use base  'Exporter';
#use AutoLoader qw(AUTOLOAD);


our %EXPORT_TAGS = ( 'all' => [ qw(
       centre     center     changestr    compare    copies     countstr 
       delstr     delword    datatype     d2c        b2d        d2x    
       x2b        b2x        x2c          x2d        c2x   
       d2b        errortext  insert       lastpos    left       Length     
       overlay    Pos        right        Reverse    Abbrev     sign
       space      Substr     strip        subword    translate  verify 
       word       wordindex  wordlength   wordpos    words      xrange   
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our $VERSION = '0.08';

use constant BINARY        =>  qr/^[01]{0,32}$/;
use constant REAL          =>  $RE{num}{real};
use constant HEX8          =>  qr/^(?:0x)?[\dabcdef]{0,8}$/i  ;
use constant HEX           =>  qr/^(?:0x)?[\dabcdef]*$/  ;
use constant NONNEGATIVE   =>  qr/^[+]?[\d]+$/;
use constant POSITIVE      =>  qr/^[+]?[1-9]+$/;


1;
=pod

=head1 NAME

String::Rexx - Perl implementation of Rexx string functions

=head1 SYNOPSIS

  use String::Rexx qw( :all );

  use String::Rexx qw( functions... );


=head1 DESCRIPTION

This module implements almost all string functions
of regina2-rexx . 


=over

=item Abbrev( 'long', 'short' [, len] )

 Return 1 if string $short is a shortcut for string $long. And optionally, $len
 must not be greater than what the number of charecters matched with string $shoft. 
 Otherwise, return 0.

=item countstr( 'pat', 'string' )

 Counts the number of occurences  of 'pat' within 'string'

=item  center( 'string' ,  len   [, char ]  ) 

 Returns a string of length len, with the proper padding so that 'string' is centered


=item  changestr( 'old', 'string' ,  'new' ) 

 Changes all instances of substing 'old' inside 'string' to the new string 'new'

=item  compare( 'string1' ,  'string2'  [, char ]  ) 

 Returns 0 when both strings are equal, or N when they are not. 
 The number N denotes the length of either string -- strings are always 
 compared after padding, so they always have equal length when they are compared. 
 If the comparison fails, and the string contents are unequal, it will 
 return N, the size of either string since by now hey both have the same length.  
 The default pad character is space , ' ' .


=item  copies( 'string' ,  N ) 

 Returns a string consisting of N concatenated copies. N = 0, 1, 2, ...

=item delstr( 'string' , start [,length]  )

 Deletes the substring which starts at $start.  
 Length defaults to the rest of string.

=item delword( 'string' , start [,length]  )

 Deletes $length words, starting from $start.  
 Length defaults to the rest of string.

=item errortext( N ) 

 Returns the error string that describes the error number N .

=item  datatype( 'string'  [, option ]   )

 When 'string' represents a number or a non-number literal, this fuction 
 returns 'NUM' or 'LIT', respectively. 
 Option can be either 'NUM' or 'LIT'; when specified, the fuction returns 1 (true) or
 0 (false) depending whether 'string' is a NUM or a LIT .
 If the user-supplied option is neither NUM or LOT, the return value is set to undef ;

=item  d2c( N )

 Same as chr(N) . Converts decimal N to its char in the character set. 

=item  d2x( N [, length] )

 Converts decimal N to a hex string of size $lenght .

=item  insert( 'source' , 'target' [,'position' ]  [,'length'] [, char ] ) 

 Inserts string 'source' into string 'targer'. 
 Position defaults to 0, length defaults to len of $source , and 
 padding char defaults to ' ' .

=item lastpos( 'needle' , 'haystack',   [, start ]  )

 Returns the position of $needle in $haystack (searching from the end) . 
 Returns 0 if not found, and 1 when neelde occurs at start of haystack

=item left( 'string' , length,   [, 'char']  )

  Returns the leftmost $length chars. If there are not
  enough characters, the string is padded (prepended) with char characters.
  Char defaults to space.

=item Length( 'string' )

 Returns the length of string.

=item overlay( 'source', 'target' [, start] [, length] [, pad]  )

 Overstrikes the $target string, with $source .


=item Reverse( 'string' )

  Reverses the order of characters in string.

=item Pos( 'needle' , 'haystack',   [, start ]  )

 Returns the position of $needle in $haystack . 
 Returns 0 if not found, and 1 when neelde occurs at start of haystack

=item right( 'string' , length,   [, 'char']  )

  Returns the $length chars from the end of string. If there are not
  enough characters, the string is padded (prepended) with char characters.
  Char defaults to space.


=item space( 'string' [, 'length']  [, 'char']  )

  After removing leading and trailing spaces, internal whitespace
  change to $length chars. Char defaults to  ' ' , and length defaults to 1 .


=item strip( 'string' [, 'Option']  [, 'char']  )
  
  Strips leading whitespace from string.
  The optional 2nd param can be set to 'leading', 'trailing', or 'both' .
  The optional 3rd param will strip chars instead of whitespace.
  Returns the striped string.

=item Substr( 'string', start, [, length ]  [, padchar ] )
  
  Returns a substring of string. If string does not have enough chars
  to fill the request, we use padding with character padchar .

=item wordindex( 'string', N )

  Returns the index in the string for the Nth word.

=item wordlength( 'string', N )

  Returns the length of the Nth word in the string. Where N=1,2,...
  Returns 0 if there are less worlds than N .
  Raises exception if is  N < 1

=item subword( 'string', start [, N ] )

  Returns a string of words staring from start. N denotes how many
  words to return (default is as many as possible.)
  start = N = 1,2,...

=item translate( 'string' [, 'new' , 'old'  [, pad] ]  )

  The translitaration oparator. It returns a strings where all characters 
  in 'old' and transformed to the corresponding characters in 'new' .
  In the special case when all options are absent, it translates $string
  to upper case.

=item verify( 'string', 'chars' [, sense] [, start] )

 Returns 0 if $string consists from characters in the set $chars , otherwise
 it returns the position of the 1st character in $sting that failed the match.
 The sense param is either 'M' for match, or 'N' for non-match, default is 'M' .
 The start param indicate the position from 'string' to start matching (default is 1,
 to match from the start of 'string').


=item wordpos( 'pattern' , 'string' )
 
 Returns the position of the word in 'string' containing  'pattern'

=item word( 'string', wordno )

  Returns the nth  word in the string.

=item words( 'string' )

  Returns the number of words in the string.

=item xrange( S , E )

  Retruns a sequence of characters, starting with char S, and ending with char E .


=back

=head2 EXPORT

None by default. 


=head1 AUTHOR

Ioannis Tambouras, E<lt>ioannis@earthlink.netE<gt>

=head1 SEE ALSO

L<regina(1)>.

=cut
sub Abbrev ($$;$) {
         ( local $_ , my ( $short , $len )) =  validate_pos @_ ,
				{ type  => SCALAR              },
				{ type  => SCALAR              }, 
				{ regex => qr/^\+?\s*\d+$/, optional=>1  }; 

          /^$short/  ||  ((defined $len)&&length $short >= $len)    ? 1
                                                                    : 0  ;
}
sub center ($$;$) {

       my ($str , $len , $char) =  validate_pos @_  , 
			  	  { type  => SCALAR } ,
			          { regex => qr/^\+?\s*\d+$/          } ,
			          { regex => qr/^.$/ , default => ' ' },
                                                      ;

       $str       =  substr( $str, 0, $len )   ;  # if they asked  for less space than given text
       my $offset =  ($len -  length $str)/2  ;
       ($char x $offset)   . $str  .  ($char x ($offset+0.6) )   ;
}
sub centre ($$;$)  { goto &center }
sub  changestr ($$$) {
        my ( $old , $string, $new) = @_ ;
        $string  =~  s/\Q$old/$new/g      ,  $string;
}
sub compare ($$;$)  {
        my ( $a, $b , $char) =  validate_pos  @_ ,
                                     { type  => SCALAR },
                                     { type  => SCALAR },
                                     { regex => qr/^.$/ , default => ' ' };

        my ($Alen , $Blen)   =  ( length($a)  , length($b) );
        my $max              =  ($Alen > $Blen) ? $Alen : $Blen ;

        substr( $a, $Alen )  =  $char  x ($max - $Alen) ;
        substr( $b, $Blen )  =  $char  x ($max - $Blen) ;
        $a cmp $b  && $max ;
}
sub  copies ($$)  {
        my ( $str , $num ) = validate_pos  @_ ,
                                     { type  => SCALAR      },
                                     { regex => NONNEGATIVE } ;
        $str x $num ;
}
sub countstr ($$) {
        (my ($pat), local $_) = @_ ;
	($pat eq '')  ? 0 :  ( () =  /\Q$pat/gx ) ;
}
sub  datatype ($;$)  {
        my ($real, $str, $option) = (REAL, validate_pos @_,
                                    { type => SCALAR },
                                    { regex => qr/^[ablmnuwx]$/i, optional=>1});
                (defined $option)
                ?  $str  =~ {      A  =>   '(?i)^[a-z\d]+$'   ,
                                   B  =>   '^[01]+$'          ,
                                   L  =>   '^[a-z]+$'         ,
                                   M  =>   '(?i)^[a-z]+$'     ,
                                   N  =>   "^$real\$"         ,
                                   U  =>   '^[A-Z]+$'         ,
                                   W  =>   '^[-+]?[\d]+$'     ,
                                   X  =>   '(?i)^[\da-f]+$'   ,
                             }->{uc $option} || 0
                :  ($str =~ /^$real$/)  && 'NUM' || 'CHAR'  ;
}
sub d2c ($) {
      chr(shift) ;
}
sub  delstr ($$;$)  {
        my ( $string , $start, $len ) = validate_pos  @_ ,
                                { type  => SCALAR                    },
                                { regex => qr/^\+?\s*\d+$/           },
                                { regex => qr/^\+?\s*\d+$/ ,
                                           default => length $_[0]   } ;

        substr( ($string || return'' ) , $start-1, $len, '' ) ;
        $string;
}
sub delword ($$;$) {
     (local $_, my ($start,$count))= validate_pos @_ ,
                                            {type => SCALAR},
                                            {regex=> NONNEGATIVE, default=>1  },
                                            {regex=> NONNEGATIVE, default=>3E4};
     $start-- ;
     / ^ (?:\S+\s*){$start} /xg   or  return $_ ;
     s/(?:(?<=^)|(?<=\s))  \G (\s*\S+){0,$count} \s* //x      ,   $_ ;
}
sub errortext ($) {
        local ($!)  = validate_pos @_ , { regex => qr/^\+?\s*\d+$/  } ,;
        $! ;
}
sub insert ($$;$$$) {
         my ($source , $target, $pos, $len, $char) = validate_pos @_ ,
                                     { type  => SCALAR                                    },
                                     { type  => SCALAR                                    },
                                     { regex => qr/^\+?\s*\d+$/ , default => 0            },
                                     { regex => qr/^\+?\s*\d+$/ , default => length $_[0] },
                                     { regex => qr/^.$/         , default => ' '          };

         my $targlen             =  length $target   ;
         substr( $source, $len ) =  '' ;

         ($pos <= $targlen) ?  substr( $target, $pos ,  0 , $source )
                            :  ($target .=   $char x ($pos-$targlen) . $source ) ;
         $target;
}
sub  lastpos  ($$;$)  {
         my ($needle , $hay, $start ) = validate_pos  @_ ,
				       { type => SCALAR                    },
				       { type => SCALAR                    },
				       { regex => qr/^\+?\s*\d+$/,          
						  default => length $_[1]   };

         1 + rindex(  $hay,  ($needle || return 0),    --$start  );
}
sub left ($$;$)  {
        my ($str, $len, $char) = validate_pos  @_  ,
                                          { type  => SCALAR              },
                                          { regex => qr/^\+?\s*\d+$/     },
                                          { type  => SCALAR, default=>' '},;

        my $padding = $char  x  (($len||return '') - length $str) ;
        substr( $str,  0,  $len) . $padding ;
}
sub Length ($)  {
       length shift();
}
sub overlay ($$;$$$)  {
      my ($source , $target, $start, $len, $char ) = validate_pos @_ ,
                                       { type  => SCALAR },
                                       { type  => SCALAR },
                                       { regex => qr/^\+?\s*\d+$/ , default => 1            },
                                       { regex => qr/^\+?\s*\d+$/ , default => length $_[0] },
                                       { regex => qr/^.$/         , default => ' '          };

      $source                 .=   $char x ($len-length $source) ;
      substr( $source, $len )  =   ''                            ;
      substr( $target, --$start, (length $source) , $source )    ;
      $target;
}
sub Pos ($$;$)  {
         my ($needle , $hay, $start ) = @_ ;
	 1 + index( $hay, ($needle||return 0), ($start||0) );
}
sub right ($$;$)  {
        my ($str, $len, $char) = validate_pos  @_  ,
                                          { type  => SCALAR              },
                                          { regex => qr/^\+?\s*\d+$/     },
                                          { type  => SCALAR, default=>' '},;

        my $padding = $char  x  (($len||return '') - length $str) ;
        $padding . substr( $str, - $len);
}
sub Reverse ($)   { 
	scalar reverse shift() ;
}
sub  space ($;$$)  {
        (local $_, my ($len , $char)) =  validate_pos  @_ ,
                                  { type  => SCALAR },
                                  { regex => NONNEGATIVE, default => 1  },
                                  { regex => qr/^.$/s   , default => ' '};

        s/^\s*|\s*$//g                  ;
        s/\s+/{ $char x $len }/eg  , $_ ;
}
sub  Substr ($$;$$)  {
        my ($str, $start, $len, $char) = @_ ;
        my $slen = length($str) || return '' ;
        my $padding = ( $slen && $start) + $len - ($slen && 1) - $slen ;
        substr($str, $start-1, $len)   .   $char  x $padding    ,
}
sub strip ($;$$) {
        (local $_, my ( $direction, $char)) = validate_pos @_  ,
                                             { type  => SCALAR       },
                                             { regex => qr/^[LTB]$/i  ,
                                               default => 'B'         },
                                             { regex => qr/^\S$/, default=>' '};
        my $pattern =  { L    =>  "^[$char]+"             ,
                         T    =>  "[$char]+\$"            ,
                         B    =>  "^[$char]+|[$char]+\$"  ,
                       }->{ uc $direction }  ;

        s/ $pattern //gx   , $_ ;
}
sub translate ($;$$$) {
        $_ = shift ,   my ($new, $old, $pad)  = @_ ;
        return uc     unless ( $new || $old );
        return undef  unless  defined $old;

        $pad = $pad || ' ' ;
		no warnings;
        eval "y/$old/$new$pad/" ;
        $_;
}
sub verify ($$;$$)   {
        (local $_, my ($ref, $opt, $start)) =
                                         validate_pos @_ ,
                                         { type => SCALAR },
                                         { type => SCALAR },
                                         { regex => qr/^[NM]$/i, default=>'N' },                                         { regex => POSITIVE,    default=> 1  };
	  return 0 if $ref eq '';
          my $pattern = qr/ (?: [\Q$ref\E]) /x ;
          pos()  = --$start;

          ($opt =~ /N/i)
             ?    do{  /\G $pattern+/xgc;
                       return (pos == length) ? 0  : 1 + pos }
             :    /$pattern/gc or return 0;
                  pos ;
}
sub word  ($$)  {
        (local $_, my $start) = validate_pos @_ ,
                                    { type  => SCALAR   }  ,
                                    { regex => POSITIVE }  ;

        $start--;
        / ^ (?>\s* (?:\S+\s*){$start}) (\s*\S+)  /x
        and $+;
}
sub wordindex ($$) {
        my ($str, $n) = validate_pos @_ , { type  => SCALAR      },
                                          { regex => NONNEGATIVE } ;

        (' '.$str) =~ / (?:\s+ (\S+)){$n} /x
        && $-[1] or 0;
}
sub wordlength ($$) {
        my ($str, $n)  =   validate_pos @_ ,  { type  => SCALAR      },
                                              { regex => NONNEGATIVE };

        (' '.$str) =~ / (?:\s (\S+)){$n} /x
                ? length ($1||'')
                : 0 ;
}
sub  subword ($$;$)  {
        (local $_, my ($start, $n)) = validate_pos @_ ,
                                    { type  => SCALAR   }  ,
                                    { regex => POSITIVE }  ,
                                    { regex => NONNEGATIVE , default => 3e3 };

        $start--;
        / ^ (?>\s* (?:\S+\s*){$start}) ((?:\s*\S+){0,$n})  /x
        and $+;
}
sub wordpos ($$) {
        (my $pat, local $_, my $i) = @_ ;

	 return  0 if  $pat eq '';
         $i++ while ( /  \G  (?>\s*\S+)  (?<!\Q$pat\E)   /xcg) ;
         ((pos||0) == length) ? 0 : ++$i ;
}
sub words ($)  {
        scalar ( () =  shift() =~ /(\S+)/g   );
}
sub xrange ($$) {
        my ($start, $end) = @_ ;
        my $len =  1 + ord ($end) - ord ($start);
        return pack 'A'x$len , $start..$end     if $len>0 ;
        pack 'A'x(257+$len) ,  $start..chr(0xff) , chr(0)..$end ;
}
sub b2d {
         (local $_) =  validate_pos @_ , { regex => qr/^[01]+$/ } ;
         eval "0b$_";

        # Method2  (4x faster)
        # pack 'A*', unpack 'N', pack  'B32', '0'x (32-length) .$_ ;
}
sub d2x {
        validate_pos @_,  { regex => NONNEGATIVE } ;

        local $_ = pack '(A*)*', unpack '(H2)*', pack 'N', shift ;
        s/^0*//g ;
        $_ or '0';
}
sub sign ($) {
       ($_[0] > 0) ?  1
                   :  ($_[0]<0) ? -1
                                :  0 ;
}
sub x2b {
        local ($_)   =  validate_pos @_,  { regex => HEX } ;

        $_ = '0'x(8-(length||return '')) . $_ ;
        ($_=unpack 'B32', pack 'H*', $_ )  =~  s/^0*(?!$)// ,     $_ ;
}
sub b2x {
        local ($_)   =  validate_pos @_,  { regex => BINARY } ;

        $_ = '0'x(32-(length||return '')) . $_ ;
        ($_ = unpack 'H*', pack 'B32', $_ )  =~   s/^ 0* (?!$) //x   , $_;
}
sub x2c {
        validate_pos @_ , { regex => HEX } ;
        unpack 'A*', pack 'H*', (shift||return '');
}
sub x2d {
        validate_pos @_ , { regex => HEX } ;
        hex shift;
}
sub c2x {
        pack '(A*)*', unpack '(H2)*', shift;
}
sub d2b {
        validate_pos  @_ ,  { regex => NONNEGATIVE };

        local $_ = unpack 'B32'x8, pack 'N', shift ;
        s/^0*//g ;
        '0' x (8-(length)%8) . $_;
}
