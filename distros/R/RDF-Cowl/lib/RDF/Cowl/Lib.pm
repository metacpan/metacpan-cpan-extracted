package RDF::Cowl::Lib;
# ABSTRACT: Private class for RDF::Cowl
$RDF::Cowl::Lib::VERSION = '1.0.0';
use strict;
use warnings;

use feature qw(state);
use FFI::CheckLib 0.28 qw( find_lib_or_die );
use Alien::Cowl;
use FFI::Platypus;
use FFI::C::File;

use base 'Exporter::Tiny';
our @EXPORT_OK = qw(arg);

sub lib {
	$ENV{RDF_COWL_LIB_DLL}
	// find_lib_or_die(
		lib => 'cowl',
		symbol => ['cowl_get_version_string'],
		alien => ['Alien::Cowl'] );
}

sub ffi {
	state $ffi;
	$ffi ||= do {
		my $ffi = FFI::Platypus->new( api => 2 );
		if( $RDF::Cowl::no_gen ) {
			# Use shared library
			$ffi->lib( __PACKAGE__->lib );
			$ffi->mangler(sub {
				$_[0] =~ s/^COWL_WRAP_//r;
			});
		} else {
			# Use bundle
			$ffi->bundle('RDF::Cowl');
		}

		# Under ULIB_HUGE
		# (default, i.e., not using COWL_EMBEDDED).
		# See <url:sisinflab-swot/cowl/lib/ulib/include/ubase.h>.
		$ffi->type( 'uint64_t' => 'ulib_uint' );

		$ffi->type( 'object(FFI::C::File)' => 'FILE' );

		# enums
		$ffi->type( 'int' => 'uvec_ret' );
		$ffi->type( 'int' => 'uhash_ret' );
		$ffi->type( 'int' => 'ustream_ret' );

		$ffi->type( "object(RDF::Cowl::Ulib::UHash_CowlObjectTable)" => "UHash_CowlObjectTable" );
		$ffi->type( "object(RDF::Cowl::Ulib::UVec_CowlObjectPtr)" => "UVec_CowlObjectPtr" );
		$ffi->type( "object(RDF::Cowl::Object)" => "CowlObjectPtr" );

		# Classes
		$ffi->type( "object(RDF::Cowl::Manager)" => "CowlManager" );
		$ffi->type( "object(RDF::Cowl::Ontology)" => "CowlOntology" );
		$ffi->type( "object(RDF::Cowl::String)" => "CowlString" );

		# CowlAny* pseudo-objects
		$ffi->type( "object(RDF::Cowl::Object)" => "CowlAny" );
		$ffi->type( "object(RDF::Cowl::AnnotValue)" => "CowlAnyAnnotValue" );
		$ffi->type( "object(RDF::Cowl::Axiom)" => "CowlAnyAxiom" );
		$ffi->type( "object(RDF::Cowl::ClsExp)" => "CowlAnyClsExp" );
		$ffi->type( "object(RDF::Cowl::DataPropExp)" => "CowlAnyDataPropExp" );
		$ffi->type( "object(RDF::Cowl::DataRange)" => "CowlAnyDataRange" );
		$ffi->type( "object(RDF::Cowl::Entity)" => "CowlAnyEntity" );
		$ffi->type( "object(RDF::Cowl::Individual)" => "CowlAnyIndividual" );
		$ffi->type( "object(RDF::Cowl::Primitive)" => "CowlAnyPrimitive" );
		$ffi->type( "object(RDF::Cowl::ObjPropExp)" => "CowlAnyObjPropExp" );

		# TODO
		$ffi->type( 'opaque' => 'UIStream' );
		$ffi->type( 'opaque' => 'UStrBuf' );


		$ffi;
	};
}

sub mangler_default {
	my $target = (caller)[0];
	my $prefix = 'cowl';
	sub {
		my ($name) = @_;
		"${prefix}_$name";
	}
}

sub arg(@) {
	my $arg = RDF::Cowl::Lib::_Arg->new(
		type => shift,
		id => shift,
	);
	return $arg, @_;
}

require RDF::Cowl::Lib::Gen::Types unless $RDF::Cowl::no_gen;

package # hide from PAUSE
  RDF::Cowl::Lib::_Arg {

use Class::Tiny qw(type id);

use overload
	q{""} => 'stringify',
	eq => 'op_eq';

sub stringify { $_[0]->type }

sub op_eq {
	my ($self, $other, $swap) = @_;
	"$self" eq "$other";
}

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::Lib - Private class for RDF::Cowl

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
