package Number::Spell;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	spell_number
);
$VERSION = '0.04';


# Preloaded methods go here.


my %expo=(
        0       =>      '',
        1       =>      'thousand',
        2       =>      'million',
        3       =>      'billion',
        4       =>      'trillion',
        5       =>      'quadrillion',
        6       =>      'quintillion',
        7       =>      'sextillion',
        8       =>      'septillion',
        9       =>      'octillion',
        10      =>      'nonillion',
        11      =>      'decillion',
        12      =>      'undecillion',
        13      =>      'duodecillion',
        14      =>      'tredecillion',
        15      =>      'quattuordecillion',
        16      =>      'quindecillion',
        17      =>      'sexdecillion',
        18      =>      'septendecillion',
        19      =>      'octodecillion',
        20      =>      'novemdecillion',
        21      =>      'vigintillion',
);


my %digit=(
         0      =>      '',
         1      =>      'one',
         2      =>      'two',
         3      =>      'three',
         4      =>      'four',
         5      =>      'five',
         6      =>      'six',
         7      =>      'seven',
         8      =>      'eight',
         9      =>      'nine',
        10      =>      'ten',
        11      =>      'eleven',
        12      =>      'twelve',
        13      =>      'thirteen',
        14      =>      'fourteen',
        15      =>      'fifteen',
        16      =>      'sixteen',
        17      =>      'seventeen',
        18      =>      'eighteen',
        19      =>      'nineteen',
        '2*'    =>      'twenty',
        '3*'    =>      'thirty',
        '4*'    =>      'forty',
        '5*'    =>      'fifty',
        '6*'    =>      'sixty',
        '7*'    =>      'seventy',
        '8*'    =>      'eighty',
        '9*'    =>      'ninety',
);

sub spell_number{
  my $data=shift;
  my %opts=@_;


  if($data=~/(\-?)\s*(\d+)/){
    my ($s,$d)=($1,$2); 
    if($d == 0){
      return "zero";
    }
    my $ret='';
    if($s eq '-'){
      $ret='negative ';
    }
    my $l=length($d);

    if(defined($opts{Format})&&($opts{Format} eq "eu")){
      #European formatting
      my $c=1;
      while($l>0){
        my $o=$l-6;
        my $len=6;
        if($o<0){
          $len=$len+$o; 
          $o=0;
        }
        my $ss=substr $d,$o,$len;
        while(length($ss)<6){
          $ss='0'.$ss;
        }
 
        my ($hun1,$tn1,$dig1,$hun2,$tn2,$dig2)=unpack("A1A1A1A1A1A",$ss);

        my $sp='';
        if($hun1!=0){
          $sp.=$digit{$hun1}." hundred "; 
        }
        if($tn1==0){
          $sp.=" ".$digit{$dig1}." ";
        }elsif($tn1==1){
          $sp.=" ".$digit{$tn1.$dig1}." ";
        }else{
          $sp.=" ".$digit{$tn1."*"}." ".$digit{$dig1}." "; 
        }

        if($sp!~/^\s*$/){
          $sp.=" thousand ";
        } 
      
        if($hun2!=0){
          $sp.=$digit{$hun2}." hundred "; 
        }
        if($tn2==0){
          $sp.=" ".$digit{$dig2}." ";
        }elsif($tn2==1){
          $sp.=" ".$digit{$tn2.$dig2}." ";
        }else{
          $sp.=" ".$digit{$tn2."*"}." ".$digit{$dig2}." "; 
        }
 
        if($c==1){
          if($sp!~/^\s*$/){
           $ret=$sp;
	  }
        }else{
          $ret=$sp.' '.$expo{$c}.' '.$ret;
        } 
        $l-=6;
        $c++;
      }

    }else{
      #American formatting
      my $c=0;
      while($l>0){
        my $o=$l-3;
        my $len=3;
        if($o<0){
          $len=$len+$o; 
          $o=0;
        }
        my $ss=substr $d,$o,$len;
        my $sp='';
        while(length($ss)<3){
          $ss='0'.$ss;
        }
        my ($hun,$tn,$dig)=unpack("A1A1A1",$ss);
        if($hun!=0){
          $sp.=$digit{$hun}." hundred "; 
        }
        if($tn==0){
          $sp.=" ".$digit{$dig}." ";
        }elsif($tn==1){
          $sp.=" ".$digit{$tn.$dig}." ";
        }else{
          $sp.=" ".$digit{$tn."*"}." ".$digit{$dig}." "; 
        }
        if($sp!~/^\s*$/){
          $ret=$sp.' '.$expo{$c}.' '.$ret;
        }
        $l-=3;
        $c++;
      }
    }


    $ret=~s/\s\s+/ /g;
    $ret=~s/^\s//g;
    $ret=~s/\s$//g;
    return $ret;
  }else{
    return "";
  }
}



# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Number::Spell - Perl extension for spelling out numbers 

=head1 SYNOPSIS

  use Number::Spell;
  my $str=spell_number(519252);

=head1 DESCRIPTION


Number::Spell provides functionality for spelling out numbers.  Currently only 
integers are supported.

By default Number::Spell does American formatting, but can be configured 
to do European formatting by calling it with the "Format => 'eu'" option:

	spell_number( ...  , Format => 'eu');

American and European formatting differ in how they represent numbers one 
billion and above.

	number 		:  	20000000000 (2 * 10^11)
	American format :	twenty billion
	European format :	twenty thousand million

With American formatting (default) Number::Spell should work for integers to 

	nine hundred ninety nine vigintillion nine hundred ninety nine 
	novemdecillion nine hundred ninety nine octodecillion nine hundred 
	ninety nine septendecillion nine hundred ninety nine sexdecillion nine 
	hundred ninety nine quindecillion nine hundred ninety nine 
	quattuordecillion nine hundred ninety nine tredecillion nine hundred 
	ninety nine duodecillion nine hundred ninety nine undecillion nine 
	hundred ninety nine decillion nine hundred ninety nine nonillion nine 
	hundred ninety nine octillion nine hundred ninety nine septillion nine 
	hundred ninety nine sextillion nine hundred ninety nine quintillion nine 
	hundred ninety nine quadrillion nine hundred ninety nine trillion nine 
	hundred ninety nine billion nine hundred ninety nine million nine 
	hundred ninety nine thousand nine hundred ninety nine

and in European formatting mode is should be valid up-to 

	nine hundred ninety nine thousand nine hundred ninety nine vigintillion 
	nine hundred ninety nine thousand nine hundred ninety nine 
	novemdecillion nine hundred ninety nine thousand nine hundred ninety 
	nine octodecillion nine hundred ninety nine thousand nine hundred 
	ninety nine septendecillion nine hundred ninety nine thousand nine 
	hundred ninety nine sexdecillion nine hundred ninety nine thousand nine 
	hundred ninety nine quindecillion nine hundred ninety nine thousand 
	nine hundred ninety nine quattuordecillion nine hundred ninety nine 
	thousand nine hundred ninety nine tredecillion nine hundred ninety nine 
	thousand nine hundred ninety nine duodecillion nine hundred ninety nine 
	thousand nine hundred ninety nine undecillion nine hundred ninety nine 
	thousand nine hundred ninety nine decillion nine hundred ninety nine 
	thousand nine hundred ninety nine nonillion nine hundred ninety nine 
	thousand nine hundred ninety nine octillion nine hundred ninety nine 
	thousand nine hundred ninety nine septillion nine hundred ninety nine 
	thousand nine hundred ninety nine sextillion nine hundred ninety nine 
	thousand nine hundred ninety nine quintillion nine hundred ninety nine 
	thousand nine hundred ninety nine quadrillion nine hundred ninety nine 
	thousand nine hundred ninety nine trillion nine hundred ninety nine 
	thousand nine hundred ninety nine billion nine hundred ninety nine 
	thousand nine hundred ninety nine million nine hundred ninety nine 
	thousand nine hundred ninety nine



=head1 FUTURE IMPROVEMENTS

	o   more formatting options.  i.e. option to get "1500" to spell as 
       		 "fifteen hundred" instead of "one thousand five hundred"
	o   support for even larger numbers
	o   support for taking input as a Math::BigInt, Math::BigInteger
	o   support for taking numbers in scientific notation
	o   foreign language support
	o   support for real numbers (including Math::BigFloat)
	o   ability to convert from a "spelled" number to an arithmetic number

=head1 AUTHOR

Les Howard, les@lesandchris.com

=head1 SEE ALSO

perl(1).

=cut
