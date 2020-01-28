use v5.12;
use strict;
use warnings;
use Benchmark qw( cmpthese );

package Implementation::SMM {
	use Moo;
	use Sub::MultiMethod qw(multimethod);
	use Types::Standard -types;
	
	multimethod stringify => (
		signature => [ Undef ],
		code      => sub {
			my ($self, $undef) = (shift, @_);
			'null';
		},
	);
	
	multimethod stringify => (
		signature => [ ScalarRef[Bool] ],
		code      => sub {
			my ($self, $bool) = (shift, @_);
			$$bool ? 'true' : 'false';
		},
	);
	
	multimethod stringify => (
		alias     => "stringify_str",
		signature => [ Str ],
		code      => sub {
			my ($self, $str) = (shift, @_);
			sprintf(q<"%s">, quotemeta($str));
		},
	);
	
	multimethod stringify => (
		signature => [ Num ],
		code      => sub {
			my ($self, $n) = (shift, @_);
			$n;
		},
	);
	
	multimethod stringify => (
		signature => [ ArrayRef ],
		code      => sub {
			my ($self, $arr) = (shift, @_);
			sprintf(
				q<[%s]>,
				join(q<,>, map($self->stringify($_), @$arr))
			);
		},
	);
	
	multimethod stringify => (
		signature => [ HashRef ],
		code      => sub {
			my ($self, $hash) = (shift, @_);
			sprintf(
				q<{%s}>,
				join(
					q<,>,
					map sprintf(
						q<%s:%s>,
						$self->stringify_str($_),
						$self->stringify($hash->{$_})
					), sort keys %$hash,
				)
			);
		},
	);
}


package Implementation::Kavorka {
	use Moo;
	use Kavorka qw(multi method);
	use Types::Standard -types;
	
	multi method stringify (Undef $undef) {
		'null';
	}
	
	multi method stringify (ScalarRef[Bool] $bool) {
		$$bool ? 'true' : 'false';
	}
	
	# Need to hoist this above Str
	multi method stringify (Num $n) {
		$n;
	}
	
	multi method stringify (Str $str) :long(stringify_str) {
		sprintf(q<"%s">, quotemeta($str));
	}
	
	multi method stringify (ArrayRef $arr) {
		sprintf(
			q<[%s]>,
			join(q<,>, map($self->stringify($_), @$arr))
		);
	}
	
	multi method stringify (HashRef $hash) {
		sprintf(
			q<{%s}>,
			join(
				q<,>,
				map sprintf(
					q<%s:%s>,
					$self->stringify_str($_),
					$self->stringify($hash->{$_})
				), sort keys %$hash,
			)
		);
	}
}

{
	package Dummy;
	use Dios;
	
	class Implementation::Dios {
		multi method stringify (undef) {
			'null';
		}
		
		multi method stringify (Scalar $bool) {
			$$bool ? 'true' : 'false';
		}
		
		multi method stringify (Str $str) {
			sprintf(q<"%s">, quotemeta($str));
		}
		
		method stringify_str (Str $str) {
			sprintf(q<"%s">, quotemeta($str));
		}
		
		multi method stringify (Num $n) {
			$n;
		}		
		
		multi method stringify (Array $arr) {
			sprintf(
				q<[%s]>,
				join(q<,>, map($self->stringify($_), @$arr))
			);
		}
		
		multi method stringify (Hash $hash) {
			sprintf(
				q<{%s}>,
				join(
					q<,>,
					map sprintf(
						q<%s:%s>,
						$self->stringify_str($_),
						$self->stringify($hash->{$_})
					), sort keys %$hash,
				)
			);
		}
	}
}

our %INPUT = (
	foo => 123,
	bar => [1,2,3],
	baz => \1,
	quux => { xyzzy => 666 },
);

our $SMM = Implementation::SMM->new;
our $KAV = Implementation::Kavorka->new;
our $DIO = Implementation::Dios->new;

say "SMM output:";
say $SMM->stringify( \%INPUT );

say "KAV output:";
say $KAV->stringify( \%INPUT );

say "DIO output:";
say $DIO->stringify( \%INPUT );

cmpthese -3, {
	SMM  => q{ $::SMM->stringify(\%::INPUT) },
	KAV  => q{ $::KAV->stringify(\%::INPUT) },
	DIO  => q{ $::DIO->stringify(\%::INPUT) },
};

__END__
      Rate  DIO  SMM  KAV
DIO  161/s   -- -79% -89%
SMM  755/s 370%   -- -48%
KAV 1444/s 799%  91%   --
