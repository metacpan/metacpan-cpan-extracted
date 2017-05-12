package SemanticWeb::OAI::ORE::TriX;
#$Id: TriX.pm,v 1.13 2010-12-06 14:44:15 simeon Exp $

=head1 NAME

SemanticWeb::OAI::ORE::TriX - Parse/serialize OAI-ORE Resource Maps in TriX format

=head1 SYNPOSIS

Module to parse and serialize OAI-ORE ReMs in TriX format.

=head1 DESCRIPTION

The TriX format is describe at L<http://www.w3.org/2004/03/trix/>

=cut

use strict;
use warnings;
use Carp;

use SemanticWeb::OAI::ORE::ReM;
use XML::Writer;

=head1 METHODS

=head2 Creator

=head3 new(%args)

=cut

sub new {
  my $class=shift;
  my $self={@_};
  bless $self, (ref($class) || $class);
  return($self);
}

=head2 Output

=head3 serialize()

Seialize in TriX format, returns serializetion as a string.

=cut

sub serialize {
  my $self=shift;
  my $out='';
  my $rem=$self->{rem};
  if (ref($rem) and $rem->isa('SemanticWeb::OAI::ORE::ReM')) {
    # Get the info from the ReM
    my $name=$rem->name();

    # create an XML writer
    my $writer=XML::Writer->new('OUTPUT'=>\$out,'DATA_MODE'=>1,'DATA_INDENT'=>1);
    $writer->startTag('trix',
                      'xmlns'=>'http://www.w3.org/2004/03/trix/trix-1/',
                      'xmlns:ore'=>'http://www.openarchives.org/ORE');
    # http://www.w3.org/2004/03/trix/trix-1/trix-1.0.xsd
    $writer->startTag('graph');

    # write name
    $writer->dataElement('uri',$name);
    
    # write metadata
    $writer->comment('required metadata');
    write_triple($writer,$name,'ore:remTimeStamp',$rem->timestamp_as_iso8601());
    write_triple($writer,$name,'ore:remAuthority',$rem->authority());

    # write aggregated resources
    $writer->comment('aggregated resources');
    foreach my $uri ($rem->aggregated_resources()) {
      write_triple($writer,$name,'ore:aggregates',$uri);
    }
   
    # write relations
    $writer->comment('rels');
    foreach my $rel (@{$rem->rels->as_array()}) {
      write_triple($writer,@$rel);
    }

    $writer->endTag('graph');
    $writer->endTag('trix');
    $writer->end();
  } else {
    carp "Can't serialize something that isn't a rem: $rem, ".ref($rem)."\n";
  }
  return($out);
}

=head2 SUBROUTINES

=head3 write_triple($writer,$subject,$predicate,$object)

Write the ($subject,$predicate,$object) to $writer.

=cut

sub write_triple {
  my ($writer,$subject,$predicate,$object)=@_;
  $writer->startTag('triple');
  # Subject and object may be id, uri, plainLiteral or typedLiteral
  $writer->dataElement('uri',$subject);
  $writer->dataElement('uri',$predicate);
  $writer->dataElement('uri',$object);
  $writer->endTag('triple');
}

=head1 SEE ALSO

L<SemanticWeb::OAI::ORE::ReM>

=head1 AUTHORS

Simeon Warner

=head1 LICENSE AND COPYRIGHT

Copyright 2007-2010 Simeon Warner.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

1;
