package Regexp::Ethiopic::Tigrigna;
use base qw(Regexp::Ethiopic);  #  this might be more useful later,
                                #  we at least get "Exporter" for free.

use utf8;
BEGIN
{
use strict;
use vars qw($VERSION @EXPORT_OK %TigrignaEquivalence %TigrignaClassEquivalence);


	$VERSION = "0.05";
	
	@EXPORT_OK = qw(%TigrignaEquivalence %TigrignaClassEquivalence);


#
#  Tigrigna Rules Orthography Equivalence
#
%TigrignaEquivalence =(
	ሀ	=> "ሀሃኀኃ",
	ሁ	=> "ሁኁ",
	ሂ	=> "ሂኂ",
	ሄ	=> "ሄኄ",
	ህ	=> "ህኅ",
	ሆ	=> "ሆኆኈ",

	ሐ	=> "ሐሓ",

	ሰ	=> "ሰሠ",
	ሱ	=> "ሱሡ",
	ሲ	=> "ሲሢ",
	ሳ	=> "ሳሣ",
	ሴ	=> "ሴሤ",
	ስ	=> "ስሥ",
	ሶ	=> "ሶሦ",
	ሷ	=> "ሷሧ",

	ቁ	=> "ቁቍ",
	ቆ	=> "ቆቈ",
	ቑ	=> "ቑቝ",
	ቖ	=> "ቖቘ",

	አ	=> "አኣ",
	ዐ	=> "ዓዐ",

	ኮ	=> "ኮኰ",
	ኾ	=> "ኾዀ",
	ጎ	=> "ጎጐ",

	ጸ	=> "ጸፀ",
	ጹ	=> "ጹፁ",
	ጺ	=> "ጺፂ",
	ጻ	=> "ጻፃ",
	ጼ	=> "ጼፄ",
	ጽ	=> "ጽፅ",
	ጾ	=> "ጾፆ",
);

foreach (ord('ሀ')..ord('ሆ')) {
	my $key = chr($_);	
	# print "KEY $key / $TigrignaEquivalence{$key}\n";
	next if ( $key eq 'ሃ' );
	my @values = split (//, $TigrignaEquivalence{$key});
	foreach (@values) {
		# print "  VALUE: $_\n";
		$TigrignaEquivalence{$_}
			= $TigrignaEquivalence{$key}
			;
	}
}
$TigrignaEquivalence{'ሓ'}
	= $TigrignaEquivalence{'ሐ'}
	;
foreach (ord('ሰ')..ord('ሷ')) {
	my $key = chr($_);	
	$TigrignaEquivalence{$key} =~ /(\w)$/;
	$TigrignaEquivalence{$1}
		= $TigrignaEquivalence{$key}
		;
}
$TigrignaEquivalence{'ቍ'}
	= $TigrignaEquivalence{'ቁ'}
	;
$TigrignaEquivalence{'ቈ'}
	= $TigrignaEquivalence{'ቆ'}
	;
$TigrignaEquivalence{'ቝ'}
	= $TigrignaEquivalence{'ቑ'}
	;
$TigrignaEquivalence{'ቘ'}
	= $TigrignaEquivalence{'ቖ'}
	;
$TigrignaEquivalence{'ኣ'}
	= $TigrignaEquivalence{'አ'}
	;
$TigrignaEquivalence{'ኰ'}
	= $TigrignaEquivalence{'ኮ'}
	;
$TigrignaEquivalence{'ዀ'}
	= $TigrignaEquivalence{'ኾ'}
	;
$TigrignaEquivalence{'ዓ'}
	= $TigrignaEquivalence{'ዐ'}
	;
$TigrignaEquivalence{'ጐ'}
	= $TigrignaEquivalence{'ጎ'}
	;
foreach (ord('ጸ')..ord('ጾ')) {
	my $key = chr($_);	
	$TigrignaEquivalence{$key} =~ /(\w)$/;
	$TigrignaEquivalence{$1}
		= $TigrignaEquivalence{$key}
		;
}


#
#  Family Eqivalence
#
%TigrignaClassEquivalence =(
	ሀ	=> "ሀ-ሆኀ-ኆኈ-ኍ",
	ሰ	=> "ሰ-ሷሠ-ሧ",
	ጸ	=> "ጸ-ጿፀ-ፆ"
);
$TigrignaClassEquivalence{'ሠ'}
	= $TigrignaClassEquivalence{'ሰ'}
	;
$TigrignaClassEquivalence{'ፀ'}
	= $TigrignaClassEquivalence{'ጸ'}
	;
}


sub import
{

	my @args = ( shift ); # package
	foreach (@_) {
		if ( /overload/o ) {
			use overload;
			overload::constant 'qr' => \&getRe;
		}
		elsif ( /EthiopicClasses|(sub|[gs]et)Form|:forms|:utils/ ) {
			Regexp::Ethiopic->export_to_level (1, "Regexp::Ethiopic", $_);
		}
		else {
			push (@args, $_);
		}
	}
	if ($#args) {
		Regexp::Ethiopic::Tigrigna->export_to_level (1, @args);
	}

}


#
# move into Regexp::Ethiopic later...
#
sub getFamilyEquivalent
{
my ($chars) = @_;


	return $chars if ( length($chars) == 1 );

	$chars =~ s/(\w)(?=\w)/$1,/og;
	my @Chars = split ( /,/, $chars );
	my $return;
	foreach (@Chars) {
		$char = $_;
		foreach	( keys %TigrignaClassEquivalence ) {
			$return .= $_ if ( $TigrignaClassEquivalence{$char} eq $TigrignaClassEquivalence{$_} );
		}
	}

	$return;
}


sub getRe
{
$_ = ($#_) ? $_[1] : $_[0];


	s/\[=(\p{Ethiopic})=\]/($TigrignaEquivalence{$1}) ? "[$TigrignaEquivalence{$1}]" : $1/eog;
	s/\[=#(\p{Ethiopic})#=\]/($TigrignaClassEquivalence{$1}) ? "[$TigrignaClassEquivalence{$1}]" : $1/eog;
	s/\[=#([\p{Ethiopic}]+)#=\]/Regexp::Ethiopic::setRange(getFamilyEquivalent($1),"all")/eog;

	Regexp::Ethiopic::getRe ( $_ );
}



#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################


__END__

=encoding utf8

=head1 NAME

Regexp::Ethiopic::Tigrigna - Regular Expressions Support for Tigrigna Language.

=head1 SYNOPSIS

 #
 #  Overloading Perl REs:
 #
 use utf8;
 use Regexp::Ethiopic::Tigrigna 'overload';

 :


 if ( /([=አ=])ለም[=ጸ=][=ሃ=]ይ/ ) {
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
 require Regexp::Ethiopic::Tigrigna;

 my $string = "([=አ=])ለም[=ጸ=][=ሃ=]ይ/";
 my $re = Regexp::Ethiopic::Tigrigna::getRe ( $re );

 s/abc($re)xyz/"abc".fixForm($1,6)."xyz"/eg;

=head1 DESCRIPTION

The Regexp::Ethiopic::Tigrigna module provides POSIX style character class
definitions for working with the localized use of Ethiopic syllabary in
the Tigrigna (ti) language.  The character classes provided by the
Regexp::Ethiopic::Tigrigna package correspond to properties of the script
under Tigrigna orthography rules.

The Regexp::Ethiopic::Tigrigna uses Regexp::Ethiopic so generally you
would not need to import both.  Regexp::Ethiopic::Tigrigna conditionally
exports the hashes %TigrignaEquivalence and %TigrignaClassEquivalence
should you wish to use them.  Regexp::Ethiopic::Tigrigna can also
export %EthiopiClass of Regexp::Ethiopic:

use Regexp::Ethiopic::Tigrigna qw(%EthiopicClasses %TigrignaEquivalence %TigrignaClassEquivalence);

The Regexp::Ethiopic::Tigrigna package is NOT derived from the Regexp class
and may not be instantiated into an object.  See the files in the
doc/ and examples/ directories that are included with this package.

=head1 REQUIRES

Works perfectly with Perl 5.8.0, may work with Perl 5.6.x but has
not yet been tested.

=head1 BUGS

None presently known.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=cut
