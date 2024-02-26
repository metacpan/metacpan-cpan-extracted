package RDF::Cowl::Ulib::UString;
# ABSTRACT: [Internal] A counted String
$RDF::Cowl::Ulib::UString::VERSION = '1.0.0';
# UString
# See also: CowlString
use strict;
use warnings;
use namespace::autoclean;
use RDF::Cowl::Lib qw(arg);
use Class::Method::Modifiers qw(around);
use FFI::Platypus::Record;
use FFI::Platypus::Memory qw( strdup strcpy );

my $ffi = RDF::Cowl::Lib->ffi;

# UString
record_layout_1($ffi,
	'ulib_uint' => '_size',
	'opaque'    => '_data',
);
$ffi->type('record(RDF::Cowl::Ulib::UString)', 'UString');

around new => sub {
	my ($orig, $class, $arg) = @_;
	return RDF::Cowl::Ulib::UString::copy_buf($arg);
};

require RDF::Cowl::Lib::Gen::Class::UString unless $RDF::Cowl::no_gen;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::Ulib::UString - [Internal] A counted String

=head1 VERSION

version 1.0.0

=head1 GENERATED DOCUMENTATION

See more documentation at:

L<RDF::Cowl::Lib::Gen::Class::UString>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
