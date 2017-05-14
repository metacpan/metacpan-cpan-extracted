###  $Id: Sign.pm 312 2008-07-17 18:59:39Z overmars $
####------------------------------------------
###
## @file
# Define Treasure Class

## @class Treasure
# Treasure items of all kinds, a kind of SimpleThing with value

package OpenGL::QEng::Treasure;

use strict;
use warnings;

use base qw/OpenGL::QEng::SimpleThing/;

#------------------------------------------
sub new {
  my ($class,@props) = @_;

  @props = %{$props[0]} if (scalar(@props) == 1);

  my %ttexture = ('poster'=>'scroll', 'gem'=>'treasure',
		  'copper'=>'coins', 'silver'=>'coins', 'gold'=>'coins',
		 );
  my @scale;
  $scale[0]  = 0.0;
  $scale[1]  = 0.6;
  $scale[2]  = 0.9;
  $scale[3]  = 1.0;
  $scale[4]  = 1.0;
  $scale[5]  = 1.0;
  $scale[6]  = 1.0;
  $scale[7]  = 1.0;
  $scale[8]  = 1.0;
  $scale[9]  = 1.0;
  $scale[10] = 1.0;
  $scale[11] = 0.9;
  $scale[12] = 0.7;
  $scale[13] = 0.5;
  $scale[14] = 0.37;
  $scale[15] = 0.37;
  $scale[16] = 0.0;

  # Bag shape parameters
  my (@x,@y);
  $y[  0] = 0.00; $x[  0]= -0.5;
  $y[  1] = 0.10; $x[  1]= -0.6;
  $y[  2] = 0.20; $x[  2]= -0.7;
  $y[  3] = 0.30; $x[  3]= -0.73;
  $y[  4] = 0.40; $x[  4]= -0.71;
  $y[  5] = 0.50; $x[  5]= -0.67;
  $y[  6] = 0.60; $x[  6]= -0.55;
  $y[  7] = 0.65; $x[  7]= -0.30;
  $y[  8] = 0.54; $x[  8]= -0.18;
  $y[  9] = 0.53; $x[  9]= -0.10;
  $y[ 10] = 0.60; $x[ 10]=  0.20;
  $y[ 11] = 0.57; $x[ 11]=  0.40;
  $y[ 12] = 0.50; $x[ 12]=  0.48;
  $y[ 13] = 0.40; $x[ 13]=  0.53;
  $y[ 14] = 0.35; $x[ 14]=  0.60;
  $y[ 15] = 0.30; $x[ 15]=  0.70;
  $y[ 16] = 0.20; $x[ 16]=  0.79;
  $y[ 17] = 0.10; $x[ 17]=  0.81;
  $y[ 18] = 0.00; $x[ 18]=  0.76;

  my $self = OpenGL::QEng::SimpleThing->new;
  $self->{type}    = 'copper';
  $self->{count}   = 1;
  $self->{texture} = undef;
  $self->{model}   ||= {};
  $self->{model}{x}     = \@x;
  $self->{model}{y}     = \@y;
  $self->{model}{scale} = \@scale;
  bless($self,$class);

  $self->passedArgs({@props});
  $self->create_accessors;
  $self->register_events;

  unless ($self->{texture}) {
    if (!defined($ttexture{$self->type})) {
      print "Unknown treasure type $self->{type}\n";
    } else {
      $self->{texture} = $ttexture{$self->type};
    }
  }
  $self;
}

#------------------------------------------
## @method $ desc($self)
# Return a text description of this object
sub desc { 'This could be valuable, let\'s hang onto it' }

#------------------------------------------
## @method $ textName($self)
# Return the text description of this thing
sub textName {
  my $self = shift @_;

  my $type = $self->{type};
  my $cnt = $self->{count};
  if ((defined $type)  && (defined ($cnt))) {
    my $plural = '';
    if ($cnt>1) {
      $plural = 's';
    }
    return "$cnt\n".$type.$plural;
  }
  return "coins";
}

#------------------------------------------
## @method $ value
# return value of this treasure
sub value {
  my ($self) = @_;
  my $substance = ($self->{type} =~ /(copper|silver|gold|gem)/x)
	        ? $self->{type} : '?';
  my $cnt       = $self->{count} || 1;
  my $val=$cnt* {'?'    => 1,
		 copper => 1,
		 silver => 10,
		 gold   => 100,
		 gem    => 1000}->{$substance};
  warn "=== value=$val, stuff=$substance, n=$cnt, self=$self\n"
    if $ENV{WIZARD};
  return $val;
}

#--------------------------
## @method $ combine($thing)
# combine similar things
# Return 1 if they did combine otherwise 0
sub combine {
  my ($self, $thing) = @_;

  if ($self->{'type'} eq $thing->{'type'}) {
    $self->{'count'} += $thing->{'count'};
    return 1;
  }
  0;
}

{;
 my $dl = 0;

#--------------------------
 sub draw {
   my ($self,$mode) = @_;

   if ($mode == OpenGL::GL_SELECT) {
     OpenGL::glLoadName($self->{GLid});
   }
   if ($self->texture ne 'coins') {
     $self->SUPER::draw(@_);
     return;
   }
   OpenGL::glTranslatef($self->{x},$self->y,$self->{z});
   OpenGL::glRotatef($self->{yaw},0,1,0) if $self->{yaw};
   if ($dl) {
     OpenGL::glCallList($dl);
   } else {
     $dl = $self->getDLname();
     OpenGL::glNewList($dl,OpenGL::GL_COMPILE);
     OpenGL::glColor3f(165.0/255.0,42.0/255.0,42.0/255.0); # brown
     $self->tErr('err @ treasure9');
     for (my $zidx=0;$zidx<16;$zidx++) {
       OpenGL::glBegin(OpenGL::GL_TRIANGLE_STRIP);
       my $zStep = 1;
       my $z  = ($zidx*2/15-1.0);
       my $z1 = (($zidx+$zStep)*2/15-1.0);
       my $scale  = $self->{model}{scale}[$zidx];
       my $scale1 = $self->{model}{scale}[($zidx+$zStep)];
       for (my $idx=1; $idx<(@{$self->{model}{x}})-1; $idx++) {
	 if ($idx%5 == 0) {
	   OpenGL::glColor3f(139.0/255.0,35.0/255.0,35.0/255.0);	# brown4
	 } else {
	   OpenGL::glColor3f(165.0/255.0,42.0/255.0,42.0/255.0);	# brown
	 }
	 my $currx  = $self->{model}{x}[$idx]*$scale*0.6;
	 my $currx1 = $self->{model}{x}[$idx]*$scale1*0.6;
	 my $curry  = $self->{model}{y}[$idx]*$scale;
	 my $curry1 = $self->{model}{y}[$idx]*$scale1;
	 OpenGL::glVertex3f($currx,$curry,$z);
	 OpenGL::glVertex3f($currx1,$curry1,$z1);
       }
       OpenGL::glEnd();
       $self->tErr('err @ treasure0');
     }
     OpenGL::glColor3f(0.0,0.0,0.0);	# Black
     OpenGL::glBegin(OpenGL::GL_LINE_STRIP);
     OpenGL::glVertex3f(-1.0,0.0,4.2/5);
     OpenGL::glVertex3f(-0.5,0.5/5,4.0/5);
     OpenGL::glVertex3f(-0.45,0.125/5,4/5);
     OpenGL::glVertex3f(-0.525,0.25/5,4/5);
     OpenGL::glVertex3f(-0.5475,0.375/5,4/5);
     OpenGL::glVertex3f(-0.5325,0.5/5,4/5);
     OpenGL::glVertex3f(-0.5025,0.625/5,4/5);
     OpenGL::glVertex3f(-0.4125,0.75/5,4/5);
     OpenGL::glVertex3f(-0.225,0.8125/5,4/5);
     OpenGL::glVertex3f(-0.135,0.675/5,4/5);
     OpenGL::glVertex3f(-0.075,0.6625/5,4/5);
     OpenGL::glVertex3f(0.15,0.75/5,4/5);
     OpenGL::glVertex3f(0.36,0.625/5,4/5);
     OpenGL::glVertex3f(0.45,0.4375/5,4/5);
     OpenGL::glVertex3f(0.5925,0.25/5,4/5);
     OpenGL::glVertex3f(1.0,0.0,4/5);
     OpenGL::glEnd();
     $self->tErr('err @ treasure2');

     OpenGL::glEndList();
     OpenGL::glCallList($dl); #### Draw it the first time
   }
   OpenGL::glRotatef(-$self->{yaw},0,1,0) if $self->{yaw};
   OpenGL::glTranslatef(-$self->{x},-$self->y,-$self->{z});
 }
} #end closure

#==============================================================================
1;

__END__

=head1 NAME

Treasure -- items of all kinds, a kind of SimpleThing with value

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

