use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::Toolkit::Mite;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.050005';

use Sub::HandlesVia::Mite -all;
extends 'Sub::HandlesVia::Toolkit';

use Types::Standard -types, -is;

sub setup_for {
	my $me = shift;
	my ($target) = @_;
	$me->install_has_wrapper($target);
}

my %SPECS;
sub install_has_wrapper {
	my $me = shift;
	my ($target) = @_;
	
	no strict 'refs';
	no warnings 'redefine';
	
	my $orig         = \&{ "$target\::has" };
	my $uses_mite    = ${ "$target\::USES_MITE" };
	my $mite_shim    = ${ "$target\::MITE_SHIM" };

	*{ "$target\::has" } = sub {
		my ( $names, %spec ) = @_;
		return $orig->($names, %spec) unless $spec{handles}; # shortcut
		
		my @shv;
		for my $name ( ref($names) ? @$names : $names) {
			( my $real_name = $name ) =~ s/^[+]//;
			my $shv = $me->clean_spec( $target, $real_name, \%spec );
			$SPECS{$target}{$real_name} = \%spec;
			$orig->( $name, %spec );
			push @shv, $shv if $shv;
		}
		
		if ( $ENV{MITE_COMPILE}
		or defined($Mite::COMPILING) && ( $Mite::COMPILING eq $mite_shim  )) {
			return;
		}
		
		if ( $uses_mite eq 'Mite::Role' ) {
			require Role::Hooks;
			'Role::Hooks'->after_apply( $target, sub {
				my ( $from, $to ) = @_;
				return if 'Role::Hooks'->is_role( $to );
				for my $shv ( @shv ) {
					$me->install_delegations( { %$shv, target => $to } );
				}
			} );
		}
		else {
			for my $shv ( @shv ) {
				$me->install_delegations( $shv );
			}
		}
		
		return;
	};
}

my @method_name_generator = (
	{ # public
		reader      => sub { "get_$_" },
		writer      => sub { "set_$_" },
		accessor    => sub { $_ },
		lvalue      => sub { $_ },
		clearer     => sub { "clear_$_" },
		predicate   => sub { "has_$_" },
		builder     => sub { "_build_$_" },
		trigger     => sub { "_trigger_$_" },
	},
	{ # private
		reader      => sub { "_get_$_" },
		writer      => sub { "_set_$_" },
		accessor    => sub { $_ },
		lvalue      => sub { $_ },
		clearer     => sub { "_clear_$_" },
		predicate   => sub { "_has_$_" },
		builder     => sub { "_build_$_" },
		trigger     => sub { "_trigger_$_" },
	},
);

sub code_generator_for_attribute {
	my ( $me, $target, $attrname ) = ( shift, @_ );
	
	my $name = $attrname->[0];
	my $spec = $SPECS{$target}{$name};
	my $env  = {};
	
	my $private = 0+!! ( $name =~ /^_/ );
	
	$spec->{is} ||= bare;
	if ( $spec->{is} eq lazy ) {
		$spec->{builder} = 1 unless exists $spec->{builder};
		$spec->{is}      = ro;
	}
	if ( $spec->{is} eq ro ) {
		$spec->{reader} = '%s' unless exists $spec->{reader};
	}
	if ( $spec->{is} eq rw ) {
		$spec->{accessor} = '%s' unless exists $spec->{accessor};
	}
	if ( $spec->{is} eq rwp ) {
		$spec->{reader} = '%s' unless exists $spec->{reader};
		$spec->{writer} = '_set_%s' unless exists $spec->{writer};
	}
	
	for my $property ( 'reader', 'writer', 'accessor', 'builder', 'lvalue' ) {
		defined( my $methodname = $spec->{$property} ) or next;
		if ( $methodname eq 1 ) {
			my $gen = $method_name_generator[$private]{$property};
			local $_ = $name;
			$spec->{$property} = $gen->( $_ );
		}
		$spec->{$property} =~ s/\%s/$name/g;
	}
	
	my ( $get, $set, $get_is_lvalue, $set_checks_isa, $default, $slot );
	
	if ( my $reader = $spec->{reader} || $spec->{accessor} || $spec->{lvalue} ) {
		$get = sub { shift->generate_self . "->$reader" };
		$get_is_lvalue = false;
	}
	else {
		$get = sub { shift->generate_self . "->{q[$name]}" };
		$get_is_lvalue = true;
	}
	
	if ( my $writer = $spec->{writer} || $spec->{accessor} ) {
		$set = sub {
			my ( $gen, $expr ) = @_;
			$gen->generate_self . "->$writer($expr)";
		};
		$set_checks_isa = true;
	}
	elsif ( $writer = $spec->{lvalue} ) {
		$set = sub {
			my ( $gen, $expr ) = @_;
			"( " . $gen->generate_self . "->$writer = $expr )";
		};
		$set_checks_isa = false;
	}
	else {
		$set = sub {
			my ( $gen, $expr ) = @_;
			"( " . $gen->generate_self . "->{q[$name]} = $expr )";
		};
		$set_checks_isa = false;
	}
	
	$slot = sub { shift->generate_self . "->{q[$name]}" };
	
	if ( ref $spec->{builder} ) {
		$default = $spec->{builder};
		$env->{'$shv_default_for_reset'} = \$default;
	}
	elsif ( $spec->{builder} ) {
		$default = $spec->{builder};
	}
	elsif ( ref $spec->{default} ) {
		$default = $spec->{default};
		$env->{'$shv_default_for_reset'} = \$default;
	}
	elsif ( exists $spec->{default} ) {
		my $value = $spec->{default};
		$default = sub { $value };
		$env->{'$shv_default_for_reset'} = \$default;
	}
	
	require Sub::HandlesVia::CodeGenerator;
	return 'Sub::HandlesVia::CodeGenerator'->new(
		toolkit               => $me,
		target                => $target,
		attribute             => $name,
		env                   => $env,
		isa                   => $spec->{type},
		coerce                => $spec->{coerce},
		generator_for_get     => $get,
		generator_for_set     => $set,
		get_is_lvalue         => $get_is_lvalue,
		set_checks_isa        => $set_checks_isa,
		set_strictly          => true,
		generator_for_default => sub {
			my ( $gen, $handler ) = @_ or die;
			if ( !$default and $handler ) {
				return $handler->default_for_reset->();
			}
			elsif ( is_CodeRef $default ) {
				return sprintf(
					'(%s)->$shv_default_for_reset',
					$gen->generate_self,
				);
			}
			elsif ( is_Str $default ) {
				require B;
				return sprintf(
					'(%s)->${\ %s }',
					$gen->generate_self,
					B::perlstring( $default ),
				);
			}
			elsif ( is_ScalarRef $default ) {
				return $$default;
			}
			elsif ( is_HashRef $default ) {
				return '{}';
			}
			elsif ( is_ArrayRef $default ) {
				return '[]';
			}
			return;
		},
		( $slot ? ( generator_for_slot => $slot ) : () ),
	);
}

1;

