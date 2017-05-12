=head1 NAME

Template::TAL::Output - base class for Template::TAL output layers

=head1 SYNOPSIS

  my $tt = Template::TAL->new( output => "Template::TAL::Output::XML" );
  print $tt->process('foo');

=head1 DESCRIPTION

The render method of Template::TAL::Template produces a DOM tree. TT then
gives that tree to its output class (in $tt->output) for conversion to
a byte sequence. This class is the superclass of all Template::TAL output
classes. By default, TT will use Template::TAL::Output::HTML, but you
may want to use Template::TAL::Output::XML to produce XML output.

=head1 SUBCLASSING

You only have to override the 'render' method, which should take an
XML::LibXML::Document object, and return a byte sequence. Preferably,
you should respect the 'charset' property of the instance (assuming
that applies to your output method).

=cut

package Template::TAL::Output;
use warnings;
use strict;
use Carp qw( croak );

=head1 METHODS

=over

=item new()

Create a new instance of the output class.

=cut

sub new {
  return bless {}, shift;
}

=item charset

Get/set chained accessor that returns/sets the character set that the output
will be encoded into.  By default, this is 'utf-8'.

=cut

sub charset {
  my $self = shift;
  return $self->{charset} ||= "utf-8" unless @_;
  $self->{charset} = shift;
  return $self;
}

=item render( XML DOM )

returns a byte sequence representing the XML DOM passed.

=cut

sub render {
  croak("Template::TAL::Output is abstract - use a subclass");
}

=back

=head1 COPYRIGHT

Written by Tom Insam, Copyright 2005 Fotango Ltd. All Rights Reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 BUGS

None known.  Please see L<Template::TAL> for details of how to report bugs

=head1 SEE ALSO

L<Template::TAL>

=cut

1;
