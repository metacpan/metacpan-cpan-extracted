package Sys::Config::Manage::Perms;

use warnings;
use strict;
use File::Basename;
use base 'Error::Helper';
use String::ShellQuote;

=head1 NAME

Sys::Config::Manage::Perms - Handles file permissions for files in a configuration directory.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS

    use Sys::Config::Manage::Perms;

    my $foo = Sys::Config::Manage::Perms->new();
    ...

=head1 METHODS

=head2 new

This initiates the object.

One argument is required and it is a hash reference.

=head3 args hash ref

=head4 scm

This is a initiated Sys::Config::Manage object.

=head4 default

Default value to use for the mode.

If not specified, it defaults to '0644'.

    $foo=Sys::Config::Manage::Perms->new(\%args);
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
		module=>'Sys-Config-Manage-Perms',
		perror=>undef,
		error=>undef,
		errorString=>"",
		default=>'0644',
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
	if ( defined( $args{default} ) ){
		#make sure the perms are sane
        if ( $args{default} !~ /^[01246][01234567][01234567][01234567]$/ ){
			$self->{perror}=1;
			$self->{error}=12;
			$self->{errorString}='"'.$args{default}.'" does not appear to be a valid value';
			$self->warn;
			return $self;
        }
		$self->{default}=$args{default};
	}

	$self->{scm}=$args{scm};

	return $self;
}

=head2 downSync

This syncs the file permissions down from the configuration
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
		my $perms=$self->getPerms( $configDir, $files[$int] );
		if( $self->error ){
			warn($self->{module}.' '.$method.': Sys::Config::Manage::Perms->getPerms errored');
			return undef;
		}

		#try to chmod it
		if(!chmod( oct($perms), $files[$int] )){
			$self->{error}='17';
            $self->{errorString}='chmod( '.$perms.', "'.$files[$int].'") errored';
			$self->warn;
            return undef;
		}
		
		$int++;
	}

	return 1;
}

=head2 getPerms

This retrieves the mode for a file.

Two arguments are taken.The first is the configuration directory,
which if not defined is automatically chosen. The second is the
file in question.

    my $mode=$foo->getPerms( $configDir, $file );
    if($foo->error){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub getPerms{
    my $self=$_[0];
    my $configDir=$_[1];
    my $file=$_[2];
	my $method='getPerms';

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
	my $permsfile=$self->{scm}->{baseDir}.'/'.$configDir.'/'.$path.'/.SysConfigManage/Perms/'.$name;

	#make sure the file has some perms
	if (! -f $permsfile ){
        return $self->{default};
	}

	#read the file
	my $fh;
	if ( ! open( $fh, '<', $permsfile ) ){
		$self->{error}=15;
		$self->{errorString}='Unable to open "'.$permsfile.'"';
		$self->warn;
		return undef;
	}
	my $perms=<$fh>;
	chomp($perms);
	close( $fh );

	return $perms;
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


		my $permsFile=$path.'/.SysConfigManage/Perms/'.$name;
		$permsFile=~s/\/\/*/\//g;

		#make sure the perms file exists and if so add it
		if ( -f $permsFile ) {
			push(@found, $files[$int]);
		}

		$int++;
	}

	return @found;
}

=head2 setPerms

This sets the permissions for a file. This does require the numeric value.

Three arguments are taken.

The first one is the configuration directory to use. If none is
specified, it will automatically be choosen.

The second is the config file to add the perms for.

The third numeric value for the permissions.

    $foo->setPerms($configDir, $file, '0640');
    if($foo->error){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub setPerms{
	my $self=$_[0];
	my $configDir=$_[1];
	my $file=$_[2];
	my $perms=$_[3];
	my $method='setPerms';

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
	if ( ! defined( $perms ) ){
		$self->{error}=11;
		$self->{errorString}='No value for the permissions specified';
		$self->warn;
        return undef;
	}

	#make sure the perms are sane
	if ( $perms !~ /^[01246][01234567][01234567][01234567]$/ ){
        $self->{error}=12;
        $self->{errorString}='"'.$perms.'" does not appear to be a valid value';
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
	my $permsdir=$scmd.'/Perms';
	if ( ! -d $permsdir ){
		if ( ! mkdir( $permsdir ) ){
			$self->{error}=14;
            $self->{errorString}='Unable to create "'.$permsdir.'"';
            $self->warn;
            return undef;
		}
	}

	#this is the file that will store the perms
	my $permsfile=$permsdir.'/'.$name;

	#check if it exists
	my $exists=0;
	if ( -f $permsfile ){
		$exists=1;
	}

	my $fh;
	if ( ! open( $fh, '>', $permsfile ) ){
		$self->{error}=15;
		$self->{errorString}='Unable to open "'.$permsfile.'"';
		$self->warn;
		return undef;
	}
	print $fh $perms;
	close( $fh );

	#add it if it, if it did not exist previously
	if ( ! $exists ){
		if (defined( $self->{scm}->{addCommand} )) {
			my $command=$self->{scm}->{addCommand};
			my $newfile=shell_quote($permsfile);
			
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

=head2 setPermsFromFile

This sets the permissions for a file, from a already existing file.

Three arguments are taken.

The first one is the configuration directory to use. If none is
specified, it will automatically be choosen.

The second is the config file to add the perms for.

    $foo->setPermsFromFile($configDir, $file);
    if($foo->error){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub setPermsFromFile{
    my $self=$_[0];
    my $configDir=$_[1];
    my $file=$_[2];
    my $method='setPermsFromFile';

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
	my $mode = (stat($file))[2] & 07777;
	$mode=sprintf("%04o", $mode);
	
	$self->setPerms($configDir, $file, $mode);
	if ( $self->error ){
		warn($self->{module}.' '.$method.': : setPerm errored');
        return undef;
	}

	return 1;
}

=head2 upSync

This syncs the file permissions up from the file system to
configuration directory.

Two arguments can be used.

The first is the configuration directory. If not specified, it will
be automaticallly choosen.

The second is the files to sync. If not specifiedm, all files will
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
		#try to sync it from what it currently is
		$self->setPermsFromFile( $configDir, $files[$int] );
		if( $self->error ){
			warn( $self->{module}.' '.$method.': $self->setPermsFromFile( $configDir, $files[$int] ) errored' );
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

The value specified for the permissions does not appear to be valid.

Validity is checked via the regexp below.

    /^[01246][01234567][01234567][01234567]$/

=head2 13

The ".SysConfigManage" directory does not exist and could not be created.

=head2 14

The ".SysConfigManage/Perms" directory does not exist and could not be created.

=head2 15

Unable to opens the permissions file.

=head2 16

The add command failed.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sys-config-manage-perms at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sys-Config-Manage-Perms>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sys::Config::Manage::Perms


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

1; # End of Sys::Config::Manage::Perms
