package Module::Install::Admin::RDF;

use 5.008;
use base qw(Module::Install::Base);
use strict;

use Object::ID;
use RDF::Trine qw[];
use URI::file qw[];

our $VERSION = '0.009';

my $Model = {};

sub rdf_metadata
{
	my ($self) = @_;
	
	my $addr = object_id($self->_top);
	return $Model->{$addr} if defined $Model->{$addr};
	my $model = $Model->{$addr} = RDF::Trine::Model->new;
	
	my $parser;
	
	while (<meta/*.{ttl,turtle,nt}>)
	{
		my $iri = URI::file->new_abs($_);
		$parser ||= RDF::Trine::Parser->new('Turtle');
		$parser->parse_file_into_model("$iri", $_, $model);
	}
	
	$parser = undef;
	
	while (<meta/*.{rdf,rdfxml,rdfx}>)
	{
		my $iri = URI::file->new_abs($_);
		$parser ||= RDF::Trine::Parser->new('RDFXML');
		$parser->parse_file_into_model("$iri", $_, $model);
	}
	
	$parser = undef;
	
	while (<meta/*.{pret,pretdsl}>)
	{
		my $iri = URI::file->new_abs($_);
		require RDF::TrineX::Parser::Pretdsl;
		$parser ||= RDF::TrineX::Parser::Pretdsl->new;
		$parser->parse_file_into_model("$iri", $_, $model);
	}
	
	return $model;
}

sub rdf_project_uri
{
	my ($self) = @_;
	my $model = $self->rdf_metadata;
	
	my @candidates = $model->subjects(
		RDF::Trine::iri('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
		RDF::Trine::iri('http://usefulinc.com/ns/doap#Project'),
		);
	return $candidates[0] if scalar @candidates == 1;
	
	my %counts = map {
		$_ => $model->count_statements($_, undef, undef);
		} @candidates;
	my @best = sort { $counts{$b} <=> $counts{$a} } @candidates;
	return $best[0] if @best;
	
	return undef;
}

sub write_meta_ttl
{
	no warnings;
	
	my ($self, $file) = @_;
	
	my %NS = qw(
		rdf	http://www.w3.org/1999/02/22-rdf-syntax-ns#
		rdfs	http://www.w3.org/2000/01/rdf-schema#
		foaf	http://xmlns.com/foaf/0.1/
		doap	http://usefulinc.com/ns/doap#
		cpan	http://purl.org/NET/cpan-uri/person/
		dcs	http://ontologi.es/doap-changeset#
		bugs	http://ontologi.es/doap-bugs#
		deps	http://ontologi.es/doap-deps#
		cpant	http://purl.org/NET/cpan-uri/terms#
	);
	
	my $prj = $self->rdf_project_uri;
	$NS{dist} = $1 if defined $prj && $prj->uri =~ m{^(http://purl\.org/NET/cpan-uri/dist/.+/)project};
	
	my $ser = eval {
		require RDF::TrineX::Serializer::MockTurtleSoup;
		"RDF::TrineX::Serializer::MockTurtleSoup"->new(
			abbreviate      => qr{/NET/cpan-uri/},
			colspace        => 17,
			indent          => "\t",
			labelling       => [
				"$NS{rdfs}label",
				"$NS{foaf}name",
				"$NS{doap}name",
			],
			namespaces      => \%NS,
			priorities      => sub {
				my ($ser, $n, $m) = @_;
				return 100 if $m->count_statements(
					$n,
					RDF::Trine::iri("$NS{rdf}type"),
					RDF::Trine::iri("$NS{doap}Project"),
				);
				return 80 if $m->count_statements(
					$n,
					RDF::Trine::iri("$NS{rdf}type"),
					RDF::Trine::iri("$NS{doap}Version"),
				);
				return 60 if $m->count_statements(
					$n,
					RDF::Trine::iri("$NS{rdf}type"),
					RDF::Trine::iri("$NS{foaf}Person"),
				);
				return 40 if $m->count_statements(
					$n,
					RDF::Trine::iri("$NS{foaf}name"),
					undef,
				);
				return 0;
			},
			repeats         => 1,
		);
	} || do {
		"RDF::Trine::Serializer::Turtle"->new(
			namespaces      => \%NS,
		);
	};
	
	open my $out, ">", $file or die "Could not open '$file': $!";
	$ser->serialize_model_to_file($out, $self->rdf_metadata);
}

1;

__END__
=head1 NAME

Module::Install::Admin::RDF - internals for Module::Install::RDF

=head1 DESCRIPTION

Code that only runs on the module author's machine.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<Module::Install::RDF>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2013 by Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut
