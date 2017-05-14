###  $Id: GUICanvasThing.pm 322 2008-07-19 22:32:21Z duncan $
####------------------------------------------
## @file
# Define GUICanvasThing Class
# GUI Widgets and related capabilities
#

## @class GUICanvasThing
# Base class for things that can be drawn on a GUICanvas

package OpenGL::QEng::GUICanvasThing;

use strict;
use warnings;

use base qw/OpenGL::QEng::GUIThing/;

#--------------------------------------------------
## @cmethod % new()
# Create a GUICanvasThing
#
sub new {
  my ($class,@props) = @_;

  @props = %{$props[0]} if (scalar(@props) == 1);

  my $self = OpenGL::QEng::GUIThing->new;
  $self->{x}     = 0;
  $self->{y}     = 0;
  $self->{color} = 'black';
  $self->{tag}   = undef;
  bless($self,$class);

  $self->passedArgs({@props});
  $self->create_accessors;

  $self;
}

#------------------------------------------------------------------------------
1;

__END__

=head1 NAME

GUICanvasThing -- Base class for things that can be drawn on a GUICanvas

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

