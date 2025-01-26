package Regexp::Ethiopic::Geez;
use base qw(Regexp::Ethiopic);  #  this might be more useful later,
                                #  we at least get "Exporter" for free.

use utf8;
BEGIN
{
use strict;
use vars qw($VERSION @EXPORT_OK %GeezEquivalence);


	$VERSION = "0.06";
	
	@EXPORT_OK = qw(%GeezEquivalence);


#
#  Geez Rules Orthography Equivalence
#
%GeezEquivalence =(
	ሀ	=> "ሀሃ",
	ሐ	=> "ሐሓ",
	ኀ	=> "ኀኃ",

	ቁ	=> "ቁቍ",
	ቆ	=> "ቆቈ",

	አ	=> "አኣ",
	ዐ	=> "ዓዐ",

	ኮ	=> "ኮኰ",
	ጎ	=> "ጎጐ"
);

$GeezEquivalence{'ሃ'}
	= $GeezEquivalence{'ሀ'}
	;
$GeezEquivalence{'ሓ'}
	= $GeezEquivalence{'ሐ'}
	;
$GeezEquivalence{'ኃ'}
	= $GeezEquivalence{'ኀ'}
	;
$GeezEquivalence{'ቍ'}
	= $GeezEquivalence{'ቁ'}
	;
$GeezEquivalence{'ቈ'}
	= $GeezEquivalence{'ቆ'}
	;
$GeezEquivalence{'ኣ'}
	= $GeezEquivalence{'አ'}
	;
$GeezEquivalence{'ኰ'}
	= $GeezEquivalence{'ኮ'}
	;
$GeezEquivalence{'ዀ'}
	= $GeezEquivalence{'ኾ'}
	;
$GeezEquivalence{'ዓ'}
	= $GeezEquivalence{'ዐ'}
	;
$GeezEquivalence{'ጐ'}
	= $GeezEquivalence{'ጎ'}
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
		Regexp::Ethiopic::Geez->export_to_level (1, @args);
	}

}


sub getRe
{
$_ = ($#_) ? $_[1] : $_[0];


	s/\[=(\p{Ethiopic})=\]/($GeezEquivalence{$1}) ? "[$GeezEquivalence{$1}]" : $1/eog;

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

Regexp::Ethiopic::Geez - Regular Expressions Support for Geez Language.

=head1 SYNOPSIS

 #
 #  Overloading Perl REs:
 #
 use utf8;
 use Regexp::Ethiopic::Geez 'overload';

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
 require Regexp::Ethiopic::Geez;

 my $string = "([=አ=])ለም[=ጸ=][=ሃ=]ይ/";
 my $re = Regexp::Ethiopic::Geez::getRe ( $re );

 s/abc($re)xyz/"abc".fixForm($1,6)."xyz"/eg;

=head1 DESCRIPTION

The Regexp::Ethiopic::Geez module provides POSIX style character class
definitions for working with the localized use of Ethiopic syllabary in
the Geez (gez) language.  The character classes provided by the
Regexp::Ethiopic::Geez package correspond to properties of the script
under Geez orthography rules.

The Regexp::Ethiopic::Geez uses Regexp::Ethiopic so generally you
would not need to import both.  Regexp::Ethiopic::Geez conditionally
exports the hash %GeezEquivalence 
should you wish to use them.  Regexp::Ethiopic::Geez can also
export %EthiopiClass of Regexp::Ethiopic:

use Regexp::Ethiopic::Geez qw(%EthiopicClasses %GeezEquivalence %GeezClassEquivalence);

The Regexp::Ethiopic::Geez package is NOT derived from the Regexp class
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
