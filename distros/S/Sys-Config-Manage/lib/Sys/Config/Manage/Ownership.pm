package Sys::Config::Manage::Ownership;

use warnings;
use strict;
use File::Basename;
use base 'Error::Helper';
use String::ShellQuote;

=head1 NAME

Sys::Config::Manage::Ownership - Handles file user/group ownership for files in the configuration directory.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';

=head1 METHODS

=head2 new

This initiates the object.

One argument is required and it is a hash reference.

=head3 args hash ref

=head4 scm

This is a initiated Sys::Config::Manage object.

=head4 defaultUID

This is the default user ID for a file.

If not specified, the default is '0'.

=head4 defaultGID

This is the default group ID for a file.

If not specified, the default is '0'.

    $foo=Sys::Config::Manage::Ownership->new(\%args);
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
		module=>'Sys-Config-Manage-Ownership',
		perror=>undef,
		error=>undef,
		errorString=>"",
		defaultUID=>'0',
		defaultGID=>'0',
	};
	bless $self;

	#make sure we have a Sys::Config::Manage
	if(!defined( $args{scm} ) ){
		$self->{perror}=1;
		$self->{error}=1;
		$self->{errorString}='Nothing passed for the Sys::Config::Manage object';
		$self->warn;
		return $self;
	}

	#make sure that it is really a Sys::Config::Manage object
	if( ref( $args{scm} ) ne "Sys::Config::Manage"  ){
		$self->{perror}=1;
		$self->{error}=2;
		$self->{errorString}='$args{scm} is not a Sys::Config::Manage object';
		$self->warn;
		return $self;
	}

	#figures out what the defualt is
	if ( defined( $args{defaultUID} ) ){
		#make sure the perms are sane
        if ( $args{default} !~ /^[0123456789]*$/ ){
			$self->{perror}=1;
			$self->{error}=12;
			$self->{errorString}='"'.$args{default}.'" does not appear to be a valid value';
			$self->warn;
			return $self;
        }
		$self->{defaultUID}=$args{defaultUID};
	}

	#figures out what the defualt is
	if ( defined( $args{defaultGID} ) ){
		#make sure the perms are sane
        if ( $args{default} !~ /^[0123456789]*$/ ){
			$self->{perror}=1;
			$self->{error}=12;
			$self->{errorString}='"'.$args{default}.'" does not appear to be a valid value';
			$self->warn;
			return $self;
        }
		$self->{defaultGID}=$args{defaultGID};
	}

	$self->{scm}=$args{scm};

	return $self;
}

=head2 downSync

This syncs the group/user ownership down from the configuration
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
    $foo->downSync( $configDir );
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
		$configDir=$self->{scm}->selectConfigDir;
		if ($self->{scm}->error) {
			$self->{error}=5;
			$self->{errorString}='Sys::Config::Manage->selectConfigDir errored error="'.
				$self->{scm}->error.'" errorString="'.$self->{scm}->errorString.'"';
			$self->warn;
			return undef;
		}
	}
	
	#make sure the config directory is valid
	my $valid=$self->{scm}->validConfigDirName($configDir);
	if ($self->{scm}->error) {
		$self->{error}=6;
		$self->{errorString}='Sys::Config::Manage->validConfigDirName errored error="'.
			$self->{scm}->error.'" errorString="'.$self->{scm}->errorString.'"';
		$self->warn;
		return undef;
	}
	if (defined( $valid )) {
		$self->{error}=3;
		$self->{errorString}='The configuration directory name '.$valid;
		$self->warn;
		return undef;
	}
	
	#makes sure it exists
	if ( ! -d $self->{scm}->{baseDir}.'/'.$configDir ) {
		$self->{error}=4;
		$self->{errorString}='The configuration directory, "'.$self->{baseDir}.'/'.$configDir.'", does not exist';
		$self->warn;
		return undef;
	}

	#checks and make sure all the files exist
	my $int=0;
	if(defined( $files[$int] )){
		my @allfiles=$self->{scm}->listConfigFiles($configDir);
        if( $self->{scm}->error ){
            $self->{error}='16';
            $self->{errorString}='Sys::Config::Manage->listConfigFiles errored error="'.
                $self->{scm}->error.'" errorString="'.$self->{scm}->errorString.'"';
			$self->warn;
            return undef;
        }
		
		#make sure each file asked to be synced is tracked
		while(defined( $files[$int]  )){

			my $matched=0;
			my $int2=0;
			while(defined( $allfiles[$int2] )){
				if( $files[$int] eq $allfiles[$int2] ){
					$matched=1;
				}

				$int2++;
			}

			if(! $matched){
				$self->{error}='8';
				$self->{errorString}='"'.$files[$int].'" does not exist under the configuration directory, "'.$configDir.'",';
				$self->warn;
				return undef;
			}

			$int++;
		}

	}else{
		#if we get here, no files have been specified so we do them all
		@files=$self->{scm}->listConfigFiles($configDir);
		if( $self->{scm}->error ){
			$self->{error}='16';
			$self->{errorString}='Sys::Config::Manage->listConfigFiles errored error="'.
				$self->{scm}->error.'" errorString="'.$self->{scm}->errorString.'"';
			$self->warn;
			return undef;
		}
	}

	#process each file
	$int=0;
	while( defined( $files[$int] ) ){
		#get the perms for the file we will set it on
		my $uid=$self->getUID( $configDir, $files[$int] );
		if( $self->error ){
			warn($self->{module}.' '.$method.': Sys::Config::Manage::Ownership->getUID errored');
			return undef;
		}

		#get the perms for the file we will set it on
		my $gid=$self->getGID( $configDir, $files[$int] );
		if( $self->error ){
			warn($self->{module}.' '.$method.': Sys::Config::Manage::Ownership->getGID errored');
			return undef;
		}

		#try to chmod it
		if(!chmod( $uid, $gid, $files[$int] )){
			$self->{error}='17';
            $self->{errorString}='chown( '.$uid.', '.$gid.', "'.$files[$int].'") errored';
			$self->warn;
            return undef;
		}
		
		$int++;
	}

	return 1;
}

=head2 getGID

This retrieves the GID for a file.

Two arguments are taken.The first is the configuration directory,
which if not defined is automatically chosen. The second is the
file in question.

    my $gid=$foo->getGID( $configDir, $file );
    if($foo->error){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub getGID{
    my $self=$_[0];
    my $configDir=$_[1];
    my $file=$_[2];
	my $method='getGID';

    #blank any previous errors
    if (!$self->errorblank) {
        return undef;
    }

	#make sure we have a directory to use
	if (!defined($configDir)) {
		$configDir=$self->{scm}->selectConfigDir;
		if ($self->{scm}->error) {
			$self->{error}=5;
			$self->{errorString}='Sys::Config::Manage->selectConfigDir errored error="'.
				$self->{scm}->error.'" errorString="'.$self->{scm}->errorString.'"';
			$self->warn;
			return undef;
		}
	}
	
	#make sure the config directory is valid
	my $valid=$self->{scm}->validConfigDirName($configDir);
	if ($self->{scm}->error) {
		$self->{error}=6;
		$self->{errorString}='Sys::Config::Manage->validConfigDirName errored error="'.
			$self->{scm}->error.'" errorString="'.$self->{scm}->errorString.'"';
		$self->warn;
		return undef;
	}
	if (defined( $valid )) {
		$self->{error}=3;
		$self->{errorString}='The configuration directory name '.$valid;
		$self->warn;
		return undef;
	}
	
	#makes sure it exists
	if ( ! -d $self->{scm}->{baseDir}.'/'.$configDir ) {
		$self->{error}=4;
		$self->{errorString}='The configuration directory, "'.$self->{baseDir}.'/'.$configDir.'", does not exist';
		$self->warn;
		return undef;
	}

	#make value for the file is specified
	if (!defined( $file )) {
		$self->{error}=7;
		$self->{errorString}='No file specified';
		$self->warn;
		return undef;
	}
	
	#make sure the file exists, under the config dir
	if (! -f $self->{scm}->{baseDir}.'/'.$configDir.'/'.$file ) {
		$self->{error}=8;
		$self->{errorString}='The file does not exist in the configuration directory';
		$self->warn;
		return undef;
	}

	#figure out what the perms file is
	my ($name,$path,$suffix) = fileparse($file);
	my $idfile=$self->{scm}->{baseDir}.'/'.$configDir.'/'.$path.'/.SysConfigManage/GID/'.$name;

	#make sure the file has some perms
	if (! -f $idfile ){
        return $self->{defaultGID};
	}

	#read the file
	my $fh;
	if ( ! open( $fh, '<', $idfile ) ){
		$self->{error}=15;
		$self->{errorString}='Unable to open "'.$idfile.'"';
		$self->warn;
		return undef;
	}
	my $id=<$fh>;
	chomp($id);
	close( $fh );

	return $id;
}

=head2 getUID

This retrieves the UID for a file.

Two arguments are taken.The first is the configuration directory,
which if not defined is automatically chosen. The second is the
file in question.

    my $UID=$foo->getUID( $configDir, $file );
    if($foo->error){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub getUID{
    my $self=$_[0];
    my $configDir=$_[1];
    my $file=$_[2];
	my $method='getUID';

    #blank any previous errors
    if (!$self->errorblank) {
        return undef;
    }

	#make sure we have a directory to use
	if (!defined($configDir)) {
		$configDir=$self->{scm}->selectConfigDir;
		if ($self->{scm}->error) {
			$self->{error}=5;
			$self->{errorString}='Sys::Config::Manage->selectConfigDir errored error="'.
				$self->{scm}->error.'" errorString="'.$self->{scm}->errorString.'"';
			$self->warn;
			return undef;
		}
	}
	
	#make sure the config directory is valid
	my $valid=$self->{scm}->validConfigDirName($configDir);
	if ($self->{scm}->error) {
		$self->{error}=6;
		$self->{errorString}='Sys::Config::Manage->validConfigDirName errored error="'.
			$self->{scm}->error.'" errorString="'.$self->{scm}->errorString.'"';
		$self->warn;
		return undef;
	}
	if (defined( $valid )) {
		$self->{error}=3;
		$self->{errorString}='The configuration directory name '.$valid;
		$self->warn;
		return undef;
	}
	
	#makes sure it exists
	if ( ! -d $self->{scm}->{baseDir}.'/'.$configDir ) {
		$self->{error}=4;
		$self->{errorString}='The configuration directory, "'.$self->{baseDir}.'/'.$configDir.'", does not exist';
		$self->warn;
		return undef;
	}

	#make value for the file is specified
	if (!defined( $file )) {
		$self->{error}=7;
		$self->{errorString}='No file specified';
		$self->warn;
		return undef;
	}
	
	#make sure the file exists, under the config dir
	if (! -f $self->{scm}->{baseDir}.'/'.$configDir.'/'.$file ) {
		$self->{error}=8;
		$self->{errorString}='The file does not exist in the configuration directory';
		$self->warn;
		return undef;
	}

	#figure out what the perms file is
	my ($name,$path,$suffix) = fileparse($file);
	my $idfile=$self->{scm}->{baseDir}.'/'.$configDir.'/'.$path.'/.SysConfigManage/UID/'.$name;

	#make sure the file has some perms
	if (! -f $idfile ){
        return $self->{defaultUID};
	}

	#read the file
	my $fh;
	if ( ! open( $fh, '<', $idfile ) ){
		$self->{error}=15;
		$self->{errorString}='Unable to open "'.$idfile.'"';
		$self->warn;
		return undef;
	}
	my $id=<$fh>;
	chomp($id);
	close( $fh );

	return $id;
}

=head2 listConfigFiles

This lists the various config files that are being
tracked that actually have a value specified.

Not all files returned by Sys::Config::Manage->listConfigFiles
will have a value specified.

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
		$configDir=$self->{scm}->selectConfigDir;
		if ($self->{scm}->error) {
			$self->{error}=5;
			$self->{errorString}='Sys::Config::Manage->selectConfigDir errored error="'.
				$self->{scm}->error.'" errorString="'.$self->{scm}->errorString.'"';
			$self->warn;
			return undef;
		}
	}

	#make sure the config directory is valid
	my $valid=$self->{scm}->validConfigDirName($configDir);
	if ($self->{scm}->error) {
		$self->{error}=6;
		$self->{errorString}='Sys::Config::Manage->validConfigDirName errored error="'.
			$self->{scm}->error.'" errorString="'.$self->{scm}->errorString.'"';
		$self->warn;
		return undef;
	}
	if (defined( $valid )) {
		$self->{error}=3;
		$self->{errorString}='The configuration directory name '.$valid;
		$self->warn;
		return undef;
	}

	#makes sure it exists
	if ( ! -d $self->{scm}->{baseDir}.'/'.$configDir ) {
		$self->{error}=4;
		$self->{errorString}='The configuration directory, "'.$self->{baseDir}.'/'.$configDir.'", does not exist';
		$self->warn;
		return undef;
	}

	#holds what will be returned
	my @found;

	#get a list of files
	my @files=$self->{scm}->listConfigFiles($configDir);

	
	#process every found file
	my $int=0;
	while (defined( $files[$int] )) {
		my ($name,$path,$suffix)=fileparse($self->{scm}->{baseDir}
										   .'/'.$configDir.'/'.$files[$int]);

		my $UIDfile=$path.'/.SysConfigManage/UID/'.$name;
		$UIDfile=~s/\/\/*/\//g;

		my $GIDfile=$path.'/.SysConfigManage/GID/'.$name;
		$GIDfile=~s/\/\/*/\//g;

		#make sure the perms file exists and if so add it
		if (
			( -f $UIDfile ) ||
			( -f $GIDfile )
			) {
			push(@found, $files[$int]);
		}

		$int++;
	}

	return @found;
}

=head2 setGID

This sets the GID for a file. This does require the numeric value.

Three arguments are taken.

The first one is the configuration directory to use. If none is
specified, it will automatically be choosen.

The second is the config file to add the perms for.

The third numeric value for the GID.

    $foo->setGID($configDir, $file, $gid);
    if($foo->error){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub setGID{
	my $self=$_[0];
	my $configDir=$_[1];
	my $file=$_[2];
	my $id=$_[3];
	my $method='setGID';

	#blank any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#make sure we have a directory to use
	if (!defined($configDir)) {
		$configDir=$self->{scm}->selectConfigDir;
		if ($self->{scm}->error) {
			$self->{error}=5;
			$self->{errorString}='Sys::Config::Manage->selectConfigDir errored error="'.
			                     $self->{scm}->error.'" errorString="'.$self->{scm}->errorString.'"';
			$self->warn;
			return undef;
		}
	}

	#make sure the config directory is valid
	my $valid=$self->{scm}->validConfigDirName($configDir);
	if ($self->{scm}->error) {
		$self->{error}=6;
		$self->{errorString}='Sys::Config::Manage->validConfigDirName errored error="'.
		                     $self->{scm}->error.'" errorString="'.$self->{scm}->errorString.'"';
		$self->warn;
		return undef;
	}
	if (defined( $valid )) {
		$self->{error}=3;
		$self->{errorString}='The configuration directory name '.$valid;
		$self->warn;
		return undef;
	}

	#makes sure it exists
	if ( ! -d $self->{scm}->{baseDir}.'/'.$configDir ) {
		$self->{error}=4;
		$self->{errorString}='The configuration directory, "'.$self->{baseDir}.'/'.$configDir.'", does not exist';
		$self->warn;
		return undef;
	}

	#make value for the file is specified
	if (!defined( $file )) {
		$self->{error}=7;
		$self->{errorString}='No file specified';
		$self->warn;
		return undef;
	}

	#make sure the file exists, under the config dir
	if (! -f $self->{scm}->{baseDir}.'/'.$configDir.'/'.$file ) {
		$self->{error}=8;
		$self->{errorString}='The file does not exist in the configuration directory';
		$self->warn;
		return undef;	
	}

	#make sure we have a some perms passed
	if ( ! defined( $id ) ){
		$self->{error}=11;
		$self->{errorString}='No value for the permissions specified';
		$self->warn;
        return undef;
	}

	#make sure the perms are sane
	if ( $id !~ /^[0123456789]*$/ ){
        $self->{error}=12;
        $self->{errorString}='"'.$id.'" does not appear to be a valid value';
        warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
        return undef;
	}

	#creates the .SysConfigManage if needed
	my ($name,$path,$suffix) = fileparse($file);
    my $scmd=$self->{scm}->{baseDir}.'/'.$configDir.'/'.$path.'/.SysConfigManage';
	if ( ! -d $scmd ){
		if ( ! mkdir( $scmd ) ){
			$self->{error}=13;
			$self->{errorString}='Unable to create "'.$scmd.'"';
			$self->warn;
			return undef;
		}
	}

	#makes sure that the perms dir exists
	my $iddir=$scmd.'/GID';
	if ( ! -d $iddir ){
		if ( ! mkdir( $iddir ) ){
			$self->{error}=14;
            $self->{errorString}='Unable to create "'.$iddir.'"';
            $self->warn;
            return undef;
		}
	}

	#this is the file that will store the perms
	my $idfile=$iddir.'/'.$name;

	#check if it exists
	my $exists=0;
	if ( -f $idfile ){
		$exists=1;
	}

	my $fh;
	if ( ! open( $fh, '>', $idfile ) ){
		$self->{error}=15;
		$self->{errorString}='Unable to open "'.$idfile.'"';
		$self->warn;
		return undef;
	}
	print $fh $id;
	close( $fh );

	#add it if it, if it did not exist previously
	if ( ! $exists ){
		if (defined( $self->{scm}->{addCommand} )) {
			my $command=$self->{scm}->{addCommand};
			my $newfile=shell_quote($idfile);
			
			$command=~s/\%\%\%file\%\%\%/$newfile/g;
			system($command);
			my $exit = $?<<8;
			if ($exit ne '0') {
				$self->{error}=16;
				$self->{errorString}='The add command failed. command="'.$command.'" exit="'.$exit.'"';
				$self->warn;
				return undef;
			}
        }
	}
	
	return 1;
}

=head2 setUID

This sets the UID for a file. This does require the numeric value.

Three arguments are taken.

The first one is the configuration directory to use. If none is
specified, it will automatically be choosen.

The second is the config file to add the perms for.

The third numeric value for the UID.

    $foo->setUID($configDir, $file, $uid);
    if($foo->error){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub setUID{
	my $self=$_[0];
	my $configDir=$_[1];
	my $file=$_[2];
	my $id=$_[3];
	my $method='setUID';

	#blank any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#make sure we have a directory to use
	if (!defined($configDir)) {
		$configDir=$self->{scm}->selectConfigDir;
		if ($self->{scm}->error) {
			$self->{error}=5;
			$self->{errorString}='Sys::Config::Manage->selectConfigDir errored error="'.
			                     $self->{scm}->error.'" errorString="'.$self->{scm}->errorString.'"';
			$self->warn;
			return undef;
		}
	}

	#make sure the config directory is valid
	my $valid=$self->{scm}->validConfigDirName($configDir);
	if ($self->{scm}->error) {
		$self->{error}=6;
		$self->{errorString}='Sys::Config::Manage->validConfigDirName errored error="'.
		                     $self->{scm}->error.'" errorString="'.$self->{scm}->errorString.'"';
		$self->warn;
		return undef;
	}
	if (defined( $valid )) {
		$self->{error}=3;
		$self->{errorString}='The configuration directory name '.$valid;
		$self->warn;
		return undef;
	}

	#makes sure it exists
	if ( ! -d $self->{scm}->{baseDir}.'/'.$configDir ) {
		$self->{error}=4;
		$self->{errorString}='The configuration directory, "'.$self->{baseDir}.'/'.$configDir.'", does not exist';
		$self->warn;
		return undef;
	}

	#make value for the file is specified
	if (!defined( $file )) {
		$self->{error}=7;
		$self->{errorString}='No file specified';
		$self->warn;
		return undef;
	}

	#make sure the file exists, under the config dir
	if (! -f $self->{scm}->{baseDir}.'/'.$configDir.'/'.$file ) {
		$self->{error}=8;
		$self->{errorString}='The file does not exist in the configuration directory';
		$self->warn;
		return undef;	
	}

	#make sure we have a some perms passed
	if ( ! defined( $id ) ){
		$self->{error}=11;
		$self->{errorString}='No value for the permissions specified';
		$self->warn;
        return undef;
	}

	#make sure the perms are sane
	if ( $id !~ /^[0123456789]*$/ ){
        $self->{error}=12;
        $self->{errorString}='"'.$id.'" does not appear to be a valid value';
        warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
        return undef;
	}

	#creates the .SysConfigManage if needed
	my ($name,$path,$suffix) = fileparse($file);
    my $scmd=$self->{scm}->{baseDir}.'/'.$configDir.'/'.$path.'/.SysConfigManage';
	if ( ! -d $scmd ){
		if ( ! mkdir( $scmd ) ){
			$self->{error}=13;
			$self->{errorString}='Unable to create "'.$scmd.'"';
			$self->warn;
			return undef;
		}
	}

	#makes sure that the perms dir exists
	my $iddir=$scmd.'/UID';
	if ( ! -d $iddir ){
		if ( ! mkdir( $iddir ) ){
			$self->{error}=14;
            $self->{errorString}='Unable to create "'.$iddir.'"';
            $self->warn;
            return undef;
		}
	}

	#this is the file that will store the perms
	my $idfile=$iddir.'/'.$name;

	#check if it exists
	my $exists=0;
	if ( -f $idfile ){
		$exists=1;
	}

	my $fh;
	if ( ! open( $fh, '>', $idfile ) ){
		$self->{error}=15;
		$self->{errorString}='Unable to open "'.$idfile.'"';
		$self->warn;
		return undef;
	}
	print $fh $id;
	close( $fh );

	#add it if it, if it did not exist previously
	if ( ! $exists ){
		if (defined( $self->{scm}->{addCommand} )) {
			my $command=$self->{scm}->{addCommand};
			my $newfile=shell_quote($idfile);
			
			$command=~s/\%\%\%file\%\%\%/$newfile/g;
			system($command);
			my $exit = $?<<8;
			if ($exit ne '0') {
				$self->{error}=16;
				$self->{errorString}='The add command failed. command="'.$command.'" exit="'.$exit.'"';
				$self->warn;
				return undef;
			}
        }
	}
	
	return 1;
}

=head2 setGIDfromFile

This sets the GID for a file, from a already existing file.

Three arguments are taken.

The first one is the configuration directory to use. If none is
specified, it will automatically be choosen.

The second is the config file to add the perms for.

    $foo->setUIDfromFile($configDir, $file);
    if($foo->error){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub setGIDfromFile{
    my $self=$_[0];
    my $configDir=$_[1];
    my $file=$_[2];
    my $method='setGIDfromFile';

    #blank any previous errors
    if (!$self->errorblank) {
        return undef;
    }

	#make sure we have a directory to use
	if (!defined($configDir)) {
		$configDir=$self->{scm}->selectConfigDir;
		if ($self->{scm}->error) {
			$self->{error}=5;
			$self->{errorString}='Sys::Config::Manage->selectConfigDir errored error="'.
				$self->{scm}->error.'" errorString="'.$self->{scm}->errorString.'"';
			$self->warn;
			return undef;
		}
	}

	#make sure the config directory is valid
	my $valid=$self->{scm}->validConfigDirName($configDir);
	if ($self->{scm}->error) {
		$self->{error}=6;
		$self->{errorString}='Sys::Config::Manage->validConfigDirName errored error="'.
			$self->{scm}->error.'" errorString="'.$self->{scm}->errorString.'"';
		$self->warn;
		return undef;
	}
	if (defined( $valid )) {
		$self->{error}=3;
		$self->{errorString}='The configuration directory name '.$valid;
		$self->warn;
		return undef;
	}

	#makes sure it exists
	if ( ! -d $self->{scm}->{baseDir}.'/'.$configDir ) {
		$self->{error}=4;
		$self->{errorString}='The configuration directory, "'.$self->{baseDir}.'/'.$configDir.'", does not exist';
		$self->warn;
		return undef;
	}

	#make value for the file is specified
	if (!defined( $file )) {
		$self->{error}=7;
		$self->{errorString}='No file specified';
		$self->warn;
		return undef;
	}

	#make sure the file exists, under the config dir
	if (! -f $self->{scm}->{baseDir}.'/'.$configDir.'/'.$file ) {
		$self->{error}=8;
		$self->{errorString}='The file does not exist in the configuration directory';
		$self->warn;
		return undef;
	}

	#make sure the file exists, on the fs
	if (! -f $file ) {
		$self->{error}=9;
		$self->{errorString}='The file does not exist in the configuration directory';
		$self->warn;
		return undef;
	}

	#make sure it is not under the base directory
	if ( ! $self->{scm}->notUnderBase($file) ){
		$self->{error}=10;
		$self->{errorString}='"'.$file.'" exists under the base directory, "'.$self->{scm}->{baseDir}.'"';
		$self->warn;
        return undef;
	}

	#stat the file
	my $id = (stat($file))[5];
	
	$self->setGID($configDir, $file, $id);
	if ( $self->error ){
		warn($self->{module}.' '.$method.': : setUID errored');
        return undef;
	}

	return 1;
}

=head2 setUIDfromFile

This sets the UID for a file, from a already existing file.

Three arguments are taken.

The first one is the configuration directory to use. If none is
specified, it will automatically be choosen.

The second is the config file to add the perms for.

    $foo->setUIDfromFile($configDir, $file);
    if($foo->error){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub setUIDfromFile{
    my $self=$_[0];
    my $configDir=$_[1];
    my $file=$_[2];
    my $method='setUIDfromFile';

    #blank any previous errors
    if (!$self->errorblank) {
        return undef;
    }

	#make sure we have a directory to use
	if (!defined($configDir)) {
		$configDir=$self->{scm}->selectConfigDir;
		if ($self->{scm}->error) {
			$self->{error}=5;
			$self->{errorString}='Sys::Config::Manage->selectConfigDir errored error="'.
				$self->{scm}->error.'" errorString="'.$self->{scm}->errorString.'"';
			$self->warn;
			return undef;
		}
	}

	#make sure the config directory is valid
	my $valid=$self->{scm}->validConfigDirName($configDir);
	if ($self->{scm}->error) {
		$self->{error}=6;
		$self->{errorString}='Sys::Config::Manage->validConfigDirName errored error="'.
			$self->{scm}->error.'" errorString="'.$self->{scm}->errorString.'"';
		$self->warn;
		return undef;
	}
	if (defined( $valid )) {
		$self->{error}=3;
		$self->{errorString}='The configuration directory name '.$valid;
		$self->warn;
		return undef;
	}

	#makes sure it exists
	if ( ! -d $self->{scm}->{baseDir}.'/'.$configDir ) {
		$self->{error}=4;
		$self->{errorString}='The configuration directory, "'.$self->{baseDir}.'/'.$configDir.'", does not exist';
		$self->warn;
		return undef;
	}

	#make value for the file is specified
	if (!defined( $file )) {
		$self->{error}=7;
		$self->{errorString}='No file specified';
		$self->warn;
		return undef;
	}

	#make sure the file exists, under the config dir
	if (! -f $self->{scm}->{baseDir}.'/'.$configDir.'/'.$file ) {
		$self->{error}=8;
		$self->{errorString}='The file does not exist in the configuration directory';
		$self->warn;
		return undef;
	}

	#make sure the file exists, on the fs
	if (! -f $file ) {
		$self->{error}=9;
		$self->{errorString}='The file does not exist in the configuration directory';
		$self->warn;
		return undef;
	}

	#make sure it is not under the base directory
	if ( ! $self->{scm}->notUnderBase($file) ){
		$self->{error}=10;
		$self->{errorString}='"'.$file.'" exists under the base directory, "'.$self->{scm}->{baseDir}.'"';
		$self->warn;
        return undef;
	}

	#stat the file
	my $id = (stat($file))[4];
	
	$self->setUID($configDir, $file, $id);
	if ( $self->error ){
		warn($self->{module}.' '.$method.': : setUID errored');
        return undef;
	}

	return 1;
}

=head2 upSync

This syncs the file user/group up from the file system to
configuration directory.

Two arguments can be used.

The first is the configuration directory. If not specified, it will
be automaticallly choosen.

The second is the files to sync. If not specified, all files will
be synced.

    #sync the specified files
    $foo->upSync( $configDir, \@files);
    if($foo->error){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

    #syncs all the files
    $foo->upSync( $configDir );
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
    my $method='upSync';
	
	#blank any previous errors
    if (!$self->errorblank) {
		return undef;
    }
	
	#make sure we have a directory to use
	if (!defined($configDir)) {
		$configDir=$self->{scm}->selectConfigDir;
		if ($self->{scm}->error) {
			$self->{error}=5;
			$self->{errorString}='Sys::Config::Manage->selectConfigDir errored error="'.
				$self->{scm}->error.'" errorString="'.$self->{scm}->errorString.'"';
			$self->warn;
			return undef;
		}
	}
	
	#make sure the config directory is valid
	my $valid=$self->{scm}->validConfigDirName($configDir);
	if ($self->{scm}->error) {
		$self->{error}=6;
		$self->{errorString}='Sys::Config::Manage->validConfigDirName errored error="'.
			$self->{scm}->error.'" errorString="'.$self->{scm}->errorString.'"';
		$self->warn;
		return undef;
	}
	if (defined( $valid )) {
		$self->{error}=3;
		$self->{errorString}='The configuration directory name '.$valid;
		$self->warn;
		return undef;
	}
	
	#makes sure it exists
	if ( ! -d $self->{scm}->{baseDir}.'/'.$configDir ) {
		$self->{error}=4;
		$self->{errorString}='The configuration directory, "'.$self->{baseDir}.'/'.$configDir.'", does not exist';
		$self->warn;
		return undef;
	}

	#checks and make sure all the files exist
	my $int=0;
	if(defined( $files[$int] )){
		my @allfiles=$self->{scm}->listConfigFiles($configDir);
        if( $self->{scm}->error ){
            $self->{error}='16';
            $self->{errorString}='Sys::Config::Manage->listConfigFiles errored error="'.
                $self->{scm}->error.'" errorString="'.$self->{scm}->errorString.'"';
			$self->warn;
            return undef;
        }
		
		#make sure each file asked to be synced is tracked
		while(defined( $files[$int]  )){

			my $matched=0;
			my $int2=0;
			while(defined( $allfiles[$int2] )){
				if( $files[$int] eq $allfiles[$int2] ){
					$matched=1;
				}

				$int2++;
			}

			if(! $matched){
				$self->{error}='8';
				$self->{errorString}='"'.$files[$int].'" does not exist under the configuration directory, "'.$configDir.'",';
				$self->warn;
				return undef;
			}

			$int++;
		}

	}else{
		#if we get here, no files have been specified so we do them all
		@files=$self->{scm}->listConfigFiles($configDir);
		if( $self->{scm}->error ){
			$self->{error}='16';
			$self->{errorString}='Sys::Config::Manage->listConfigFiles errored error="'.
				$self->{scm}->error.'" errorString="'.$self->{scm}->errorString.'"';
			$self->warn;
			return undef;
		}
	}

	#process each file
	$int=0;
	while( defined( $files[$int] ) ){
		#try to sync the UID from what it currently is
		$self->setUIDfromFile( $configDir, $files[$int] );
		if( $self->error ){
			warn( $self->{module}.' '.$method.': $self->setUIDfromFile( $configDir, $files[$int] ) errored' );
			return undef;
		}

		#try to sync the GID from what it currently is
		$self->setGIDfromFile( $configDir, $files[$int] );
		if( $self->error ){
			warn( $self->{module}.' '.$method.': $self->setGIDfromFile( $configDir, $files[$int] ) errored' );
			return undef;
		}
		
		$int++;
	}

	return 1;
}

=head1 ERROR CODES

=head2 1

Nothing passed for the Sys::Config::Manage object.

=head2 2

$args{scm} is not a Sys::Config::Manage object.

=head2 3

Invalid configuration directory name.

=head2 4

The configuration directory does not exist.

=head2 5

Sys::Config::Manage->selectConfigDir errored.

=head2 6

Sys::Config::Manage->validConfigDirName errored.

=head2 7

No filename specified.

=head2 8

The specified file does not exist under the configuration directory.

=head2 9

The specified file does not exist on the file system.

=head2 10

The file specified file is under the base directory.

=head2 11

No value for the permissions specified.

=head2 12

The value specified for the [UG]ID does not appear to be valid.

Validity is checked via the regexp below.

    /^[0123456789]*$/

=head2 13

The ".SysConfigManage" directory does not exist and could not be created.

=head2 14

The ".SysConfigManage/UID" directory does not exist and could not be created.

=head2 15

Unable to opens the [GU]ID file.

=head2 16

The add command failed.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sys-config-manage-perms at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sys-Config-Manage-Ownership>.  I will
be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sys::Config::Manage::Ownership


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

1; # End of Sys::Config::Manage::Ownership
