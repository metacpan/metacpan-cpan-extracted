package RDF::Cowl::Lib::Gen::Class::Literal;
# ABSTRACT: Private class for RDF::Cowl::Literal
$RDF::Cowl::Lib::Gen::Class::Literal::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::Literal;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# cowl_literal
$ffi->attach( [
 "COWL_WRAP_cowl_literal"
 => "new" ] =>
	[
		arg "opaque" => "dt",
		arg "CowlString" => "value",
		arg "opaque" => "lang",
	],
	=> "CowlLiteral"
	=> sub {
		my $RETVAL;
		my $xs    = shift;
		my $class = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				Maybe[ CowlDatatype ], { name => "dt", },
				CowlString, { name => "value", },
				Maybe[ CowlString ], { name => "lang", default => undef, },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::Literal::new: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_literal_from_string
$ffi->attach( [
 "COWL_WRAP_cowl_literal_from_string"
 => "from_string" ] =>
	[
		arg "opaque" => "dt",
		arg "UString" => "value",
		arg "opaque" => "lang",
	],
	=> "CowlLiteral"
	=> sub {
		my $RETVAL;
		my $xs    = shift;
		my $class = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				Maybe[ UString ], { name => "dt", },
				UString, { name => "value", },
				Maybe[ UString ], { name => "lang", default => undef, },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::Literal::from_string: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_literal_get_datatype
$ffi->attach( [
 "COWL_WRAP_cowl_literal_get_datatype"
 => "get_datatype" ] =>
	[
		arg "CowlLiteral" => "literal",
	],
	=> "CowlDatatype"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlLiteral, { name => "literal", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_literal_get_value
$ffi->attach( [
 "COWL_WRAP_cowl_literal_get_value"
 => "get_value" ] =>
	[
		arg "CowlLiteral" => "literal",
	],
	=> "CowlString"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlLiteral, { name => "literal", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_literal_get_lang
$ffi->attach( [
 "COWL_WRAP_cowl_literal_get_lang"
 => "get_lang" ] =>
	[
		arg "CowlLiteral" => "literal",
	],
	=> "CowlString"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlLiteral, { name => "literal", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::Lib::Gen::Class::Literal - Private class for RDF::Cowl::Literal

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
