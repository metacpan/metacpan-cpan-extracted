package Pod::Autopod; ## Generates pod documentation by analysing perl modules.
$Pod::Autopod::VERSION = '1.215';
use 5.006; #Pod::Abstract uses features of 5.6
use FileHandle;
use strict;
use Pod::Abstract;
use Pod::Abstract::BuildNode qw(node nodes);


# This Module is designed to generate pod documentation of a perl class by analysing its code.
# The idea is to have something similar like javadoc. So it uses also comments written directly
# obove the method definitions. It is designed to asumes a pm file which represents a class.
# 
# Of course it can not understand every kind of syntax, parameters, etc. But the plan is to improve
# this library in the future to understand more and more automatically.
#
# Please note, there is also an "autopod" command line util in this package.
#
#
# SYNOPSIS
# ========
#
#  use Pod::Autopod;
#
#  new Pod::Autopod(readfile=>'Foo.pm', writefile=>'Foo2.pm');
# 
#  # reading Foo.pm and writing Foo2.pm but with pod
#
#
#  my $ap = new Pod::Autopod(readfile=>'Foo.pm');
#  print $ap->getPod();
#
#  # reading and Foo.pm and prints the generated pod. 
#
#  my $ap = new Pod::Autopod();
#  $ap->setPerlCode($mycode);
#  print $ap->getPod();
#  $ap->writeFile('out.pod');
#
#  # asumes perl code in $mycoce and prints out the pod.
#  # also writes to the file out.pod
#
#
# HOWTO
# =====
# 
# To add a documentation about a method, write it with a classical remark char "#" 
# before the sub{} definition:
#
#  # This method is doing foo.
#  #
#  #  print $self->foo();
#  #
#  # 
#  # It is not doing bar, only foo.
#  sub foo{
#	   ...
#  }
#
# A gap before sub{} is allowed.
#
# In further versions of autopod, here new features will appear.
#
# To define parameters and return values you can use a boundle of keywords.
# So far parameters and return values can not realy be autodetected, so manual
# way is necessary, but it is designed to type it rapidly.
#
#  sub foo{ # void ($text)
#	  ...
#  }
#
# The example above produces the following method description: 
#
#  $self->foo($text);
#
# The object "$self" is the default and automatially used when a constructor was found ("new")
# or the class inherits with ISA or "use base".
# You can change this by the parameter "selfstring" in the autopod constructor.
#
# The example looks simple, but the engine does more than you think. Please have a look here:
#
#  sub foo{ # void (scalar text)
#	  ...
#  }
#  
# That procudes the same output! It means the dollar sign of the first example is a symbol which means "scalar".
#
#  sub foo{ # ($)
#	  ...
#  }
#
# Produces:
#
#  $self->foo($scalar);
#
# As you see, that was the quickest way to write the definition. The keywork "void" is default.
#
# The following keywords or characters are allowed:
#
#	 array       @
#	 arrayref   \@
#	 hash        %
#	 hashref    \%
#	 method      &
#	 scalar      $
#	 scalarref  \$
#  void       only as return value
#
# Now a more complex example:
#
#  sub foo{# $state ($firstname,$lastname,\%persondata)
#  ...
#  }
#
# produces:
#
#  my $state = $self->foo($firstname, $lastname, \%persondata);
#
# or write it in java style:
#
#  sub foo{# scalar state (scalar firstname,scalar lastname,hashref persondata)
#  ...
#  }
#
# Multiple return values may be displayed as following:
# 
#  sub foo{# $a,$b ($text)
#  ...
#  }
#
# produces:
#
#  my ($a, $b) = $self->foo($text);
#
#
# If you want to use key values pairs as in a hash, you may describe it like:
#
#  sub foo{# void (firstname=>$scalar,lastname=>scalar)
#  ...
#  }
#
# The second "scalar" above is without a "$", that is no mistake, both works.
# 
# There is also a way to expain that a value A OR B is expected. See here:
#
#  sub foo{# $lista|\$refb (\@list|$text,$flag)
#  ...
#  }
#
# procudes:
#
#   my $lista | \$refb = $self->foo(\@list | $text, $flag);
#
# Of course, that is not an official perl syntax with the or "|", but it shows
# you that is expected.
#
#
# In the First Part obove all method descriptions, you can add general informations, which are
# per default displayed under the head item "DESCRIPTION". But also own items can be used by
# underlining a text with "=" chars like:
#
#  # HOWTO
#  # =====
#  # Read here howto do it.   
#
# Some of these title keywords are allways places in a special order, which you can not change. For
# example LICENSE is allways near the end.
#
# Added some hacks to teach this tool also some doxygen parametes. For example:
#
#  # @brief  kept as simple text
#  # @param  text to be added
#  # @return string with some text
#  sub foo{
#    return "abc".shift;
#  }
#
#
# procudes:
#
#   my $string = $self->foo($text);
#
#
# LICENSE
# =======
# You can redistribute it and/or modify it under the conditions of LGPL.
#
# By the way, the source code is quite bad. So feel free to replace this idea with something better Perl OO code.
# 
# AUTHOR
# ======
# Andreas Hernitscheck  ahernit(AT)cpan.org 


# Constructor
#
# The keyvalues are not mandatory.
#
# selfstring may hold something like '$self' as alternative to '$self', which is default.
#
# alsohiddenmethods gets a boolean flag to show also methods which starts with "_".
#
sub new{ # $object ($filename=>scalar,alsohiddenmethods=>scalar,selfstring=>scalar) 
my $pkg=shift;
my %v=@_; 


	my $self={};
	bless $self,$pkg;

	$self->{package}=$pkg;

	foreach my $k (keys %v){ ## sets values to object
		$self->{$k}=$v{$k};
	}  
	
	$self->{'selfstring'} = $self->{'selfstring'} || '$self';
	

	if ($self->{'readfile'}){
		$self->readFile($self->{'readfile'});
	}


	if ($self->{'writefile'}){
		$self->writeFile($self->{'writefile'});
	}


	if ($self->{'readdir'}){
		$self->readDirectory($self->{'readdir'});
	}	

return $self;
}  


## Returns the border string which delimit the perl code and pod inside a pm file.
sub getBorderString{ ## $scalar
my $self=shift;
my $pkg=$self->{'package'};

	if ($self->{'BORDER'} eq ''){
		
		my $border = '#' x 20;
		$border .= " pod generated by $pkg - keep this line to make pod updates possible ";
		$border .= '#' x 20;
		$self->{'BORDER'}=$border;
		
	}

return $self->{'BORDER'};	
}


## Set an alternative border string. 
## If you change this, you have to do it again when updating the pod.
sub setBorderString{ ## void ($borderstring)
my $self=shift;
my $s=shift;

	$self->{'BORDER'} =$s;

}



# Expects Perl code as arrayref
# or text (scalar).
# 
# When used, it automatically runs scanArray().
# This now passes the filename to be used in case
# we are podding a .pl or .cgi file. NW 
sub setPerlCode{ ## void ($text|\@array, $file)
my $self=shift;
my $code=shift;
my $file=shift;

	my $arr; 

	if (!ref $code){
		my @a = split(/\n/,$code);
		$arr = \@a; 
	}else{
		$arr=$code;
	}

	$self->{'PERL_CODE'}=$arr;

	$self->scanArray($arr, $file);	
	$self->buildPod();
}


# Returns perl code which was set before.
sub getPerlCode{# $text
my $self=shift;
	
	my $border = $self->getBorderString();
	
	my $arr = $self->{'PERL_CODE'};
	
	my @code;
	foreach my $row (@$arr){
		
		if ($row=~ m/$border/){last}; ## border found, end loop
		
		push @code,$row;
	}
		
	my $text=join("",@code);	
		
return $text;		
}



# Returns the pod formated text.s
sub getPod{ ## $text
my $self=shift;

return $self->{"POD_TEXT"};	
}



sub _getFileArray{
my $self=shift;
my $filename=shift;
my @f;

	my $fh=new FileHandle;
	open($fh,'<',$filename);
		#lockhsh($fh);
		@f=<$fh>;
		#unlockh($fh);
	close($fh);


return wantarray ? @f : \@f;
}


sub _getFileScalar{
my $self=shift;
my $filename=shift;
	
	my $a = $self->_getFileArray($filename);

return join("",@$a);	
}



# writes a pod file
#
# If the file has a pm or pl or cgi extension, it writes the perl code and the pod
# If the file has a pod extension or any, it only writes the pod.
sub writeFile{ # void ($filename)
my $self=shift;
my $file=shift;
my $pod=$self->getPod();

	if ($file=~ m/\.(pm|pl|cgi)$/i){ ## target is pm or pl or cgi file, so add perl-code 
		my $text=$self->getPerlCode();
		$text.="\n".$self->{'BORDER'}."\n\n$pod";
		$self->_putFile($file,$text);
	}else{## target is any or pod file, write only pod
		$self->_putFile($file,$pod);
	}
	
}


## Reading a Perl class file and loads it to memory.
sub readFile{ # void ($filename)
my $self=shift;
my $file=shift or die "need filename";


	my $arr = $self->_getFileArray($file);
	$self->setPerlCode($arr, $file);
	
	
}


## scans a directoy recoursively for pm files and may
## generate pod of them.
##
## You can also set the flag updateonly to build new pod
## only for files you already build a pod (inside the file)
## in the past. Alternatively you can write the magic word
## AUTOPODME somewhere in the pm file what signals that this
## pm file wants to be pod'ed by autopod.
##
## The flag pod let will build a separate file. If poddir set,
## the generated pod file will be saved to a deparate directory.
## With verbose it prints the list of written files.
##
sub readDirectory{ # void ($directory,updateonly=>scalar,pod=>scalar,verbose=>scalar)
my $self=shift;
my $directory=shift or die "need directory";
my $v={@_};
my $updateonly=$v->{'updateonly'};
my $verbose=$v->{'verbose'};
my $pod=$v->{'pod'};
my $poddir=$v->{'poddir'};
my $border=$self->getBorderString();


	my @dir = $self->_getPodFilesRecoursive($directory);


	foreach my $filein (@dir){
		
		my $fileout = $filein;

    if ($poddir){
      $pod=1;
      $fileout=~ s|^$directory|$poddir|;

      my $p=_extractPath($fileout);


      if (!-e $p){
        _makeDirRecursive($p);
      }
    }

		
		my $filecontent = $self->_getFileScalar($filein);
		if ($updateonly){
			if (($filecontent!~ m/$border/) &&  ($filecontent!~ m/AUTOPODME/) ){$fileout=undef}; ## no border, no update
		}
		
		if ($pod){
			$fileout=~ s/\.pm$/.pod/;
		}
		
		my $ap = new Pod::Autopod();
		$ap->readFile($filein);
		$ap->writeFile($fileout);
	
		print $fileout."\n" if $verbose && $fileout;
		
	}

}





sub _getPodFilesRecoursive{
my $self=shift;
my $path=shift;
my %para=@_;
my @files;

	@files=$self->_getFilesRecoursiveAll($path);
	$self->_filterFileArray(\@files,ext=>'pm',path=>$path);
	@files=sort @files;

return wantarray ? @files : \@files;
}


sub _getFilesRecoursiveAll{
my $self=shift;
my $path=shift;
my %para;
my @f;
my @fm;


	@f=$self->_getDirArray($path);

	#$self->_filterFileArray(\@f);
	$self->_addPathToArray($path,\@f);

	foreach my $d (@f){
		if (-d $d){
		push @fm,$self->_getFilesRecoursiveAll($d);
		}
	}
	push @f,@fm;

	
	
return @f;
}  



sub _getDirArray{
my $self=shift;
my $path=shift;
my @f;
my @nf;

	opendir(FDIR,$path);
		@f=readdir FDIR;
	closedir(FDIR);

	foreach my $d (@f){
		if ($d!~ m/^\.\.?/){push @nf,$d};
	}

return wantarray ? @nf : \@nf;
}



sub _addPathToArray{
my $self=shift;
my $path=shift;
my $dir_ref=shift;

		foreach my $z (@$dir_ref){
			$z=$path.'/'.$z;
		}
}
  



sub _filterFileArray{
my $self=shift;
my $dir_ref=shift;
my %para=@_;
my @nf;
my $path=$para{path};


	if ($para{onlyFiles} ne ''){$para{noDir}=1};
	
	
	foreach my $i (@$dir_ref){
		my $ok=1;
		if ($i=~ m/^\.\.?$/){$ok=0};
				
		if (-d $i){$ok=0};

		my $ext=lc($para{ext});
		if (exists $para{ext}){
			if ($i=~ m/\.$ext$/i){$ok=1}else{$ok=0};
		};

		if ($ok == 1){push @nf,$i};
	}
	@$dir_ref=@nf;
	undef @nf;

}
  
  
  



	

sub _putFile{
my $self=shift;
my $file=shift;
my $text=shift;

	my $fh=new FileHandle;
	open($fh,'>',"$file");
#		lockh($fh);
		print $fh $text;
#		unlockh($fh);
	close($fh);
}  






# This class may scan the perl code.
# But it is called automatically when importing a perl code.
sub scanArray{
my $self=shift;	
my $arr=shift or die "Arrayref expected";	
my $file=shift;	
	$self->{'STATE'} = 'head';
	
	
	## reverse read
	for (my $i=0;$i < scalar(@$arr); $i++){
		my $p=scalar(@$arr)-1-$i;

		my $writeOut = 1;
		
		
		
		
		my $line = $arr->[$p];

		if ((($line=~ m/^\s*\#/) || ($p == 0)) && ($self->{'STATE'} eq 'headwait')){ ## last line of body
			$self->{'STATE'} = 'head';
		}elsif((($line=~ m/^\s*$/) || ($p == 0)) && ($self->{'STATE'} eq 'head')){ ## last line of body
			$self->{'STATE'} = 'bodywait';

			## collected doxy params? then rewrite methodline
			if ((exists $self->{'METHOD_ATTR'}->{ $self->_getMethodName() }->{'doxyparamline'}) && (scalar(@{ $self->{'METHOD_ATTR'}->{ $self->_getMethodName() }->{'doxyparamline'} }) > 0)){

				my $methodlinerest = $self->{'METHOD_ATTR'}->{ $self->_getMethodName() }->{'methodlinerest'};

				if ($methodlinerest !~ /\{\s+.+/){ ## dont overwrite existing line
					my @param;
					foreach my $l (@{ $self->{'METHOD_ATTR'}->{ $self->_getMethodName() }->{'doxyparamline'} }){
						$l =~ m/^([^\s]+)/;
						my $firstword = $1;
						if ($firstword !~ m/^[\$\@\%]/){$firstword='$'.$firstword}; # scalar is fallback if nothing given
						push @param, $firstword;
					}
					
					my $retparam = $self->{'METHOD_ATTR'}->{ $self->_getMethodName() }->{'doxyreturn'} || 'void';

					my $newmethodlinerest = sprintf("{ # %s (%s)", $retparam, join(", ",@param));
					$self->{'METHOD_ATTR'}->{ $self->_getMethodName() }->{'methodlinerest'} = $newmethodlinerest;
				}

			}

		}
		


		if (($self->{'STATE'} eq 'headwait') && ($line!~ m/^\s*$/) && ($line!~ m/^\s*\#/)){
			$self->{'STATE'}='free';
		}


		if ((($line=~ m/^\s*\}/) || ($p == 0) || ($line=~ m/^\s*sub [^ ]+/)) && ($self->{'STATE'}=~ m/^(head|headwait|bodywait|free)$/)){ ## last line of body
			$self->_clearBodyBuffer();
			$self->{'STATE'} = 'body';
			$self->_addHeadBufferToAttr();
		}

		# a hack for doxy gen, which rewrites the methodline
		# doxy @return
		if ($self->{'STATE'} eq 'head'){
			if ($line=~ m/^\s*#\s*\@return\s+(.*)/){
				my $retline = $1; # also containts description, which is not used at the moment
				$retline =~ m/([^\s]+)(.*)/;
				my $retval = $1;
				my $desc = $2 || $retval;

				if ($retval !~ m/^[\$\@\%]/){$retval='$'.$retval}; # scalar is fallback if nothing given

				if (exists $self->{'METHOD_ATTR'}->{ $self->_getMethodName() }->{'returnline'}){
					$self->{'METHOD_ATTR'}->{ $self->_getMethodName() }->{'methodlinerest'} =~ s/(\s*\#\s*)([^\s]+) /$1$retval/;	# remove/replace value behind "sub {" declaration
				}else{
					$self->{'METHOD_ATTR'}->{ $self->_getMethodName() }->{'methodlinerest'} = $retval;
				}
				
				$self->_addLineToHeadBuffer("");
				$self->_addLineToHeadBuffer("returns $desc");
				$self->_addLineToHeadBuffer("");
				$writeOut = 0;

				$self->{'METHOD_ATTR'}->{ $self->_getMethodName() }->{'doxyreturn'} = $retval;
			}

			if ($line=~ m/^\s*#\s*\@(brief|method)\s+(.*)/){ ## removes the @brief word
				my $text = $2;
				$self->_addLineToHeadBuffer($text);
				$writeOut = 0;
			}

			if ($line=~ m/^\s*#\s*\@param\s+(.*)/){ ## creates a param text.
				my $text = $1;
				$self->_addLineToHeadBuffer("");
				$self->_addLineToHeadBuffer("parameter: $text");
				$self->_addLineToHeadBuffer("");
				$writeOut = 0;

				$self->{'METHOD_ATTR'}->{ $self->_getMethodName() }->{'doxyparamline'} ||= [];
				push @{ $self->{'METHOD_ATTR'}->{ $self->_getMethodName() }->{'doxyparamline'} }, $text;
			}

		}









		if ($line=~ m/^\s*sub [^ ]+/){ ## head line
			$self->_clearHeadBuffer();
			$self->_setMethodLine($line);
			$self->{'STATE'} = 'headwait';
			$self->_addBodyBufferToAttr();
			$self->_setMethodAttr($self->_getMethodName(),'returnline',$self->_getMethodReturn());
			$self->_setMethodReturn(undef);	
		}


                
                
		
		if ($writeOut){
			if ($self->{'STATE'} eq 'head'){
				$self->_addLineToHeadBuffer($line);
			}elsif($self->{'STATE'} eq 'body'){
				$self->_addLineToBodyBuffer($line);	
			}
		}
		
		if ($line=~ m/^\s*package ([^\;]+)\;(.*)/){
			$self->{'PKGNAME'}=$1;
			$self->{'PKGNAME_DESC'}=$2;
			$self->{'PKGNAME_DESC'}=~ s/^\s*\#*//g;
		}

		if ($line=~ m/^\s*use +([^\; ]+)[\; ](.*)/){
			$self->{'REQUIRES'} = $self->{'REQUIRES'} || [];
			my $name=$1;
			my $rem=$2;
			$rem=~ s/^[^\#]*\#*//;
			push @{$self->{'REQUIRES'}},{'name'=>$name,'desc'=>$rem};
		}


		if (($line=~ m/^\s*use base +([^\; ]+)[\;](.*)/) ||
			($line=~ m/^\s*our +\@ISA +([^\; ]+)[\;](.*)/)){
			$self->{'INHERITS_FROM'} = $self->{'INHERITS_FROM'} || [];
			my $name=$1;
			my $rem=$2;
			$name=~ s/qw\(//g;
			$name=~ s/[\)\']//g;
			my @n=split(/ +/,$name);
			foreach my $n (@n){
				push @{$self->{'INHERITS_FROM'}},{'name'=>$n} if $n;	
			}
		}
		
		#print $line.'   -   '.$self->{'STATE'};
	}
	
	
	if ((exists $self->{'METHOD_ATTR'}->{'new'}) || (scalar($self->{'INHERITS_FROM'}) >= 1 )){ ## its a class!
		$self->{'ISCLASS'}=1;
	}
		
		
	if (!exists $self->{'PKGNAME'}){
      my $filet=$file;
      $filet =~ s/\.pm//g;
      $filet =~ s|/|::|g;
			$self->{'PKGNAME'}=$filet;
      $self->{'PKGNAME_DESC'}=$filet;
  }

	#	print Dumper($self->{'METHOD_ATTR'});
	$self->_analyseAttributes();


	$self->_scanDescription($arr);


	#print Dumper($self->{'METHOD_ATTR'});

	
}




sub _scanDescription{
my $self=shift;	
my $arr=shift or die "Arrayref expected";	
	
	$self->{'STATE'} = 'head';
	
	my @text;
	
	my $state='wait';
	for (my $i=0;$i < scalar(@$arr); $i++){
		
		my $line = $arr->[$i];
		
		if (($line=~ m/^\s*\#+(.*)/) && ($state=~ m/^(wait|rem)$/)){	
			$state='rem';
			$line=~ m/^\s*\#+(.*)/;
			my $text=$1;

			# doxy @brief in head
			if ($text=~ m/^\s*\@brief\s+(.*)/i){
				$text = $1;
			}
			

			push @text,$text;	
			
		}elsif(($line!~ m/^\s*\#+(.*)/) && ($state=~ m/^(rem)$/)){
			$state='done';
		}
		
	}
	
	
	my $more = $self->_findOwnTitlesInArray(array=>\@text, default=>'DESCRIPTION');
	
	$self->{'MORE'} = $more;

}





sub _findOwnTitlesInArray{
my $self=shift;	
my $v={@_};
my $arr=$v->{'array'}  or die "Array expected";
my $default=$v->{'default'};
my $morearr={};

	$self->_prepareArrayText(array=>$arr);

	my $area = $default;

	my $nextok=0;
	for (my $i=0;$i < scalar(@$arr); $i++){

		my $line = $arr->[$i];
		my $next = $arr->[$i+1];
		
		## is introduction?
		if ($next=~ m/^\s*(\={3,50})/){ ## find a ==== bar
			my $l=length($1);
			$area=$self->_trim($line);
			$nextok=$i+2; ## skip next 2 rows
		}
		
		if ($i >= $nextok){
			$morearr->{$area} = $morearr->{$area} || [];
			push @{$morearr->{$area}},$line;
		}

	}
	
	
return $morearr;
}






sub _addLineToHeadBuffer{
my $self=shift;
my $line=shift;

	$line = $self->_trim($line);

	$self->{'HEAD'} = $self->{'HEAD'} || [];
	
	unshift @{$self->{'HEAD'}},$line;
		

}




sub _addLineToBodyBuffer{
my $self=shift;
my $line=shift;

	$line = $self->_trim($line);

	if ($line=~ m/^\s*return (.*)/){
		if (!$self->_getMethodReturn){
			$self->_setMethodReturn($line);	
		}
	}


	$self->{'BODY'} = $self->{'BODY'} || [];
	
	unshift @{$self->{'BODY'}},$line;
		

}



sub _clearBodyBuffer{
my $self=shift;
my $line=shift;

	$line = $self->_trim($line);

	$self->{'BODY'} = [];

}




sub _clearHeadBuffer{
my $self=shift;
my $line=shift;

	$line = $self->_trim($line);

	$self->{'HEAD'} = [];

}


sub _addHeadBufferToAttr{
my $self=shift;

	my $m = $self->_getMethodName();
	if ($m){
		$self->_setMethodAttr($m,'head',$self->{'HEAD'})
	}
}



sub _addBodyBufferToAttr{
my $self=shift;

	my $m = $self->_getMethodName();
	$self->_setMethodAttr($m,'body',$self->{'BODY'})
}




sub _setMethodLine{
my $self=shift;
my $s=shift;

	$s = $self->_trim($s);
	
	if ($s=~ m/sub ([^ \{]+)(.*)/){
		$self->_setMethodName($1);
		$self->_setMethodAttr($1,'methodlinerest',$2);
	}


$self->{'METHOD_LINE'}=$s;
}



sub _getMethodLine{
my $self=shift;

return $self->{'METHOD_LINE'};
}



sub _setMethodName{
my $self=shift;
my $s=shift;


$self->{'METHOD_NAME'}=$s;
}





sub _getMethodReturn{
my $self=shift;

return $self->{'METHOD_RETURN'};
}



sub _setMethodReturn{
my $self=shift;
my $s=shift;


$self->{'METHOD_RETURN'}=$s;
}





sub _getMethodName{
my $self=shift;


return $self->{'METHOD_NAME'};
}




sub _setMethodAttr{
my $self=shift;
my $name=shift;
my $k=shift;
my $s=shift;

$self->{'METHOD_ATTR'}->{$name}->{$k}=$s;
}





sub _trim{
my $self=shift;
my $s=shift;

	if (ref $s){

		$$s=~ s/^\s*//;
		$$s=~ s/\s*$//;
		
	}else{

	 	$s=~ s/^\s*//;
 		$s=~ s/\s*$//;

		return $s;
	}
	 
}  





sub _analyseAttributes{
my $self=shift;
my $attr = $self->{'METHOD_ATTR'};


	foreach my $method (keys %$attr){
		my $mat=$attr->{$method};
		
		$self->_analyseAttributes_Method(attributes=>$mat,method=>$method);
		$self->_analyseAttributes_Head(attributes=>$mat,method=>$method);
	}
	
	
}





sub _analyseAttributes_Method{
my $self=shift;
my $v={@_};
my $method=$v->{'method'};
my $mat=$v->{'attributes'};


	my $mrest = $mat->{'methodlinerest'};
	$mrest=~ s/^[^\#]+\#*//;
	$mat->{'methodlinecomment'}=$mrest;

	my ($re,$at) = split(/\(/,$mrest,2);
	$at=~ s/\)//;


	$mat->{'returntypes'} = $self->_getTypeTreeByLine($re);
	$mat->{'attributetypes'} = $self->_getTypeTreeByLine($at);

	
}








sub _analyseAttributes_Head{
my $self=shift;
my $v={@_};
my $method=$v->{'method'};
my $mat=$v->{'attributes'};


	$self->_prepareArrayText(array=>$mat->{'head'});

}




sub _prepareArrayText{
my $self=shift;
my $v={@_};
my $array=$v->{'array'};

	#print Dumper($array);
	## removes rem and gap before rows

	my $space=99;
	foreach my $h (@{$array}){
		
		$h=~ s/^\#+//; ## remove remarks
		
		if ($h!~ m/^(\s*)$/){
			$h=~ m/^( +)[^\s]/;
			my $l=length($1);
			if (($l >0) && ($l < $space)){
				$space=$l
			}
		}
	}


	if ($space != 99){
		foreach my $h (@{$array}){
			$h=~ s/^\s{0,$space}//;
		}	
	}

	
	
    foreach my $line (@{$array}){
        my @replace;
  
        ## list items
        if ($line=~ m/^\s*-\s+(.*)/){ # minus
                my $text = $1;

                if ( $self->{'SUB_STATE'} ne 'listitem' ){
                    $self->{'SUB_STATE'} = 'listitem';

                    push @replace, "=over";
                }

                push @replace,"";
                push @replace, "=item *";
                push @replace, $text;
                push @replace,"";
                
                $line = undef;
        
        }elsif( $self->{'SUB_STATE'} eq 'listitem' ){
                push @replace, "=back";
                push @replace, "";

                delete $self->{'SUB_STATE'};
        }

	if ( $line =~ m/^\s*\@method\s+(.*)/i ){
            push @replace,"";
	}

        
        if (scalar(@replace) > 0){
            $line = join("\n",@replace);
        }
    }

    
    
}






sub _getTypeTreeByLine{
my $self=shift;
my $line=shift;

	
	my @re = split(/\,/,$line);
	
	my @rettype;
	foreach my $s (@re){
		$s=$self->_trim($s);


		my @or = split(/\|/,$s);
		my @orelems;
		my $elem={};
		
		foreach my $o (@or){
			my $name;
			my $type;
			my $typevalue;
			
			if ($o=~ m/^([^ ]+)\s*\=\>\s*([^ ]+)$/){
				$type='keyvalue';
				$name=$1;
				$typevalue=$2;
			
			}elsif ($o=~ m/^([^ ]+) ([^ ]+)$/){
				$type=lc($1);
				$name=$2;
			}elsif ($o=~ m/^([^ \$\%\@]+)$/){
				$type=lc($1);
			}elsif ($o=~ m/^([\$\%\@\\]+)(.*)$/){
				my $typec=$1;
				my $namec=$2;
				
				if ($typec eq '$'){$type='scalar'}
				if ($typec eq '\$'){$type='scalarref'}
				if ($typec eq '%'){$type='hash'}
				if ($typec eq '\%'){$type='hashref'}
				if ($typec eq '@'){$type='array'}
				if ($typec eq '\@'){$type='arrayref'}
				if ($typec eq '&'){$type='method'}
				if ($typec eq '\&'){$type='method'}

				$name=$namec || $type;
			}
			
			$elem = {name=>$name,type=>$type,typevalue=>$typevalue};
			push @orelems, $elem;
		}

		

		push @rettype,\@orelems;
	} 
	
	
return  \@rettype;
}





# Builds the pod. Called automatically when imporing a perl code.
sub buildPod{
my $self=shift;
my $attr = $self->{'METHOD_ATTR'};

	$self->{'POD_PARTS'}={};

	$self->_buildPod_Name();
	$self->_buildPod_Methods();
	$self->_buildPod_Requires();
	$self->_buildPod_Inherits();
	$self->_buildPod_More();


	$self->_buildPodText();

}





sub _buildPod_Requires{
my $self=shift;

	my $re=$self->{'REQUIRES'} || [];


	my %dontshow;
	my @dontshow = qw(vars strict warnings libs base);
	map {$dontshow{$_}=1} @dontshow;

	my $node = node->root;

	$node->push( node->head1("REQUIRES") );
	
	if (scalar(@$re) > 0){


		foreach my $e (@$re){

			my $name=$e->{'name'};
			my $desc=$e->{'desc'};

			if (!$dontshow{$name}){

				$desc=$self->_trim($desc);
				my $text = "L<$name> $desc\n\n";
        if ($name ne $self->{'PKGNAME'}){
				  $node->push( node->text($text));
        }
			}		
		}
		
		$self->{'POD_PARTS'}->{'REQUIRES'} = $node;	
	}

}





sub _buildPod_Inherits{
my $self=shift;

	my $re=$self->{'INHERITS_FROM'} || [];

	my %dontshow;
	my @dontshow = qw(vars strict warnings libs base);
	map {$dontshow{$_}=1} @dontshow;

	my $node = node->root;

	$node->push( node->head1("IMPLEMENTS") );
	
	if (scalar(@$re) > 0){


		foreach my $e (@$re){

			my $name=$e->{'name'};
			my $desc=$e->{'desc'};

			if (!$dontshow{$name}){

				$desc=$self->_trim($desc);
				my $text = "L<$name> $desc\n\n";

				$node->push( node->text($text));
			}		
		}
		
		$self->{'POD_PARTS'}->{'IMPLEMENTS'} = $node;	
	}

}




sub _buildPodText{
my $self=shift;

	my $parts=$self->{'POD_PARTS'};

	my @text;

	my @first = qw(NAME SYNOPSIS DESCRIPTION REQUIRES IMPLEMENTS EXPORTS HOWTO NOTES METHODS);
	my @last  = ('CAVEATS','TODO','TODOS','SEE ALSO','AUTHOR','COPYRIGHT','LICENSE','COPYRIGHT AND LICENSE');

	my @own = keys %{$parts};
	my @free;
	push @own,@first;
	push @own,@last;
	
	my %def;
	map {$def{$_}=1} @first;
	map {$def{$_}=1} @last;
	
	foreach my $n (@own){
		if (!exists $def{$n}){push @free,$n};
	}

	my @all;
	push @all,@first,@free,@last;

	foreach my $area (@all){
		if (exists $parts->{$area}){
			push @text,$parts->{$area}->pod;
		}
	}
	
	

	
	my $node = node->root;
	$node->push( node->cut );
	push @text,$node->pod;
	
	my $text=join("\n",@text);

	$self->{"POD_TEXT"} = $text;
}





sub _buildPod_Name{
my $self=shift;
my $attr = $self->{'METHOD_ATTR'};
my $name = $self->{'PKGNAME'};

	my $node = node->root;

	$node->push( node->head1("NAME") );
	
	my @name;
	
	push @name,$self->{'PKGNAME'};
	push @name,$self->_trim($self->{'PKGNAME_DESC'}) if $self->{'PKGNAME_DESC'};
	
	my $namestr = join(" - ",@name)."\n\n";


	$node->push( node->text($namestr));


	$self->{'POD_PARTS'}->{'NAME'} = $node;

}







sub _buildPod_More{
my $self=shift;
my $attr = $self->{'METHOD_ATTR'};



	my $more = $self->{'MORE'};

	foreach my $area (keys %$more){

		my $node = node->root;
			
		my $desc=$more->{$area};
                # length(@$desc) throws an error on newer perl, so use scalar(@$desc) instead. NW		
		if (scalar(@$desc) > 0){
	
			$node->push( node->head1("$area") );
			$node->push( node->text( join("\n",@$desc)."\n\n" ));
				
		}

		$self->{'POD_PARTS'}->{$area} = $node;
	}


}






sub _buildPod_Methods{
my $self=shift;
my $attr = $self->{'METHOD_ATTR'};

	my $node = node->root;

	$node->push( node->head1("METHODS") );

	## sort alphabeticaly
	my @methods = keys %$attr;
	@methods = sort @methods;

	if (exists $attr->{'new'}){ ## constructor first 
		$self->_buildPod_Methods_addMethod(node=>$node,method=>'new');
	}

	foreach my $method (@methods){

		my $ok = 1;

		if ($method eq ''){$ok=0};

		if ($method=~ m/^\_/){
			$ok=0;
			if ($self->{'alsohiddenmethods'}){$ok=1};
		}

		if ($ok){
			if ($method ne 'new'){
				$self->_buildPod_Methods_addMethod(node=>$node,method=>$method);
			}
		}
		
	}

	
	$self->{'POD_PARTS'}->{'METHODS'} = $node;
}




sub _buildPod_Methods_addMethod{
my $self=shift;
my $v={@_};
my $node=$v->{'node'};
my $method=$v->{'method'};
my $attr = $self->{'METHOD_ATTR'};
my $mat=$attr->{$method};

	my $selfstring='';
	if ($self->{'ISCLASS'}){
		$selfstring=$self->{'selfstring'}.'->';	
	}
	

	## method name
	$node->push( node->head2("$method") );


	## how to call

	my $retstring = $self->_buildParamString(params=>$mat->{'returntypes'}, braces=>1,separatorand=>', ',separatoror=>' | ');
	my $paramstring = $self->_buildParamString(params=>$mat->{'attributetypes'}, braces=>0,separatorand=>', ',separatoror=>' | ');

	my $addit=0;
	if ($retstring){
		$retstring = " my $retstring = $selfstring$method($paramstring);";
		$addit=1;
	}elsif($paramstring){
		$retstring = " $selfstring$method($paramstring);";
		$addit=1;
	}else{
		$retstring = " $selfstring$method();";
		$addit=1;
	}


	if ($addit){
		$retstring.="\n\n";		
		$node->push( node->text($retstring) );		
	}


	### head text 

	my $text;
	if ($mat->{'head'}){
		$text = join("\n",@{ $mat->{'head'} }); ## I added the return here, which is necessary using example codes before methods
		if ($text){$text.="\n\n\n"};
	
		$node->push( node->text($text) );
	}
	


}



sub _buildParamString{
my $self=shift;
my $v={@_};
my $params=$v->{'params'};
my $braces=$v->{'braces'};
my $separatorand=$v->{'separatorand'} || ',';
my $separatoror=$v->{'separatoror'} || '|';
my $text='';


	if ((exists $params->[0]->[0]->{'type'}) && ($params->[0]->[0]->{'type'} eq 'void')){return};

	my @and;
	foreach my $arra (@$params){

		my @or;
		foreach my $e (@$arra){
	
			my $name = $e->{'name'};
			my $type = $e->{'type'};
	
			my $wname = $name || $type;
	
			if ($type ne 'keyvalue'){
				my $ctype=$self->_typeToChar($type);
				push @or,"$ctype$wname";
			}else{
				my $typev = $e->{'typevalue'};
				my $ctype=$self->_typeToChar($typev);
				push @or,"$name => $ctype$typev";
			}
			
		}
			
		push @and,join($separatoror,@or);
	}
	
	$text=join($separatorand,@and);

	if ((scalar(@$params) > 1) && ($braces)){
		$text="($text)";
	}

return $text;
}



sub _typeToChar{
my $self=shift;
my $type=shift;
my $c='';

	my $m = {	'array'			=>	'@',
						'arrayref'	=>	'\@',
						'hash'			=>	'%',
						'hashref'		=>	'\%',
						'method'		=>	'&',
						'scalar'		=>	'$',
						'scalarref'	=>	'\$',
	};

	$c=$m->{$type} || $c;

return $c;
}





sub _makeDirRecursive{
my $dir=shift;
my $path;

  if (!-e $dir){

    my @path=split(/\//,$dir);
    foreach my $p (@path){
      if (!-e $path.$p){
        mkdir $path.$p;
#        print "CREATE: ".$path.$p."\n";
      }
      $path.=$p.'/';
    }

  }
}




sub _extractPath{
my $p=shift;

  if ($p=~ m/\//){
    $p=~ s/(.*)\/(.*)$/$1/;
  }else{
    if ($p=~ m/^\.*$/){ # only ".."
      $p=$p; ## nothing to do
    }else{
      $p='';
    }
  }

return $p;
}





1;











#################### pod generated by Pod::Autopod - keep this line to make pod updates possible ####################

=head1 NAME

Pod::Autopod - Generates pod documentation by analysing perl modules.


=head1 SYNOPSIS


 use Pod::Autopod;

 new Pod::Autopod(readfile=>'Foo.pm', writefile=>'Foo2.pm');

 # reading Foo.pm and writing Foo2.pm but with pod


 my $ap = new Pod::Autopod(readfile=>'Foo.pm');
 print $ap->getPod();

 # reading and Foo.pm and prints the generated pod. 

 my $ap = new Pod::Autopod();
 $ap->setPerlCode($mycode);
 print $ap->getPod();
 $ap->writeFile('out.pod');

 # asumes perl code in $mycoce and prints out the pod.
 # also writes to the file out.pod




=head1 DESCRIPTION

This Module is designed to generate pod documentation of a perl class by analysing its code.
The idea is to have something similar like javadoc. So it uses also comments written directly
obove the method definitions. It is designed to asumes a pm file which represents a class.

Of course it can not understand every kind of syntax, parameters, etc. But the plan is to improve
this library in the future to understand more and more automatically.

Please note, there is also an "autopod" command line util in this package.




=head1 REQUIRES

L<Pod::Autopod> 

L<Data::Dumper> 

L<Pod::Abstract::BuildNode> 

L<Pod::Abstract> 

L<FileHandle> 

L<5.006> Pod::Abstract uses features of 5.6


=head1 HOWTO


To add a documentation about a method, write it with a classical remark char "#" 
before the sub{} definition:

 # This method is doing foo.
 #
 #  print $self->foo();
 #
 # 
 # It is not doing bar, only foo.
 sub foo{
   ...
 }

A gap before sub{} is allowed.

In further versions of autopod, here new features will appear.

To define parameters and return values you can use a boundle of keywords.
So far parameters and return values can not realy be autodetected, so manual
way is necessary, but it is designed to type it rapidly.

 sub foo{ # void ($text)
  ...
 }

The example above produces the following method description: 

 $self->foo($text);

The object "$self" is the default and automatially used when a constructor was found ("new")
or the class inherits with ISA or "use base".
You can change this by the parameter "selfstring" in the autopod constructor.

The example looks simple, but the engine does more than you think. Please have a look here:

 sub foo{ # void (scalar text)
  ...
 }
 
That procudes the same output! It means the dollar sign of the first example is a symbol which means "scalar".

 sub foo{ # ($)
  ...
 }

Produces:

 $self->foo($scalar);

As you see, that was the quickest way to write the definition. The keywork "void" is default.

The following keywords or characters are allowed:

 array       @
 arrayref   \@
 hash        %
 hashref    \%
 method      &
 scalar      $
 scalarref  \$
 void       only as return value

Now a more complex example:

 sub foo{# $state ($firstname,$lastname,\%persondata)
 ...
 }

produces:

 my $state = $self->foo($firstname, $lastname, \%persondata);

or write it in java style:

 sub foo{# scalar state (scalar firstname,scalar lastname,hashref persondata)
 ...
 }

Multiple return values may be displayed as following:

 sub foo{# $a,$b ($text)
 ...
 }

produces:

 my ($a, $b) = $self->foo($text);


If you want to use key values pairs as in a hash, you may describe it like:

 sub foo{# void (firstname=>$scalar,lastname=>scalar)
 ...
 }

The second "scalar" above is without a "$", that is no mistake, both works.

There is also a way to expain that a value A OR B is expected. See here:

 sub foo{# $lista|\$refb (\@list|$text,$flag)
 ...
 }

procudes:

  my $lista | \$refb = $self->foo(\@list | $text, $flag);

Of course, that is not an official perl syntax with the or "|", but it shows
you that is expected.


In the First Part obove all method descriptions, you can add general informations, which are
per default displayed under the head item "DESCRIPTION". But also own items can be used by
underlining a text with "=" chars like:

 # HOWTO
 # =====
 # Read here howto do it.   

Some of these title keywords are allways places in a special order, which you can not change. For
example LICENSE is allways near the end.

Added some hacks to teach this tool also some doxygen parametes. For example:

 # @brief  kept as simple text
 # @param  text to be added
 # @return string with some text
 sub foo{
   return "abc".shift;
 }


procudes:

  my $string = $self->foo($text);




=head1 METHODS

=head2 new

 my $object = $self->new($filename => $scalar, alsohiddenmethods => $scalar, selfstring => $scalar);

Constructor

The keyvalues are not mandatory.

selfstring may hold something like '$self' as alternative to '$self', which is default.

alsohiddenmethods gets a boolean flag to show also methods which starts with "_".



=head2 buildPod

 $self->buildPod();

Builds the pod. Called automatically when imporing a perl code.


=head2 foo

 $self->foo();

This method is doing foo.

 print $self->foo();


It is not doing bar, only foo.


=head2 getBorderString

 my $scalar = $self->getBorderString();

Returns the border string which delimit the perl code and pod inside a pm file.


=head2 getPerlCode

 my $text = $self->getPerlCode();

Returns perl code which was set before.


=head2 getPod

 my $text = $self->getPod();

Returns the pod formated text.s


=head2 readDirectory

 $self->readDirectory($directory, updateonly => $scalar, pod => $scalar, verbose => $scalar);

scans a directoy recoursively for pm files and may
generate pod of them.

You can also set the flag updateonly to build new pod
only for files you already build a pod (inside the file)
in the past. Alternatively you can write the magic word
AUTOPODME somewhere in the pm file what signals that this
pm file wants to be pod'ed by autopod.

The flag pod let will build a separate file. If poddir set,
the generated pod file will be saved to a deparate directory.
With verbose it prints the list of written files.



=head2 readFile

 $self->readFile($filename);

Reading a Perl class file and loads it to memory.


=head2 scanArray

 $self->scanArray();

This class may scan the perl code.
But it is called automatically when importing a perl code.


=head2 setBorderString

 $self->setBorderString($borderstring);

Set an alternative border string.
If you change this, you have to do it again when updating the pod.


=head2 setPerlCode

 $self->setPerlCode($text | \@array, $file);

Expects Perl code as arrayref
or text (scalar).

When used, it automatically runs scanArray().
This now passes the filename to be used in case
we are podding a .pl or .cgi file. NW


=head2 writeFile

 $self->writeFile($filename);

writes a pod file

If the file has a pm or pl or cgi extension, it writes the perl code and the pod
If the file has a pod extension or any, it only writes the pod.



=head1 AUTHOR

Andreas Hernitscheck  ahernit(AT)cpan.org 


=head1 LICENSE

You can redistribute it and/or modify it under the conditions of LGPL.

By the way, the source code is quite bad. So feel free to replace this idea with something better Perl OO code.



=cut

