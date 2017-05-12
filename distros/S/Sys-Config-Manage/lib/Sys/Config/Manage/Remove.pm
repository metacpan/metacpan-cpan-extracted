package Sys::Config::Manage::Remove;

use warnings;
use strict;
use File::Basename;
use base 'Error::Helper';
use String::ShellQuote;
use File::Spec;
use File::Path qw(remove_tree);
use String::ShellQuote;

=head1 NAME

Sys::Config::Manage::Remove - Removes no longer desired files and/or directories.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';


=head1 SYNOPSIS

    use Sys::Config::Manage::Remove;

    my $foo = Sys::Config::Manage::Remove->new();
    ...

=head1 METHODS

=head2 new

=head3 args hash

=head4 scm

This is a initialized Sys::Config::Manage object.

    $foo=Sys::Config::Manage::Remove->new(\%args);
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

=head2 add

This adds a directory or file to be removed.

    $foo->add( $configDir, $somethingToAdd );
    if ( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub add{
	my $self=$_[0];
	my $configDir=$_[1];
	my $item=$_[2];

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

	# make sure something is specified
	if ( ! defined( $item ) ){
		$self->{error}=3;
		$self->{errorString}='No item that should be removed defined';
		$self->warn;
		return undef;
	}

	# make sure it starts with a / or contain \n
	if (
		( $item !~ /^\// ) ||
		( $item =~ /\n/ )
		){
		$self->{error}=4;
		$self->{errorString}='The path,"'.$item.'", does not appear to be a valid path';
		$self->warn;
		return undef;
	}

	$item=File::Spec->canonpath( $item );

	my $exists=$self->exists( $configDir, $item );
	if ( $self->error ){
		$self->warnString('Failed to check if it already exists');
		return undef;
	}
	if ( $exists ){
		$self->{error}=10;
		$self->{errorString}='"'.$item.'" already exists';
		$self->warn;
		return undef;
	}

	my @list=$self->list( $configDir );
	if ( $self->error ){
		$self->warnString('Failed to fetch the list for "'.$configDir.'"');
		return undef;
	}

	#add it to the list
	push( @list, $item );
	@list=sort( @list );

	#saves it
	$self->save( $configDir, \@list );

	return 1;
}

=head2 clean

This removes everything in the remove list for a specified
configuration directory.

There is one argument taken and that is the configuration
directory. If it is not specified, it will be automatically
choosen.

    $foo->clean( $configDir );
    if ( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub clean{
	my $self=$_[0];
	my $configDir=$_[1];

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

	#gets the list
	my @list=$self->list;
	if ( $self->error ){
		$self->warnString('Failed to get the remove list for "'.$configDir.'"');
		return undef;
	}

	my $int=0;
	while( defined( $list[$int] ) ){
		if ( -d $list[$int] ){
			remove_tree( $list[$int], { error=>\my $err } );
			if (@$err) {
				$self->{error}=11;
				$self->{errorString}='Failed to remove the file "'.$list[$int].'"';
				$self->warn;
				return undef;				
			}
		}
		if ( -f $list[$int] ){
			if ( ! unlink( $list[$int] ) ){
				$self->{error}=11;
				$self->{errorString}='Failed to remove the file "'.$list[$int].'"';
				$self->warn;
				return undef;
			}
		}

		$int++;
	}

	return 1;
}

=head2 exists

This check if a path already exists in the list or not.

Two arguments are taken. The first is the configuration
directory, which is automatically choosen if not specified.
The second is the path to check for.

The returned value is a boolean.

    my $exists=$foo->exists( $configDir, $path );
    if ( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub exists{
	my $self=$_[0];
	my $configDir=$_[1];
	my $item=$_[2];

	#blank any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	# make sure something is specified
	if ( ! defined( $item ) ){
		$self->{error}=3;
		$self->{errorString}='No item that should be removed defined';
		$self->warn;
		return undef;
	}

	# make sure it starts with a / or contain \n
	if (
		( $item !~ /^\// ) ||
		( $item =~ /\n/ )
		){
		$self->{error}=4;
		$self->{errorString}='The path,"'.$item.'", does not appear to be a valid path';
		$self->warn;
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
		$self->{error}=7;
		$self->{errorString}='Sys::Config::Manage->validConfigDirName errored error="'.
			$self->{scm}->error.'" errorString="'.$self->{scm}->errorString.'"';
		$self->warn;
		return undef;
	}
	if (defined( $valid )) {
		$self->{error}=8;
		$self->{errorString}='The configuration directory name '.$valid;
		$self->warn;
		return undef;
	}

	#makes sure it exists
	if ( ! -d $self->{scm}->{baseDir}.'/'.$configDir ) {
		$self->{error}=9;
		$self->{errorString}='The configuration directory, "'.$self->{baseDir}.'/'.$configDir.'", does not exist';
		$self->warn;
		return undef;
	}

	$item=File::Spec->canonpath( $item );

	my @list=$self->list( $configDir );
	if ( $self->error ){
		$self->warnString('Failed to fetch the list for "'.$configDir.'"');
		return undef;
	}

	my $int=0;
	while( defined( $list[$int] ) ){
		if ( $list[$int] eq $item ){
			return 1;
		}

		$int++;
	}

	return 0;
}

=head2 list

This returns the list of the paths to remove.

One argument is taken and that is the configuration directory to
us. If not specified, it is automatically selected.

    my @removePaths=$foo->list( $configDir );
    if ( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub list{
	my $self=$_[0];
	my $configDir=$_[1];

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
		$self->{error}=7;
		$self->{errorString}='Sys::Config::Manage->validConfigDirName errored error="'.
			$self->{scm}->error.'" errorString="'.$self->{scm}->errorString.'"';
		$self->warn;
		return undef;
	}
	if (defined( $valid )) {
		$self->{error}=8;
		$self->{errorString}='The configuration directory name '.$valid;
		$self->warn;
		return undef;
	}

	#makes sure it exists
	if ( ! -d $self->{scm}->{baseDir}.'/'.$configDir ) {
		$self->{error}=9;
		$self->{errorString}='The configuration directory, "'.$self->{baseDir}.'/'.$configDir.'", does not exist';
		$self->warn;
		return undef;
	}

	#reads it
	my @removelines;
	my $removefile=$self->{scm}->{baseDir}.'/'.$configDir.'/.SysConfigManage/Remove/list';
	if ( ! -f $removefile ){
		return @removelines;
	}
	my $fh;
	if ( ! open( $fh, '<', $removefile ) ){
		$self->{error}=6;
		$self->{errorString}='Failed to open the remove file, "'.$removefile.'"';
		$self->warn;
		return undef;
	}
	@removelines=<$fh>;
	close( $fh );

	#chomp each line
	my $int=0;
	while ( defined( $removelines[$int] ) ){
		chomp( $removelines[$int] );
		
		$int++;
	}

	return @removelines;
}

=head2 remove

This removes the specified path from the remove list.

Two arguments are taken. The first is the configuration
directory, which if not specified is automatically choosen.
The second is the path to remove.

    $foo->remove( $configDir, $path );
    if ( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub remove{
	my $self=$_[0];
	my $configDir=$_[1];
	my $item=$_[2];

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

	# make sure something is specified
	if ( ! defined( $item ) ){
		$self->{error}=3;
		$self->{errorString}='No item that should be removed defined';
		$self->warn;
		return undef;
	}

	# make sure it starts with a / or contain \n
	if (
		( $item !~ /^\// ) ||
		( $item =~ /\n/ )
		){
		$self->{error}=4;
		$self->{errorString}='The path,"'.$item.'", does not appear to be a valid path';
		$self->warn;
		return undef;
	}

	$item=File::Spec->canonpath( $item );

	my $exists=$self->exists( $configDir, $item );
	if ( $self->error ){
		$self->warnString('Failed to check if it already exists');
		return undef;
	}
	if ( ! $exists ){
		$self->{error}=13;
		$self->{errorString}='"'.$item.'" the path does not exist';
		$self->warn;
		return undef;
	}

	my @list=$self->list( $configDir );
	if ( $self->error ){
		$self->warnString('Failed to fetch the list for "'.$configDir.'"');
		return undef;
	}

	my @newlist;

	my $int=0;
	while ( defined( $list[$int] ) ){
		if ( $list[$int] ne $item ){
			push( @newlist, $list[$int] );
		}

		$int++;
	}

	$self->save( $configDir, \@newlist );
	if ( $self->error ){
		$self->warnString( 'Failed to save the list' );
		return undef;
	}

	return 1;
}

=head2 save

This replaces the current remove list with another.

Two arguments are taken. The first is the configuration
directory, which is automatically selected if not specified.
The second is the list to replace it with.

    $foo->save( $configDir, \@removeList );
    if ( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub save{
	my $self=$_[0];
	my $configDir=$_[1];
	my @list;
	if(defined($_[2])){
		@list= @{$_[2]};
	}

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
		$self->{error}=7;
		$self->{errorString}='Sys::Config::Manage->validConfigDirName errored error="'.
			$self->{scm}->error.'" errorString="'.$self->{scm}->errorString.'"';
		$self->warn;
		return undef;
	}
	if (defined( $valid )) {
		$self->{error}=8;
		$self->{errorString}='The configuration directory name '.$valid;
		$self->warn;
		return undef;
	}
	
	my $towrite='';
	my $int=0;
	while( defined( $list[$int] ) ){

		if ( 
			($list[$int] !~ /^\// ) ||
			( $list[$int] =~ /\n/ )
			){
			$self->{error}=4;
			$self->{errorString}='The path, "'.$list[$int].'", does appear to be valid';
			$self->warn;
			return undef;
		}
		chomp($list[$int]);
		$towrite=$towrite.$list[$int]."\n";

		$int++;
	}

	#makes sure the directory exists
    if ( ! -d $self->{scm}->{baseDir}.'/'.$configDir.'/.SysConfigManage/' ){
        if ( ! mkdir( $self->{scm}->{baseDir}.'/'.$configDir.'/.SysConfigManage/' ) ){
            $self->{error}=12;
            $self->{errorString}='Failed to create "'.$self->{scm}->{baseDir}.'/'.$configDir.'/.SysConfigManage/"';
            $self->warn;
            return undef;
        }
    }
	if ( ! -d $self->{scm}->{baseDir}.'/'.$configDir.'/.SysConfigManage/Remove' ){
		if ( ! mkdir( $self->{scm}->{baseDir}.'/'.$configDir.'/.SysConfigManage/Remove/' ) ){
			$self->{error}=12;
			$self->{errorString}='Failed to create "'.$self->{scm}->{baseDir}.'/'.$configDir.'/.SysConfigManage/Remove/"';
			$self->warn;
			return undef;
		}
	}

	#saves it
	my $exists=0;
	my $removefile=$self->{scm}->{baseDir}.'/'.$configDir.'/.SysConfigManage/Remove/list';
	if ( -f $removefile ){
		$exists=1;
	}
	my $fh;
	if ( ! open( $fh, '>', $removefile ) ){
		$self->{error}=6;
		$self->{errorString}='Failed to open the remove file, "'.$removefile.'"';
		$self->warn;
		return undef;
	}
	print $fh $towrite;
	close( $fh );

	if ( ! $exists ){
		my $command=$self->{scm}->getAddCommand;

		if ( defined( $command ) ){
			$removefile=shell_quote($removefile);
			
			$command=~s/\%\%\%file\%\%\%/$removefile/g;
			system($command);
			my $exit = $?<<8;
			if ($exit ne '0') {
				$self->{error}=12;
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

No item that should be removed defined.

=head2 4

The path does not appear to be a valid path. This means it
does not start with a "/" or contains a newline.

=head2 5

Sys::Config::Manage->selectConfigDir errored.

=head2 6

Failed to open the remove file.

=head2 7

Sys::Config::Manage->validConfigDirName errored.

=head2 8

Invalid configuration directory name.

=head2 9

The configuration directory does not exist.

=head2 10

It already exists.

=head2 11

Failed to remove a file or path.

=head2 12

Failed to add the new file.

=head2 13

The path does not exist.

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

1; # End of Sys::Config::Manage::Remove
