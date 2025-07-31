package Template::Plex;

use strict;
use warnings;

our $VERSION = 'v0.9.0';
use feature qw<say refaliasing>;
no warnings "experimental";


use Log::ger;
use Log::OK;	#Allow control of logging from the command line

use Symbol qw<delete_package>;

use constant::more KEY_OFFSET=>0;
use constant::more DEBUG=>0;

use constant::more {plex_=>0, meta_=>1, args_=>2, sub_=>3,
  package_=>4, init_done_flag_=>5, skip_=>6,
	cache_=>7, slots_=>8, parent_=>9, default_result_=>10, id_=>11, ref_cache_=>12
};

use constant::more KEY_COUNT=>ref_cache_ - plex_ +1;

#Template::Plex::Internal uses the field name constants so import it AFTER
#we define them
use Template::Plex::Internal;

our %top_level_cache;
sub new {
	my ($package, $plex)=@_;
	my $self=[];
  #$self->[plex_]=$plex;
	$self->[cache_]={};
  $self->[slots_]={};
	bless $self, $package;
}
sub get_cache {
	$_[0][cache_];
}

#Returns a template loaded and intialised
sub load {
    my ($self, $path, $vars, %opts)=@_;
		my $template;
		if(ref($self)){
			DEBUG and Log::OK::TRACE and log_trace __PACKAGE__." instance load called for $path";
			\my %fields=$self->args;

			my %options=$self->meta->%{qw<root use base>}; #copy
      if(%opts){
        $opts{caller}=$self; 
      }
      else {
        $options{caller}=$self;
      }
      
			$template=Template::Plex::Internal->new(\&Template::Plex::Internal::_prepare_template, $path, $vars?$vars:\%fields, %opts?%opts:%options);

		}
		else{
			DEBUG and Log::OK::TRACE and log_trace __PACKAGE__." class load called for $path";
			#called on package
      my $dummy=[];
      $dummy->[Template::Plex::meta_]={file=>(caller)[1]}; 
      bless $dummy, "Template::Plex";
      $opts{caller}=$dummy;

			$template=Template::Plex::Internal->new(\&Template::Plex::Internal::_prepare_template, $path, $vars, %opts);

		}
			$template->setup;
			$template;
}

#Returns a template which was already loaded can called from the callers position
#
#TODO: special case where the second argument is a hash ref or undef
# This indicates no id was specified so use implicit cache entry
# path must always be defined.
# eg 
#   cache undef, "path", .... ; #will use explicit cache key
#   cache "path", {var};        #Use implicit cache key
#   cache "path";               #Use implicit cache key
#
# This tidies up the common use case for cached templates
sub cache {
    my $self=shift;
    my @args=@_;

    if(@args ==1){
        # Recalling implicit cache key with path only
        unshift @args, undef;
    }
    elsif(defined($args[1]) and ref($args[1]) eq "HASH"){
      # variables hash ref given, with implicit cache id
      unshift @args, undef;
    }
    else{
      # Expect explicit cache Id
    }

		my ($id, $path, $vars, %opts)=@args;

    #my ($self, $id, $path, $vars, %opts)=@_;
		DEBUG and Log::OK::TRACE and log_trace __PACKAGE__." cache: $path";
		$id//=$path.join "", caller;	#Set if undefined
    #say STDERR "-=----IN CACHE id=$id, path=$path, vars=", %$vars, %opts;
    #use Data::Dumper;
    #say STDERR Dumper [$id, $path, $vars, \%opts];
    #sleep 1;
		if(ref($self)){
      my $c=$self->[cache_]{$id};
      if($c){
          return $c;
      }
      else {
        my $template=$self->load($path, $vars, %opts);
        $template->[id_]=$id;
        $template->[ref_cache_]=$self->[cache_];
        
        $self->[cache_]{$id}//=$template;
      }
		}
		else{
      my $c=$top_level_cache{$id};
      if($c){
			    return $c 
      }
      else {
        my $template=$self->load($path, $vars, %opts);
        $template->[id_]=$id;
        $template->[ref_cache_]=\%top_level_cache;
        $top_level_cache{$id}//=$template;
      }
		}
}

#TODO: add parameter checking as per cache
sub immediate {
		DEBUG and Log::OK::TRACE and log_trace __PACKAGE__." immediate!!";
    
    my $self=shift;
    my @args=@_;
    if(@args ==1){
        # Recalling implicit cache key with path only
        unshift @args, undef;
    }
    elsif(defined($args[1]) and ref($args[1]) eq "HASH"){
      # variables hash ref given, with implicit cache id
      unshift @args, undef;
    }
    else{
      # Expect explicit cache Id, path, vars and options
    }

		my ($id, $path, $vars, @opts)=@args;


		DEBUG and Log::OK::TRACE and log_trace __PACKAGE__." immediate: $path";
		$id//=$path.join "", caller;	#Set if undefined
		
		my $template=$self->cache($id, $path, $vars, @opts);
		return $template->render($vars) if $template;
		"";

}


#########################################
# sub _plex_ {                          #
#         $_[0][Template::Plex::plex_]; #
# }                                     #
#########################################

sub meta :lvalue { $_[0][Template::Plex::meta_]; }

sub args :lvalue{ $_[0][Template::Plex::args_]; }

sub init_done_flag:lvalue{ $_[0][Template::Plex::init_done_flag_]; }


sub _render {
	#sub in plex requires self as first argument
	return $_[0][sub_](@_);
}

sub skip {
	DEBUG and Log::OK::DEBUG and log_debug("Template::Plex: Skipping Template: ".$_[0]->meta->{file});
	$_[0]->[skip_]->();
}

#A call to this method will run the sub an preparation
#and immediately stop rendering the template
sub _init {
	my ($self, $sub)=@_;
	
	return if $self->[init_done_flag_];
	DEBUG and Log::OK::DEBUG and log_debug("Template::Plex: Initalising Template: ".$self->meta->{file});
	unless($self->isa("Template::Plex")){
	#if($self->[meta_]{package} ne caller){
		DEBUG and Log::OK::ERROR and log_error("Template::Plex: init must only be called within a template: ".$self->meta->{file});
		return;
	}

	$self->pre_init;
	$sub->();
	$self->post_init;

	$self->[init_done_flag_]=1;
	$self->skip;
	"";		#Must return an empty string
}

sub pre_init {

}

sub post_init {

}
sub prefix {
}
sub postfix {
}

#Execute the template in setup mode
sub setup {
	my $self=shift;
	#Test that the caller is not the template package
	DEBUG and Log::OK::DEBUG and log_debug("Template::Plex: Setup Template: ".$self->meta->{file});
	if($self->[meta_]{package} eq caller){
		#Log::OK::ERROR and log_error("Template::Plex: setup must only be called outside a template: ".$self->meta->{file});
		#		return;
	}
	$self->[init_done_flag_]=undef;
	$self->render(@_);
	
	#Check if an init block was used
	unless($self->[init_done_flag_]){
		DEBUG and Log::OK::WARN and log_warn "Template::Plex ignoring no \@{[init{...}]} block in template from ". $self->meta->{file};
		$self->[init_done_flag_]=1;
	}
	"";
}

# Slotting and Inheritance
#
#

#Marks a slot in a parent template.
#A child template can fill this out by calling fill_slot on the parent
sub slot {
	my ($self, $slot_name, $default_value)=@_;
	$slot_name//="default";	#If no name assume default

	DEBUG and Log::OK::TRACE and log_trace __PACKAGE__.": Template called slot: $slot_name";
	my $data=$self->[slots_]{$slot_name};
	my $output="";
	
	$data//=$default_value;
	if(defined($data) and ref $data and $data->isa("Template::Plex")){
		#render template
		if($slot_name eq "default"){
			DEBUG and Log::OK::TRACE and log_trace __PACKAGE__.": copy default slot";
			$output.=$self->[default_result_]//"";
		}
		else {
			DEBUG and Log::OK::TRACE and log_trace __PACKAGE__.": render non default template slot";
			$output.=$data->render;
		}
	}
	else {
		DEBUG and Log::OK::TRACE and log_trace __PACKAGE__.": render non template slot";
		#otherwise treat as text
		$output.=$data//"";
	}
	$output
}

sub fill_slot {
	my ($self)=shift;
	my $parent=$self->[parent_]//$self;
	unless($parent){
		DEBUG and Log::OK::WARN and log_warn __PACKAGE__.": No parent setup for: ". $self->meta->{file};
		return;
	}

	unless(@_){
		#An unnamed fill spec implies the default slot to which this template will be rendered
		$parent->[slots_]{default}=$self;
	}
	else{
		#5.36 multi element for loop
		#disabled for backwards compatability
		#
		#for my ($k,$v)(@_){
		#	$parent->[slots_]{$k}=$v;
		#}

		my %fillers=@_;
		for (keys %fillers){
      # Only fill the slot if it doesn't have a value
      $parent->[slots_]{$_}=$fillers{$_};
		}
	}
	"";
}

sub append_slot {
  my($self)=shift;
	my $parent=$self->[parent_]//$self;
  unless($parent){

    DEBUG and Log::OK::WARN and log_warn __PACKAGE__.": No parent setup for ". $self->meta->{file};
    return
  }
  else{
    my %fillers=@_;
    for(keys %fillers){
      $parent->[slots_]{$_}.=$fillers{$_};
    }
  }
}

sub prepend_slot {
  my($self)=shift;
  my $parent=$self->[parent_]//$self;
  unless($parent){

    DEBUG and Log::OK::WARN and log_warn __PACKAGE__.": No parent setup for ". $self->meta->{file};
    return
  }
  else{
    my %fillers=@_;
    for(keys %fillers){
      $parent->[slots_]{$_}=$fillers{$_}.$parent->[slots_]{$_};
    }
  }
}




sub inherit {
	my ($self, $path)=@_;
	DEBUG and Log::OK::DEBUG and log_debug __PACKAGE__.": Inherit: $path";
	#If any parent variables have be setup load the parent template

	#Setup the parent. Cached  with path
	my $p=$self->load($path, $self->args, $self->meta->%*);
  #$p->[slots_]={};

	#Add this template to the default slot
	$p->[slots_]{default}=$self;
	$self->[parent_]=$p;
}

sub render {
	my ($self, $fields, $top_down)=@_;
	#We don't call parent render if we are uninitialised


	
	#If the template uninitialized, we just do a first pass
	unless($self->init_done_flag){

		return $self->_render;

	}

	DEBUG and Log::OK::TRACE and log_trace __PACKAGE__.": render :".$self->meta->{file}." flag: ".($top_down//"");

	#locate the 'top level' template and  call downwards
	my $p=$self;
	if(!$top_down){
		while($p->[parent_]){
			$p=$p->[parent_];
		}
		$p->render($fields,1);
	}
	else{
		#This is Normal template or top of hierarchy
		#child has called parent and parent is the top
		#
		#Turn it around and call back down the chain
		#

		DEBUG and Log::OK::TRACE and log_trace __PACKAGE__.": render: no parent bottom up. assume normal render";
		#Check slots. Slots indicate we need to call the child first
		if($self->[slots_] and $self->[slots_]->%*){
			DEBUG and Log::OK::TRACE and log_trace __PACKAGE__.": render: rendering default slot";
			$self->[default_result_]=$self->[slots_]{default}->render($fields,1);
		}

		#now call render on self. This renders non hierarchial templates
		DEBUG and Log::OK::TRACE and log_trace __PACKAGE__.": render: rendering body and sub templates";
		my $total=$self->_render($fields); #Call down the chain with top_down flag
		$self->[default_result_]="";	#Clear
		return $total;
	}
}

sub parent {$_[0][parent_];}



# the callee is reomved from refernece cache if an ID is present.
# internal variables are released
#
sub cleanup {
  #use Data::Dumper;
  #say STDERR Dumper $_[0];
  for($_[0][id_]//()){
    delete $_[0][ref_cache_]{$_};
  }
  delete_package $_[0][meta_]{package};# if $_[0][package_];
  $_[0]->@*=();
  $_[0]=undef;
}



sub DESTROY {
  #say STDERR "DESTROY";
  delete_package $_[0][meta_]{package} if $_[0][meta_]{package};
}

#Internal testing use only
sub __internal_test_proxy__ {
	"PROXY";
}

1;
