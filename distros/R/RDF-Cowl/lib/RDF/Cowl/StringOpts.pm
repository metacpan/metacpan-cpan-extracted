package RDF::Cowl::StringOpts;
# ABSTRACT: String creation options
$RDF::Cowl::StringOpts::VERSION = '1.0.0';
# CowlStringOpts
use strict;
use warnings;
use namespace::autoclean;
use RDF::Cowl::Lib qw(arg);

my $ffi = RDF::Cowl::Lib->ffi;
## #define COWL_SO 8
$ffi->type('uint8_t', 'CowlStringOpts');

use Const::Exporter
opts => [
	NONE   => 0,
	COPY   => 1<<0,
	INTERN => 1<<1,
];

use Const::Exporter
aggregate => [
	NONE => 0,
];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::StringOpts - String creation options

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
