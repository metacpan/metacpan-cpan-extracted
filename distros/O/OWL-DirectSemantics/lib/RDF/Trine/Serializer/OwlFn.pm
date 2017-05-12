package RDF::Trine::Serializer::OwlFn;

BEGIN {
	$RDF::Trine::Serializer::OwlFn::AUTHORITY = 'cpan:TOBYINK';
	$RDF::Trine::Serializer::OwlFn::VERSION   = '0.001';
};

use 5.008;
use strict;

use RDF::Trine;
use base qw[RDF::Trine::Serializer];
use OWL::DirectSemantics;

BEGIN
{
	$RDF::Trine::Serializer::serializer_names{$_} = __PACKAGE__
		foreach qw[ofn owlfn owlfunctional];
	
	$RDF::Trine::Serializer::format_uris{'http://www.w3.org/ns/formats/OWL_Functional'} = __PACKAGE__;
	
	$RDF::Trine::Serializer::media_types{'text/owl-functional'} = __PACKAGE__;
}

sub new
{
	my ($class, %args) = @_;
	return bless \%args, $class;
}

sub serialize_model_to_file
{
	my ($self, $fh, $model) = @_;
	
	my $tmp = RDF::Trine::Model->temporary_model;
	$model->as_stream->each(sub { $tmp->add_statement($_[0]) });
	
	my $translator = OWL::DirectSemantics->new;
	my $ontology   = $translator->translate($tmp);
	
	print $fh $ontology->fs;
}

1;

=head1 NAME

RDF::Trine::Serializer::OwlFn - OWL Functional Syntax Serializer

=head1 SYNOPSIS

	use RDF::Trine;
	my $ser = RDF::Trine::Serializer->new('owlfn');
	print $ser->serialize_model_to_string($model);

=head1 DESCRIPTION

=head2 Methods

This class inherits methods from the L<RDF::Trine::Serializer> class.

=head1 SEE ALSO

L<RDF::Closure>, L<RDF::Trine::Parser::OwlFn>.

L<http://www.perlrdf.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2011-2012 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

