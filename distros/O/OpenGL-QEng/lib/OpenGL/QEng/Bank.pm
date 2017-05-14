###  $Id: Bank.pm 424 2008-08-19 16:27:43Z duncan $
####------------------------------------------

## @file Bank.pm
# Define Bank Class

## @class Bank
# Combination of a sign and a chest
# @map_item    - Bank
#

package OpenGL::QEng::Bank;

use strict;
use warnings;
use OpenGL::QEng::Chest;
use OpenGL::QEng::Sign;

use base qw/OpenGL::QEng::Volume/;

#------------------------------------------------------------
## @cmethod Bank new(@args)
# Create a bank at given location
#
sub new {
  my ($class,@props) = @_;

  my $props = (scalar(@props) == 1) ? $props[0] : {@props};

  my $self = OpenGL::QEng::Volume->new;
  $self->{maxval}  = 230;
  $self->{sign}    =
    OpenGL::QEng::Sign->new(x=>0, z=>0.4, yaw=>0,
	      texture => 'bank',
	      text    => '000/230',
	      wrap_class =>
	      {text_location => sub{
		 my $model = $_[0]->{model};
		 ($model->{minx}+0.55*($model->{maxx}-$model->{minx}), # X
		  $model->{miny}+0.19*($model->{maxy}-$model->{miny}), # Y
		  $model->{maxz}+0.01,0);                              # Z
	       },
	      },
	     );
  $self->{chest}   =
    OpenGL::QEng::Chest->new(x=>0, z=>2, yaw=>180, );
  $self->{chest}->fixed->{wrap_class} =
    {value => sub{
       my ($self) = @_;
       my $sum = 0;
       foreach my $o (@{$self->holds}) {
	 $sum += $o->value if $o->can('value');
       }
       $self->is_at->is_at->sign->text($sum.'/'.$self->is_at->is_at->maxval);
     },
     put_thing => sub{
       my ($self,@arg) = @_;
       $self->SUPER::put_thing(@arg);
       #$arg[0]->printMe; #XXX if wizard?
       $self->value;
     },
     take_thing => sub{
       my ($self,@arg) = @_;
       my $r = $self->SUPER::take_thing(@arg);
       $self->value;
       return $r;
     }
    };
  $self->{chest}->fixed->wrap_class;
  bless($self,$class);

  $self->passedArgs($props);
  $self->register_events;
  $self->create_accessors;
  $self->assimilate($self->{sign});
  $self->assimilate($self->{chest});

  $self;
}

#------------------------------------------
sub printMe { #XXX merge into Thing
  my ($self,$depth) = @_;

  (my $map_ref = ref $self) =~ s/OpenGL::QEng:://;
  print STDOUT '  'x$depth,"$map_ref $self->{x} $self->{z} $self->{yaw};\n";
}


#==============================================================================
1;

__END__

=head1 NAME

Bank -- a place to keep and account for valuables

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

