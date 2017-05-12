package Sys::Config::Manage;

use warnings;
use strict;
use Sys::Hostname;
use File::Copy;
use File::Find;
use File::Basename;
use File::Path 'make_path';
use Cwd 'abs_path';
use String::ShellQuote;
use base 'Error::Helper';

=head1 NAME

Sys::Config::Manage - Manages system configuration information.

=head1 VERSION

Version 0.3.1

=cut

our $VERSION = '0.3.1';

=head1 SYNOPSIS

    use Sys::Config::Manage;

    my $foo = Sys::Config::Manage->new();
    ...

=head1 METHODS

=head2 new

=head3 args hash

=head4 addCommand

This is the command to call on the file once it is copied over.

If not defined, nothing will be attempted after it is copied over.

=head4 autoCreateConfigDir

If this is specified, the configuration directory will automatically
be created under the base directory if needed.

This defaults to false, 0.

=head4 baseDir

The base directory the config base is stored in.

=head4 hostnameFallback

If the regexp selection method is being used, the hostname method will
be used.

=head4 selectionMethod

This is the selection method to use for selecting a system directory.

The valid methods are listed below.

    hostname
    regexp

If not specified, the hostname method is used.

    my $foo=$Sys::Config::Manage->new(\%args);
    if($foo->error){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub new{
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};
	my $method='new';

	my $self = {
				module=>'Sys-Config-Manage',
				perror=>undef,
				error=>undef,
				errorString=>"",
				addCommand=>undef,
				baseDir=>undef,
				selectionMethod=>'hostname',
				autoCreateConfigDir=>0,
				hostnameFallback=>1,
				};
	bless $self;

	#make sure a base directory is set
	if (!defined( $args{baseDir} )) {
		$self->{perror}=1;
		$self->{error}=1;
		$self->{errorString}='No base directory specified';
		$self->warn;
		return $self;
	}
	$self->{baseDir}=$args{baseDir};

	#clean it up
	$self->{baseDir} =~ s/\/\/*/\//g;

	#makes sure the base directory
	if (! -d $self->{baseDir}) {
		$self->{perror}=1;
		$self->{error}=4;
		$self->{errorString}='"'.$self->{baseDir}.'" does not exist or is not a directory';
		$self->warn;
		return $self;
	}

    #copies the addcommand if needed
    if (defined( $args{addCommand} )) {
        $self->{addCommand}=$args{addCommand};
    }

	#copies the hostnameFallback if needed
	if (defined( $args{hostnameFallback} )) {
		$self->{hostnameFallback}=$args{hostnameFallback};
	}

	#sets the autoCreateConfigDir value if needed
	if (defined( $args{autoCreateConfigDir} )) {
		$self->{autoCreateConfigDir}=$args{autoCreateConfigDir};
	}

	#make sure the selection
	if (defined( $args{selectionMethod} )) {
		if (
			( $args{selectionMethod} ne 'hostname' ) &&
			( $args{selectionMethod} ne 'regexp' )
			) {
			$self->{perror}=1;
			$self->{error}=2;
			$self->{errorString}='"'.$args{selectionMethod}.'" is not a valid selection method';
			$self->warn;
			return $self;
		}
		$self->{selectionMethod}=$args{selectionMethod};
	}

	#gets the hostname as it will be used later most likely...
	$self->{hostname}=hostname;

	return $self;
}

=head2 add

This adds a new file.

Two arguments are taken. The first is the file to added
and the second is the configuration directory to use. If
no configuration directory is specified, one will
automatically selected.

    #add it with a automatically selected config dir
    $foo->add($file);
    if($foo->error){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }
    
    #add it with a automatically specified config dir
    $foo->add($file, $configDir);
    if($foo->error){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub add{
	my $self=$_[0];
	my $file=$_[1];
	my $configDir=$_[2];
	my $method='add';

	#blank any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#make sure we have a file
	if (!defined($file)) {
		$self->{error}=7;
		$self->{errorString}='No file specified';
		$self->warn;
		return undef;
	}

	#make sure it is a file and it exists
	if (! -f $file ) {
		$self->{error}=8;
        $self->{errorString}='"'.$file.'" does not exist or is not a file';
		$self->warn;
        return undef;
	}

	#make sure we have a directory to use
	if (!defined($configDir)) {
		$configDir=$self->selectConfigDir;
		if ($self->error) {
			warn($self->{module}.' '.$method.': Unable to select a config dir');
			return undef;
		}
	}

	#make sure the config directory is valid
	my $valid=$self->validConfigDirName($configDir);
	if ($self->error) {
		warn($self->{module}.' '.$method.':'.$self->error.': Errored checking if the configuration directory name is valid');
		return undef;
	}
	if (defined( $valid )) {
		$self->{error}=6;
		$self->{errorString}='The configuration directory name '.$valid;
		$self->warn;
		return undef;
	}

	#makes sure the specified config directory is not a file
	if ( -f $self->{baseDir}.'/'.$configDir ) {
		$self->{error}=13;
		$self->{errorString}='"'.$self->{baseDir}.'/'.$configDir.'" is a file and thusly can not be used as a configuration directory';
		$self->warn;
		return undef;
	}

	#makes sure it exists
	if ( ! -d $self->{baseDir}.'/'.$configDir ) {
		if ( $self->getAutoCreateConfigDir ) {
			if (! mkdir( $self->{baseDir}.'/'.$configDir ) ) {
				$self->{error}=14;
				$self->{errorString}='"'.$self->{baseDir}.'/'.$configDir.'" could not be created';
				$self->warn;
				return undef;
			}
		}else {
			$self->{error}=15;
			$self->{errorString}='"'.$self->{baseDir}.'/'.$configDir.'" could not be created as autoCreateConfigDir is set to false';
			$self->warn;
			return undef;
		}
	}

	#get the full path
	$file=abs_path($file);

	#makes the new path
	my $newfile=$self->{baseDir}.'/'.$configDir.'/'.$file;
	$newfile=~s/\/\/*/\//g;

	#figures out what the new directory will be
	my ($name,$path,$suffix) = fileparse( $file );
	my $newpath=$self->{baseDir}.'/'.$configDir.'/'.$path;
	$newfile=~s/\/\/*/\//g;

	#make sure the new path does not exist as a file
	#while this may look stupid, it makes sure i
	if ( -f $newpath ) {
		$self->{error}=9;
		$self->{errorString}='"'.$newpath.'" is a file, so unable to create the directory';
		$self->warn;
        return undef;
	}

	#handles it if the directory path does not yet exist in the configuration directory
	if (! -d $newpath ) {
		if (! make_path($newpath) ) {
			$self->{error}=10;
			$self->{errorString}='The path "'.$newpath.'" could not be created';
			$self->warn;
			return undef;
		}
	}

	#copies the file
	if (! copy($file, $newfile) ) {
		$self->{error}=11;
		$self->{errorString}='Unable to copy "'.$file.'" to "'.$newfile.'"';
		$self->warn;
		return undef;
	}

	#adds it
	if (defined( $self->{addCommand} )) {
		my $command=$self->{addCommand};
		$newfile=shell_quote($newfile);
		
		$command=~s/\%\%\%file\%\%\%/$newfile/g;
		system($command);
		my $exit = $?<<8;
		if ($exit ne '0') {
			$self->{error}=12;
			$self->{errorString}='The add command failed. command="'.$command.'" exit="'.$exit.'"';
			$self->warn;
			return undef;
		}
	}

	#it has been added now
	return 1;
}

=head2 configDirExists

This verifies that the specified config directory exists.

    my $returned=$foo->configDirExists($dir);
    if($foo->error){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }
    if (!$returned){
        warn('The config dir does not exist or is not a directory');
    }

=cut

sub configDirExists{
	my $self=$_[0];
	my $configDir=$_[1];
	my $method='getSelectionMethod';	

	#blank any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#it does not exist or is not a directory
	if (! -d $self->{baseDir}.'/'.$configDir) {
		return undef;
	}

	#it exists
	return 1;
}

=head2 downSync

This syncs the configs down from the configuration
directory to the system.

Two arguments can be used.

The first is the configuration directory. If not specified, it will
be automaticallly choosen.

The second is the files to sync. If not specifiedm, all files will
be synced.

    #sync the specified files
    $foo->downSync( $configDir, \@files);
    if($foo->error){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

    #syncs all the files
    $foo->downSync
    if($foo->error){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub downSync{
    my $self=$_[0];
    my $configDir=$_[1];
    my @files;
    if (defined($_[2])) {
	@files=@{$_[2]};
    }
    my $method='downSync';

    #blank any previous errors
    if (!$self->errorblank) {
		return undef;
    }

    #make sure we have a directory to use
    if (!defined($configDir)) {
		$configDir=$self->selectConfigDir;
		if ($self->error) {
			warn($self->{module}.' '.$method.': Unable to select a config dir');
			return undef;
		}
    }

    #make sure the config directory is valid
    my $valid=$self->validConfigDirName($configDir);
    if ($self->error) {
		warn($self->{module}.' '.$method.':'.$self->error.': Errored checking if the configuration directory name is valid');
		return undef;
	}
    if (defined( $valid )) {
		$self->{error}=6;
		$self->{errorString}='The configuration directory name '.$valid;
		$self->warn;
		return undef;
    }

    #makes sure it exists
    if ( ! -d $self->{baseDir}.'/'.$configDir ) {
		$self->{error}=16;
		$self->{errorString}='The configuration directory, "'.$self->{baseDir}.'/'.$configDir.'", does not exist';
		$self->warn;
		return undef;
    }

    #get the files if if none is specified
    if (!defined( $files[0] )) {
		@files=$self->listConfigFiles($configDir);
    }
	
    #get the files if if none is specified
    my @allFiles=$self->listConfigFiles($configDir);

    #makes sure all the files exist
    my $int=0;
    while (defined( $files[$int] )) {
		my $matched=0;
		my $int2=0;
		while (defined( $allFiles[$int2] )) {
			if ( $files[$int] eq $allFiles[$int2] ) {
				$matched=1;
			}
			
			$int2++;
		}
		
        #figures out what the new directory will be and checks
        my ($name,$path,$suffix) = fileparse( $files[$int] );
		if( -f $path ){
			$self->{error}=19;
			$self->{errorString}='"'.$path.'" should be a directory, but it is a file ';
			$self->warn;
			return undef;
	}
	
	#make sure it is matched
	if (!$matched) {
	    $self->{error}=18;
	    $self->{errorString}='"'.$files[$int].'" is not tracked';
		$self->warn;
	    return undef;
	}
	
		$int++;
    }

    #copies each file from the repo to the FS
    $int=0;
	while( defined( $files[$int] ) ){
		my $repofile=$self->{baseDir}.'/'.$configDir.'/'.$files[$int];
		$repofile=~s/\/\/*/\//g;
		
        #figures out what the new directory will be
        my ($name,$path,$suffix) = fileparse( $files[$int] );
		
		#make the path if it does not exist
		if(! -e $path){
			if(!make_path( $path )){
				$self->{error}=10;
				$self->{errorString}='"'.$path.'" could not be created as a directory';
				$self->warn;
				return undef;
			}
		}
		
		#
		if(! copy($repofile, $files[$int]) ){
			$self->{error}=19;
			$self->{errorString}='"'.$files[$int].'" could not be synced';
			$self->warn;
			return undef;
		}
		
		$int++;
    }

    return 1;
}

=head2 getAddCommand

This returns the current add command.

If none is set, undef will be returned.

    my $addCommand=$foo->getAddCommand;
    if($foo->error){
        warn('error:'.$foo->error.': '.$foo->errorString); 
    }

=cut

sub getAddCommand{
	my $self=$_[0];
	my $method='getAddCommand';

	#blank any previous errors
	if (! $self->errorblank) {
		return undef;
	}

	return $self->{addCommand};
}

=head2 getAutoCreateConfigDir

This returns the autoCreateConfigDir value.

    my $autoCreateConfigDir=$foo->getBaseDir;
    if($foo->error){
        warn('error:'.$foo->error.': '.$foo->errorString); 
    }

=cut

sub getAutoCreateConfigDir{
	my $self=$_[0];
	my $method='autoCreateConfigDir';

	#blank any previous errors
	if (! $self->errorblank) {
		return undef;
	}

	return $self->{autoCreateConfigDir};
}

=head2 getBaseDir

This returns what the base directory is set to.

    my $baseDir=$foo->getBaseDir;
    if($foo->error){
        warn('error:'.$foo->error.': '.$foo->errorString); 
    }

=cut

sub getBaseDir{
	my $self=$_[0];
	my $method='getBaseDir';	

	#blank any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	return $self->{baseDir};
}


=head2 getHostnameFallback

This returns the current value for hostnameFallback.

    my $hostnameFallback=$foo->getHostnameFallback;
    if($foo->error){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub getHostnameFallback{
	my $self=$_[0];
	my $method='getHostnameFallback';

    #blank any previous errors
    if (!$self->errorblank) {
        return undef;
    }

    return $self->{baseDir};
}

=head2 getSelectionMethod

This returns the current selection method.

    my $selectionMethod=$foo->getSelectionMethod;
    if($foo->error){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub getSelectionMethod{
	my $self=$_[0];
	my $method='getSelectionMethod';	

	#blank any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	return $self->{selectionMethod};
}

=head2 listConfigDirs

This lists the available configuration directories.

    my @dirs=$foo->listConfigDirs;
    if($foo->error){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub listConfigDirs{
	my $self=$_[0];
	my $method='listConfigDirs';

	#blank any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#opens the directory for reading
	my $dh=undef;
	if (! opendir( $dh, $self->{baseDir} ) ) {
		$self->{error}=5;
		$self->{errorString}='Unable to open "'.$self->{baseDir}.'"';
		$self->warn;
		return undef;
	}

	#reads each entry and check if it should be added
	my @dirs;
	my $entry=readdir($dh);
	while ( defined($entry) ) {
		if (
			( $entry ne '.SysConfigManage' ) &&
			( -d $entry )
			) {
			push( @dirs, $entry  );
		}

		$entry=readdir($dh);
	}

	#close the directory
	closedir($dh);

	return @dirs;
}

=head2 listConfigFiles

This lists the various config files that are currently being tracked.

    my @files=$foo->listConfigFiles;
    if($foo->error){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub listConfigFiles{
	my $self=$_[0];
	my $configDir=$_[1];
	my $method='listConfigFiles';

	#blank any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#make sure we have a directory to use
	if (!defined($configDir)) {
		$configDir=$self->selectConfigDir;
		if ($self->error) {
			warn($self->{module}.' '.$method.':'.$self->error.': Unable to select a directory');
			return undef;
		}
	}

	#make sure the config directory is valid
	my $valid=$self->validConfigDirName($configDir);
	if ($self->error) {
		warn($self->{module}.' '.$method.':'.$self->error.': Errored checking if the configuration directory name is valid');
		return undef;
	}
	if (defined( $valid )) {
		$self->{error}=6;
		$self->{errorString}='The configuration directory name '.$valid;
		$self->warn;
		return undef;
	}

	#makes sure it exists
	if ( ! -d $self->{baseDir}.'/'.$configDir ) {
		$self->{error}=16;
		$self->{errorString}='The configuration directory, "'.$self->{baseDir}.'/'.$configDir.'", does not exist';
		$self->warn;
		return undef;
	}

	#holds what will be returned
	my @found;

	#find the file
	find( {
		   wanted => sub{
			   #don't match .svn stuff
			   if ( $_ eq ".svn" ) {
				   return;
			   }
			   if($File::Find::dir =~ /\.svn$/){
				   return;
			   }
			   if($File::Find::dir =~ /\.svn\//){
				   return;
			   }

			   #don't match .SysConfigManage stuff
			   if ( $_ eq ".SysConfigManage" ) {
				   return;
			   }
			   if($File::Find::dir =~ /\.SysConfigManage$/){
                   return;
               }
               if($File::Find::dir =~ /\.SysConfigManage\//){
                   return;
               }

			   #don't match .git stuff
			   if ( $_ eq ".git" ) {
				   return;
			   }
               if($File::Find::dir =~ /\.git$/){
                   return;
               }
               if($File::Find::dir =~ /\.git\//){
                   return;
               }

			   #only list files
			   if ( ! -f $_ ) {
				   return;
			   }

			   my $foundfile=$File::Find::dir."/".$_;
			   #$foundfile=~s/\/\//\//g;
			   my $regexp='^'.$self->{baseDir}.'/'.$configDir;
			   $foundfile=~s/$regexp//;

			   push(@found, $foundfile);

		   }
		   }, $self->{baseDir}.'/'.$configDir
		 );

	return @found;
}

=head2 notUnderBase

This makes sure that the a file is not under the base directory.

If it returns true, then the file is not under the base directory.

If it returns false, then it is under the base directory.

    my $returned=$foo->notUnderBase($file);
    if($foo->error){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }
    if ( ! $returned ){
        print "The file is under the base directory.\n".
    }

=cut

sub notUnderBase{
	my $self=$_[0];
	my $file=$_[1];
	my $method='notUnderBase';

	#blank any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#make sure we have a file specified
	if( ! defined( $file ) ){
		$self->{error}=7;
		$self->{errorString}='No file specified';
		$self->warn;
	}

	#clean up the path
	$file=~s/\/\/*/\//g;

	my $regexp="^".quotemeta($self->{baseDir}."/");
	$regexp=~s/\/\/*/\//g;

	#if it matches, then it 
	if( $file =~ /$regexp/ ){
		return 0;
	}

	return 1;
}

=head2 regexpSelectConfigDir

This reads $baseDir.'/.mapping' and returns the selected configuration
directory.

A optional hostname may be specified to check for.

A return of undef with out a error means it was not matched

    my $configDir=$foo->regexpSelect;
    if($foo->error){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }else{
        if(!defined(configDir)){
            warn('No match found');
        }
    }

=cut

sub regexpSelectConfigDir{
	my $self=$_[0];
	my $hostname=$_[1];
	my $method='regexpSelectSelectConfigDir';

	#blank any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	if (!defined( $hostname )) {
		$hostname=$self->{hostname};
	}

	#make sure it exists or is readable
	if ( -f $self->{baseDir}.'/.mapping' ) {
		$self->{error}=5;
		$self->{error}='"'.$self->{baseDir}.'/.mapping" does not exist or is not a file';
		$self->warn;
		return undef;
	}

	#tries to open it
	my $dh;
	if ( ! open( $dh, '<', $self->{baseDir}.'/.mapping' ) ) {
		$self->{error}=6;
		$self->{error}='"'.$self->{baseDir}.'/.mapping" could not be opened';
		$self->warn;
		return undef;
	}

	#read it and close it
	my @lines=<$dh>;
	close $dh;

	#process each line
	my $int=0;
	while ( defined( $lines[$int] ) ) {
		my ($dir, $regexp)=split(/ /, $lines[$int], 2);

		if ( $hostname =~ /$regexp/ ) {

			return $dir;
		}

		$int++;
	}

	return undef;
}

=head2 selectConfigDir

This selects the configuration directory to use.

    my $configDir=$foo->selectConfigDir;
    if($foo->error){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub selectConfigDir{
    my $self=$_[0];
    my $method='setSelectionMethod';

    #blank any previous errors
    if (!$self->errorblank) {
        return undef;
    }

	my $selectionMethod=$self->getSelectionMethod;

	if( $selectionMethod eq 'hostname' ){
		return lc(hostname);
	}

    if ( $selectionMethod eq 'regexp' ){
		my $configDir=$self->regexpSelect;
		if ( $self->error ) {
			warn($self->{module}.' '.$method.': regexpSelect failed');
			return undef;
		}
		if (!defined($configDir)) {
			if ($self->getHostnameFallback) {
				return hostname;
			}
			$self->{error}=17;
			$self->{errorString}='Hostname is disabled and regexp selection did not find any thing';
			$self->warn;
			return undef;
		}
		return $configDir;
    }

	return undef;
}

=head2 setAddCommand

This changes the add command.

If nothing is specified, it will be set to undef, meaning
nothing will be done to add it.

    #sets nothing to be added
    $foo->setAddMethod();
    if($foo->error){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

    #sets it to 'svn add --parents %%%file%%%'
    $foo->setAddMethod('svn add --parents %%%file%%%');
    if($foo->error){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub setAddCommand{
    my $self=$_[0];
	my $command=$_[1];
    my $method='setAddCommand';

    #blank any previous errors
    if (!$self->errorblank) {
        return undef;
    }

	$self->{addCommand}=$command;

	return 1;
}

=head2 setAutoCreateConfigDir

This changes the add command.

If nothing is specified, it will be set to undef, meaning
nothing will be done to add it.

    #sets nothing to be added
    $foo->setAddMethod();
    if($foo->error){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

    #sets it to 'svn add --parents %%%file%%%'
    $foo->setAddMethod('svn add --parents %%%file%%%');
    if($foo->error){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub setAutoCreateConfigDir{
    my $self=$_[0];
    my $autocreate=$_[1];
    my $method='setAutoCreateConfigDir';
	
    #blank any pre1;3Avious errors
    if (!$self->errorblank) {
        return undef;
    }
	
    $self->{autoCreateConfigDir}=$autocreate;
	
    return 1;
}

=head2 setSelectionMethod

This sets the selection method to use.

The valid methods are listed below.

    hostname
    regexp

    $foo->setSelectionMethod($method);
    if($foo->error){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub setSelectionMethod{
	my $self=$_[0];
	my $selectionMethod=$_[1];
	my $method='setSelectionMethod';

	#blank any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#make sure a method is specified
	if (!defined($selectionMethod)) {
		$self->{error}=3;
		$self->{errorString}='No selection method specified';
		$self->warn;
		return undef;
	}

	#make sure it is valid
	if (
		( $selectionMethod ne 'hostname' ) &&
		( $selectionMethod ne 'regexp' )
		) {
		$self->{error}=2;
		$self->{errorString}='"'.$selectionMethod.'" is not a valid selection method';
		$self->warn;
		return undef;
	}

	#saves the selection method
	$self->{selectionMethod}=$selectionMethod;

	return 1;
}

=head2 upSync

This syncs the configs up from the system to the configuration
directory

Two arguments can be used.

The first is the configuration directory. If not specified, it will
be automaticallly choosen.

The second is the files to sync. If not specifiedm, all files will
be synced.

    #sync the specified files
    $foo->downSync( $configDir, \@files);
    if($foo->error){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

    #syncs all the files
    $foo->downSync($configDir);
    if($foo->error){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub upSync{
    my $self=$_[0];
    my $configDir=$_[1];
    my @files;
    if (defined($_[2])) {
		@files=@{$_[2]};
    }
    my $method='downSync';

    #blank any previous errors
    if (!$self->errorblank) {
		return undef;
    }

    #make sure we have a directory to use
    if (!defined($configDir)) {
		$configDir=$self->selectConfigDir;
		if ($self->error) {
			warn($self->{module}.' '.$method.': Unable to select a config dir');
			return undef;
		}
    }

    #make sure the config directory is valid
    my $valid=$self->validConfigDirName($configDir);
    if ($self->error) {
		warn($self->{module}.' '.$method.':'.$self->error.': Errored checking if the configuration directory name is valid');
		return undef;
    }
    if (defined( $valid )) {
		$self->{error}=6;
		$self->{errorString}='The configuration directory name '.$valid;
		$self->warn;
		return undef;
    }

    #makes sure it exists
    if ( ! -d $self->{baseDir}.'/'.$configDir ) {
		$self->{error}=16;
		$self->{errorString}='The configuration directory, "'.$self->{baseDir}.'/'.$configDir.'", does not exist';
		$self->warn;
		return undef;
    }

    #get the files if if none is specified
    if (!defined( $files[0] )) {
		@files=$self->listConfigFiles($configDir);
    }

    #get the files if if none is specified
    my @allFiles=$self->listConfigFiles($configDir);

    #makes sure all the files exist
    my $int=0;
    while (defined( $files[$int] )) {
	my $matched=0;
	my $int2=0;
	while (defined( $allFiles[$int2] )) {
	    if ( $files[$int] eq $allFiles[$int2] ) {
			$matched=1;
	    }
		
	    $int2++;
	}
	
	#figures out what the new directory will be and checks
	my ($name,$path,$suffix) = fileparse( $files[$int] );
	if( -f $path ){
	    $self->{error}=19;
	    $self->{errorString}='"'.$path.'" should be a directory, but it is a file ';
		$self->warn;
	    return undef;
	}
	
	#make sure it is matched
	if (!$matched) {
	    $self->{error}=18;
	    $self->{errorString}='"'.$files[$int].'" is not tracked';
		$self->warn;
	    return undef;
	}
	
	$int++;
    }

    #copies each file from the fs to the repo
	$int=0;
    while( defined( $files[$int] ) ){
		my $repofile=$self->{baseDir}.'/'.$configDir.'/'.$files[$int];
		$repofile=~s/\/\/*/\//g;

        #figures out what the new directory will be
        my ($name,$path,$suffix) = fileparse( $files[$int] );
		
		#copy it back up from the FS and into the repo
		if(! copy($files[$int], $repofile) ){
			$self->{error}=19;
			$self->{errorString}='"'.$files[$int].'" could not be synced';
			$self->warn;
			return undef;
		}
		
		$int++;
    }

    return 1;
}

=head2 validConfigDirName

This checks to make sure configuration directory name
is valid.

    my $returned=$foo->validConfigDirName($name);
    if($foo->error){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }
    if(defined( $returned )){
        print 'Invalid name... '.$returned."\n";
    }

=cut

sub validConfigDirName{
	my $self=$_[0];
	my $name=$_[1];
	my $method='validConfigDirName';

	#blank any previous errors
	$self->errorblank; # don't really care if a permanent error is set here


	#always needs defined...
	if (!defined( $name )) {
		return 'not defined'
	}

	#make sure it is not not contain a slash
	if ( $name =~ /^\// ) {
		return 'matched /^\//';
	}


	#makes sure the mapping file is not specified
	if ($name eq '.mapping' ) {
		return 'matched ".mapping"';

	}

	#can't be any where in the path
	if ( $name =~ /\.SysConfigManage/ ) {
		return 'matched /\.SysConfigManage/';
	}

	#make sure it does not start with a period
	if ( $name =~ /^\./ ) {
		return 'mathced /^\./';
	}

	return undef;
}

=head1 ERROR CODES

=head2 1

No base directory specified.

=head2 2

No valid selection method specified.

=head2 3

Selection method not specified.

=head2 4

The specified directory does not exist or is not a directory.

=head2 5

The $baseDir.'/.mapping' file does not exist or is not a file.

=head2 6

Invalid config name.

=head2 7

No file specified.

=head2 8

The specified file does not exist or is not a file.

=head2 9

Makes sure the new path under the configuration directory is not a file.

=head2 10

The new path could not be created.

=head2 11

Copying the file failed.

=head2 12

The add command exited with a non-zero.

=head2 13

The selected configuration directory is a file.

=head2 14

The selected configuration directory could not be created.

=head2 15

The selected configuration directory does not exist and autoCreateConfigDir set to false.

=head2 16

The configuration directory does not exist.

=head2 17

Regexp selection did not match any thing and hostname fallback is not enabled.

=head2 18

One of the specified config files is not tracked.

=head2 19

Failed to copy a file for syncing.

=head1 Config Storage

Each config is stored under $baseDir.'/'.$configDir and then each config
is saved under the the configuration directory with the path on the file
system mapped onto the configuration directory.

Lets say the base directory is '/root/configs/' and the configuration
directory is 'foo.bar', with a config file of '/etc/rc.conf', then the
resulting path of the added file is '/root/configs/foo.bar/etc/rc.conf'.

The configuration directory can then be selected by three different methods.
The first method is manually, the third is the regexp method, and the third
is the hostname method. The name of the configuration directory may not
contain any forward slashes or start with a period.

The regexp method reads $baseDir.'/.mapping'. Each line contains two fields.
The first field is the configuration directory under the base directory. The
next field is a regular expression. If the regular expression matches the
hostname, the configuration directory in the first field is used. The first
match is used. Any line starting with a "#" is a comment.

The hostname method uses the hostname for the configuration directory. It also
converts the hostname to lowercase.

Any where in the path, the regexp /\.SysConfigManage/ maynot be found. This
is a reserved directory that will be used some time in the future.

After a file is added, a add command can be used. The add command prior to being
ran will have any instance of '%%%file%%%' replaced with a escaped file name.

Lets say the base directory is '/root/configs/' and the configuration
directory is 'foo.bar', with a config file of '/etc/rc.conf', and a add command
of 'svn add --parents %%%file%%%', then the executed command will be
'svn add --parents /root/configs/foo.bar/etc/rc.conf'.

To help integrate with subversion and git, directories matching /^.git$/ and
/^.svn$/ are ignored.

=head2 Ownership Storage

The path under which the configuration file is stored, under the configuration directory,
has a '.SysConfigManage/UID/' and '.SysConfigManage/GID/' directory. Each directory
contains a corresponding file that mirrors the name of the file in question.

Each file contains either the numeric GID or UID of the file in question.

=head2 Permission Storage

The path under which the configuration file is stored, under the configuration directory,
has a '.SysConfigManage/Perms/'. The directory contains a corresponding file that mirrors
the name of the file in question.

Each file contains either the numeric mode of the file in question.

The regexp below is used for verification.

    /^[01246][01234567][01234567][01234567]$/

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sys-config-manage at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sys-Config-Manage>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sys::Config::Manage


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Sys-Config-Manage>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sys-Config-Manage>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Sys-Config-Manage>

=item * Search CPAN

L<http://search.cpan.org/dist/Sys-Config-Manage/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Zane C. Bowers-Hadley.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Sys::Config::Manage
