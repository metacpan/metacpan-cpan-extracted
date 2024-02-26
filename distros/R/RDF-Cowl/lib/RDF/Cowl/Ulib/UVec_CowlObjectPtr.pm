package RDF::Cowl::Ulib::UVec_CowlObjectPtr;
# ABSTRACT: [Internal] Raw vector
$RDF::Cowl::Ulib::UVec_CowlObjectPtr::VERSION = '1.0.0';
# UVec(CowlObjectPtr)
# See also: CowlVector
use strict;
use warnings;
use namespace::autoclean;
use RDF::Cowl::Lib qw(arg);

my $ffi = RDF::Cowl::Lib->ffi;

# CowlAny
# -> same as CowlObjectPtr
# -> same as CowlObject *

unless( $RDF::Cowl::no_gen ) {
	# uvec_CowlObjectPtr
	$ffi->attach( [
	 "COWL_WRAP_my_uvec_new_on_heap_CowlObjectPtr"
	 => "new" ] =>
		[
		],
		=> "UVec_CowlObjectPtr"
	);
}

require RDF::Cowl::Lib::Gen::Class::UVec_CowlObjectPtr unless $RDF::Cowl::no_gen;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::Ulib::UVec_CowlObjectPtr - [Internal] Raw vector

=head1 VERSION

version 1.0.0

=head1 GENERATED DOCUMENTATION

See more documentation at:

L<RDF::Cowl::Lib::Gen::Class::UVec_CowlObjectPtr>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
