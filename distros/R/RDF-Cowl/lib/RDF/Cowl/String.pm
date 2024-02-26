package RDF::Cowl::String;
# ABSTRACT: The string type
$RDF::Cowl::String::VERSION = '1.0.0';
# CowlString
use strict;
use warnings;
use parent 'RDF::Cowl::Object';
use RDF::Cowl::Lib qw(arg);

my $ffi = RDF::Cowl::Lib->ffi;

use overload '""' => 'STRINGIFY';

sub STRINGIFY {
	my ($self) = @_;
	$self->get_cstring;
}

# cowl_string_get_cstring
$ffi->attach( [ "cowl_string_get_cstring" => "get_cstring" ] =>
	[
		arg "CowlString" => "string",
	],
	=> "opaque"
	=> sub {
		my $RETVAL;
		my $xs    = shift;
		$RETVAL = $xs->(@_);

		# TODO maybe use window() instead
		# This copies the string to Perl
		my $RETVAL_str = $ffi->cast( 'opaque' => 'string', $RETVAL );

		return $RETVAL_str;
	}
);

require RDF::Cowl::Lib::Gen::Class::String unless $RDF::Cowl::no_gen;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::String - The string type

=head1 VERSION

version 1.0.0

=head1 GENERATED DOCUMENTATION

See more documentation at:

L<RDF::Cowl::Lib::Gen::Class::String>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
