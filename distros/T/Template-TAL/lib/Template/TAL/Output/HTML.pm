=head1 NAME

Template::TAL::Output::HTML - output templates as HTML

=head1 SYNOPSIS

  my $tt = Template::TAL->new( output => "Template::TAL::Output::HTML" );
  print $tt->process('foo.tal');

=head1 DESCRIPTION

This is a Template::TAL output filter that produces HTML output, instead of
XML. It does nothing clever, I just use the toStringHTML function of
L<XML::LibXML>.

=cut

package Template::TAL::Output::HTML;
use warnings;
use strict;
use Carp qw( croak );
use base qw( Template::TAL::Output );
use Encode;

sub render {
  my ($self, $dom) = @_;
  $dom->setEncoding( $self->charset );
  return Encode::encode( $self->charset, $dom->toStringHTML() );
}

=head1 COPYRIGHT

Written by Tom Insam, Copyright 2005 Fotango Ltd. All Rights Reserved

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut

1;
