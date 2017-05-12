package Ruby::literal;

use strict;
use warnings;
use Carp ();

require Ruby;
require overload;

my %Typemap = (
		q       => \&Ruby::_string_handler,
		integer => \&Ruby::_integer_handler,
		binary  => \&Ruby::_integer_handler,
		float   => \&Ruby::_float_handler,
);
sub typemap
{
	if(@_){
		my %t;
		for my $h(@_){
			if($h eq 'string'){
				$t{q} = $Typemap{q};
			}
			elsif($h eq 'integer'){
				$t{integer} = $Typemap{integer};
				$t{binary}  = $Typemap{binary};
			}
			elsif($h eq 'float'){
				$t{float} = $Typemap{float};
			}
			elsif($h eq 'numeric'){
				$t{integer} = $Typemap{integer};
				$t{binary}  = $Typemap{binary};
				$t{float}   = $Typemap{float};
			}
			elsif($h eq 'all'){
				return %Typemap;
			}
			else{
				Carp::croak(qq{Unknown overload handler "$h"});
			}
		}
		return %t;
	}
	else{
		return %Typemap;
	}
}

sub import{
	shift;
	overload::constant( typemap(@_) );
}
sub unimport{
	shift;
	overload::remove_constant( typemap(@_) );
}

1;