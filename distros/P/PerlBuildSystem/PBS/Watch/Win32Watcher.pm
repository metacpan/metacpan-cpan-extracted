
package PBS::Watch::Win32Watcher ;

use strict;
use warnings ;

use PBS::Constants ;

use Win32::IPC ;
use Win32::ChangeNotify;
use Data::TreeDumper ;
use File::Basename ;

our $VERSION = '0.1' ;

my $watcher_singleton ;

#-------------------------------------------------------------------------------------

=head1 NAME

Win32Watcher - Win32 watch mechanism for watch_server.pl

=head1 DESCRIPTION

This module is used by I<watch_server.pl> on windows. watches are directory based in windows,
when queried, the watch server willl report all the files, in the directory where one or more files where modified,
to be modified. PBS will compute an MD5 for those files thus not all the files in the directory will
get rebuild.

=cut

#-------------------------------------------------------------------------------------

sub new
{
die "multiple definitions of a singleton!" if defined $watcher_singleton ;

my ($class, $modified_files, $deleted_files) = @_ ;

my $self = 
	{
	  WATCHED_DIRECTORIES => {} # {directory_name => watch}
	, WATCHED_FILES       => {} # {directory_name => {file1 => 1, file2 => 1}, directory_name2 => {}}
	, MODIFIED_FILES      => $modified_files
	, DELETED_FILES       => $deleted_files
	} ;

$watcher_singleton = $self ;

return bless $self, $class ;
}

#-------------------------------------------------------------------------------------

sub WatchFile
{
my ($self, $file) = @_ ;

my ($file_name, $directory_to_watch) = fileparse($file) ;

if(exists $self->{WATCHED_DIRECTORIES}{$directory_to_watch})
	{
	$self->{WATCHED_FILES}{$directory_to_watch}{$file}++ ;
	
	return(1) ; # already watching directory
	}
else
	{
	my $watch = Win32::ChangeNotify->new($directory_to_watch, 0,  "FILE_NAME | LAST_WRITE");

	if(defined $watch)
		{
		$self->{WATCHED_DIRECTORIES}{$directory_to_watch} = $watch ;
		$self->{WATCHED_FILES}{$directory_to_watch}{$file}++  ;
		return(1) ;
		}
	else
		{
		return(0) ;
		}
	}
}

#-------------------------------------------------------------------------------------

sub NeedsSynch
{
my ($self) = @_ ;

return($self->Synch()) ;
}


#-------------------------------------------------------------------------------------

sub Synch
{
my ($self) = @_ ;

my $needed_synch = 0 ;

for (1 .. 2)
	{
	# single synch is not enough for reasons eluding me
	
	for my $directory (keys %{$self->{WATCHED_DIRECTORIES}})
		{
		my @watches = ($self->{WATCHED_DIRECTORIES}{$directory}) ; # must be done this way :(
		
		if(Win32::IPC::wait_any(@watches, 0))
			{
			print "Changes in directory '$directory'\n" ;
			
			$needed_synch++ ;
			
			for my $file ( keys %{$self->{WATCHED_FILES}{$directory}})
				{
				$self->{MODIFIED_FILES}{$file} = WATCH_TYPE_DIRECTORY ;
				}
				
			$self->{WATCHED_DIRECTORIES}{$directory}->reset() ;
			}
		else
			{
			$self->{WATCHED_DIRECTORIES}{$directory}->reset() ;
			#~ print "No changes in directory '$directory'\n" ;
			}
		}
	}

return($needed_synch) ;
}

#-------------------------------------------------------------------------------------
1 ;

=head1 AUTHOR

Khemir Nadim ibn Hamouda. nadim@khemir.net

=head1 SEE ALSO

B<PBS>

=cut
