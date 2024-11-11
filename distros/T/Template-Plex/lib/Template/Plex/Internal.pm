package Template::Plex::Internal;
use strict;
use warnings;

use Template::Plex;


use feature qw<state refaliasing>;
no warnings "experimental";

use File::Spec::Functions qw<file_name_is_absolute>;

use Export::These qw<block pl jmap>;

my $Include=qr|\@\{\s*\[\s*include\s*\(\s*(.*?)\s*\)\s*\] \s* \}|x;
my $Init=qr|\@\{\s*\[\s*init\s*\{(?:.*?)\}\s*\] \s* \}|smx;

# Match any curly bracket not contained withing a @{[ ]} block
#my $plain=qr/(?<! \@\{ \s* \[) (?:\{ \| \}) (?!\] \s* \})/smx;


sub new;	#forward declare new;

sub lexical{
	my $href=shift;
	die "NEED A HASH REF " unless  ref $href eq "HASH" or !defined $href;
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

	sub parent {
		$self->parent(@_);
	}
	sub slot {
		$self->slot(@_);
	}
	sub fill_slot {
		$self->fill_slot(@_);
	}
	sub append_slot {
		$self->append_slot(@_);
	}

	sub prepend_slot {
		$self->prepend_slot(@_);
	}

  sub fill_var{
    my $name=shift;
    no strict "refs";
    $$name=shift;
    "";
  }

  sub append_var{
    my $name=shift;
    no strict "refs";
    $$name .= shift;
    "";

  }
  sub prepend_var{
    my $name=shift;
    no strict "refs";
    $$name = shift . $$name;
    "";

  }


	sub inherit {
		$self->inherit(@_);
	}

	sub load {
		$self->load(@_);
	}

	sub cache {
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

		my ($id, $path, $var, @opts)=@args;
		#we want to cache based on the caller
		$id=$path.join "", caller;
		#unshift @_, $id;
		$self->cache($id,$path, $var,@opts);
	}

	sub immediate {
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
		my ($id, $path, $var, @opts)=@args;
		#we want to cache based on the caller
		$id=$path.join "", caller;
		my $template=$self->cache($id, $path,$var, @opts);
		if($template){
			return $template->render($var);
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
  ##__END
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
    my $e=$@; #Save the error as require will nuke it
    require Error::Show;
    my $context=Error::Show::context(error=>$e, program=>$prog,
      start_mark=>'##__START',
      end_mark=>'##__END',
      start_offset=>2,
      end_offset=>5,
      limit=>1
    );
    # Replace the pseudo filename with the file name if we have one 
    my $filename=$meta{file};
    $context=~s/(\(eval \d+\))/$filename/g;
    # Rethrow the exception, translated context line numbers
		die $context;
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
	
	$buffer=~s/^(\s*\@\{\[.*?\]\})\n/$1/gms;
}

sub _comment_strip {
  \my $buffer=\(shift);
  $buffer=~s/^\s*#.*?\n//gms;
}


sub _init_fix{
	\my $buffer=\$_[0];
	#Look for an init block
	#unless($buffer=~/\@\[\{\s*init\s*\{
	unless($buffer=~$Init){
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
	die "Template::Plex::Internal first argument must be defined" unless defined $path;

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
    elsif(ref($path) eq "SCALAR"){
      # Make relative to callers path
      my $cpath=$options{caller}->meta->{file};
      use File::Basename "dirname";
      my $rpath=dirname $cpath;
      $rpath.="/".$$path;
      $options{file}=$rpath;

			my $fh;
			if(open $fh, "<", $rpath){
				<$fh> 
			}
			else {
				die "Could not open file: $rpath $!";
				"";
			}
    }
		else{
			#Assume a path
			#Prepend the root if present and if not absolute
      

      # only prepend root if relative path
      #unless($path=~m|^/|){
      unless(file_name_is_absolute($path)){
        # Assume working dir if no root
        $path=join "/", $root, $path if $root;
      }
			$options{file}=$path;

			my $fh;
			if(open $fh, "<", $path){
				<$fh> 
			}
			else {
				die "Could not open file: $path $!";
				"";
			}
		}
	};

	$args//={};		#set to empty hash if not defined
	
	chomp $data unless $options{no_eof_chomp};
	# Perform inject substitution
  #
	_subst_inject($data, root=>$root) unless $options{no_include};
	# Perform superfluous EOL removal
  #
	_block_fix($data) unless $options{no_block_fix};
	_init_fix($data) unless $options{no_init_fix};
  _comment_strip($data) if $options{use_comments};

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
