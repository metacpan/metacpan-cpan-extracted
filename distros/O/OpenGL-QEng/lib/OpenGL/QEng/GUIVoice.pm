###  $Id: $
####------------------------------------------
###
## @file
# Define GUIVoice Class

## @class GUIVoice
# GUI class for voice like user interface messages in game
#

package OpenGL::QEng::GUIVoice;

use strict;
use warnings;
use OpenGL::QEng::GUIText;

use base qw/OpenGL::QEng::GUIFrame OpenGL::QEng::Voice/;

#----------------------------------------------------------------------
sub new {
  my ($class,@props) = @_;

  my $props = (scalar(@props) == 1) ? $props[0] : {@props};

  my $self = OpenGL::QEng::GUIFrame->new;
  $self->{color}  = undef;
  bless($self,$class);

  $self->passedArgs($props);
  $self->{textarea} ||= OpenGL::QEng::GUIText->new(x      => $self->{x},
				     y      => $self->{y},
				     width  => $self->{width},
				     height => $self->{height},
				     color  => $self->{color},
				    );
  $self->adopt($self->{textarea});
  $self->create_accessors;
  $self->register_events;

  $self;
}

#----------------------------------------------------------------------
sub register_events {
  my ($self) = @_;

  $self->{event}->callback($self,'msg',
		    sub {
		      my ($self,$stash,$obj,$ev,@arg) = @_;
		      $self->message(@arg);
		    });
  $self->{event}->callback($self,'clear_msg',
		    sub {
		      my ($self,$stash,$obj,$ev,@arg) = @_;
		      $self->{textarea}->erase;
		    });
  $self->{event}->callback($self,'bell',
		    sub {
		      my ($self,$stash,$obj,$ev,@arg) = @_;
		      $self->bellRing
		    });
}

#----------------------------------------------------------------------
{my @backgrounds = ('beige', 'light blue', 'light green');
 my $backidx = 0;

## @method message($text)
#Display the text in the feedback panel
 sub message {
   my $self = shift @_;

   for my $m (@_){
     my @lines = split "\n", $m;
     $self->{textarea}->insert(@lines);
   }
   $self->{textarea}->color($backgrounds[$backidx++]);
   $backidx = 0 if $backidx == @backgrounds;
 }
}

# -----------------------------------------------------------------------------
1;

__END__

=head1 NAME

GUIVoice -- voice like user interface message interface for game

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

