package RDF::Cowl::Manager;
# ABSTRACT: Manages ontology documents
$RDF::Cowl::Manager::VERSION = '1.0.0';
# CowlManager
use strict;
use warnings;
use parent 'RDF::Cowl::Object';
use RDF::Cowl::Lib qw(arg);

my $ffi = RDF::Cowl::Lib->ffi;

$ffi->attach( [ "cowl_manager_write_file" => "write_FILE" ] =>
	[
		arg "CowlManager" => "manager",
		arg "CowlOntology" => "ontology",
		arg "FILE" => "file",
	],
	=> "cowl_ret"
);

$ffi->attach( [ "cowl_manager_read_file" => "read_FILE" ] =>
	[
		arg "CowlManager" => "manager",
		arg "FILE" => "file",
	],
	=> "CowlOntology"
);

require RDF::Cowl::Lib::Gen::Class::Manager unless $RDF::Cowl::no_gen;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::Manager - Manages ontology documents

=head1 VERSION

version 1.0.0

=head1 GENERATED DOCUMENTATION

See more documentation at:

L<RDF::Cowl::Lib::Gen::Class::Manager>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
