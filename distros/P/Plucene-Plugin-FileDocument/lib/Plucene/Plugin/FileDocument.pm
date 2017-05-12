package Plucene::Plugin::FileDocument;

our $VERSION = '1.01';

use strict;
use warnings;

=head1 NAME

Plucene::Plugin::FileDocument - turn a file into a document

=head1 SYNOPSIS

  my $writer = Plucene::Index::Writer->new(...);
  $writer->add_document(Plucene::Plugin::FileDocument->new($filename));

=head1 DESCRIPTION

This is a Plucene::Document subclass for indexing an entire file on disk.

=head1 CONSTRUCTOR

=head2 new

  $writer->add_document(Plucene::Plugin::FileDocument->new($filename));

This loads the file with the given name, and turns it into a
Plucene::Document.

By default two Text fields will be created: 'path', which is the full
name of the file, and 'text' which is the content of the file.

Extra fields can can be added by passing a hash of { fieldname => subref }
pairs to the constructor:

  $writer->add_document(Plucene::Plugin::FileDocument->new($filename, 
    lastmod => sub { (stat(+shift->{path}))[9] },
  );

These subrefs will be passed a hashref of the 'path' and 'text'.

=head1 CUSTOMISATION

=head2 document_class / field_class

By default we assume you are using Plucene::Document and
Plucene::Document::Field. If you are using subclasses of these instead,
then you should override these methods accordingly.

=cut

use File::Slurp 'read_file';

use Plucene::Document;
use Plucene::Document::Field;

sub new {
  my ($self, $file, %args) = @_;
  my $doc = $self->document_class->new;
  my $field_class = $self->field_class;
  my $hash = {
    path => $file,
    text => scalar read_file($file),
  };
  while (my ($field, $subref) = each %args) { 
    $hash->{$field} = $subref->($hash);
  }
  while (my ($key, $val) = each %$hash) { 
    $doc->add($field_class->Text($key => $val));
  }
  return $doc;
}

sub document_class { "Plucene::Document" } 
sub field_class    { "Plucene::Document::Field" } 

=head1 AUTHOR

Tony Bowden, based on example code from the Lucene benchmark suite.

=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
  bug-Plucene-Plugin-FileDocument@rt.cpan.org

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2004-2005 Kasei

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License; either version
  2 of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

1;

