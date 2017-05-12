package Net::Plesk::Method;

use strict;

use vars qw( $VERSION @ISA $AUTOLOAD $DEBUG );

$VERSION = '0.01';

$DEBUG = 0;

my %char_entities = (
  '&' => '&amp;',
  '<' => '&lt;',
  '>' => '&gt;',
);

=head1 NAME

Net::Plesk::Method - Perl base class for Plesk XML Remote API Method

=head1 SYNOPSIS

  @ISA = qw( Net::Plesk::Method );

=head1 DESCRIPTION

This module implements a base class for constructing requests using SWSOFT's
Plesk.

=head1 METHODS

=over 4

=item new

Creates a new Net::Plesk::Method object and initializes it.
=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $me;
  my $self = \$me;
  bless($self, $class);
  $self->init(@_);
  return $self;
}


=item encode

Returns the xml encoded entity

=cut

sub encode {
  my ($self,$value) = (shift,shift);
  $value =~ s/([&<>])/$char_entities{$1}/ge;
  return $value;
}

=back

=head1 BUGS

  Creepy crawlies.

=head1 SEE ALSO

SWSOFT Plesk Remote API documentation (1.4.0.0 or later)

=head1 AUTHOR

Jeff Finucane E<lt>jeff@cmh.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Jeff Finucane

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

