package RDF::Cowl::Lib::Gen::Class::Annotation;
# ABSTRACT: Private class for RDF::Cowl::Annotation
$RDF::Cowl::Lib::Gen::Class::Annotation::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::Annotation;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# cowl_annotation
$ffi->attach( [
 "COWL_WRAP_cowl_annotation"
 => "new" ] =>
	[
		arg "CowlAnnotProp" => "prop",
		arg "CowlAnyAnnotValue" => "value",
		arg "opaque" => "annot",
	],
	=> "CowlAnnotation"
	=> sub {
		my $RETVAL;
		my $xs    = shift;
		my $class = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlAnnotProp, { name => "prop", },
				CowlAnyAnnotValue, { name => "value", },
				Maybe[ CowlVector ], { name => "annot", default => undef, },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::Annotation::new: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_annotation_get_prop
$ffi->attach( [
 "COWL_WRAP_cowl_annotation_get_prop"
 => "get_prop" ] =>
	[
		arg "CowlAnnotation" => "annot",
	],
	=> "CowlAnnotProp"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlAnnotation, { name => "annot", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_annotation_get_value
$ffi->attach( [
 "COWL_WRAP_cowl_annotation_get_value"
 => "get_value" ] =>
	[
		arg "CowlAnnotation" => "annot",
	],
	=> "CowlAnnotValue"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlAnnotation, { name => "annot", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_annotation_get_annot
$ffi->attach( [
 "COWL_WRAP_cowl_annotation_get_annot"
 => "get_annot" ] =>
	[
		arg "CowlAnnotation" => "annot",
	],
	=> "CowlVector"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlAnnotation, { name => "annot", },
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

RDF::Cowl::Lib::Gen::Class::Annotation - Private class for RDF::Cowl::Annotation

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
