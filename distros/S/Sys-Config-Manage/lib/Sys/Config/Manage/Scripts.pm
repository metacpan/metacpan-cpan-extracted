package Sys::Config::Manage::Scripts;

use warnings;
use strict;
use File::Basename;
use base 'Error::Helper';
use String::ShellQuote;
use Term::CallEditor qw/solicit/;

=head1 NAME

Sys::Config::Manage::Scripts - Allows scripts to be stored specifically for a configuration directory.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';


=head1 SYNOPSIS

    use Sys::Config::Manage::Scripts;

    my $foo = Sys::Config::Manage::Scripts->new();
    ...

=head1 METHODS

=head2 new

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
		module=>'Sys-Config-Manage-Scripts',
		perror=>undef,
		error=>undef,
		errorString=>"",
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

	$self->{scm}=$args{scm};

	return $self;
}

=head2 editScript

=cut

sub editScript{
	my $self=$_[0];
    my $configDir=$_[1];
	my $script=$_[2];

    if( ! $self->errorblank ){
        return undef;
	}

	#make sure a script is specified
	if(!defined($script)){
		$self->{error}=7;
		$self->{errorString}='No script specified';
		$self->warn;
		return undef;
	}

	#make sure that it does not contain a forward slash
	if ( $script =~ /\// ){
		$self->{error}=10;
		$self->{errorString}='The script name,"'.$script.'", contains a forward slash.';
		$self->warn;
		return undef;
	}

	#make sure we have a directory to use
	if (!defined($configDir)) {
		$configDir=$self->{scm}->selectConfigDir;
		if ($self->{scm}->error) {
			$self->{error}=3;
			$self->{errorString}='Sys::Config::Manage->selectConfigDir errored error="'.
				$self->{scm}->error.'" errorString="'.$self->{scm}->errorString.'"';
			$self->warn;
			return undef;
		}
	}
	
	#make sure the config directory is valid
	my $valid=$self->{scm}->validConfigDirName($configDir);
	if ($self->{scm}->error) {
		$self->{error}=3;
		$self->{errorString}='Sys::Config::Manage->validConfigDirName errored error="'.
			$self->{scm}->error.'" errorString="'.$self->{scm}->errorString.'"';
		$self->warn;
		return undef;
	}
	if (defined( $valid )) {
		$self->{error}=4;
		$self->{errorString}='The configuration directory name '.$valid;
		$self->warn;
		return undef;
	}
	
	#makes sure it exists
	if ( ! -d $self->{scm}->{baseDir}.'/'.$configDir ) {
		$self->{error}=5;
		$self->{errorString}='The configuration directory, "'.$self->{baseDir}.'/'.$configDir.'", does not exist';
		$self->warn;
		return undef;
	}

	my $scriptFile=$self->{scm}->{baseDir}.'/'.$configDir.'/.SysConfigManage/Scripts/'.$script;

	#error if it does not exist
	my $data='';
	if(  -f $scriptFile ){
		my $fh;
		if ( ! open( $fh, '<', $scriptFile ) ){
			$self->{error}=11;
			$self->{errorString}='Failed to open "'.$scriptFile.'" for reading';
			$self->warn;
			return undef;
		}
		$data=join('', <$fh>);
		close $fh;
	}

	my $fh=solicit($data);
	$data=join( '', <$fh> );
	close( $fh );

	$self->writeScript( $configDir, $script, $data );
	if ( $self->error ){
		$self->warnString('Failed to write the script out');
		return undef;
	}

	return 1;
}

=head2 getScript

This returns the contents of the specified script.

Two arguments are taken. The first and optional one is the
configuration directory, which if not specified it will be
automatically choosen. The second and required is the
script name.

    my $data=$foo->getScript( $configDir, $script );
    if($foo->error){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub getScript{
	my $self=$_[0];
    my $configDir=$_[1];
	my $script=$_[2];

    if( ! $self->errorblank ){
        return undef;
	}

	#make sure a script is specified
	if(!defined($script)){
		$self->{error}=7;
		$self->{errorString}='No script specified';
		$self->warn;
		return undef;
	}

	#make sure that it does not contain a forward slash
	if ( $script =~ /\// ){
		$self->{error}=10;
		$self->{errorString}='The script name,"'.$script.'", contains a forward slash.';
		$self->warn;
		return undef;
	}

	#make sure we have a directory to use
	if (!defined($configDir)) {
		$configDir=$self->{scm}->selectConfigDir;
		if ($self->{scm}->error) {
			$self->{error}=3;
			$self->{errorString}='Sys::Config::Manage->selectConfigDir errored error="'.
				$self->{scm}->error.'" errorString="'.$self->{scm}->errorString.'"';
			$self->warn;
			return undef;
		}
	}
	
	#make sure the config directory is valid
	my $valid=$self->{scm}->validConfigDirName($configDir);
	if ($self->{scm}->error) {
		$self->{error}=3;
		$self->{errorString}='Sys::Config::Manage->validConfigDirName errored error="'.
			$self->{scm}->error.'" errorString="'.$self->{scm}->errorString.'"';
		$self->warn;
		return undef;
	}
	if (defined( $valid )) {
		$self->{error}=4;
		$self->{errorString}='The configuration directory name '.$valid;
		$self->warn;
		return undef;
	}
	
	#makes sure it exists
	if ( ! -d $self->{scm}->{baseDir}.'/'.$configDir ) {
		$self->{error}=5;
		$self->{errorString}='The configuration directory, "'.$self->{baseDir}.'/'.$configDir.'", does not exist';
		$self->warn;
		return undef;
	}

	my $scriptFile=$self->{scm}->{baseDir}.'/'.$configDir.'/.SysConfigManage/Scripts/'.$script;

	#error if it does not exist
	if( ! -f $scriptFile ){
		$self->{error}=12;
		$self->{errorString}='The script, "'.$script.'"("'.$scriptFile.'"), does not exist';
		$self->warn;
		return undef;
	}

	#open it for reading
	my $fh;
	if ( ! open( $fh, '<', $scriptFile ) ){
		$self->{error}=11;
		$self->{errorString}='Failed to open "'.$scriptFile.'" for reading';
		$self->warn;
		return undef;
	}
	my $data=join('', <$fh>);
	close $fh;

	return $data;
}

=head2 listScripts

This lists the scripts for the configuration directory in question.

    my @scripts=$foo->listScripts($configDir);
    if ( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub listScripts{
	my $self=$_[0];
	my $configDir=$_[1];

	if( ! $self->errorblank ){
		return undef;
	}
	
	#make sure we have a directory to use
	if (!defined($configDir)) {
		$configDir=$self->{scm}->selectConfigDir;
		if ($self->{scm}->error) {
			$self->{error}=3;
			$self->{errorString}='Sys::Config::Manage->selectConfigDir errored error="'.
				$self->{scm}->error.'" errorString="'.$self->{scm}->errorString.'"';
			$self->warn;
			return undef;
		}
	}

	#make sure the config directory is valid
	my $valid=$self->{scm}->validConfigDirName($configDir);
	if ($self->{scm}->error) {
		$self->{error}=3;
		$self->{errorString}='Sys::Config::Manage->validConfigDirName errored error="'.
			$self->{scm}->error.'" errorString="'.$self->{scm}->errorString.'"';
		$self->warn;
		return undef;
	}
	if (defined( $valid )) {
		$self->{error}=4;
		$self->{errorString}='The configuration directory name '.$valid;
		$self->warn;
		return undef;
	}
	
	#makes sure it exists
	if ( ! -d $self->{scm}->{baseDir}.'/'.$configDir ) {
		$self->{error}=5;
		$self->{errorString}='The configuration directory, "'.$self->{baseDir}.'/'.$configDir.'", does not exist';
		$self->warn;
		return undef;
	}

	#the script directory
	my $scriptDir=$self->{scm}->{baseDir}.'/'.$configDir.'/.SysConfigManage/Scripts/';

	#return undef if the script directory does not exist
	if (! -d $scriptDir ){
		return undef;
	}

	#read the directory
	my $fh;
	if(! opendir( $fh, $scriptDir ) ){
		$self->{error}=6;
		$self->{errorString}='Unable to open the script directory, "'.$scriptDir.'",';
		$self->warn;
		return undef;
	}
	my @dirEntries=readdir($fh);
	closedir($fh);

	#only interested in files
	my @toreturn;
	my $int=0;
	while(defined($dirEntries[$int])){
		if( -f $scriptDir.'/'.$dirEntries[$int] ){
			push(@toreturn, $dirEntries[$int]);
		}

		$int++;
	}
	
	return @toreturn;
}

=head2 scriptExists

This verifies that the script in question exists.

Two arguments are taken. The first is the configuration
directory and if not specified it will be choosen
automatically. The second is the script name.

    my $exists=$foo->scriptExists($configDir, $script);
    if( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }else{
        if( $exists ){
            print "It exists\n";
        }else
            print "It does not exists\n";
        }
    }

=cut

sub scriptExists{
	my $self=$_[0];
	my $configDir=$_[1];
	my $script=$_[2];
	
	if( ! $self->errorblank ){
		return undef;
	}

	if(!defined($script)){
		$self->{error}=7;
		$self->{errorString}='No script specified';
		$self->warn;
		return undef;
	}
	
	#make sure we have a directory to use
	if (!defined($configDir)) {
		$configDir=$self->{scm}->selectConfigDir;
		if ($self->{scm}->error) {
			$self->{error}=3;
			$self->{errorString}='Sys::Config::Manage->selectConfigDir errored error="'.
				$self->{scm}->error.'" errorString="'.$self->{scm}->errorString.'"';
			$self->warn;
			return undef;
		}
	}

	#make sure the config directory is valid
	my $valid=$self->{scm}->validConfigDirName($configDir);
	if ($self->{scm}->error) {
		$self->{error}=3;
		$self->{errorString}='Sys::Config::Manage->validConfigDirName errored error="'.
			$self->{scm}->error.'" errorString="'.$self->{scm}->errorString.'"';
		$self->warn;
		return undef;
	}
	if (defined( $valid )) {
		$self->{error}=4;
		$self->{errorString}='The configuration directory name '.$valid;
		$self->warn;
		return undef;
	}
	
	#makes sure it exists
	if ( ! -d $self->{scm}->{baseDir}.'/'.$configDir ) {
		$self->{error}=5;
		$self->{errorString}='The configuration directory, "'.$self->{baseDir}.'/'.$configDir.'", does not exist';
		$self->warn;
		return undef;
	}

	if( -f $self->{scm}->{baseDir}.'/'.$configDir.'/.SysConfigManage/Scripts/'.$script ){
		return 1;
	}

	return undef;
}

=head2 readScript

This reads a script and returns it's contents.

The arguments are taken. The fist is the name of the configuration
directory and it not specified it will be automarically choosen.
The second is the script name.

    my $contents=$foo->readScript( $configDir, $script );
    if( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub readScript{
	my $self=$_[0];
	my $configDir=$_[1];
	my $script=$_[2];
	
	if( ! $self->errorblank ){
		return undef;
	}
	
	if(!defined($script)){
		$self->{error}=7;
		$self->{errorString}='No script specified';
		$self->warn;
		return undef;
	}
	
	#make sure we have a directory to use
	if (!defined($configDir)) {
		$configDir=$self->{scm}->selectConfigDir;
		if ($self->{scm}->error) {
			$self->{error}=3;
			$self->{errorString}='Sys::Config::Manage->selectConfigDir errored error="'.
				$self->{scm}->error.'" errorString="'.$self->{scm}->errorString.'"';
			$self->warn;
			return undef;
		}
	}
	
	#make sure the config directory is valid
	my $valid=$self->{scm}->validConfigDirName($configDir);
	if ($self->{scm}->error) {
		$self->{error}=3;
		$self->{errorString}='Sys::Config::Manage->validConfigDirName errored error="'.
			$self->{scm}->error.'" errorString="'.$self->{scm}->errorString.'"';
		$self->warn;
		return undef;
	}
	if (defined( $valid )) {
		$self->{error}=4;
		$self->{errorString}='The configuration directory name '.$valid;
		$self->warn;
		return undef;
	}
	
	#makes sure the configuration directory exists
	if ( ! -d $self->{scm}->{baseDir}.'/'.$configDir ) {
		$self->{error}=5;
		$self->{errorString}='The configuration directory, "'.$self->{baseDir}.'/'.$configDir.'", does not exist';
		$self->warn;
		return undef;
	}

	my $scriptFile=$self->{scm}->{baseDir}.'/'.$configDir.'/.SysConfigManage/Scripts/'.$script;

	#error if it does not exist
	if( ! -f $scriptFile ){
		$self->{error}=12;
		$self->{errorString}='The script, "'.$script.'"("'.$scriptFile.'"), does not exist';
		$self->warn;
		return undef;
	}

	my $fh;
	if( ! open( $fh, '<', $scriptFile ) ){
		$self->{error}=11;
		$self->{errorString}='The script, "'.$script.'"("'.$scriptFile.'"), could not be opened ';
		$self->warn;
		return undef;
	}
	my $contents=join('', <$fh>);
	close($fh);

	return $contents;
}

=head2 runScript

This executes the via system.

The arguments are taken. The fist is the name of the configuration
directory and it not specified it will be automarically choosen.
The second is the script name.

    my $exit=$foo->runScript($configDir, $script);
    if( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }  

=cut

sub runScript{
	my $self=$_[0];
	my $configDir=$_[1];
	my $script=$_[2];

	if( ! $self->errorblank ){
		return undef;
	}

	if(!defined($script)){
		$self->{error}=7;
		$self->{errorString}='No script specified';
		$self->warn;
		return undef;
	}
	
	#make sure we have a directory to use
	if (!defined($configDir)) {
		$configDir=$self->{scm}->selectConfigDir;
		if ($self->{scm}->error) {
			$self->{error}=3;
			$self->{errorString}='Sys::Config::Manage->selectConfigDir errored error="'.
				$self->{scm}->error.'" errorString="'.$self->{scm}->errorString.'"';
			$self->warn;
			return undef;
		}
	}
	
	#make sure the config directory is valid
	my $valid=$self->{scm}->validConfigDirName($configDir);
	if ($self->{scm}->error) {
		$self->{error}=3;
		$self->{errorString}='Sys::Config::Manage->validConfigDirName errored error="'.
			$self->{scm}->error.'" errorString="'.$self->{scm}->errorString.'"';
		$self->warn;
		return undef;
	}
	if (defined( $valid )) {
		$self->{error}=4;
		$self->{errorString}='The configuration directory name '.$valid;
		$self->warn;
		return undef;
	}
	
	#makes sure it exists
	if ( ! -d $self->{scm}->{baseDir}.'/'.$configDir ) {
		$self->{error}=5;
		$self->{errorString}='The configuration directory, "'.$self->{baseDir}.'/'.$configDir.'", does not exist';
		$self->warn;
		return undef;
	}

	my $scriptFile=$self->{scm}->{baseDir}.'/'.$configDir.'/.SysConfigManage/Scripts/'.$script;

	#error if it does not exist
	if( ! -f $scriptFile ){
		$self->{error}=12;
		$self->{errorString}='The script, "'.$script.'"("'.$scriptFile.'"), does not exist';
		$self->warn;
		return undef;
	}

	system($scriptFile);

	return $?<<8;
}

=head2 writeScript

This writes a script. If it does not exist, it will be created.

Three arguments are taken. The first is the configuration directory,
the second is the script name, and the third is the contents of the script.

If the configuration directory is not specified, it will be automaticaly choosen.

    $foo->writeScript($configDir, $scriptName, $scriptContents);
    if( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
	}

=cut

sub writeScript{
	my $self=$_[0];
	my $configDir=$_[1];
	my $script=$_[2];
	my $data=$_[3];

	if( ! $self->errorblank ){
		return undef;
	}
	
	if(!defined($script)){
		$self->{error}=7;
		$self->{errorString}='No script name specified';
		$self->warn;
		return undef;
	}

	if ( $script =~ /\// ){
		$self->{error}=10;
		$self->{errorString}='The script name,"'.$script.'", contains a forward slash.';
		$self->warn;
		return undef;
	}

	if(!defined($data)){
		$self->{error}=8;
		$self->{errorString}='Nothing specified for the script';
		$self->warn;
		return undef;
	}

	#make sure we have a directory to use
	if (!defined($configDir)) {
		$configDir=$self->{scm}->selectConfigDir;
		if ($self->{scm}->error) {
			$self->{error}=3;
			$self->{errorString}='Sys::Config::Manage->selectConfigDir errored error="'.
				$self->{scm}->error.'" errorString="'.$self->{scm}->errorString.'"';
			$self->warn;
			return undef;
		}
	}
	
	#make sure the config directory is valid
	my $valid=$self->{scm}->validConfigDirName($configDir);
	if ($self->{scm}->error) {
		$self->{error}=3;
		$self->{errorString}='Sys::Config::Manage->validConfigDirName errored error="'.
			$self->{scm}->error.'" errorString="'.$self->{scm}->errorString.'"';
		$self->warn;
		return undef;
	}
	if (defined( $valid )) {
		$self->{error}=4;
		$self->{errorString}='The configuration directory name '.$valid;
		$self->warn;
		return undef;
	}
	
	#makes sure it exists
	if ( ! -d $self->{scm}->{baseDir}.'/'.$configDir ) {
		$self->{error}=5;
		$self->{errorString}='The configuration directory, "'.$self->{baseDir}.'/'.$configDir.'", does not exist';
		$self->warn;
		return undef;
	}

	#make sure the script directory exists
	if( ! -d $self->{scm}->{baseDir}.'/'.$configDir.'/.SysConfigManage/'  ){
		if(!mkdir( $self->{scm}->{baseDir}.'/'.$configDir.'/.SysConfigManage' )){
			$self->{error}=9;
			$self->{errorString}='"'.$self->{scm}->{baseDir}.'/'.$configDir.'/.SysConfigManage/'.'" could not be created';
			$self->warn;
			return undef;
		}
	}
	if( ! -d $self->{scm}->{baseDir}.'/'.$configDir.'/.SysConfigManage/Scripts/'  ){
        if(!mkdir( $self->{scm}->{baseDir}.'/'.$configDir.'/.SysConfigManage/Scripts' )){
            $self->{error}=9;
            $self->{errorString}='"'.$self->{scm}->{baseDir}.'/'.$configDir.'/.SysConfigManage/Scripts" could not be created';
            $self->warn;
            return undef;
        }
    }

	my $file=$self->{scm}->{baseDir}.'/'.$configDir.'/.SysConfigManage/Scripts/'.$script;

	#check if it exists already or not
	my $exists=0;
	if( -e $file ){
		$exists=1;
	}

	my $fh;
	if( ! open( $fh, '>', $file ) ){
		$self->{error}=11;
		$self->{errorString}='"'.$file.'" could not be opened for writing';
		$self->warn;
		return undef;
	}
	print $fh $data;
	close($fh);

	chmod( oct('0774'), $file );

	#add it if it, if it did not exist previously
	if ( ! $exists ){
		if (defined( $self->{scm}->{addCommand} )) {
			my $command=$self->{scm}->{addCommand};
			my $newfile=shell_quote($file);
			
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

=head1 ERROR CODES

=head2 1

Nothing passed for the Sys::Config::Manage object.

=head2 2

$args{scm} is not a Sys::Config::Manage object.

=head2 3

Sys::Config::Manage errored.

=head2 4

Invalid configuration directory name.

=head2 5

The specified configuration directory does not exist.

=head2 6

Unable to open the script directory.

=head2 7

No script specified.

=head2 8

No script data specified.

=head2 9

Unable to create a required directory.

=head2 10

The script name contains a '/'.

=head2 11

Could not open the script.

=head2 12

The script does not exist.

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

1; # End of Sys::Config::Manage::Scripts
