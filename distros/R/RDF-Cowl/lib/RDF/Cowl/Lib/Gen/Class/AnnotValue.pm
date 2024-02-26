package RDF::Cowl::Lib::Gen::Class::AnnotValue;
# ABSTRACT: Private class for RDF::Cowl::AnnotValue
$RDF::Cowl::Lib::Gen::Class::AnnotValue::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::AnnotValue;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# cowl_annot_value_get_type
$ffi->attach( [
 "COWL_WRAP_cowl_annot_value_get_type"
 => "get_type" ] =>
	[
		arg "CowlAnyAnnotValue" => "value",
	],
	=> "CowlAnnotValueType"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlAnyAnnotValue, { name => "value", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::Lib::Gen::Class::AnnotValue - Private class for RDF::Cowl::AnnotValue

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
