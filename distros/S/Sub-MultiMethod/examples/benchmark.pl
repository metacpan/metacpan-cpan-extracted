use v5.22;
use strict;
use warnings;
use Benchmark qw( cmpthese );

package Implementation::SMM {
	use Moo;
	use Sub::MultiMethod qw(multimethod);
	use Types::Standard -types;
	
	multimethod stringify => (
		positional => [ Undef ],
		code       => sub {
			my ($self, $undef) = (shift, @_);
			'null';
		},
	);
	
	multimethod stringify => (
		positional => [ ScalarRef[Bool] ],
		code       => sub {
			my ($self, $bool) = (shift, @_);
			$$bool ? 'true' : 'false';
		},
	);
	
	multimethod stringify => (
		alias      => "stringify_str",
		positional => [ Str ],
		code       => sub {
			my ($self, $str) = (shift, @_);
			sprintf(q<"%s">, quotemeta($str));
		},
	);
	
	multimethod stringify => (
		positional => [ Num ],
		code       => sub {
			my ($self, $n) = (shift, @_);
			$n;
		},
	);
	
	multimethod stringify => (
		positional => [ ArrayRef ],
		code       => sub {
			my ($self, $arr) = (shift, @_);
			sprintf(
				q<[%s]>,
				join(q<,>, map($self->stringify($_), @$arr))
			);
		},
	);
	
	multimethod stringify => (
		positional => [ HashRef ],
		code       => sub {
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

package Implementation::MD {
	use Moo;
	use Multi::Dispatch;
	use Types::Standard -types;
	
	multimethod stringify (Undef $undef) {
		'null';
	}
	
	multimethod stringify (ScalarRef[Bool] $bool) {
		$$bool ? 'true' : 'false';
	}
	
	multimethod stringify (Str $str) {
		sprintf(q<"%s">, quotemeta($str));
	}
	
	multimethod stringify (Num $n) {
		$n;
	}
	
	multimethod stringify (ArrayRef $arr) {
		sprintf(
			q<[%s]>,
			join(q<,>, map($self->stringify($_), @$arr))
		);
	}
	
	multimethod stringify (HashRef $hash) {
		sprintf(
			q<{%s}>,
			join(
				q<,>,
				map sprintf(
					q<%s:%s>,
					$self->stringify($_),
					$self->stringify($hash->{$_})
				), sort keys %$hash,
			)
		);
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
our $MD  = Implementation::MD->new;

say "SMM output:";
say $SMM->stringify( \%INPUT );

say "KAV output:";
say $KAV->stringify( \%INPUT );

say "DIO output:";
say $DIO->stringify( \%INPUT );

say "MD output:";
say $MD->stringify( \%INPUT );

cmpthese -3, {
	SMM  => q{ $::SMM->stringify(\%::INPUT) },
	KAV  => q{ $::KAV->stringify(\%::INPUT) },
	DIO  => q{ $::DIO->stringify(\%::INPUT) },
	MD   => q{ $::MD ->stringify(\%::INPUT) },
};

__END__
       Rate   DIO   KAV   SMM    MD
DIO   372/s    --  -88%  -93%  -98%
KAV  3197/s  759%    --  -38%  -84%
SMM  5140/s 1280%   61%    --  -75%
MD  20189/s 5322%  531%  293%    --