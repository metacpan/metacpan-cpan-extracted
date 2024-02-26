package RDF::Cowl::PrimitiveFlags;
# ABSTRACT: These flags are used to control iteration over primitives
$RDF::Cowl::PrimitiveFlags::VERSION = '1.0.0';
# CowlPrimitiveFlags
use strict;
use warnings;
use namespace::autoclean;
use RDF::Cowl::Lib qw(arg);

my $ffi = RDF::Cowl::Lib->ffi;
## #define COWL_PF 8
$ffi->type('uint8_t', 'CowlPrimitiveFlags');

use Const::Exporter
flags => [
	CLASS      => 1<<0,
	OBJ_PROP   => 1<<1,
	DATA_PROP  => 1<<2,
	ANNOT_PROP => 1<<3,
	NAMED_IND  => 1<<4,
	ANON_IND   => 1<<5,
	DATATYPE   => 1<<6,
	IRI        => 1<<7,
];

use Const::Exporter
aggregate => [
	NONE => 0,
	ALL  => 0xFF,

	ENTITY =>
		(CLASS | OBJ_PROP | DATA_PROP | ANNOT_PROP |
			NAMED_IND | DATATYPE)
];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::PrimitiveFlags - These flags are used to control iteration over primitives

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
