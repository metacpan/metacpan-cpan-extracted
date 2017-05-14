###  $Id: Part.pm 424 2008-08-19 16:27:43Z duncan $
####------------------------------------------
###
## @file
# Define Part Class

## @class Part

package OpenGL::QEng::Part;

use strict;
use warnings;

use base qw/OpenGL::QEng::Box/;

#-----------------------------------------------------------
sub new {
  my ($class,@props) = @_;

  my $props = (scalar(@props) == 1) ? $props[0] : {@props};

  my $self = OpenGL::QEng::Box->new($props);
  bless($self,$class);

  $self->passedArgs($props);
  $self->create_accessors;
  $self->register_events;

  $self;
}

#-----------------------------------------------------------
sub handle_touch {
  my ($self,@args) = @_;
  $self->is_at->handle_touch(@args);
}

#==============================================================================
1;

__END__

=head1 NAME

Part -- class for Things that are a part of composite Things: i.e, the
lid of a chest

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

