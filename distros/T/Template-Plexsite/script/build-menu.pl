use strict;
use warnings;
no warnings "experimental";


#Url table maps input file paths relative to input root, to 
#output urls usable by a web client

#	$root is the root of the project. All inputs are ultimately relative to this location
#	$html_root is the output dir which contains your site/rendered/copied files
#
# The $location entry in a Plexsite template specified as an abs path. which is the OUTPUT url
# This is appended to the $html_root to give the location on disk

# local resources in a template are specifed relative to the template
#
#
# When processing a template a transformed url table is passed as a variable.
# The transformation makes all output urls relative to the current output level
#
#
# Each plt is preprocessed with it's own variable set
# A reference to a global url_table and nav hashes allows relative building


use Log::ger;
use Log::ger::Output "Screen";
use Log::ger::Util;

use Log::OK {
	lvl=>"info",
	opt=>"verbose"
};

Log::ger::Util::set_level(Log::OK::LEVEL);


use feature qw<say>;
use File::Basename qw<basename dirname>;
use File::Spec::Functions qw<rel2abs abs2rel>;
use Cwd qw<realpath>;
use File::Path qw<mkpath>;
use File::Copy;
use Data::Dumper;

use Template::Plex;
use Template::Plexsite;

use JSON;

#use GetOpt::Long;
use feature ":all";

my $html_root="site";

#Takes a list or multiple input templates
#Generates a table mapping template path to  output path and tag name

my %tag_table; #maps tags to outputs
my %url_table; #maps input filename to output urls

#Do preprocess

my @stages=("preprocess","process");


my %opts;
$opts{base}="Template::Plexsite";
$opts{use}=["Template::Plexsite"];
$opts{root}="src";

my %nav=(
	_data=>{
		label=>"TOP",
		href=>$url_table{"templates/about.plex"}
	}
);
\my $root=\$opts{root};


my $stage_count=1;
Log::OK::INFO and log_info "Stage $stage_count: Building url table from inputs";
$stage_count++;

#First pass config stages for each input file

my %templates;
my %configs;

for(@ARGV){

	
	#Skip if input is not a plt dir
	 next unless /plt$/;

	\my %config={};
	#Convert path to relative path from root
	my $input=abs2rel realpath($_), $root;

$config{url_table}=\%url_table;
$config{html_root}=$html_root;
$config{locale}="en";

$config{nav}=\%nav;
#$config{input};
$config{menu}=undef;

	
	Log::OK::INFO and log_info "Processing $_";
	$config{output}={};#undef;#"/dev/null";
	$config{input}=$input;


	$configs{$input}=\%config;

	#Test the type of index file
	my ($index_file)= <"$root/$input/index.*" >;
	my $target;
	my $src;
	if($index_file=~/html/){
		$src="index.html.plex";
		$target="index.html";
	}
	elsif($index_file=~/css/){
		$src="index.css.plex";
		$target="index.css";
	}
	else{
		$target="index.unkown";
	}

	#Inputs are dirs with plt extensions. A index.html page exists inside
	my $template=plex $input."/".$src, $configs{$input}, %opts;
	my $result=$template->setup;#render;

	#If Output variable is set, we can add it to the list
	if($config{output}{location}){
		#Process menu entry if required
		#
		if($config{menu}){
			Log::OK::DEBUG and log_debug "Template sets a menu entry. Adding to navication";
			#Split the menu item
			my @parts=split m|/|, $config{menu}{path};
			Log::OK::DEBUG and log_debug "Menu path will be: ", join ", ", @parts;
			my $parent=$config{nav};

			for(@parts){
				$parent = $parent->{$_}//={};
			}

			$parent->{_data}{href}//=$input;

			for( keys $config{menu}->%*){
				next if $_ eq "path";
				$parent->{_data}{$_}=$config{menu}{$_};
			}
		}
			
		
		#add entry to output file table
		$url_table{$input}=$config{locale}."/".$config{output}{location}."/".$target;


		$templates{$input}=$template;
	}
	NONE:
}
#Log::OK::INFO and log_info Dumper \%url_table;

#Process url table to generate multiple tables base on dir levels
for my $val (values %url_table){
	$val =~ s|^/||;
};


#Prepare layout here to add any resources to the url table
my %layout_config;

$layout_config{slot}="";
$layout_config{url_table}=\%url_table;
$layout_config{nav}=\%nav;
$layout_config{locale}="en";
$layout_config{output}="";
my $layout=plex "templates/page.plex", \%layout_config, %opts;


#Run any initialisation code for page layout the layout
$layout->setup;#render;


## Create url tables which create outputs relative to output directories
# The relative table is passed to the template at that dir level to allow 
# correct relative resolving of resources
my %dir_table;
for my $input_path(keys %url_table){
	my $output_path=$url_table{$input_path};

	my $dir=dirname $output_path;
	next if $dir_table{$dir};
	my $base=basename $output_path;
	for my $input_path (keys %url_table){
		my $output_path=$url_table{$input_path};
		my $rel=abs2rel $output_path, $dir;
		$dir_table{$dir}{$input_path}=$rel;
	}
}


Log::OK::INFO and log_info "Stage $stage_count: Rendering outputs";
$stage_count++;

for my $arg (@ARGV){
	#Convert path to relative path from root
	my $input=abs2rel realpath($arg), $root;
	next unless $templates{$input};
	#lookup output  from main table
	my $out=$url_table{$input};

	#lookup relative table
	my $dir=dirname $out;
	my $table=$dir_table{$dir};
	$layout_config{url_table}=$table;

	$configs{$input}{url_table}=$table;
	
	my $result;
	my $name;
	if($input=~/plt/){
		$name=basename $templates{$input}->meta->{file};
		$name=~s/\.plex$//;


		if($templates{$input}->meta->{file}=~/html/i){
			Log::OK::INFO and log_info "$input: Rendering as HTML";


			$layout_config{slot}=$templates{$input}->render;
			$layout_config{output}=$templates{$input}->args->{output};
			
			$result=$layout->render;
		}
		elsif($templates{$input}->meta->{file}=~/css/i){
			Log::OK::INFO and log_info "$input: Rendering as CSS";
			$result=$templates{$input}->render;

		}
		else {

		}
	}
	else {
		#Log::OK::WARN and log_warn "Unkown type";
		$result="";
	}

	#Config from each tempalte
	\my %config=$configs{$input};
	$dir = $config{locale}."/".$config{output}{location};
	$dir= "$html_root/$dir";

	#TODO: language options here?
	my $file= $dir."/".$name;#"index.html";

	mkpath $dir;

	my $fh;
	unless(open $fh, ">", $file){
		Log::OK::ERROR and log_error "Could not open output location file $file";
	}
	Log::OK::DEBUG and log_debug("writing to file $file");
	print $fh $result;

	close $fh;


}

#write files to output dir

Log::OK::INFO and log_info "Stage $stage_count: Copying resources";
$stage_count++;

for(keys %url_table){
	my $input=$_;
	my $output=$url_table{$input};

	next if($input=~/plt$/);

	$input=$root."/".$input;
	$output=$html_root."/".$output;
	my @stat_in=stat $input;
	my @stat_out=stat $output;
	unless(@stat_in){
		Log::OK::WARN and log_warn "Could not locate input: $input";
		next;
	}

	if($stat_out[9] < $stat_in[9]){
		Log::OK::INFO and log_info("COPY $input=> $output");
		copy $input, $output;
	}
	else {
		Log::OK::DEBUG and log_debug("Upto date: $input=> $output");
	}
}

#say Dumper \%url_table;
#say Dumper \%nav;
Log::OK::INFO and log_info "Stage $stage_count: Writing site map";
$stage_count++;

my $menu=Template::Plexsite::json_menu \%nav, \%url_table;

my $json_menu=encode_json $menu;
#write to site as menu file?
my $fh;
my $file=$html_root."/menu.json";
unless(open $fh, ">", $file){
	warn "Could not create menu.json file $file";
}

print $fh $json_menu;
close $fh;

