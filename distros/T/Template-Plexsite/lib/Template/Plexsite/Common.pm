package Template::Plexsite::Common;


use feature qw<say current_sub refaliasing>;

use Log::ger;
use Log::OK {
	lvl=>"info"
};
use Template::Plex;
use Time::HiRes qw<time>;
use File::Basename qw<dirname basename>;
use File::Spec::Functions qw<abs2rel rel2abs>;

use List::Util qw<any pairs>;
use Exporter 'import';
use Data::Dumper;




our @EXPORT_OK=qw<
html_unordered_list
html_ordered_list

build_time
section_start
section_end
div_script
html_menu
json_menu


>;

our @EXPORT=@EXPORT_OK;




sub html_unordered_list {

	"<ul>"
	.(Template::Plex::jmap {;"<li>$_</li>"} @_)
	."</ul>"

}
sub html_ordered_list {
	"<ol>"
	.(Template::Plex::jmap {;"<li>$_</li>"} @_)
	."</ol>"
}

sub build_time {
	"<span>Built using Template::Plex @ ".time."</span>";
}

sub section_start {
	
	my %options=@_;
	my $out='<div class="section_wrapper"> <div ';
	$out.=qq|id="$options{id}"| if $options{id};
	$out.=qq|class="|.join(" ", "section", $options{class}).'"';
	$out.=">\n";
	$out;
}

sub section_end {
	'</div>
	<div class="section_gutter"></div>

	</div>'
}

sub div_script {
	my $content=pop;
	my %options=@_;
	my $out="<div id=\"$options{id}\"><script>\n";
	$out.=$content;
	$out.="</script></div>";
	$out;
}

sub _sort_children{
	my ($level)=@_;
	sort {$a->[1]{_data}{order} <=> $b->[1]{_data}{order}}
	map {$_->[1]{_data}{order}//0; $_; }
	grep {$_->[0] ne "_data"}
	pairs $level->%*;
}

sub json_menu {
	my ($nav, $url_table, $object)=@_;
	my $first;
	unless(defined $object){
		$first=1;
		$object={};
	}
	#Convert hash structure into json
	
	#_data becomes data (with noe specific details)
	#_data->label becomes name?
	#all remaining entries get added to children
	
	$object->{name}=$nav->{_data}{label};
	$object->{data}->%*=$nav->{_data}->%*; #copy
	$object->{data}{href}=$url_table->{$nav->{_data}{href}};

	#delete $object->{data}{label};

	
	my @children=_sort_children $nav;


	for(@children){
		push $object->{children}->@*, __SUB__->($_->[1], $url_table);
	}

	$object;

}

# Build up links in a html navigation menu, relative to $base href in nav
# entries are input origin, so need to be converted by table
# Each level of the menu is sub div
#
sub html_menu{
	my ($menu_path, $nav, $url_table, $base)=@_;
  # $menu_path is the unix style file path into the menu 
  # $nav is the accumulated nav structure representing the entire menu
  # $url_table is the url mapping table
  # $base is the base for relative uril (input name space) 
  #

  #say Dumper $nav;  


	my $nav_class="menu_html_container";
	my $list_class="menu_list";
	my $item_class="menu_list_item";
	my $seq=0;
	my $css="
		.menu_label {
			width:100%;
			display:block;
		}
    .menu_label.active {
      color:blue;
    }
		ul.$list_class {
			padding:0;
		}

		li.$item_class {
			padding:0;	
		}
	";
	my $do_level =sub {
		$seq++;
		#sleep 1;
		my $level=shift;
		my $i=shift;
		my $output="";


    #find the current max order
    my $max; 
    my @pairs=
      grep {$_->[0] ne "_data"}
      pairs $level->%*;

    for my $p (@pairs){
      for($p->[1]{_data}{order}){
        
        unless(defined($max)){
          $max=$_;
          next;
        }
        $max=$_ if $_>$max;
      }
    }
    $max//=0;


		#Order the children in level according to order field
		my @stack= 
		sort {$a->[1]{_data}{order} <=> $b->[1]{_data}{order}}
		map {$_->[1]{_data}{order}//= ++$max; $_; }
    @pairs;
    #grep {$_->[0] ne "_data"}
    #pairs $level->%*;


		#render _data first
		$output.="<nav class=\"$nav_class\"><ul class=\"$list_class\">" unless $i;
    
		for($level->{_data}){
      my $checked=(index($menu_path, $_->{path})==0) ?"checked":"";
      if($checked){
        #say "Nav path: ".$_->{path};
        #say "Active path: ".$menu_path;

      }
      #say "CHECKED: $checked";
			$_->{href}=~ s|^/||;
			$output.="<li class=\"$item_class\">";
			$output.="<input type=\"checkbox\" id=\"input_$seq\" class=\"hidden_checkbox\" $checked></input>" if @stack;

			$css.=qq|.$item_class> #input_$seq:checked ~ .item ~ ul {
				display:block;
			}
			.$item_class> #input_$seq ~ .item ~ ul {
				background-color: orange;
				display:none;
			}
			| if @stack;

			$output.="<div class=\"item\">";
      my $active=$menu_label eq $_->{path};

      #say "ACTIVE: $active";
			$output.="<label class=\"menu_label\" for=\"input_$seq\" id=\"label_$seq\">" if @stack;

			$output.="<a href=\"".($url_table->map_input_to_output($_->{href}, $base))."\">$_->{label}</a></label>
			</div>\n";
			$output.="\n";
		}

		$output.="<ul class=\"$list_class\">";


		for(@stack){
			$output.=__SUB__->($_->[1], $i+1);
		}

		$output.="</ul></li>";
		$output.="</ul><nav>" unless $i;

		$output;
	};
	my $tmp=$do_level->($nav,0);
	"<style>$css</style>".$tmp;
}


## METHODS
#

sub pre_init {
	
}

sub post_init{
}

#Loads and initializes a sub template base on the selected locale
sub locale2 {
	my ($self, $lang_code)=@_;
	my $dir=dirname $self->meta->{file};
	my $basename=basename $self->meta->{file};
	unless($lang_code){
		$lang_code=$self->locale_code;
	}

	$lang_template=$dir."/".$lang_code."/".$basename;

	#test if file exists, if note we use an inline temlpate
	if(-f $self->meta->{root}."/".$lang_template){
		$lang_template;	
	}
	else {
		$lang_template=[""];	
	}
	my $template= plex $lang_template, $self->args, $self->meta->%*;
	$template->setup;	
	$template
}

#adds static files. Path given is relative to the plt dir currently active
sub add_plt_resource {
	#add resource to the url table
	my ($self, $input, $output)=@_;

	my $url_table=$self->args->{url_table};
	my $t_out=$self->args->{output};
	my $input_plt=$self->args->{input};
	my $locale=$self->args->{locale};

	#input is relative to template root
	
	#output if present is relative to output root
		
	#If output is not present, resource will be placed in sub dir of this template
	

	my $root=$self->meta->{root};
	

	#add to url table	
	unless($output){
		$output=$t_out->{location}."/".$input;
	}

	my $in=$input_plt."/".$input;
	$url_table->@{$in}=($locale."/".$output);
	$in;
}

#Relative to project root
sub add_resource {
	#add resource to the url table
	my ($self, $input, $output)=@_;

	my $url_table=$self->args->{url_table};
	my $t_out=$self->args->{output};
	#my $input_plt=$self->args->{input};
	my $locale=$self->args->{locale};

	#input is relative to template root
	
	#output if present is relative to output root
		
	#If output is not present, resource will be placed in sub dir of this template
	

	my $root=$self->meta->{root};

	#Test if input is infact a dir
	my $path=$root."/".$input;
	
	if(-d $path){
		my @stack;
		my @inputs;
		#recursivy add resources
		#
		push @stack, $path;	
	
		while(@stack){
			my $item=pop @stack;
			Log::OK::DEBUG	 and log_debug "Plexsite: TESTING item  $item";
			if( -d $item){
				push @stack, <"$item/*">;
			}
			else {
				push @inputs, $item;
			}
		}
		
		for(@inputs){
			#strip root from working dir relative paths from globbing
			s/^$root\///;

			$url_table->@{$_}=($_);
		}
		@inputs;

	}
	else {
		#Assume a file
		#add to url table	
		unless($output){
			$output=$input; #$t_out->{location}."/".$input;
		}

		my $in=$input;
		$url_table->@{$in}=($output);
		$in;
	}
}


sub locale_code {
	$_[0]->args->{locale};
}
sub test {
	"TEST METHOD CALLED";
}

#Variables used in EACh templates
#	$output
#		hash with  location and title files
#			location is url location
#			title is page title
#	$menu
#		hash with 
#			order	relative oder within the level
#			path	url path to resoource
#			label	label to display
#			icon	icon to use
#	$publish
#		bool
#			process this template?
#
#
#Variables   ACCUMULATING and stateful
#	$nav
#		hash with built up from menu fieldjs
#	$url
#		hash all resources added relative to the current template output	

1;
