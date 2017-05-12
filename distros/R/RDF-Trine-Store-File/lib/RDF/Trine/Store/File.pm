package RDF::Trine::Store::File;

use 5.006;
use strict;
use warnings;
use base qw(RDF::Trine::Store);
use RDF::Trine::Error qw(:try);
use RDF::Trine::Serializer::NTriples;
use RDF::Trine::Parser;
use File::Data;
use File::Util;
use Scalar::Util qw(blessed);
use File::Temp qw/tempfile/;
use Carp qw/croak/;
use Log::Log4perl;
use Digest::MD5 ('md5_hex');


=head1 NAME

RDF::Trine::Store::File - Using a file with N-Triples as triplestore

=head1 VERSION

Version 0.1

=cut

our $VERSION = '0.1';


=head1 SYNOPSIS

To be used as a normal triple store.

  my $store = RDF::Trine::Store::File->new($filename);
  $store->add_statement(RDF::Trine::Statement->new(
						   RDF::Trine::Node::Resource->new('http://example.org/a'),
						   RDF::Trine::Node::Resource->new('http://example.org/b'),
						   RDF::Trine::Node::Resource->new('http://example.org/c')
						  ));
  ...

=head1 METHODS

=head2 new($filename)

A constructor, takes a filename as parameter. If the file doesn't
exist, it will be created.

=cut

sub new {
  my $class = shift;
  my $file  = shift;
  my($fu) = File::Util->new();
  unless (-e $file) {
    $fu->touch($file);
  }
  my $self  = bless(
		    {
		     file => $file,
		     fu	  => $fu,
		     nser => RDF::Trine::Serializer::NTriples->new,
		     log  => Log::Log4perl->get_logger("rdf.trine.store.file")
		    }, $class);
  return $self;
}

=head2 new_with_string('File;'.$filename)

A constructor, takes a string config as parameter. If the file doesn't
exist, it will be created. The string will typically begin with C<File;>, e.g.

  my $store = RDF::Trine::Store::File->new_with_string('File;/path/to/file.nt');

=cut

sub _new_with_string {
  my ($class, $filename) = @_;
  return $class->new($filename);
}

=head2 new_with_config({ storetype => 'File', file => $filename});

A constructor, takes a hashref config as parameter. If the file doesn't
exist, it will be created. It needs to have a C<storetype> key with C<File> as the value, e.g.

  my $store = RDF::Trine::Store::File->new_with_config({ storetype => 'File', file => $filename});


=cut

sub _new_with_config {
  my $class = shift;
  my $config = shift;
  return $class->new($config->{file});
}

=head2 temporary_store

Constructor that creates a temporary file to work on.

=cut

sub temporary_store {
  my $class = shift;
  my ($fh, $filename) = tempfile(EXLOCK => 0);
  return $class->new($filename);
}


=head2 add_statement($statement)

Adds the specified C<$statement> to the underlying model.

=cut

sub add_statement {
  my ($self, $st) = @_;
  unless (blessed($st) and $st->isa('RDF::Trine::Statement')) {
    throw RDF::Trine::Error::MethodInvocationError -text => "Not a valid statement object passed to add_statement";
  }
  my $mm = RDF::Trine::Model->temporary_model;
  $mm->add_statement($st);
  $self->{log}->debug("Attempting addition of statement");
  my $fd = File::Data->new($self->{file});
  $fd->append($self->{nser}->serialize_model_to_string($mm));
  return;
}

=head2 get_statements($subject, $predicate, $object)

Returns a stream object of all statements matching the specified subject,
predicate and objects. Any of the arguments may be undef to match any value.

=cut

sub get_statements {
  my $self = shift;
  my @lines = $self->_search_statements(@_);
  my $parser = RDF::Trine::Parser->new( 'ntriples' );  
  my $mm = RDF::Trine::Model->temporary_model;
  $parser->parse_into_model( '', join('', @lines), $mm );
  return $mm->get_statements(undef, undef, undef, undef);
}

=head2 count_statements($subject, $predicate, $object)

Returns a count of all the statements matching the specified subject,
predicate and objects. Any of the arguments may be undef to match any value.

=cut

sub count_statements {
  my $self = shift;
  my @lines = $self->_search_statements(@_);
  return scalar @lines;
}

# Private method to actually search for statements based on a regexp.

sub _search_statements {
  my $self = shift;
  my $regexp = $self->_search_regexp(@_);
  my $fd = File::Data->new($self->{file});
  $self->{log}->debug("Searching with regexp $regexp");
  return $fd->SEARCH($regexp);
}



=head2 remove_statement($statement)

Removes the specified C<$statement> from the underlying model.

=cut

sub remove_statement {
  my ($self, $st) = @_;
  unless (blessed($st) and $st->isa('RDF::Trine::Statement')) {
    throw RDF::Trine::Error::MethodInvocationError -text => "Not a valid statement object passed to remove_statement";
  }
  my $mm = RDF::Trine::Model->temporary_model;
  $mm->add_statement($st);
  $self->{log}->debug("Attempting removal of statement");
  my $fd = File::Data->new($self->{file});
  my $triple = $self->{nser}->serialize_model_to_string($mm);
  $triple =~ s/\^/\\^/g;
  $triple =~ s/\\u/\\\\u/g;
  $fd->REPLACE($triple, '');
  return;
}


=head2 remove_statements($subject, $predicate, $object)

Removes all statement matching the specified subject, predicate and
objects. Any of the arguments may be undef to match any value.

=cut

sub remove_statements {
  my $self = shift;
  my $regexp = $self->_search_regexp(@_);
  my $fd = File::Data->new($self->{file});
  $self->{log}->debug("Removing with regexp $regexp");
  my @lines = $fd->REPLACE($regexp, '');
  $self->{log}->info("Removed " . scalar @lines . " statements.");
  return;
}



=head2 get_contexts

Contexts are not supported for this store.

=cut


sub get_contexts {
  croak "Contexts not supported for the File store";
}

=head2 size

Returns the number of statements in the store. Breaks if there are
comments or empty lines in the file.

=cut

sub size {
  my $self = shift;
  return $self->{fu}->line_count($self->{file});
}

=head2 etag

Returns an etag based on the last modification time of the file. Note:
This has resolution of one second, so it cannot be relied on for data
that changes fast.

=cut

sub etag {
  my $self = shift;
  return md5_hex($self->{fu}->last_modified($self->{file}));
}

=head2 nuke

Permanently removes the store file and its data.

=cut

sub nuke {
  my $self = shift;
  unlink $self->{file};
  return $self;
}

# Private method to create a regexp to be used in all kind of searching

sub _search_regexp {
  my $self = shift;
  my $i = 1;
  my @stmt;
  foreach my $term (@_[0..2]) { # Create an array of RDF terms for later replacing for variables, discard context
    my $outterm = $term || RDF::Trine::Node::Resource->new("urn:rdf-trine-store-file-$i");
    $outterm = RDF::Trine::Node::Resource->new("urn:rdf-trine-store-file-$i") if ($outterm->isa('RDF::Trine::Node::Variable'));
    push(@stmt, $outterm);
    $i++;
  }
  my $mm = RDF::Trine::Model->temporary_model;
  $mm->add_statement(RDF::Trine::Statement->new(@stmt));
  my $triple_resources = $self->{nser}->serialize_model_to_string($mm);
  chomp($triple_resources);
  $triple_resources =~ s/\.\s*$/\\./;
  $triple_resources =~ s/urn:rdf-trine-store-file-(1|2)/.*?/g;
  $triple_resources =~ s/<urn:rdf-trine-store-file-3>/.*/;
  $triple_resources =~ s/\^/\\^/g;
  $triple_resources =~ s/\\u/\\\\u/g;
  my $out = '(' . $triple_resources . '\n)';
  $self->{log}->debug("Search regexp: $out");
  return $out;
}

=head1 DISCUSSION

This module is intended mostly as a simple backend to dump data to a
file and do as little as possible in memory. Thus, it is mostly
suitable in cases where a lot of data is written to file. It should be
possible to use it as a SPARQL store with L<RDF::Query>, but the
performance is likely to be somewhere between terrible and abyssmal,
so don't do that unless you are prepared to be waiting around.

On the good side, adding statements should be pretty fast, as it just
appends to a file. The C<size> method should be pretty fast too, as it
just counts the lines in that file. Finally, it supports the C<etag>
method, not perfectly, but that's still pretty good!

It uses a lot of heuristics tied to the format chosen, i.e.
N-Triples. That's a line-based format, with predictable amounts of
whitespace, allowing us to create relatively simple regular
expressions as search patterns in the file. This is likely to be
somewhat fragile (it is making assumptions about the file that is true
in the L<RDF::Trine::Serializer::Ntriples> case, but not in the
format), but it kinda works.

It is important to note that this module does nothing to prevent you
from adding duplicate statements like other stores should do. This is
because it would dramatically reduce C<add_statement> performance and
thus kill the main use case for this module. Perhaps it could be made
optional at some point, but for now, just be aware that this may not
always return the right counts if two identical statements are
inserted and possibly produce unexpected results if you against the
advice above should attempt to use this a store for SPARQL.


I've decided to use L<File::Data> to actually do the work with the
file. Locking and that kind of stuff is done there and is thus Not My
Problem. If it is yours, then L<File::Data> is probably the right
place to go and fix it.


=head1 TODO

This is beta-quality software but it has a pretty comprehensive test
suite. These are some things that could be done:

=over

=item * Support bulk operations (somewhat less important)

=item * Find a way to do duplicate checking efficiently

=back

=head1 AUTHOR

Kjetil Kjernsmo, C<< <kjetilk at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-rdf-trine-store-file at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RDF-Trine-Store-File>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc RDF::Trine::Store::File

The perlrdf mailing list is the right place to seek help and discuss this module:

L<http://lists.perlrdf.org/listinfo/dev>

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=RDF-Trine-Store-File>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/RDF-Trine-Store-File>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/RDF-Trine-Store-File>

=item * Search CPAN

L<http://search.cpan.org/dist/RDF-Trine-Store-File/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Kjetil Kjernsmo.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of RDF::Trine::Store::File
