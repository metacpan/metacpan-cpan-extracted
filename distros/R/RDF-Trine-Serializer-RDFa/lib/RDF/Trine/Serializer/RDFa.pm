package RDF::Trine::Serializer::RDFa;

use 5.010001;
use strict;
use warnings;
use base qw(RDF::Trine::Serializer);
use RDF::RDFa::Generator;
use RDF::TrineX::Compatibility::Attean;


our $AUTHORITY = 'cpan:KJETILK';
our ($VERSION);
BEGIN {
  $VERSION = '0.100';
  $RDF::Trine::Serializer::serializer_names{ 'rdfa' } = __PACKAGE__;
  $RDF::Trine::Serializer::format_uris{ 'http://www.w3.org/ns/formats/RDFa' } = __PACKAGE__;
  foreach my $type (qw(application/xhtml+xml text/html)) {
	 $RDF::Trine::Serializer::media_types{ $type } = __PACKAGE__;
  }
}


sub new {
  my ($class, %args) = @_;
  my $opts = $args{generator_options};
  delete $args{generator_options};
  my $gen = RDF::RDFa::Generator->new(%args); 
  my $self = bless( { gen => $gen, opts => $opts }, $class);
  return $self;
}

sub serialize_model_to_string {
  my ($self, $model) = @_;
  return $self->{gen}->create_document($model, %{$self->{opts}})->toString;
}

sub serialize_model_to_file {
  my ($self, $fh, $model) = @_;
  print {$fh} $self->{gen}->create_document($model, %{$self->{opts}})->toString;
}

sub serialize_iterator_to_string {
  my ($self, $iter) = @_;
  my $model = RDF::Trine::Model->temporary_model;
  while (my $st = $iter->next) {
	 $model->add_statement($st);
  }
  return $self->serialize_model_to_string($model);
}

sub serialize_iterator_to_file {
  my ($self, $fh, $iter) = @_;
  my $model = RDF::Trine::Model->temporary_model;
  while (my $st = $iter->next) {
	 $model->add_statement($st);
  }
  return $self->serialize_model_to_file($fh, $model);
}


1;

__END__

=pod

=encoding utf-8

=head1 NAME

RDF::Trine::Serializer::RDFa - RDFa Serializer for RDF::Trine

=head1 SYNOPSIS

 use RDF::Trine::Serializer;

 my $s = RDF::Trine::Serializer->new('RDFa', style => 'HTML::Hidden');
 my $string = $s->serialize_model_to_string($model);

=head1 DESCRIPTION

The L<RDF::Trine::Serializer> class provides an API for serializing
RDF graphs to strings and files. This subclass provides RDFa
serialization via L<RDF::RDFa::Generator>.

It is intended that this module will replace the RDF::Trine
compatibility methods in L<RDF::RDFa::Generator>, which are now
deprecated. This is done to allow both L<RDF::Trine> and L<Attean> to
use it, but not require them as dependencies.

=head1 METHODS

Beyond the methods documented below, this class inherits methods from the
L<RDF::Trine::Serializer> class.

=over

=item C<< new >>

Returns a new RDFa serializer object. It can any arguments are passed
on to L<RDF::RDFa::Generator>, see it's documentation for
details. This includes a C<style> argument that names a module that
formats the output. In addition, a C<generator_options> argument may
be passed. This is passed to the generator's C<create_document>
methods as options, and are typically used for style-specific
configuration.

=item C<< serialize_model_to_file ( $fh, $model ) >>

Serializes the C<$model> to RDFa, printing the results to the supplied
filehandle C<<$fh>>.

=item C<< serialize_model_to_string ( $model ) >>

Serializes the C<$model> to RDFa, returning the result as a string.

=item C<< serialize_iterator_to_file ( $file, $iter ) >>

Serializes the iterator to RDFa, printing the results to the supplied
filehandle C<<$fh>>.

=item C<< serialize_iterator_to_string ( $iter ) >>

Serializes the iterator to RDFa, returning the result as a string.

=back

=head1 BUGS

Please report any bugs to
L<https://github.com/kjetilk/p5-rdf-trine-serializer-rdfa/issues>.

=head1 SEE ALSO

L<RDF::RDFa::Generator>, L<RDF::Trine>, L<Attean>

=head1 ACKNOWLEDGEMENTS

This module is mostly a straightforward port with substantial
cutnpaste from L<RDF::RDFa::Generator> and L<RDF::Trine> by Toby
Inkster and Gregory Todd Williams respectively.

=head1 AUTHOR

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2017, 2018 by Kjetil Kjernsmo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

