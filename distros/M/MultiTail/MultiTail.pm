package MultiTail;
#
# Copyright (c) 1997 Stephen G. Miano.  All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Following are other pachages needed for MultiTail
#
use Carp;
use strict;
use File::stat qw(:FIELDS);
use File::Basename;
use FileHandle;
use DirHandle;
use vars qw( $AUTOLOAD $LastScan $True $False $DEBUG $VERSION $GMT $TC $FileAttributeChanged );
#
# Define sub
#
sub new;
sub update_attribute;
sub getparams;
sub GetParams;
sub CheckAttributes;
sub CreateFileDataStructure;
sub CreateListOfFiles;
sub OpenFileToTail;
sub read;
sub print;
sub printpat;
sub printexceptpat;
sub printstat;
sub Patterns;
sub Prefix;
sub RemoveDups;
sub CheckIfArrayOrFile;
sub ExceptPatterns;
sub OpenUpdateFiles;
sub UpdateStat;
sub Time;
sub version;
sub debug;
sub close_all_files;
sub FileState;
sub SetFileState;
sub PosFileMark;
sub printfilestates;
sub match_closure;
#
$True=1;
$False=0;
$GMT=$False;
$TC=$False;
$LastScan=time;
$DEBUG=$False;
$VERSION=0.5;
$FileAttributeChanged=$False;
my $pattern_sub;
my $exceptpattern_sub;
my %Attribute=();
my @File_Data_Structure;
my @StatArray = qw { dev ino mode nlink uid gid rdev size
         atime mtime ctime blksize blocks }; # Stat ids
#
# Code added for MSWin32
#
my $MSWin32 = ( $^O eq "MSWin32" ) ? $True : $False;
#
########################################################################
#
# Creating a new PTAIL object
#
########################################################################
#
sub new {
	my $class=shift;
	my(%argvs)=@_;
	my $args = getparams(\%argvs);
	my $self;
	my $rds;
	#	
	# set default vars
	#
	my %Default=();
	$Default{'Files'}=$False;
	$Default{'MaxAge'}=10;
	$Default{'NumLines'}=10;
	$Default{'OutputPrefix'}=$False;
	$Default{'Pattern'}=$False;
	$Default{'ExceptPattern'}=$False;
	$Default{'ScanForFiles'}=$False;
	$Default{'RemoveDuplicate'}=$False;
	$Default{'Function'}=$False;
	$Default{'Debug'}=$False;
	#
	foreach my $keys ( keys %$args ) {
		$args->{$keys}=$Default{$keys} unless $args->{$keys};
	}
	#
	$DEBUG=$args->{'Debug'};
	if ( $args->{'Files'} ) {
		$rds=CreateFileDataStructure( CreateListOfFiles($args->{'Files'})), 
	}
	# convert hash array to constant var
	#
	%Attribute = (
		Files   => $args->{'Files'},
		MaxAge  => $args->{'MaxAge'}, 
		NumLines => $args->{'NumLines'},
		OutputPrefix => $args->{'OutputPrefix'},
		Pattern => $args->{'Pattern'},
		ExceptPattern => $args->{'ExceptPattern'},
		ScanForFiles => $args->{'ScanForFiles'},
		RemoveDuplicate => $args->{'RemoveDuplicate'},
		Function=> $args->{'Function'},
		Debug  => $args->{'Debug'},
		FileArray => $rds,
	);
	$self=\%Attribute;
	bless $self, $class;
	CheckAttributes($self);
	return $self;

}
#
########################################################################
#
# Update Object Attribute
#
########################################################################
#
sub update_attribute {
	my ($rFD)=shift;
	my(%argvs)=@_;
	my $args = getparams(\%argvs);
	#
	foreach my $keys ( keys %$args ) {
		if ( $keys eq "Files" ) {
			$FileAttributeChanged=$True;
		}
		$rFD->{$keys}=$args->{$keys} if $args->{$keys};
	}
}
#
########################################################################
#
# Front end to Getparams function for MultiTail
#
########################################################################
#
sub getparams {
	my($rargvs)=@_;
	my ($MaxAge,$NumLines, $OutputPrefix,$Pattern,
		$ExceptPattern,$Debug,$ScanForFiles,$RemoveDuplicate,
		$Function,$Files);
	my $args =
        GetParams $rargvs,
        {   MaxAge        => \$MaxAge,
            NumLines      => \$NumLines,
            OutputPrefix  => \$OutputPrefix,
            Pattern       => \$Pattern,
            ExceptPattern => \$ExceptPattern,
            Debug         => \$Debug,
            ScanForFiles  => \$ScanForFiles,
            RemoveDuplicate  => \$RemoveDuplicate,
            Function  	  => \$Function,
            Files         => \$Files,
        },
        [qw(MaxAge NumLines OutputPrefix Pattern ExceptPattern Debug 
				ScanForFiles RemoveDuplicate Function Files)];
	#
}
#
########################################################################
#
# Check each Attributes for Min and Max Values
# 
# Exit Codes
#	 1001 - MaxAge is less the zero
#	 1002 - NumLines is less the zero
#	 1003 - OutputPrefix must one ( )
#	 1004 - Pattern must is not a file or ARRAY
#	 1005 - ExceptPattern is not a file or ARRAY
#	 1006 - Debug is not 0 or 1
#	 1007 - ScanForFiles is less the zero
#	 1008 - RemoveDuplicate is not 0 or 1
#	 1009 - Function is not ref to fuction
#	 1010 - File attribute not set
#
########################################################################
#
sub CheckAttributes {
	my($args)=shift;
	local($_);
	for ( keys %$args ) {
		/MaxAge/ and do { # /MaxAge/ must be >= zero
			if ( $args->{MaxAge} < 0 ) {
				print STDOUT "ERROR: MultiTail object MaxAge must be >= zero\n";
		  		exit 1001;
			}
			next;
		};
		/NumLines/ and do { # /NumLines/ must be >= zero
			if ( $args->{NumLines} < 0 ) {
				print STDOUT "ERROR: MultiTail object NumLines must be >= zero\n";
		 		exit 1002;
			}
			next;
		};
		/OutputPrefix/ and do { # /OutputPrefix/ must be a file or ARRAY
			unless ( $args->{OutputPrefix} =~ /^(p|f|t|tg|tc|pt|ptg|ptc|ft|ftg|ftc|tp|tpg|tpc|tf|tfg|tfc)$/){
				next if ! $args->{OutputPrefix};
				print STDOUT "ERROR: MultiTail object OutputPrefix must ARRAY of file\n";
		 		exit 1003;
			}
			next;
		};
		/Pattern/ and do { # /Pattern/ must be a file or ARRAY
			next if ! $args->{Pattern};
			no strict 'refs';
			if ( ref($args->{Pattern}) ne "ARRAY" and ! -f $args->{Pattern} ) {
				print STDOUT "ERROR: MultiTail object Pattern must ARRAY or file\n";
		 		exit 1004;
			}
			next;
		};
		/ExceptPattern/ and do { # /ExceptPattern/ must be a file or ARRAY
			next if ! $args->{ExceptPattern};
			if ( ref($args->{ExceptPattern}) ne "ARRAY" and ! -f $args->{ExceptPattern} ) {
				print STDOUT "ERROR: MultiTail object ExceptPattern must ARRAY or file\n";
		 		exit 1005;
			}
			next;
		};
		/Debug/ and do { # /Debug/ must be 0 or 1
			unless ( $args->{Debug} =~ /^[0|1]$/ ) {
				print STDOUT "ERROR: MultiTail object  must 0 or 1\n";
		 		exit 1006;
			}
			next;
		};
		/ScanForFiles/ and do { # /ScanForFiles/ must be 0 or 1
			if ( $args->{ScanForFiles} < 0 ) {
				print STDOUT "ERROR: MultiTail object ScanForFiles must be >= zero\n";
		 		exit 1007;
			}
			next;
		};
		/RemoveDuplicate/ and do { # /RemoveDuplicate/ must be 0 or 1
			unless ( $args->{RemoveDuplicate} =~ /^[0|1]$/ ) {
				print STDOUT "ERROR: MultiTail object RemoveDuplicate must 0 or 1\n";
		 		exit 1008;
			}
			next;
		};
		/Function/ and do { # /Function/ must be a function
			if ( ref($args->{Function}) ne "CODE" ) {
				next if ! $args->{Function};
				print STDOUT "ERROR: MultiTail object Function must be a function\n";
		 		exit 1009;
			}
			next;
		};
		/Files/ and do { # All attributes have default except for Files
			next if ! $args->{Pattern};
			unless ( $args->{Files} ) {
				print STDOUT "ERROR: MultiTail object must have attribute Files\n";
				exit 1010;
			}
			next;
		};
	}
}
#
########################################################################
#
# Get params past to object MultiTail
#
########################################################################
#
sub GetParams {
    my $argvref = shift or croak "Missing required argument.\n";
    my $params  = shift or croak "Missing required parameters hash.\n";
    my $arglist = shift or croak "Missing required arglist array.\n";
    my %args;
    my ($param, $var);
    if (ref($argvref) eq 'HASH') {
	my $href = $argvref;
	%args = %$href;			# initialize result with input hash
	foreach $param (keys %$href) {	# for each named argument...
	    # Is this a known parameter?
	    if (exists($params->{$param})) {
		$var = $params->{$param};
		while ($var ne '' && ref($var) eq '') {	# indirect refs?
		    $var = $params->{$param = $var};
		}
		if ($var ne '') {
		    $$var = $href->{$param}; # assign the param's variable
		    $args{$param} = $$var;	# make sure canonical param gets defined
		    next;		# go to the next parameter
		}
	    }
	    if (!exists($params->{$param})) {
		croak "Unknown parameter: \"$param\"\n";
	    }
	}
    } else {			# use args in the order given for variables
	my $i;
	for ($i = 0; $i <= $#$arglist; $i++) {
	    $param = $arglist->[$i];	# get the next argument
	    $var = $params->{$param};	# get it's variable
	    next unless defined($var);
	    while ($var ne '' && ref($var) eq '') {
		$var = $params->{$param = $var};
	    }
	    if ($var ne '') {
		$$var = $i <= $#$argvref ? $argvref->[$i] : '';
		$args{$param} = $$var;	# assign to the hash
	    } elsif (!exists($params->{$param})) {
		croak "Unknown parameter: \"$param\" for argument $i.\n";
	    }
	}
    }
    # Now, make sure all variables get initialized
    foreach $param (keys %$params) {
	$var = $params->{$param};
	while ($var ne '' && ref($var) eq '') {
	    $var = $params->{$param = $var};
	}
	if ($var ne '' && !exists($args{$param})) {
	    $$var = $args{$param} = undef;
	}
    }
    \%args;			# return the HASH ref
}
#
########################################################################
#
# Will open all file and create a file data Structure
#
########################################################################
#
sub CreateFileDataStructure {
	my($File_Array)=@_;
	my $BFILE;
	my $fh;
	my $Exist;
	my $rhash;
	my $Pos=0;
	my $online=$False;
	my %FileHash=();
	#
	if ( %Attribute ) {
		$online=$True;
		foreach my $FH ( @{$Attribute{'FileArray'}} ) {
			$FileHash{$FH->{'name'}} = 1;
		}
	}
	foreach my $FILE ( @$File_Array ) {
		#
		# if not run by fuction new check if file is already being monitored
		if ( %Attribute ) {
			next if $FileHash{$FILE};
		}
		#
		# stat file
		#
		$Exist = ( stat($FILE) ? $True : $False);
		$BFILE=basename($FILE);
		{
		no strict 'refs';
		%$FILE = (
			'name'		=>	$FILE,
			'basename'	=>	$BFILE,
			'fh'		=>	$fh,
			'stat'		=> {
					 'dev'     => $st_dev,
					 'ino'     => $st_ino,
					 'mode'    => $st_mode,
					 'nlink'   => $st_nlink,
					 'uid'     => $st_uid,
					 'gid'     => $st_gid,
					 'rdev'    => $st_rdev,
					 'size'    => $st_size,
					 'atime'   => $st_atime,
					 'mtime'   => $st_mtime,
					 'ctime'   => $st_ctime,
					 'blksize' => $st_blksize,
					 'blocks'  => $st_blocks
				   },
			'open'			=>	$False,
			'exist'			=>	$Exist,
			'read'		        =>	$False,
			'online'		=>	$online,
			'pos'			=>	$Pos,
			'FileState'		=>	0,
			'LastState'		=>	0,
			'LastMtime'		=>	$st_mtime,
			'OpenTime'		=>	0,
			'LineArray' 		=> 	[],
			'PatternLineArray' 	=> 	[],
			'ExceptPatternLineArray' 	=> 	[]
		);
		$rhash=\%$FILE;
		$$rhash{'LastState'} = FileState($rhash); 
		$$rhash{'FileState'} = $$rhash{'LastState'};
		push(@File_Data_Structure,\%$FILE);
		}
	}
	return \@File_Data_Structure;
}
#
########################################################################
#
# Create a array of text file from dirs and filename
# Checks files for dups (links) and absolute path
#
########################################################################
#
sub CreateListOfFiles {
	my($rArrayOfFileNames)=@_;
	#
	# Check if dir and expand
	#
	my @RegFileArray=();
	my @FileArray=();
	my @ReturnFileArray=();
	my @result=();
	my $file;
	my %path_file;
	#
	# Expand all reg file names
	#
	foreach my $FILE ( @$rArrayOfFileNames ) {
		@result = glob($FILE);
		push(@RegFileArray,@result);
	}
	#
	# check for dir and expand
	#
	foreach my $FILE ( @RegFileArray ) {
		if ( -d $FILE ) {
			print STDOUT "Dir $FILE is being expanded\n" if $DEBUG; 
			my $d = new DirHandle "$FILE";
			if(defined $d ) {
				while(defined($_=$d->read)) {
					$file="${FILE}/$_";
					if ( -T $file ) {
						push(@FileArray,$file);
					}
				}
     		}
		}
		else {
			push(@FileArray,$FILE);
		}
	}
	#
	# Checks files for dups (links) and absolute path
	#
	foreach my $FILE ( @FileArray ) {
		#
		# check for absolute path
		#
		unless ( $FILE =~ m#^/# || $MSWin32 ) {
			print STDOUT "File $FILE is not absolute path ... will not be used\n" if $DEBUG; 
			next;
		}
		unless ( ( $FILE =~ m#^\w:# || $FILE =~ m#^//# ) || ! $MSWin32 ) {
			print STDOUT "File $FILE is not NT absolute path ... will not be used\n" if $DEBUG; 
			next;
		}
		#
		# stat file
		#
		next unless stat($FILE);
		#
		# Check if any two file names point to the same file
		# Checking for links (Note: There are not links in NT)
		#
		my $key = "$st_dev $st_ino";
		if ( exists $path_file{$key} && ! $MSWin32 ) {
			print STDOUT "Warning: $FILE is linked to $path_file{$key}\n" if $DEBUG;
			print STDOUT "File $path_file{$key} ... will not be used\n" if $DEBUG;
			next;
		}
		$path_file{$key}=$FILE;
		#
		# Check if text file
		if ( -T $FILE ) {
			push(@ReturnFileArray,$FILE);
		}
		else {
			print STDOUT "$FILE is not a text file , will not be used\n" if $DEBUG;
		}
	}
	#
	return \@ReturnFileArray;
}

########################################################################
#
# Read all new data from file
#
########################################################################
#
# Read all new data from files
#
sub read {
	#
	my ($rFD)=shift;
	my @TotalArray=();		# Used with attribute Fuction
	my $PresentTime=time;
	#
	# Check if file dir should be rescanned
	# $LastScan is in sec
	# $rFD->{'ScanForFiles'} is in minutes
	#
	if (( $rFD->{'ScanForFiles'} and 
            ($LastScan + ($rFD->{'ScanForFiles'}*60)) < $PresentTime) or
	     $FileAttributeChanged ) {
		print STDOUT "Scanning for new files\n" if $DEBUG;
		$rFD->{'FileArray'} = 
		CreateFileDataStructure( CreateListOfFiles($rFD->{'Files'}));
		#
		$LastScan = $PresentTime;
		$FileAttributeChanged=$False;
	}
	#
	# This is for DEBUG
	if ( $DEBUG ) {
		print STDOUT "DEBUG list of file to be checked\n";
		foreach my $FH ( @{$rFD->{'FileArray'}} ) {
			print $FH->{'name'} . "\n";
		}
	}
	#
	# Check stat of files
	#
	OpenUpdateFiles($rFD);
	#
	#
	foreach my $FH ( @{$rFD->{'FileArray'}} ) {
		# reset array to remove last read data
		@{$FH->{'LineArray'}}=();
		#
		if ( $FH->{'exist'} and $FH->{'open'} ) {
			if ( defined $FH->{'fh'} ) {
				@{$FH->{'LineArray'}} = $FH->{'fh'}->getlines;
				$FH->{'pos'}=$FH->{'fh'}->getpos;
			}
			if ($FH->{'stat'}{mtime} < ($PresentTime - ($rFD->{'MaxAge'} * 60))) {
				$FH->{'fh'}->close;
				$FH->{'open'} = $False;
			}
		}
		$FH->{'LastState'} = FileState;
	}
	#
	# Run Pattern function if object Pattern attribute was set
	Patterns($rFD) if $rFD->{'Pattern'};
	#
	# Run ExceptPatterns function if object ExceptPatterns attribute was set
	ExceptPatterns($rFD) if $rFD->{'ExceptPattern'};
	#
	# Remove deplicate line from arrays
	RemoveDups($rFD) if $rFD->{'RemoveDuplicate'};
	#
	# create a Prefix Array if object OutputPrefix attribute was set
	Prefix($rFD,0) if $rFD->{'OutputPrefix'};
	#
	# Run custom function Pass complete array to custom user fuction
	if ( $rFD->{'Function'} ) {
		foreach my $FH ( @{$rFD->{'FileArray'}} ) {
			push(@TotalArray,@{$FH->{LineArray}});
		}
		&{$rFD->{'Function'}}(\@TotalArray)
	}
	#
	return($rFD);
}
#
########################################################################
#
# print out line in from file array (Mostly for help with )
#
########################################################################
#
sub print {
	my($rFD)=shift;
	foreach my $FH ( @{$rFD->{FileArray}} ) {
		foreach my $LINE ( @{$FH->{LineArray}} ) {
			print $LINE;
		}
	}
}
#
########################################################################
#
# Print out lines from pattern file array (Mostly for help with )
#
########################################################################
#
sub printpat {
	my($rFD)=shift;
	#print STDOUT Data::Dumper->Dump($rFD) if $DEBUG;
	foreach my $FH ( @$rFD{'FileArray'} ) {
		foreach my $LINE ( @{$FH->{PatternLineArray}} ) {
			print $LINE;
		}
	}
}
#
########################################################################
#
# print out line from pattern file except array (Mostly for help with )
#
########################################################################
#
sub printexceptpat {
	my($rFD)=shift;
	#print STDOUT Data::Dumper->Dump($rFD) if $DEBUG;
	foreach my $FH ( @$rFD{'FileArray'} ) {
		foreach my $LINE ( @{$FH->{ExceptPatternLineArray}} ) {
			print $LINE;
		}
	}
}
#
########################################################################
#
# Print out stat output for each file (Mostly for help with )
#
########################################################################
#
sub printstat {
	my($rFD)=shift;
	foreach my $FH ( @$rFD{'FileArray'} ) {
		print "Stat ouput for file $FH->{name}\n";
		print "------------------------------------------------\n";
		foreach my $stat_id ( @StatArray ) {
			print "$stat_id = $FH->{'stat'}{$stat_id}\n";
		}
	}
}
#
########################################################################
#
# Print out All file states
#  (See note in MultiTail.pm for function OpenUpdateFiles)
#
########################################################################
#
sub printfilestates {
	my($FH)=@_;
	my $vector=pack("b4",0);
	my $open; my $read; my $exist;my $online;

	if ( $FH->{'FileState'} != $FH->{'LastState'} ) {
		print STDOUT "The State of file $FH->{name} has changed\n";
		print STDOUT "-Old state\n";
		vec($vector,0,4)=$FH->{'LastState'};
		($online,$read,$open,$exist) = split(//, unpack("b4", $vector));
		print STDOUT "\tExist = $exist Open = $open Read = $read Online = $online \n";
		print STDOUT "-New State\n";
		vec($vector,0,4)=$FH->{'FileState'};
		($online,$read,$open,$exist) = split(//, unpack("b4", $vector));
		print STDOUT "\tExist = $exist Open = $open Read = $read Online = $online \n";
	}
	else {
		print STDOUT "No Change in state for file $FH->{name}\n";
	}
}
########################################################################
#
# Check if arg is an arrayof pattern  or filename of patterns
# Return ref to array of patterns
#
########################################################################
sub CheckIfArrayOrFile {
	my($r_listofpatterns)=@_;
	#
	my @patterns=();
	my $patternfile;
	my $patfh;
	#
	# check if list of pattern is an array of a file
	#
	if ( ref($r_listofpatterns) eq "ARRAY" ) {
			@patterns=@$r_listofpatterns;
	}
	else {
		#
		# check if it is a file
		#
		{
		no strict 'refs';
		if ( -f $r_listofpatterns ) {
			$patternfile=$r_listofpatterns;
			#
			# open pattern file
			#
			stat($patternfile) || croak "Could not open pattern file\n";
			$patfh = new FileHandle "$patternfile", "r";
			while(<$patfh>) {
				chomp;
				next if /^#/;		# Remove line of comments
				next if /^\s*$/;	# Remove Blank lines
				push (@patterns,$_);
			}
			$patfh->close;
		}
		else {
			croak "Argv for sub Pattern was not an Array or File $patternfile was not found\n";
		}
		}
	}
	#
	return \@patterns;
}
########################################################################
#
# Add prefix define by OutputPrefix option to data array
#
# List of what is Object Options. Default is False
# GMT = Greenwich time ZONE
#
#  p   => path name of the input file
#  f   => file name of the input file
#  t   => time in HHMMSS
#  tg  => time in HHMMSS GMT
#  tc  => time in MM/DD/YYYY HH:MM:SS
#  pt  => path and time
#  ptg => path and time GMT
#  ptc => path and time complete
#  ft  => file and time
#  ftg => file and time GMT
#  ftc => file and time complete
#  tp  => time and path
#  tpg => time and path GMT
#  tpc => time complete and path
#  tf  => time and file
#  tfg => time and file GMT
#  tfc => time complete and file
#
########################################################################
sub Prefix {
	my($rFD)=shift;
	my($ArrayType)=@_;
	#
	my @TempArray=();
	my $InArray="LineArray";
	my $OutArray="LineArray";
	my $r=$rFD;
	my $TmpOutputPrefix;
	#
	# Check for GMT
	#
	$TmpOutputPrefix = $rFD->{'OutputPrefix'};
	if ( $rFD->{'OutputPrefix'} =~ /g/ ) {
		$TmpOutputPrefix =~ s/g//;
		$GMT=$True;
	}
	if ( $rFD->{'OutputPrefix'} =~ /c/ ) {
		$TmpOutputPrefix =~ s/c//;
		$TC=$True;
	}
	foreach my $FH ( @{$rFD->{'FileArray'}} ) {
		foreach my $LINE ( @{$FH->{$InArray}} ) {
			$TmpOutputPrefix eq "p" && 
			   push(@TempArray,"$FH->{'name'} : $LINE");
			$TmpOutputPrefix eq "f" && 
			   push(@TempArray,"$FH->{'basename'} : $LINE");
			$TmpOutputPrefix eq "t" && 
			   push(@TempArray,Time($r) . " : $LINE");
			$TmpOutputPrefix eq "pt" && 
			   push(@TempArray,"$FH->{'name'} " . Time($r) . " : $LINE");
			$TmpOutputPrefix eq "tp" && 
			   push(@TempArray,Time($r) . " $FH->{'name'} : $LINE");
			$TmpOutputPrefix eq "ft" && 
			   push(@TempArray,"$FH->{'basename'} " . Time($r) . " : $LINE");
			$TmpOutputPrefix eq "tf" && 
			   push(@TempArray,Time($r) . " $FH->{'basename'} : $LINE");
		}
		@{$FH->{$OutArray}} = @TempArray;
		@TempArray=();
	}
	return($rFD);
}
########################################################################
#
# open a ( file or Array ) of patterns and check for lines matching 
# the pattern
# 
# Returns Data Structure with 
#
########################################################################
sub Patterns {
	my($rFD)=shift;
	#
  $pattern_sub = match_closure(CheckIfArrayOrFile($rFD->{'Pattern'})) unless defined($pattern_sub);
	foreach my $FH ( @{$rFD->{FileArray}} ) {
		@{$FH->{PatternLineArray}}=();
		foreach my $LINE ( @{$FH->{LineArray}} ) {
			push(@{$FH->{PatternLineArray}},$LINE) if ( $pattern_sub->($LINE) );
		}
		@{$FH->{LineArray}}=@{$FH->{PatternLineArray}};
	}
	return($rFD);
}
#
########################################################################
#
# open a ( file or Array ) of paterns and return excepticheck them against lines 
# from file array
#
########################################################################
#
sub ExceptPatterns {
	my($rFD)=shift;
	#
  $exceptpattern_sub = match_closure(CheckIfArrayOrFile($rFD->{'ExceptPattern'})) unless defined($exceptpattern_sub);
	foreach my $FH ( @{$rFD->{FileArray}} ) {
		@{$FH->{ExceptPatternLineArray}}=();
		foreach my $LINE ( @{$FH->{LineArray}} ) {
				push(@{$FH->{ExceptPatternLineArray}},$LINE) unless ( $exceptpattern_sub->($LINE) );
		}
		@{$FH->{LineArray}}=@{$FH->{ExceptPatternLineArray}};
	}
	#
	return($rFD);
}
#
########################################################################
#
# create closures fuction with eval for efficiency in patterm matching
#
########################################################################
sub match_closure {
   my($array) = shift;
	my $out;
   $out = join ('|', @$array);
   eval 'sub { $_[0] =~ /($out)/o; }'
}
#
########################################################################
#
# Remove Duplicate line from file array
#
########################################################################
#
sub RemoveDups {
	my($rFD)=shift;
	my %Mark;
	#
	foreach my $FH ( @{$rFD->{FileArray}} ) {
		#
		undef(%Mark);
		grep($Mark{$_}++, @{$FH->{LineArray}});
		@{$FH->{LineArray}}=(keys(%Mark)); 
		undef(%Mark);
	}
	return($rFD);
}
########################################################################
#
# Open and Close files as needed for tailing
# Should be done before ptail->read
#
# All file are in a combination of four states.
# 
# 1. Exist  = True (File exist at this time )
#           = False ( File does not exist at this time )
# 
# 2. Open   = True (File is open at this time )
#           = False ( File is not open at this time )
# 
# 3. Read   = True (File has been read since open )
#           = False ( File has not been read since open )
# 
# 4. online = True (File exist now or existed once during this process)
#           = False (File has never existed during this process)
# 
# The table below list the states that a file can be in
# and what action should be taken.
# 
# BV = Binary Value
#  ____________________________________________________________________ 
# | BV || Exist | Open | Read | OnLine || Action                        
# |____||_______|______|______|________||______________________________|
# |----||-------|------|------|--------||------------------------------|
# | 0  ||  F    |  F   |  F   |   F    || 1) Skip file
# |    ||       |      |      |        ||
# |----||-------|------|------|--------||------------------------------|
# | 1  ||  F    |  F   |  F   |   T    || 1) Skip file
# |    ||       |      |      |        ||   
# |----||-------|------|------|--------||------------------------------|
# | 2  ||  F    |  F   |  T   |   F    || 1) (read = False)
# |    ||       |      |      |        || 2) Skip file
# |----||-------|------|------|--------||------------------------------|
# | 3  ||  F    |  F   |  T   |   T    || 1) (read = False)
# |    ||       |      |      |        || 2) Skip file 
# |----||-------|------|------|--------||------------------------------|
# | 4  ||  F    |  T   |  F   |   F    || 1) Close File (open = False)
# |    ||       |      |      |        || 2) Skip file
# |----||-------|------|------|--------||------------------------------|
# | 5  ||  F    |  T   |  F   |   T    || 1) Close File (open = False) 
# |    ||       |      |      |        || 2) Skip file
# |----||-------|------|------|--------||------------------------------|
# | 6  ||  F    |  T   |  T   |   F    || 1) Check if file has changed
# |    ||       |      |      |        || 2) if file has not changed for
# |    ||       |      |      |        ||    MaxAge, close file
# |----||-------|------|------|--------||------------------------------|
# | 7  ||  F    |  T   |  T   |   T    || 1) Close File (open =False)
# |    ||       |      |      |        || 2) Take offline
# |    ||       |      |      |        ||    (online = False)           
# |    ||       |      |      |        || 3) (read = False)
# |----||-------|------|------|--------||------------------------------|
# | 8  ||  T    |  F   |  F   |   F    || 1) Open File (open = True)
# |    ||       |      |      |        || 2) Put online (online = True)
# |    ||       |      |      |        || 3) Start reading from location
# |    ||       |      |      |        ||    NumLines (read = True)              
# |----||-------|------|------|--------||------------------------------|
# | 9  ||  T    |  F   |  F   |   T    || 1) Open File (open = True)
# |    ||       |      |      |        || 2) Start reading from top
# |    ||       |      |      |        ||    (read = True)
# |----||-------|------|------|--------||------------------------------|
# | 10 ||  T    |  F   |  T   |   F    || 1) Open File (open = True)
# |    ||       |      |      |        || 2) Start reading from last pos
# |    ||       |      |      |        || 3) Put online (online = True)
# |----||-------|------|------|--------||------------------------------|
# | 11 ||  T    |  F   |  T   |   T    || 1) Open File (open = True)
# |    ||       |      |      |        || 2) Start reading from last pos
# |----||-------|------|------|--------||------------------------------|
# | 12 ||  T    |  T   |  F   |   F    || 1) Put online (online = True)
# |    ||       |      |      |        || 2) Start reading from top
# |----||-------|------|------|--------||------------------------------|
# | 13 ||  T    |  T   |  F   |   T    || 1) Start reading from last pos
# |    ||       |      |      |        ||    (read = True)
# |----||-------|------|------|--------||------------------------------|
# | 14 ||  T    |  T   |  T   |   F    || 1) Put online (online = True)
# |    ||       |      |      |        || 2) Start reading from top
# |----||-------|------|------|--------||------------------------------|
# | 15 ||  T    |  T   |  T   |   T    || 1) Start reading from last pos
# |    ||       |      |      |        ||
#  ---------------------------------------------------------------------
#
########################################################################
sub OpenUpdateFiles {
	#
	my($rFD)=shift;
	my $FS;
	#
	foreach my $FH ( @{$rFD->{'FileArray'}} ) {
		#
		# check if file exist and update stat
		$FS = UpdateStat($FH);
		#
		SWITCH: {
		#
			($FS==0) && do {
				last SWITCH;	
			};
			($FS==2 || $FS==4 || $FS==6 ) && do {
				SetFileState($FH,0);
				last SWITCH;	
			};
			($FS==1 || $FS==3 || $FS==5 || $FS==7 ) && do {
				SetFileState($FH,1);
				last SWITCH;	
			};
			($FS==8 || $FS==14 ) && do {
				$FH->{'fh'} = new FileHandle "$FH->{name}", "r";
				$FH->{'OpenTime'} = time;
				if ( defined($FH->{'fh'}) ) {
					SetFileState($FH,15);
					PosFileMark($FH);
				}
				last SWITCH;	
			};
			($FS==9 ) && do {
				$FH->{'fh'} = new FileHandle "$FH->{name}", "r";
				$FH->{'OpenTime'} = time;
				if ( defined($FH->{'fh'}) ) {
					SetFileState($FH,15);
				}
				last SWITCH;	
			};
			($FS==12 ) && do {
				OpenFileToTail($rFD,$FH);
				if ( $FH->{'open'} ) {
					SetFileState($FH,15);
				}
				last SWITCH;	
			};
			($FS==10 || $FS==11 || $FS==13 || $FS==15 ) && do {
				OpenFileToTail($rFD,$FH);
				if ( $FH->{'open'} ) {
					SetFileState($FH,15);
					$FH->{'fh'}->setpos($FH->{'pos'});
				}
				last SWITCH;	
			};
		}
		# get current state of file
		$FH->{'FileState'}=FileState($FH);
		printfilestates($FH) if $DEBUG;
	}
}
#
########################################################################
#
# Open file if it exist and has been change 
#
########################################################################
#
sub OpenFileToTail {
	my($rFD)=shift;
	my($FH)=@_;
	my $PresentTime=time;
	#
	# return if file is already open
	#
	#
	# check if file has been changed in last MaxAge mins
	if ( ($FH->{'LastMtime'} == $FH->{'stat'}{mtime}) && 
	     ($FH->{'stat'}{mtime} < ($PresentTime - ($rFD->{'MaxAge'} * 60))) &&
	      $FH->{'open'} ) {
		$FH->{'fh'}->close if defined($FH->{'fh'});
		$FH->{'OpenTime'} = 0;
		$FH->{'open'}=$False;
		return;
	}
	if ( $FH->{'LastMtime'} == $FH->{'stat'}{mtime} ) {
		return;
	}
	if ( ! $FH->{'open'} && $FH->{'LastMtime'} < $FH->{'stat'}{mtime} ) { 
		$FH->{'fh'} = new FileHandle "$FH->{name}", "r";
		$FH->{'open'}=$True;
		$FH->{'OpenTime'} = $PresentTime;
	}
}
#
########################################################################
#
# Update stat in Data_Structure
#
########################################################################
#
sub UpdateStat {
	my($FH)=@_;
	my $tmps;
	#
	{
	no strict 'refs';
	$FH->{'LastMtime'} = $FH->{'stat'}{'mtime'};
	}
	$FH->{'exist'} = (stat($FH->{'name'}) ? $True : $False);
	$FH->{'read'} = $False unless $FH->{exist};
	#
	foreach my $stat_id ( @StatArray ) {
		$tmps="st_". $stat_id;
		{
		no strict 'refs';
		$FH->{'stat'}{$stat_id} = $$tmps;
		}
	}
	# get current state of file
	$FH->{'LastStat'} = $FH->{'FileState'};
	$FH->{'FileState'} = FileState($FH);
	#
	# this will return the FileState
}
#
########################################################################
#
# Return the time as a HHMMSS string.  $opt_g decides timezone.
#
########################################################################
#
sub Time {
	my($rFD)=shift;
	return scalar localtime if $TC;
	my($sec,$min,$hour)=($GMT ? gmtime : localtime);
	sprintf("%02d%02d%02d", $hour,$min,$sec);
}
#
########################################################################
#
# Return the version number of the MultiTail Package
#
########################################################################
#
sub version {
  return $VERSION;
}
#
########################################################################
#
# Turn on  output on for MultiTail package
#
########################################################################
#
sub debug {
	my($rFD)=shift;
	if ( $rFD->{'Debug'} ) {
		$DEBUG=0;
	}
	else {
		$DEBUG=1;
	}
	$rFD->{'Debug'}=$DEBUG;
}
#
########################################################################
#
# Close all file that are being tailed
#
########################################################################
#
sub close_all_files{
	my ($rFD)=shift;
	foreach my $FH ( @{$rFD->{'FileArray'}} ) {
		next if ! defined $FH->{fh};
		print "Closing file $FH->{name} ...\n" if $DEBUG;
		$FH->{fh}->close;
	}
}	
#
########################################################################
#
# Return the state of a file in Number terms
# 
# Exist  = 8
# Open   = 4
# Read   = 2
# Online = 1
#
########################################################################
#
sub FileState{
	my($FH)=@_;
	my $vector=pack("b4",0);
	#
	if( defined($FH->{'online'}) ) {
		vec($vector,0,1)=$FH->{'online'};	
		vec($vector,1,1)=$FH->{'read'};	
		vec($vector,2,1)=$FH->{'open'};	
		vec($vector,3,1)=$FH->{'exist'};	
		vec($vector,0,8);
	}
}
########################################################################
#
# Set the new file state in the Data Structure
# 
# Exist  = 8
# Open   = 4
# Read   = 2
# Online = 1
#
########################################################################
#
sub SetFileState{
	my($FH,$NewState)=@_;
	my $vector=pack("b4",0);
	#

	if ( $NewState > 15 ) { $NewState=15; }

	vec($vector,0,4)=$NewState;
	($FH->{'online'},$FH->{'read'},$FH->{'open'},$FH->{'exist'}) =
	split(//, unpack("b4", $vector));
	$FH->{'FileState'}=$NewState;
}
#
########################################################################
#
# Set file seek position to number of line in opt_n
#
########################################################################
#

sub PosFileMark {
	my($FH)=@_;
	#
	my $line;
	my $pos;
	my @lines=();
	my $fh=$FH->{'fh'};
	my $CharALine=120;
	my $seekbacklines=$Attribute{'NumLines'};
	my $seekback=$CharALine * ($seekbacklines +1);
	#
	if ( $seekbacklines <= 0 ) { # Move to end of file
		seek($fh,0,2);
		$FH->{'pos'}=$fh->getpos;
		return;
	}
	else {
		seek($fh, -$seekback, 2);
	}
	#
	# remove line part;
	#
	$line=$fh->getline;
	#
	# get all line to end of file
	#
	@lines=$fh->getlines;
	splice(@lines,0,$#lines-$seekbacklines + 1);
	foreach $line ( @lines ) {
		$pos += length $line;
	}
	#
	# seek to pos in file;
	#
	seek($fh, -$pos, 2);
	#
	$FH->{'pos'}=$fh->getpos;
	#
}
#
########################################################################
#
# Autoload sub-classes
#
########################################################################
#
sub AUTOLOAD {
	my($rFD)=shift;
	my $type = ref($rFD) || croak "$rFD is not and object";
	my $attribute = $AUTOLOAD;
	$attribute =~ s/.*://;
	unless ( exists $rFD->{$attribute} ) {
		croak "Can't access $attribute field in oject $rFD";
	}
	if ( $attribute eq "Files" ) {
		$FileAttributeChanged=$True;
	}
	CheckAttributes($rFD);
	if (@_) {
		return $rFD->{$attribute} = shift;
	} else {
		return $rFD->{$attribute};
	}
}
#
#
########################################################################
# POD 
########################################################################
1;
__END__
# Below is the stub of documentation MultiTail.

=head1 NAME

  MultiTail - Tail multiple files for Unix systems

=head1 SYNOPSIS

  use File::MultiTail;

=head1 DESCRIPTION

 This perl library uses perl5 objects to make it easy to
 tail a dynamic list of files and match/except lines using full
 regular expressions.

File::MultiTail;

	will tail multiple files and return the records 
	read to a Data Structure. The Data Structure can 
	be processed by MultiTail functions

The  files  specified  are processed in accordance with the 
following rules:

Note: File devices and inode number uniquely identify each entry 
in the UNIX filesystem. If the stat() command shows them to be 
the same, then only one will be used. Windows NT filesystem
NTFS does not allow links so I don't check for links on NT.

(1) Files that exist at program start  time  will  be  
    positioned to Object attribute "NumLines" before input.

(2) Files that become available subsequently  will  be  read
    from the beginning. Attribute ScanForFiles must be set to
    True (>=1) for the option. 

(3) If a file that has been selected as per rules 1 or 2  is
    deleted  or  truncated input will continue until end-of-file
    is reached before the file is closed.

(4) If a file is deleted and  it is recreated it
    is treated as a new file, will  be  read
    from the beginning

(5) To conserve file descriptors, files that are selected for
    input  are  not actually opened until data is present beyond
    the input point selected.  For example,
    if a file exists when ptail starts, ptail will determine the
    file mtime at that time and only open the file when the  mtime
    increases.

    Note: mtime = Time when data was last modified. Changed by  the
                  following functions: creat, mknod, pipe, utime,
                  and write.

(6) If an opened file has not been updated for MultiTail Object attribute
    "MaxAge" minutes it will be closed.  
    It will be reopened if it is later updated.

(7) Since MultiTail is OO you can alway change its attributes. If you change
    the list of file to be tailed (Files attribute) the attribute
    ScanForFiles will set to true and all dir and files ilists will be
    check for new files.


=head1 METHODS

=over 4
 
=item 1) 

new 

Creating a new PTAIL object

$tail = File::MultiTail->new( 
				OutputPrefix => 'tf',
            RemoveDuplicate => $True,
            Files => ['/var/log','/var/adm/*.log'] );

Or

$tail = File::MultiTail->new;
$tail->Files(['/var/log','/var/adm/*.log']);
$tail->RemoveDuplicate($True);


    class/object method takes arguments ( All have defaults )
    and returning a reference to a newly created MultiTail object.

    File     :  File attribute accepts file names that includes 
	both explicit  file/dir  names  and  file/dir expressions.
	Duplicate  file  paths  are rejected, along with non-duplicate 
   names  that  resolve to  a  device/inode combination that is 
	currently being read. NT file name must start with drive letter
   or //. 
 
    Pattern  :  Arguments can be a file name or an array of patterns
        Stores in object attribute  "LineArray" all lines
        that contain the patterns
	(Default is *)

    ExceptPattern : Arguments can be a file name or an array of patterns
	Stores in object attribute  "LineArray" all lines except
	those that contain the patterns
	(Default is *)

    MaxAge  : Maximum time in minute that an open file will be held open
	without an update.
	(Default is 10 minute)

    NumLines : Files that exist at MultiTail start time will have up to
	NumLines lines from the end of file displayed. 
	Similar to tail -NumLines.  
	(Default is 10)

    Fuction  : Reference to a function that will be run by the MultiTail
        object.
        MultiTail object will pass a ref array of all the lines read from
        the files and passed through any filters you set in the object
		 to the function.
	0 = (Default) No Fuction

    ScanForFiles : Maximum time in minute before Read will scan for new
				 files.
	If you change the attribute "Files" with fuction update_attribute
        the next Read will scan for new files.
	0 = (Default) Off 

    RemoveDuplicate : Removes all duplicate lines from LineArray
	0 = (Default) Off
	1 = On

        : Turn Debuging messages on for MultiTail.pm.
	0 = (Default) Off
	1 = On

    OutputPrefix : Determines the prefix applied to each output record.
	Output records are store in MultiTail object attribute "LineArray"
        The prefix is separated from the record by ': '.
        Prefixes supported are:
		       p  : path name of the input file
		       f  : file name of the input file
		       t  : time in HHMMSS
		       tg : time in HHMMSS GMT
		       tc : time in MM/DD/YYYY HH:MM:SS
		       pt : path and time
		       ptg: path and time GMT
		       ptc: path and time complete
		       ft : file and time
		       ftg: file and time GMT
		       ftc: file and time complete
		       tp : time and path
		       tpg: time and path GMT
		       tpc: time complete and path
		       tf : time and file
		       tfg: time and file GMT
		       tfc: time complete and file
	0 = (Default) No prefix
	GMT = Greenwich time ZONE

 Exit Codes

	 1001 - MaxAge is less the zero
	 1002 - NumLines is less the zero
	 1003 - OutputPrefix must one ( )
	 1004 - Pattern must is not a file or ARRAY
	 1005 - ExceptPattern is not a file or ARRAY
	 1006 - Debug is not 0 or 1
	 1007 - ScanForFiles is less the zero
	 1008 - RemoveDuplicate is not 0 or 1
	 1009 - Function is not ref to fuction
	 1010 - File attribute not set

=item 
read

Read all new data from file

$tail->read


Read all new date from tailed files and return new lines as part of the
Data Structure (MultiTail Object attribute LineArray)


=item 
print

Print all line contained in MultiTail Object attribute LineArray

$tail->print


=item
update_attribute

Allow you to Update (Change) any MultiTail Object attribute

$tail->update_attribute(
	Files => ["/var/log","/var/adm","/home/nnysgm/logwatcher/foo*"],
	ExceptPattern => /home/nnysgm/ExceptPattern.txt,
	RemoveDuplicate => $True
	);

This changes the Files, ExceptPattern and RemoveDuplicate
attributes for the Object $tail.

New files will be scanned for during next Read if "Files" attribute is 
changed.

Also you can use supplied methods to set attribute values.

$tail->RemoveDuplicate($True);
$tail->NumLines(100);

=item
version

Return version number on PTAIL package

$tail->version

=item
debug

Toggle the debug switch for MultiTail package

$tail->debug

	There are a number of  function in the MultiTail.pm module.
		
		o printstat :
			Print out stat output for each file.
		o printfilestates :
			Print out All file states. 
			(See note in MultiTail.pm for function OpenUpdateFiles)
		o printpat :
			Print out lines from pattern file array.
		o printexceptpat :
			Print out line from pattern file except array.

=item
close_all_files

Closes all file that are being tailed

$tail->close_all_files

=back

=head1 EXAMPLE

1)
	use File::MultiTail;

	$tail1=File::MultiTail->new (  OutputPrefix => "f", 
                      Debug => "$True", 
                      Files => ["/var/adm/messages"]
	);

	while(1) {
		$tail1->read;
		#
		$tail1->print;
		sleep 10;
	}

$tail1=MultiTail->new : Create new ptail object

- Files => Tail file /var/adm/messages

- OutputPrefix => Prepend the name of the file beginning of each
  line in object attribute  "LineArray"

$tail1->read      : Read all line from files 

$tail1->print     : Print all line in object attribute  "LineArray";

2)
	use File::MultiTail;

	$tail1=File::MultiTail->new (  OutputPrefix => "tf", 
		      Pattern => "/home/nnysgm/logwatcher/pattern",
		      ExceptPattern => "/home/nnysgm/logwatcher/epattern",
		      Fuction = > \&want,
            Files => ["/var/adm","/var/log/*.log"]
	);

	while(1) {
		$tail1->read;
		#
		$tail1->print;
		sleep 10;
	}
	
	sub want {
			(your code .... );
	}

$tail1=File::MultiTail->new : Create new ptail object

- OutputPrefix => Prepend the name of the file and time to the
  beginning of each line in object attribute  "LineArray"

- ExceptPattern => Stores in object attribute  "LineArray" all lines except 
  those that contain the patterns from file "epattern"
- Pattern => Stores in object attribute  "LineArray" all lines  
  that contain the patterns from file "pattern"

- Fuction => ref to a function that will be run by MultiTail object.
  MultiTail object will pass a ref array to the function of all the lines read from 
  the file and passed through any filters you set in the object.

- Files => Tail all files in dir /var/adm and all .log files
  dir /var/log. 

$tail1->read      : Read all line from files 

$tail1->print     : Print all line in object attribute  "LineArray";

3)
   use File::MultiTail;
  
   $tail=File::MultiTail->new;

	$tail->OutputPrefix(tf);
   $tail->Fuction(\&want);
   $tail->Files(["/var/adm","/var/log/*.log"]);
  
   while(1) {
      $tail1->read;
   }
                      
   sub want {
         (your code .... );
   }         


=head1 AUTHOR

Stephen Miano, smiano@mindspring.com

=head1 SEE ALSO
 
perl(1).

=cut
