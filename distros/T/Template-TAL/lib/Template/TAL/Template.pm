=head1 NAME

Template::TAL::Template - a TAL template

=head1 SYNOPSIS

  my $template = Template::TAL::Template->new->source( "<html>...</html>" );
  my $dom = $template->process( {} );
  print $dom->toString();

=head1 DESCRIPTION

This class represents a single TAL template, and stores its XML source.
You'll probably not see these objects directly - Template::TAL takes template
names and returns bytes. But you might.

=cut

package Template::TAL::Template;
use warnings;
use strict;
use Carp qw( croak );
use XML::LibXML;

=head1 METHODS

=over

=item new()

Create a new TAL template object.

=cut

sub new {
  my $class = shift;
  my $self = bless {}, $class;
  return $self;
}

=item filename( set filename )

the filename of the template, an alternative to L<source> below.

=cut

sub filename {
  my $self = shift;
  my $parser = XML::LibXML->new();
  return $self->document( $parser->parse_file( shift ) );
}

=item source( set source )

the TAL source of this template, as a scalar

=cut

sub source {
  my $self = shift;
  my $parser = XML::LibXML->new();
  return $self->document( $parser->parse_string( shift ) );
}

=item document( [document] )

returns the XML::LibXML::Document object that represents this
template, or sets it if a parameter is given.

=cut

sub document {
  my $self = shift;
  return $self->{_document} unless @_;
  $self->{_document} = shift;
  return $self;
}

=back

=head1 COPYRIGHT

Written by Tom Insam, Copyright 2005 Fotango Ltd. All Rights Reserved

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut

1;
