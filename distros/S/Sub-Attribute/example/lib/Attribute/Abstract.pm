package Attribute::Abstract;

use warnings;
use strict;

use Sub::Attribute;
use Carp ();

sub Abstract :ATTR_SUB{
	my($class, $sym, $code_ref) = @_;

	if(!ref $sym){
		Carp::croak('attempt to apply the Abstract attribute to anonymous subroutines');
	}
	if(defined &{$code_ref}){
		Carp::croak('attempt to apply the Abstract attribute to non-abstract methods');
	} 

	*{$sym} = sub{
		my $name = *{$sym}{PACKAGE} . '::' . *{$sym}{NAME};
		Carp::croak(qq{Cannot call abstract method "$name"});
	}
}

1;
__END__
