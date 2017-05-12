#
# The PDLA::Graphics::TriD::Window is already partially defined in
# the appropriate gdriver (GL or VRML) items defined here are common
# to both
# 

# A function declaration so indirect object method works when defining $ev
# in new_viewport:
sub PDLA::Graphics::TriD::EventHandler::new;

package PDLA::Graphics::TriD::Window;
use PDLA::Graphics::TriD::ViewPort;
use Data::Dumper;
use strict;

sub new {
  my($arg,$options) = @_;

  print "PDLA::Graphics::TriD::Window - calling SUPER::new...\n" if($PDLA::debug_trid);
  my $this = $arg->SUPER::new();

  print "PDLA::Graphics::TriD::Window - got back $this\n" if($PDLA::debug_trid);
  # Make sure the Graphics has been initialized
  $options->{width} = 	300 unless defined $options->{width};
  $options->{height} = 	300 unless defined $options->{height};
  $this->{Width} = $options->{width};
  $this->{Height} = $options->{height};

  print "PDLA::Graphics::TriD::Window: calling gdriver....\n" if($PDLA::debug_trid);
  $this->{Interactive} = $this->gdriver($options);
  print "PDLA::Graphics::TriD::Window: gdriver gave back $this->{Interactive}....\n" if($PDLA::debug_trid);

  # set default values
  if($this->{Interactive}){
      print "\tIt's interactive... calling ev_defaults...\n" if($PDLA::debug_trid);
	 $this->{Ev} = $this->ev_defaults(); 
      print "\tcalling new_viewport...\n" if($PDLA::debug_trid);
	 $this->new_viewport(0,0,$this->{Width},$this->{Height});  
  }else{
	 $this->new_viewport(0,0,1,1);  
  }

  $this->current_viewport(0);

  return($this);
}

#
# adds to all viewports
#
sub add_object {
  my($this,$object) = @_;
#  print "add_object ",ref($this),"\n";

  for(@{$this->{_ViewPorts}}) {
	 $_->add_object($object);
  }
}



sub new_viewport {
  my($this,$x0,$y0,$x1,$y1, $options) = @_;
  my $vp = new PDLA::Graphics::TriD::ViewPort($x0,$y0,$x1,$y1);
#
  print "Adding viewport $x0,$y0,$x1,$y1\n" if($PDLA::Graphics::TriD::verbose);
  push @{$this->{_ViewPorts}}, $vp;
#

  if($this->{Interactive} ){
	 # set a default controller
	 use PDLA::Graphics::TriD::ArcBall;
	 use PDLA::Graphics::TriD::SimpleScaler;
	 use PDLA::Graphics::TriD::Control3D;
         if (defined($PDLA::Graphics::TriD::offline) and $PDLA::Graphics::TriD::offline==1 ) {
            eval "use PDLA::Graphics::TriD::VRML";  
         } else {
            eval "use PDLA::Graphics::TriD::GL";  
         }

	 my $ev = $options->{EHandler};
	 $ev = new PDLA::Graphics::TriD::EventHandler($vp) unless defined($ev);
	 my $cont = $options->{Transformer};
	 $cont = new PDLA::Graphics::TriD::SimpleController() unless defined($cont);

	 $vp->transformer($cont);
    if(ref($ev)){
		$ev->set_button(0,new PDLA::Graphics::TriD::ArcCone(
																			$vp, 0,
																			$cont->{WRotation}));
		$ev->set_button(2,new PDLA::Graphics::TriD::SimpleScaler(
																				  $vp,
																				  \$cont->{CDistance}));

		$vp->eventhandler($ev);
	 }
  }
  print "new_viewport: ",ref($vp)," ",$#{$this->{_ViewPorts}},"\n" if($PDLA::Graphics::TriD::verbose);

  return $vp;
}

sub resize_viewport {
  my($this,$x0,$y0,$x1,$y1,$vpnum) = @_;
  
  $vpnum = $this->{_CurrentViewPort} unless(defined $vpnum);

  my $vp;
  if(defined($this->{_ViewPorts}[$vpnum])){
	 $vp = $this->{_ViewPorts}[$vpnum]->resize($x0,$y0,$x1,$y1);
  }
  return $vp;

}

sub current_viewport {
  my($this,$num) = @_;

  if(defined $num){
	 if(ref($num)){
		my $cnt=0;
		foreach (@{$this->{_ViewPorts}}){
		  if($num == $_){
			 $this->{_CurrentViewPort} = $cnt;
			 $_->{Active}=1;
		  }elsif(defined $_){
			 $_->{Active}=0;
		  }
		  $cnt++;
		}
	 }else{
		if(defined $this->{_ViewPorts}[$num]){
		  $this->{_CurrentViewPort} = $num;
		  $this->{_ViewPorts}[$num]->{Active}=1;
		}else{
		  print "ERROR: ViewPort $num undefined\n";
		}
	 }
  }
  return $this->{_ViewPorts}[$this->{_CurrentViewPort}];
}


sub viewports {
  my ($this) = shift;
  return $this->{_ViewPorts};
}

sub _vp_num_fromref {
  my ($this,$vp) = @_;

  if(! defined $vp){  
	 $vp = $this->{_CurrentViewPort};
  }elsif(ref($vp)){
	 my $cnt=0;
	 foreach(@{$this->{_ViewPorts}}){
		last if($vp == $_);
		$cnt++;
	 }
	 $vp = $cnt;
  }
  return $vp;
}


sub delete_viewport {
  my($this, $vp) = @_;
  my $cnt;
  if(($cnt=$#{$this->{_ViewPorts}})<= 0){
	 print "WARNING: Cannot delete final viewport - request ignored\n";
	 return;
  }
  $vp = $this->_vp_num_fromref($vp);

  $this->{_ViewPorts}[$vp]->DESTROY();
  
  splice(@{$this->{_ViewPorts}},$vp,1);
  
  if($vp == $cnt){
	 $this->current_viewport($vp-1);
  }
}





sub clear_viewports {
  my($this) = @_;
  foreach(@{$this->{_ViewPorts}}){
	 $_->clear_objects();
  }
}

sub clear_viewport {
  my($this, $vp) = @_;
  my $cnt;

  $vp = $this->_vp_num_fromref($vp);
  $this->{_ViewPorts}[$vp]->clear_objects();

}

sub set_eventhandler {
  my($this,$handler) = @_;

  $this->{EHandler} = $handler;

#  for(@{$this->{_ViewPorts}}) {
#	 $_->eventhandler($handler);
#  }
}

#sub set_transformer {
#  my($this,$transformer) = @_;
#
#  for(@{$this->{_ViewPorts}}) {
#	 $_->transformer($transformer);
#  }
#}


sub AUTOLOAD {
  my ($self,@args)=@_;
  use vars qw($AUTOLOAD);
  my $sub = $AUTOLOAD;
  
# If an unrecognized function is called for window it trys to apply it
# to all of the defined ViewPorts

  $sub =~ s/.*:://;

  print "AUTOLOAD: $sub at ",__FILE__," line ", __LINE__  ,".\n" 
	 if($PDLA::Graphics::TriD::verbose);

  print "Window AUTOLOADing '$sub': self=$self, args='".join("','",@args),"'\n" if($PDLA::debug_trid);

  if($sub =~ /^gl/ && defined  $self->{_GLObject}){
	 return  $self->{_GLObject}->$sub(@args);
  }


  for(@{$self->{_ViewPorts}}) {
    next unless defined $_;
	 $_->$sub(@args);
  }
}

1;
