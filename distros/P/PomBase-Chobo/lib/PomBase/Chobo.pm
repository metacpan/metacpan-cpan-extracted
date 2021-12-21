package PomBase::Chobo;

=head1 NAME

PomBase::Chobo - Read an OBO file and store in a Chado database

=cut

=head1 SYNOPSIS

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PomBase::Chobo


You can also look for information at:

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Kim Rutherford.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

our $VERSION = '0.035'; # VERSION

use 5.020;

use Mouse;
use Text::CSV;

use PomBase::Chobo::ParseOBO;
use PomBase::Chobo::ChadoData;
use PomBase::Chobo::OntologyData;


has dbh => (is => 'ro');
has ontology_data => (is => 'ro', required => 1);
has parser => (is => 'ro', init_arg => undef, lazy_build => 1);

with 'PomBase::Chobo::Role::ChadoStore';

sub _build_parser
{
  my $self = shift;

  return PomBase::Chobo::ParseOBO->new();
}

sub read_obo
{
  my $self = shift;
  my %args = @_;

  my $filename = $args{filename};

  my $ontology_data = $self->ontology_data();
  my $parser = $self->parser();

  $parser->parse(filename => $filename, ontology_data => $ontology_data);
}

# sub chado_store() - from PomBase::Chobo::ChadoStore

1;
