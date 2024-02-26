package RDF::Cowl::Object;
# ABSTRACT: The root pseudo-class
$RDF::Cowl::Object::VERSION = '1.0.0';
# CowlObject
use strict;
use warnings;
use feature qw(state);
use RDF::Cowl::Lib qw(arg);

use constant LOG_RELEASE => $ENV{RDF_COWL_DEVEL_LOG_RELEASE};

our %_INSIDE_OUT;

my $ffi = RDF::Cowl::Lib->ffi;

# cowl_retain
$ffi->attach( [ "cowl_retain" => "retain" ] =>
	[
		arg "opaque" => "object",
	],
	=> "CowlAny"
	=> sub {
		my $RETVAL;
		my $xs    = shift;
		my ($object) = @_;
		my $obj_class = ref $object;
		my $object_opaque = $ffi->cast( "object($obj_class)" => 'opaque', $object );
		$RETVAL = $ffi->cast( 'CowlAny', "object($obj_class)", $xs->($object_opaque) );
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained}++;
		return $RETVAL;
	}
);

sub DESTROY {
	defined $_[0]
		&& exists $RDF::Cowl::Object::_INSIDE_OUT{ ${$_[0]} }{retained}
		&& $RDF::Cowl::Object::_INSIDE_OUT{ ${$_[0]} }{retained}-- > 0
		&& do {
			print STDERR "Releasing $_[0] : @{[ ref $_[0] ]} @ @{[ ${$_[0]} ]}\n" if LOG_RELEASE;
			$_[0]->release;
			delete $RDF::Cowl::Object::_INSIDE_OUT{ ${$_[0]} }
				if $RDF::Cowl::Object::_INSIDE_OUT{ ${$_[0]} }{retained} == 0;
		};
}

sub _REBLESS {
	# cowl_get_type
	state $cowl_get_type = $ffi->function(
		"cowl_get_type" => [ 'CowlAny' ] => 'CowlObjectType'
	);

	my $object = shift;
	my $ot = $cowl_get_type->( $object );

	return bless $object, $RDF::Cowl::ObjectType::_ENUM_TYPES->[ $ot ];
}

require RDF::Cowl::Lib::Gen::Class::Object unless $RDF::Cowl::no_gen;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::Object - The root pseudo-class

=head1 VERSION

version 1.0.0

=head1 GENERATED DOCUMENTATION

See more documentation at:

L<RDF::Cowl::Lib::Gen::Class::Object>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
