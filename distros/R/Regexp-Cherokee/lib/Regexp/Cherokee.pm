package Regexp::Cherokee;
use base qw(Exporter);

use utf8;
BEGIN
{
use strict;
use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS %CherokeeClasses %CherokeeEquivalence $pseudoMatrix);

	$VERSION = "0.03";
	
	@EXPORT_OK = qw(%CherokeeClasses %CherokeeEquivalence &getForm &setForm &subForm &formatForms);
	%EXPORT_TAGS = ( utils => [qw(&getForm &setForm &subForm &formatForms)] );


%CherokeeClasses =(
	1	=> "ᎠᎦᎧᎭᎳᎹᎾᎿᏀᏆᏌᏍᏓᏔᏜᏝᏣᏩᏯ",
	2	=> "ᎡᎨᎮᎴᎺᏁᏇᏎᏕᏖᏞᏤᏪᏰ",
	3	=> "ᎢᎩᎯᎵᎻᏂᏈᏏᏗᏘᏟᏥᏫᏱ",
	4	=> "ᎣᎪᎰᎶᎼᏃᏉᏐᏙᏠᏦᏬᏲ",
	5	=> "ᎤᎫᎱᎷᎽᏄᏊᏑᏚᏡᏧᏭᏳ",
	6	=> "ᎥᎬᎲᎸᏅᏋᏒᏛᏢᏨᏮᏴ",
	Ꭰ	=> "Ꭰ-Ꭵ",
	Ꭶ	=> "Ꭶ-Ꭼ",
	Ꭽ	=> "Ꭽ-Ꮂ",
	Ꮃ	=> "Ꮃ-Ꮈ",
	Ꮉ	=> "Ꮉ-Ꮍ",
	Ꮎ	=> "Ꮎ-Ꮕ",
	Ꮖ	=> "Ꮖ-Ꮛ",
	Ꮜ	=> "Ꮜ-Ꮢ",
	Ꮣ	=> "Ꮣ-Ꮫ",
	Ꮬ	=> "Ꮬ-Ꮲ",
	Ꮳ	=> "Ꮳ-Ꮸ",
	Ꮹ	=> "Ꮹ-Ꮾ",
	Ꮿ	=> "Ꮿ-Ᏼ"
);

#
#  Cherokee Rules Orthography Equivalence
#
%CherokeeEquivalence =(
	Ꭶ	=> "ᎦᎧ",
	Ꮎ	=> "ᎾᎿᏀ",
	Ꮜ	=> "ᏌᏍ",
	Ꮣ	=> "ᏓᏔ",
	Ꮥ	=> "ᏕᏖ",
	Ꮧ	=> "ᏗᏘ",
	Ꮬ	=> "ᏜᏝ"
);
$CherokeeEquivalence{'Ꭷ'}
	= $CherokeeEquivalence{'Ꭶ'}
	;
$CherokeeEquivalence{'Ꮏ'}
	= $CherokeeEquivalence{'Ꮐ'}
	= $CherokeeEquivalence{'Ꮎ'}
	;
$CherokeeEquivalence{'Ꮝ'}
	= $CherokeeEquivalence{'Ꮜ'}
	;
$CherokeeEquivalence{'Ꮤ'}
	= $CherokeeEquivalence{'Ꮣ'}
	;
$CherokeeEquivalence{'Ꮦ'}
	= $CherokeeEquivalence{'Ꮥ'}
	;
$CherokeeEquivalence{'Ꮨ'}
	= $CherokeeEquivalence{'Ꮧ'}
	;
$CherokeeEquivalence{'Ꮭ'}
	= $CherokeeEquivalence{'Ꮬ'}
	;

# use a long string as a pseudo matrix
# get index in pseudo matrix, then find in index+form combination position in matrix

# 6x13 matrix

# Form 1: "ᎠᎦᎭᎳᎹᎾᏆᏌᏓᏜᏣᏩᏯ",
# Form 2: "ᎡᎨᎮᎴᎺᏁᏇᏎᏕᏞᏤᏪᏰ",
# Form 3: "ᎢᎩᎯᎵᎻᏂᏈᏏᏗᏟᏥᏫᏱ",
# Form 4: "ᎣᎪᎰᎶᎼᏃᏉᏐᏙᏠᏦᏬᏲ",
# Form 5: "ᎤᎫᎱᎷᎽᏄᏊᏑᏚᏡᏧᏭᏳ",
# Form 6: "ᎥᎬᎲᎸXᏅᏋᏒᏛᏢᏨᏮᏴ",

$pseudoMatrix = "ᎠᎦᎭᎳᎹᎾᏆᏌᏓᏜᏣᏩᏯᎡᎨᎮᎴᎺᏁᏇᏎᏕᏞᏤᏪᏰᎢᎩᎯᎵᎻᏂᏈᏏᏗᏟᏥᏫᏱᎣᎪᎰᎶᎼᏃᏉᏐᏙᏠᏦᏬᏲᎤᎫᎱᎷᎽᏄᏊᏑᏚᏡᏧᏭᏳᎥᎬᎲᎸXᏅᏋᏒᏛᏢᏨᏮᏴ";

}

sub import
{

	my @args = ( shift ); # package
	foreach (@_) {
		if ( /overload/o ) {
			use overload;
			overload::constant 'qr' => \&getRe;
		}
		elsif ( /:forms/o ) {
			Regexp::Cherokee->export_to_level (1, $args[0], ':forms');  # this works too...
		}
		elsif ( /:utils/o ) {
			Regexp::Cherokee->export_to_level (1, $args[0], ':utils');  # this works too...
		}
		else {
			push (@args, $_);
		}
	}
	if ($#args) {
		Regexp::Cherokee->export_to_level (1, @args);  # this works too...
	}

}


sub getForm
{
my ($letter) = @_;


	foreach my $form (1..6) {
		return $form if ( $CherokeeClasses{$form} =~ $letter );
	}
}


#
#  unfortunately the index function in Perl 5.8.0 is broken for some
#  Unicode sequences: http://rt.perl.org/rt2/Ticket/Display.html?id=22375
#
sub _index
{
my ( $haystack, $needle ) = @_;

	my $pos = my $found = 0;
	foreach (split (//, $haystack) ) {
		$found = 1 if ( /$needle/ );
		$pos++ unless ( $found );
	}

	$pos;
}


sub setForm
{
my ($letter, $form) = @_;


	$form--;
	#
	# simplify
	#
	$letter =~ s/Ꭷ/Ꭶ/;
	$letter =~ s/[ᎿᏀ]/Ꮎ/;
	$letter =~ s/Ꮝ/Ꮜ/;
	$letter =~ s/Ꮤ/Ꮣ/;
	$letter =~ s/Ꮦ/Ꮥ/;
	$letter =~ s/Ꮨ/Ꮧ/;
	$letter =~ s/Ꮭ/Ꮬ/;

	# print "letter = $letter / form = $form\n<br>";
	my $index = _index ( $pseudoMatrix, $letter );
	# print "index = $index<br>\n";

        my $offset = ( ($index%13) + $form*13 );
	substr ( $pseudoMatrix, $offset, 1 );

}


sub subForm
{
my ($set, $get) = @_;

	setForm ( $set, getForm ( $get ) );
}


sub formatForms
{
my ($format, $string) = @_;

	my @chars = split ( //, $string );

	if ( @chars != ($format =~ s/%/%/g) ) {
		$format =~ s/\p{Cherokee}//g;
		warn ( "\"$string\" is of different length from $format." );
		return;
	}

	foreach (@chars) {
		$format =~ s/%(\d+)/setForm($_, $1)/e;
	}

	$format;
}


sub handleChars
{
my ($chars,$form) = @_;

	return ( $CherokeeClasses{$form} ) if ( $chars eq "all" );

my $re;

	$chars =~ s/(\w)(?=\w)/$1,/og;
	my @Chars = split ( /,/, $chars );
	foreach (@Chars) {
		if ( /(\w)-(\w)/o ) {
			my ($a,$b) = ($1,$2);
			foreach my $char (sort keys %CherokeeClasses) {
				next if ( length($char) > 1 );
				next unless ( (ord($a) <= ord($char)) && (ord($char) <= ord($b)) );
				if ( $form eq "all" ) {
					$re .= $CherokeeClasses{$char};
				}
				else {
					$CherokeeClasses{$form} =~ /([$CherokeeClasses{$char}])/;
					$re .= $1;
				}
			}
		}
		else {
			if ( $form eq "all" ) {
				$re .= $CherokeeClasses{$_};
			}
			else {
				$CherokeeClasses{$form} =~ /([$CherokeeClasses{$_}])/;
				$re .= $1;
			}
		}
	}

$re;
}


sub setRange
{
my ($chars,$forms,$not) = @_;
$not ||= $_[3];

	my $re;

	if ( $forms eq "all" ) {
		$re = handleChars ( $chars, $forms );
	}
	else {
		my @Forms = split ( /,/, $forms);
		#
		# next time, put @Chars loop on the outside and set
		# up character ranges with -
		#
		foreach (@Forms) {
			if ( /(\d)-(\d)/o ) {
				my ($a,$b) = ($1,$2);
				foreach my $form ($a..$b) {
					$re .= handleChars ( $chars, $form );
				}
			}
			else {
				my $form = $_;
				$re .= handleChars ( $chars, $form );
			}
		}
	}

	($re) ? ($not) ? "[$not$re]" : "[$re]" : "";
}


sub getRe
{
$_ = ($#_) ? $_[1] : $_[0];


	s/\[=(\p{Cherokee})=\]/($CherokeeEquivalence{$1}) ? "[$CherokeeEquivalence{$1}]" : $1/eog;
	s/\[#(\p{Cherokee}|\d)#\]/($CherokeeClasses{$1}) ? "[$CherokeeClasses{$1}]" : ""/eog;
	s/\[#(\^)?([\d,-]+)#\]/setRange("all",$2,$1)/eog;
	s/\[#(\^)?([\p{Cherokee},-]+)#\]/setRange($2,"all",$1)/eog;

	#
	# for some stupid reason the below doesn't work, so \w
	# is used in place of \p{Cherokee}, dangerous...
	#
	# s/(\p{Cherokee})\{%([\d,-]+)\}/setRange($1,$2)/eog;
	s/(\w)\{#([\d,-]+)#\}/setRange($1,$2)/eog;

	s/\[(\^)?(\p{Cherokee}+.*?)\]\{(\^)?#([\d,-]+)#\}/setRange($2,$4,$1,$3)/eog;

	$_;
}



#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################


__END__


=head1 NAME

Regexp::Cherokee - Regular Expressions Support for Cherokee Script.

=head1 SYNOPSIS

 #
 #  Overloading Perl REs:
 #
 use utf8;
 use Regexp::Cherokee qw(overload setForm);

 :

 s/([#2#])/setForm($1,6)/eg;
 s/([ᎠᎦᎧᎭ]%2)/setForm($1,6)/eg;
 s/([ᎠᎦᎧᎭ]%{1,3})/setForm($1,6)/eg;
 s/([ᎠᎦᎧᎭ]%{1-3,7})/setForm($1,6)/eg;
 s/([#Ꮎ#])/subForm('Ꮬ',$1)/eg;  # substitute, a 'Ꮬ' for a 'Ꮎ' in the form found for the 'Ꮎ'

 if ( /[#Ꮜ#]/ ) {
   #
   # do something
   #
   :
 }

 :
 :

 #
 #  Without overloading:
 #
 use utf8;
 require Regexp::Cherokee;

 my $string = "[ᎠᎦᎧᎭ]%{1-3,7}";
 my $re = Regexp::Cherokee::getRe ( $string );

 s/abc($re)xyz/"abc".Regexp::Cherokee::setForm($1,6)."xyz"/eg;

=head1 DESCRIPTION

The Regexp::Cherokee module provides POSIX style character class
definitions for working with the Cherokee syllabary.  The character
classes provided by the Regexp::Cherokee package correspond to inate
properties of the script and are language independent.

The Regexp::Cherokee package is NOT derived from the Regexp class
and may not be instantiated into an object.  Regexp::Cherokee can
optionally export the utility functions C<getForm>, C<setForm>, 
C<subForm> and C<formatForms> (or all with the C<:utils> pragma)
to query or set the form of an Cherokee character.  Tags of variables
in the form names set to form values may be exported under the C<:forms>
pragma.

See the files in the doc/ and examples/ directories that are included
with this package.

=head2  Substituion Utilities

=head3  getForm

A utility function to query the "form" of an Cherokee syllable.  It
will return an integer between 1 and 12 corresponding to the [#\d+#]
classes.

  print getForm ( "Ꮿ" ), "\n";  # prints 1

=head3  setForm

A utility function to set the form number of a syllable.  The form
number must be an integer between 1 and 12 corresponding to the [#\d+#]
classes.

  s/(.)/setForm($1, 1)/eg;

=head3  subForm

A utility function to set the form number of a syllable based on the
form of another syllable.

  s/(\w+)([#Ꮎ#]/$1.subForm('Ꮬ', $2)/eg;


=head3  formatForms

A utility function somewhat analogous to C<sprintf> for a sequence of
syllables:

  print formatForms ( "%1%2%3%4", "ᎠᎦᎧᎭ" ), "\n";  # prints ᎠᎨᎯᎶ


=head1 LIMITATIONS

The overloading mechanism only applies to the constant part of the RE.  The
following would not be handled by the Regexp::Ethiopic package as expected:

  use Regexp::Cherokee 'overload';

  my $x = "Ꭷ";
        :
        :
  if ( /[#$x#]/ ) {
        :
        :
  }

The package never gets to see the variable C<$x> to then
perform the RE expansion.  The work around is to use the package as per:

  use Regexp::Cherokee 'overload';

  my $x = "Ꭷ";
        :
        :
  my $re = Regexp::Cherokee::getRe ( "[#$x#]" );

  if ( /$re/ ) {
        :
        :
  }


This works as expected at the cost of one extra step.  The overloading and
functional modes of the Regexp::Cherokee package may be used together
without conflict.

=head1 REQUIRES

Works perfectly with Perl 5.8.0, may work with Perl 5.6.x but has
not yet been tested.

=head1 BUGS

None presently known.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=head1 SEE ALSO

Included with this package:

  examples/overload.pl    examples/utils.p


=cut
