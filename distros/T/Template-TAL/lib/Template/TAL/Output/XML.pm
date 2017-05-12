=head1 NAME

Template::TAL::Output::XML - output templates as XML

=head1 SYNOPSIS

  my $tt = Template::TAL->new( output => "Template::TAL::Output::XML" );
  print $tt->process('foo.tal');

=head1 DESCRIPTION

This is a Template::TAL output filter that produces straight XML output
from the templates.

=cut

package Template::TAL::Output::XML;
use warnings;
use strict;
use Carp qw( croak );
use base qw( Template::TAL::Output );

use Encode;

sub render {
  my ($self, $dom) = @_;
  $dom->setEncoding( $self->charset );
  return Encode::encode( $self->charset, $dom->toString() );
}

=head1 COPYRIGHT

Written by Tom Insam, Copyright 2005 Fotango Ltd. All Rights Reserved

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut

1;
