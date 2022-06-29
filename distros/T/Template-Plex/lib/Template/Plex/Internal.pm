package Template::Plex::Internal;
use strict;
use warnings;

use Template::Plex;

use List::Util qw<min max>;

#use Symbol qw<delete_package>;
use Carp qw<carp croak>;

use feature qw<state refaliasing>;
no warnings "experimental";

#use File::Basename qw<dirname basename>;
use File::Spec::Functions qw<catfile>;
use File::Basename qw<dirname>;
use Exporter 'import';


#our %EXPORT_TAGS = ( 'all' => [ qw( plex plx  block pl plex_clear jmap) ] );

our @EXPORT_OK = qw<block pl jmap>;# @{ $EXPORT_TAGS{'all'} } );


my $Include=qr|\@\{\s*\[\s*include\s*\(\s*(.*?)\s*\)\s*\] \s* \}|x;
my $Init=qr|\@\{\s*\[\s*init\s*\{(?:.*?)\}\s*\] \s* \}|smx;


sub new;	#forward declare new;

sub lexical{
	my $href=shift;
	croak "NEED A HASH REF " unless  ref $href eq "HASH" or !defined $href;
	$href//={};
	\my %fields=$href;

	my $string="";
	for my $k (keys %fields){
		$string.= "\\my \$$k=\\\$fields{$k};\n";
	}
	$string;
}

sub  bootstrap{
	my $plex=shift;
	\my $_data_=\shift;
	my $href=shift;
	my %opts=@_;

	$href//={};
	\my %fields=$href;

my $out="package $opts{package} {
use Template::Plex::Internal qw<pl block jmap>;
no warnings qw<syntax>;
";

$out.='my $self=$plex;
';

$out.= '	\my %fields=$href;
';
$out.='		my %options=%opts; 
' if keys %opts;
                for($opts{use}->@*){
			$out.="use $_;\n";
                }
                for($opts{inject}->@*){
			$out.="$_\n";
                }

$out.=lexical($href) unless $opts{no_alias};		#add aliased variables	from hash
$out.='
	my %cache;	#Stores code refs using caller as keys

	sub clear {
		%cache=();
	}

        sub skip{
		goto _PLEX_SKIP;
        }

	$plex->[Template::Plex::skip_]=\&skip;


	sub init :prototype(&){
		$self->_init(@_);
	}

	sub slot {
		$self->slot(@_);
	}
	sub fill_slot {
		$self->fill_slot(@_);
	}
	sub inherit {
		$self->inherit(@_);
	}

	sub load {
		$self->load(@_);
	}

	sub cache {

		my ($id, $path, $var, @opts)=@_;
		#we want to cache based on the caller
		$id=$path.join "", caller;
		#unshift @_, $id;
		$self->cache($id,$path, $var,@opts);
	}

	sub immediate {
		my ($id, $path, $var, @opts)=@_;
		#we want to cache based on the caller
		$id=$path.join "", caller;
		my $template=$self->cache($id, $path,$var, @opts);
		if($template){
			return $template->render;
		}
		"";
	}


	sub {
		no warnings \'uninitialized\';
		no strict;
		#my $plex=shift;
		my $self=shift;

		\\my %fields=shift//\\%fields;


		##__START
return $self->prefix.
qq
{'.
$_data_ 
. '}
.$self->postfix;

		_PLEX_SKIP:
		"";

	}
};';

};

# First argument the template string/text. This is any valid perl code
# Second argument is a hash ref to default or base level fields
# returns a code reference which when called renders the template with the values
sub _prepare_template{
	no warnings qw<syntax>;
	my ($plex, undef, $href, %opts)=@_;
	$href//={};
	\my %fields=$href;
	\my %meta=\%opts;

	#$plex now variable is now of base class
	$plex=($opts{base}//"Template::Plex")->new($plex);

	$plex->[Template::Plex::meta_]=\%opts;
	$plex->[Template::Plex::args_]=$href;

	my $prog=&Template::Plex::Internal::bootstrap;
 	my $ref=eval $prog;
	if($@ and !$ref){
		my $error=$@;

		my $line=1;
		my $start;
		#my @lines=map { $start= $line if /##__START/;$line++ . $_."\n"; } split "\n", $prog;
		my @lines=map { $start = $line if /##__START/; $line++;$_."\n" } split "\n", $prog;
		$start+=2;
		my @error_lines;

		$error=~s/line (\d+)/do{push @error_lines, $1;"line ".($1-$start)}/eg;
		$error=~s/\(eval (\d+)\)/"(".$opts{file}.")"/eg;

		my $min=min @error_lines;
		my $max=$min;#max @error_lines;
		#print  "max: $max\n";
		$min-=5; $min=$start if $min<$start;
		$max+=5; $max=$#lines-7 if $max>($#lines-7);
		my $counter=$min-$start+1;
		my $out=$error;
		for ($min..$max){
			$out.=$counter++."  ".$lines[$_];
		}
		croak $out;
	}
	$plex->[Template::Plex::sub_]=$ref;
	$plex;
}

#a little helper to allow 'including' templates into each other
sub _munge {
	my ($input, %options)=@_;

	#test for literals
	my $path;	
	if($input =~ /^"(.*)"$/){
		#literal		
		$path=$1;	
	}
	elsif($input =~ /^'(.*)'$/){
		#literal		
		$path=$1;	
	}
	else {
		#not supported?
		#
	}
	Template::Plex::Internal->new(\&_prepare_template,$path,"",%options);	
}

sub _subst_inject {
	\my $buffer=\(shift);
	while($buffer=~s|$Include|_munge($1, @_)|e){
		#TODO: Possible point for diagnostics?
	};
}

sub _block_fix {
	#remove any new line immediately after a ]} pair
	\my $buffer=\(shift);
	#$buffer=~s/^\]\}$/]}/gms;
	
	$buffer=~s/^(\@\{\[.*?\]\})\n/$1/gms;
        ##############################################
        # while($buffer=~s/^\]\}\n/]}/gs){           #
        # }                                          #
        # while($buffer=~s/^(@\{\[.*?\]\})\n/$1/gs){ #
        # }                                          #
        ##############################################

}

sub _init_fix{
	\my $buffer=\$_[0];
	#Look for an init block
	#unless($buffer=~/\@\[\{\s*init\s*\{
	unless($buffer=~$Init){
		#carp __PACKAGE__." no init block detected. Adding dummy";
		$buffer="\@{[init{}]}".$buffer;
	}
}

my $prepare=\&_prepare_template;

my %cache;


sub clear {
	%cache=();
}


sub block :prototype(&) {
	$_[0]->();
	return "";
}
*pl=\*block;



sub new{
	my $plex=bless [], shift;
	my ($prepare, $path, $args, %options)=@_;
	my $root=$options{root};
	#croak "plex: even number of arguments required" if (@_-1)%2;
	croak "Template::Plex::Internal first argument must be defined" unless defined $path;
	#croak "plex: at least 2 arguments needed" if ((@_-1) < 2);

	my $data=do {
		local $/=undef;
		if(ref($path) eq "GLOB"){
			#file handle
			$options{file}="$path";
			<$path>;
		}
		elsif(ref($path) eq "ARRAY"){
			#process as inline template
			$options{file}="$path";
			join "", @$path;
		}
		else{
			#Assume a path
			#Prepend the root if present
			$options{file}=$path;
			$path=catfile $root, $path if $root;
			my $fh;
			if(open $fh, "<", $path){
				<$fh> 
			}
			else {
				croak "Could not open file: $path $!";
				"";
			}
		}
	};

	$args//={};		#set to empty hash if not defined
	
	chomp $data unless $options{no_eof_chomp};
	#Perform inject substitution
	_subst_inject($data, root=>$root) unless $options{no_include};
	#Perform suppurfluous EOL removal
	_block_fix($data) unless $options{no_block_fix};
	_init_fix($data) unless $options{no_init_fix};
	if($args){
		#Only call this from top level call
		#Returns the render sub

		state $package=0;
		$package++;
		$options{package}="Template::Plex::temp".$package; #force a unique package if non specified
		$prepare->($plex, $data, $args, %options);	#Prepare in the correct scope
	}
	else {
		$data;
	}
}


#Join map
sub jmap :prototype(&$@){
	my ($sub,$delimiter)=(shift,shift);	#block is first
	$delimiter//="";	#delimiter is whats left
	join $delimiter, map &$sub, @_;
}



1;
