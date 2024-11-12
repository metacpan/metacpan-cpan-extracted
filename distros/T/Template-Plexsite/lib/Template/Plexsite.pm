package Template::Plexsite;

use v5.36;

use feature qw<say try>;

use Log::ger;
use Log::OK;

use feature qw<refaliasing say current_sub>;
no warnings "experimental";

#use Template::Plex::Internal;
use parent "Template::Plex";

our $VERSION="v0.1.0";
use File::Basename qw<dirname basename>;
use File::Spec::Functions qw<catfile catdir abs2rel>;
use File::Path qw<mkpath>;
use Data::Dumper;

use constant::more KEY_OFFSET=>Template::Plex::KEY_COUNT+Template::Plex::KEY_OFFSET;
use constant::more ("dependencies_=".KEY_OFFSET,qw<locale_sub_template_ input_path_ output_path_>);
use constant::more KEY_COUNT=> output_path_- dependencies_+1;


# Resolves a plt dir path to the first index found in the plt dir. Root (src
# root) must be supplied
sub _first_index_path {
  my $self=shift;
  my $path=shift;
  my $root=shift;

  # Plexsite can also use a plt directory as a parent. Here we need to resolve
  # to the first index.plex.* file located in the dir
  #my $root=$self->meta->{root};
  my $tpath;

	if($path =~ /\.plt$/ and  -d "$root/$path"){
    # Match the first index file. Prefer file will plex/plx as the second last extension
		#First index.*.plex file
		Log::OK::DEBUG and log_debug __PACKAGE__." testing for index at $root/$path";
		($tpath)= < $root/$path/index.plex.*  $root/$path/index.plx.* $root/$path/index.*.plx $root/$path/index.*.plex >;
    Log::OK::DEBUG and log_debug "Found first path: $tpath";
    #$tpath =~ s|^$root/||;
    $tpath = abs2rel($tpath, $root);
	}

  $tpath//=$path;

  $tpath;
}

sub new {
	my $package=shift;
	$package->SUPER::new(@_);
}

# Take a path (relative to src) to a plex/plx or plt to use as base class
# First index file is use if plt is specified
# Overrides Template::Plex
#
sub inherit {
	my $self=shift;
  my $tpath=$_[0]; 
	unless($tpath){
		Log::OK::INFO and log_info "undefined parent template. Disabling inheritance";
		return;
	}

  # Plexsite can also use a plt directory as a parent. Here we need to resolve
  # to the first index.plex.* file located in the dir
  my $root=$self->meta->{root};
  $tpath=$self->_first_index_path($tpath, $root);

	#TODO: Check that output has been called
	my $table=$self->args->{table}->table;
	my $entry=$table->{$self->args->{plt}};
	unless($entry->{output}){
		Log::OK::ERROR and log_error "inhert called before output in ". $self->args->{plt} ;
	}
	$self->SUPER::inherit($tpath);
}

# Locates the first index.*.plex file in a plt directory and loads it
# as the body of the plt template.
#
# Adds important subroutines into the template namespace for resolving relative paths
#
sub load {
	my ($self, $path, $args, %options)=@_;
	Log::OK::TRACE and log_trace __PACKAGE__.": load called for $path";
	my $meta={};
	$meta=$self->meta if ref $self;

	#Force a template root for calls to super load
	my $root=$options{root}//=$meta->{root};

	#Path can be to a plt dir. If so find the index file and  load it
	my $tpath=$self->_first_index_path($path, $root);

	#This is needed to make static class method work to load
	my %l_options=$meta->%*;
	$l_options{_input_path}=$path;
	$l_options{root}=$root;
	$l_options{base}=$options{base}//"Template::Plexsite";
	$l_options{use}=["Template::Plexsite::Common",
	];
	#wrappers subs to inject
	$l_options{inject}=[
		'sub output{ 
			$self->output(@_);
		}'
    ,
		'sub navi{ 
			$self->navi(@_);
		}'
		,
		'sub locale {
			$self->locale(@_);
		}'
		,
		'sub res {
			$self->add_resource(@_);
		}'
		,
		'sub plt_res {
			$self->add_plt_resource(@_);
		}',
    'sub existing_res {
      $self->existing_resource(@_);
    }',

    'sub sys_path_src{
      $self->sys_path_src(@_);
    }',
    'sub sys_path_build{
      $self->sys_path_build(@_);
    }',
    'sub plt_path{
      $self->plt_path(@_);
    }',
		'sub lander {
			$self->lander(@_);
		}'

	];

	my $template=$self->SUPER::load($tpath, $args, %l_options);
	$template;
}

sub pre_init {

	$_[0][input_path_]=$_[0]->meta->{_input_path};

}

sub post_init {
	my ($self)=@_;
	#Test if we have a local and load it 
	Log::OK::DEBUG and log_debug __PACKAGE__." post_init: ". $self->meta->{_input_path};
		my $root=$self->meta->{root};
		my $locale=$self->args->{locale};
		for ( $self->meta->{_input_path}) {
			if(/\.plt$/ and -d "$root/$_/$locale" ){
			Log::OK::DEBUG and log_debug __PACKAGE__." post_init looking for locale ".$self->args->{locale};
				$self->[locale_sub_template_]//=$self->locale;
			}
		}
}

sub no_locale_out{
  my $self=shift;
  $self->args->{no_locale_out}=1;
}

#Adds a resource. Input is relatative to root (src)
#Output dir tree mirrors the in put tree
#If the table entry specifies a target field, this overrides the plt path
#This is most useful when a template renders other templates as content instead of links
#
sub add_resource {
	my ($self, $input, @options)=@_;
	#use the URLTable object in args 	
	my $table=$self->args->{table};
	$input=$table->add_resource($input, @options);
	
	#return the output relative path directly
	my $path=$table->map_input_to_output($input, $self->args->{target}//$self->args->{plt});
	return $path;

		
}

# Returns a path usable by IO (open etc). The input path is relative to either the src or build directory
#
sub sys_path_src {
  my $self=shift;
  my $path=shift;
  my $root=$self->meta->{root};
  # Return  the path relative to the the root (src) dir
  $root."/".$path;
}

sub sys_path_build {
  my $self=shift;
  my $path=shift;
  my $root=$self->args->{html_root};
  # Return  the path relative to the the root (src) dir
  $root."/".$path;
}


#  Returns a relative path from the current document to the resource expected
#  to already exist in the output/build dir
#  USE CASE: External data (ie video and jpack data) might already exist in the build  directory.
#           This function will give the required path for the document to access the file, without adding it as
#           an explicit resource in the url table (which is only for input resources)
#
#  NOTES: ASSUMES THE REFERENCE IS FILE NOT A DIRECTORY. ADD AN ARBITART COMPONENT TO REF IF IT IS A DIR
#
sub existing_resource {
  my $self=shift;
  my $path=shift;
  my $root=$self->args->{html_root};
  my $target="/".$root."/".$path;
  
  use Data::Dumper;
  # Get the output location of this template
  my $ref="/".$root."/".$self->output_path;

  # make a relative path from ref to target
  abs2rel($target, dirname $ref);
  

}



#resolves an input file relative to the nearest plt dir.
#Sets up the output so it is also relative to the output dir
sub add_plt_resource {
	my ($self, $input, %options)=@_;
	#input is relative to the closes plt dir
	my $plt_dir=$self->[input_path_];
	while($plt_dir ne "." and basename($plt_dir)!~/plt$/){
		$plt_dir=dirname $plt_dir;
	}
	$options{output}=catfile dirname($self->output_path), $input;
	my $plt_input= catfile($plt_dir,$input);
	$self->add_resource(
		$plt_input,
		%options
	);
	
}

# Path to a file inside a plt template. DOES NOT ADD AS RESOURCE
sub plt_path {
	my ($self, $input, %options)=@_;
	#input is relative to the closes plt dir
	my $plt_dir=$self->[input_path_];
	while($plt_dir ne "." and basename($plt_dir)!~/plt$/){
		$plt_dir=dirname $plt_dir;
	}
	$options{output}=catfile dirname($self->output_path), $input;
	my $plt_input= catfile($plt_dir,$input);
        ########################
        # $self->add_resource( #
        #         $plt_input,  #
        #         %options     #
        # );                   #
        ########################
	
}



# Construct the output path base on:
# locale if defined
# output location (dir)
# output name if defined or basename of input template (minus the plex)
sub output_path {
	my $self=shift;
	\my %config = $self->args;
	return unless $config{output};	 #no output path when no output setup

	my $name=$config{output}{name};
	unless($name){
		#No explict output name so use the basename of input
		#without any plex suffix
		$name =basename $self->meta->{file};
		$name=~s/\.plex$|\.plx$//;  #Ending in plex/plx extension
		$name=~s/(?:\.plex|\.plx)(?=\.)//;  #Not ending in plex/plx extension
	}

  my $no_locale=$config{output}{no_locale};
	my @comps=( 
    $no_locale?():($config{locale}//()),   #add locale only if we want it
    $config{output}{location}||(),                     #If no location ensure an empty list
                                                        #to force root
    $name);
	my $path=catfile @comps;
}


#When called updates the computed table entry output field
#CALLED FROM WITHING A TEMLPATE
sub output {
	my $self=shift;
	my %options=@_;
	my $output=$self->args->{output}||={};

	for(keys %options){

    # Clean up the location so it doesn't start with a slash
    # otherwise it breaks the output_path function
    #
    if($_ eq "location"){
      $options{$_}=~s|^/||;   
    }
    
		$output->{$_}=$options{$_};
	}
  #$output->{order}//=0;
	#update the table entry
	my $table=$self->args->{table}->table;
	my $entry=$table->{$self->args->{plt}};
	$entry->{output}=$self->output_path;
}

#Sets the values for a navigation item in a tree like structure
#CALLED FROM WITHIN A TEMPLATE
sub navi {
  my($self,%options)=@_;
  #Options include:
  # path: the path in the navitaiton tree
  # href: the explicit href for anchor. If not supplied defaul it the current page?
  # order:  relative ordering to other items at the same level
  # label:  whats actually shown 
  # icon:  graphics

  

  # URL table
	my $table=$self->args->{table}->table;

  # Table entry
	my $entry=$table->{$self->args->{plt}};

  \my %config=$entry->{template}{config};
  # Split the path and navigate to the level
  my @part=split m|/|, $options{path};

  my $parent=$config{nav}; #Root of nav object
  my $inc_path="";
  for my $part (@part){
    $parent = $parent->{$part}//={
      _data => {
        path=>$inc_path
      }
    };
    $inc_path .= "/";
  }


  #Copy the values
  my $data=$parent->{_data};
  for my ($k, $v) (%options){
      $data->{$k}=$v;
  }

  # Set the order to match render order if one wasn't supplied
  $data->{order}//=$entry->{template}{config}{output}{order};

  # If no href use the plt or the target
  $data->{href}//=$self->args->{target}//$self->args->{plt};

  #If just a fragment fix it to the plt path or target path
  if($data->{href} =~ /^#/){
    # Fragment ... append plt path
    $data->{href}=($self->args->{target}//$self->args->{plt}).$data->{href};
  }
}


sub lander {
	my $self=shift;
	my %options=@_;

	my $table=$self->args->{table}->table;
	my $entry=$table->{$self->args->{plt}};
	$entry->{lander}=\%options;

	
}

#Only works for plt templates
# Like a load call, but uses the information about the locale to 
# load a sub template
sub locale {
	my ($self, $lang_code)=@_;
	return $self->[locale_sub_template_] if $self->[locale_sub_template_];

	Log::OK::TRACE and log_trace __PACKAGE__." locale";
	my $dir=$self->meta->{_input_path};
	my $basename=basename $self->meta->{file};
	unless($lang_code){
		$lang_code=$self->args->{locale};
	}
	my $lang_template;
	if($lang_code){
		$lang_template=catfile $dir,$lang_code//(), $basename;
		try {
			$self->[locale_sub_template_]=$self->load($lang_template, $self->args, $self->meta->%*);
		}
		catch($e){
			Log::OK::WARN and log_warn __PACKAGE__." Could not render template $lang_template. Using empty tempalte instead";
			Log::OK::WARN and log_warn __PACKAGE__." $e";
			$self->[locale_sub_template_]=Template::Plex->load([""]);#, $self->args, $self->meta->%*);

		}
	}
	else{
		#Log::OK::WARN and log_warn __PACKAGE__." no file found for locale=>$lang_code";

		$lang_template=[""];	
		#Dummy template
		#Log::OK::WARN and log_warn __PACKAGE__." attempt to render non existent locale template. Using empty tempalte instead";
		$self->[locale_sub_template_]=Template::Plex->load([""]);#, $self->args, $self->meta->%*);
	}
}

sub build{
	my $self=shift;
  my ($fields)=@_;
  
	my $result=$self->SUPER::render(@_);


  #unless($fields->{no_file}){
    my $file=catfile $self->args->{html_root}, $self->output_path;
    mkpath dirname $file;		#make dir for output

    my $fh;
    unless(open $fh, ">", $file){
      Log::OK::ERROR and log_error "Could not open output location file $file";
    }

    Log::OK::DEBUG and log_debug("writing to file $file");
    print $fh $result;
    close $fh;

    #copy any resources this template neeeds?


    # Setup lander
    #

    my $table=$self->args->{table}->table;
    my $entry=$table->{$self->args->{plt}};
    my $lander=$entry->{lander};

    if($lander){
      $lander->{location}//="";
      $lander->{name}//="index.lander";
      $lander->{type}//="refresh";

      
      my $html_root=$self->args->{html_root};
      my $link=catfile($html_root, $lander->{location}, $lander->{name});

      if( -e $link){
        Log::OK::INFO and log_info("removing existing lander link");
        unlink $link;
      }

      for($lander->{type}){
        if(/refresh/){
          # Spit out a html with meta tag for refresh
          open my $fh, ">", $link;
          print $fh qq|
          <html>
            <head>
              <meta http-equiv="refresh" content="0; url=@{[$self->output_path]}">
            </head>
          </html>
          |;

        }
        elsif(/symlink/){
          #Log::OK::INFO and log_info("Lander for ".$self->output_path." => ".$self->[lander_]);

          symlink $self->output_path, $link;#$self->args->{input};
        }
        else{
          # Unkown lander config
        }
      }
    }
    #}
  $result;
}





1;

__END__

=head1 NAME

Template::Plexsite - Class for interlinked templating

=head1 DESCRIPTION

A subclass of L<Template::Plex> which facilitates rendering hierrarchial
templates which are interlinked with one another. It works together with
L<Tempalte::Plexsite::URLTable> to render template to the correct output
location and utilise resources



=head1 API

=head2 output

Computes and returns the path to the output location this tempalte will render to. When
called updates the C<output> attribute in the URLTable object

=head2 locale

Loads a sub template specified by the locale key and returns it. The templates
is searched for in a dir which matches the locale name. The template is not
rendered


=head2 add resource

Adds a resource to the associate URLTable. Returns the resource in OUTPUT namespace


=head2 add_plt_resource

