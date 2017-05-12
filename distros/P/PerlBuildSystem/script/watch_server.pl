
package main ;

use strict;
use warnings ;

=head1 NAME

watch_server.pl  - uses the file system file watch system to accelerate PBS

=head1 SYNOPSIS

  $> perl watch_server.pl 
  
=head1 DESCRIPTION

This utility uses the native file watching mechanism  (win32 or inotify) to speedup PBS MD5 verification.

I<watch_server> opens a socket on port 12001 and waits for PBS to contact it. For PBS to use this you must
specify I<--use_watch_server> and I<--warp>. PBS registers the files to watch and doesn't use MD5 any more
to verify the warp tree. On linux, the difference is minimal. The improvement is more spectacular on Win32 machines
where the file caching policy is poor.

 We are planning to do all the configuration through zeroconf. and use the watch server to speed up more than
 warp runs.
 
 the watch server is only used to speedup the warp verification to start with. We are also planning to use
 the watch server throughout the whole PBS, inclusive distributed PBS.
 
=head1 AUTHOR

Khemir Nadim ibn Hamouda. nadim@khemir.net

=head1 SEE ALSO

B<PerlBuildSystem>

=cut

use IO::Socket;
use POSIX qw(strftime WNOHANG);
use Time::HiRes qw(gettimeofday tv_interval) ;
use Data::TreeDumper ;

our $VERSION = '0.8' ;

my $separator = "_stop_" ;

my $modified_files = {} ;
my $deleted_files = {} ;
my $files_that_could_not_be_watched = {} ;
	
my $watcher ; # uses inotify on linux and the directory notification mechanism on windows

# load a platform specific watch componant

if($^O eq 'linux')
	{
	eval <<EOE ;
	use PBS::Watch::InotifyWatcher ;
	\$watcher = new PBS::Watch::InotifyWatcher(\$modified_files, \$deleted_files) ;
EOE
	die $@ if $@ ;
	}
else
	{
	# assume windows
	eval <<EOE ;
	use PBS::Watch::Win32Watcher ;
	\$watcher = new PBS::Watch::Win32Watcher(\$modified_files, \$deleted_files) ;
EOE
	die $@ if $@ ;
	}
	
use PBS::Constants ; # defines the types of watch events

my $port = 12001 ;
my $quit = 0;

# signal handler for interrupt key and TERM signal
$SIG{INT} = sub { $quit++ };

my $listen_socket = IO::Socket::INET->new
					(
					LocalPort => $port,
                                        Listen    => 20,
                                        Proto     => 'tcp',
                                        Reuse     => 1,
                                        Timeout   => 60*60,
                                        );
					 
die "Can't create a listening socket: $@" unless $listen_socket;
warn "PBS watch server (version $VERSION) ready.  Waiting for connections on port $port ...\n\n";   

my $clients = {} ;
my $watched_files = {} ;

#--------------------------------------------------------------------------------------------

sub Synch
{
# synchronize the system watches with our data structures

my ($watcher, $socket) = @_ ;

$watcher->Synch() ; # $watcher has reference to $modified_files and $deleted_files

# synchronize $modified_files_ref with rest of system
for my $client_id (keys %$clients)
	{
	my $client = $clients->{$client_id} ;
	
	for my $modified_file (keys %$modified_files)
		{
		if($socket)
			{
			print $socket "Modified '$modified_file'\n" ;
			print "Modified '$modified_file'\n" ;
			}
			
		$client->{MODIFIED_FILES}{$modified_file} = $modified_files->{$modified_file}  if(exists $client->{FILES}{$modified_file}) ;
		}
		
	for my $deleted_file (keys %$deleted_files)
		{
		if($socket)
			{
			print $socket "Deleted '$deleted_file'\n" ;
			print "Deleted '$deleted_file'\n" ;
			}
			
		$client->{MODIFIED_FILES}{$deleted_file} = WATCH_TYPE_FILE if(exists $client->{FILES}{$deleted_file}) ;
		}
		
	for my $file_that_could_not_be_watched (keys %$files_that_could_not_be_watched)
		{
		if($socket)
			{
			print $socket "file that could not be watched '$file_that_could_not_be_watched'\n" ;
			print "file that could not be watched '$file_that_could_not_be_watched'\n" ;
			}
			
		$client->{MODIFIED_FILES}{$file_that_could_not_be_watched} = WATCH_TYPE_DIRECTORY if(exists $client->{FILES}{$file_that_could_not_be_watched}) ;
		}
	}

%$modified_files = () ;
}

#--------------------------------------------------------------
# main loop. wait for clients.
#--------------------------------------------------------------

my $connection_index = 0 ;
while (!$quit) 
	{
	next unless my $connection = $listen_socket->accept;
	my $t0 = [gettimeofday];
	
	$connection_index++ ;
	
	my $now_string = strftime "%a %b %e %H:%M:%S %Y", gmtime ;
	print "************** Connection $connection_index $now_string **************\n" ;
	print "modified files: " . scalar(keys %$modified_files) . "\n" ;
	print "deleted files: " . scalar(keys %$deleted_files) . "\n" ;
	
	Synch($watcher) ;
	
	interact($connection);
	
	print(sprintf("time: %0.2f s.\n", tv_interval ($t0, [gettimeofday]))) ;
	print "\n" ;
	}

#--------------------------------------------------------------

sub interact 
{
my $socket = shift;

if(defined (my $command_and_args = <$socket>))
	{
	$command_and_args =~ s/\n|\r//g ;
	
	my ($command, @args) = split /$separator/, $command_and_args ;
	
	for ($command)
		{
		/^WATCH_FILES$/i and do
			{
			print "command: WATCH_FILES\n" ;
			WatchFiles($socket, $watcher, @args) ;
			last ;
			} ;
			
		/^GET_MODIFIED_FILES_LIST$/i and do
			{
			print "command: GET_MODIFIED_FILES_LIST\n" ;
			GetModifiedFilesList($socket, $watcher, @args) ;
			last ;
			} ;
			
		/^CLEAR_MODIFIED_FILES_LIST$/i and do
			{
			print "command: CLEAR_MODIFIED_FILES_LIST\n" ;
			ClearModifiedFilesList($socket, $watcher, @args) ;
			last ;
			} ;
			
		/^DUMP_STATE$/i and do
			{
			print "command: DUMP_STATE\n" ;
			DumpState($socket, $watcher, @args) ;
			last ;
			} ;
			
		/^SYNCH_DUMP$/i and do
			{
			print "command: SYNCH_DUMP\n" ;
			Synch($watcher, $socket) ;
			last ;
			} ;
			
		print $socket join($separator, 0, "ERROR: [$$] Unrecognized '$command_and_args'!") ;
		print "ERROR: [$$] Unrecognized '$command_and_args'!\n" ;
		}
	}
	
close $socket ;
}

#-------------------------------------------------------------------------------------------------------------

sub WatchFiles
{
# return 0 on failure and 1 on success

my ($socket, $watcher, $id, @files) = @_ ;

unless(defined $id && $id ne '')
	{
	my $error = "Invalid client identification!\n" ;
	
	print $error ;
	print $socket "0$separator$error\n" ;
	
	return ;
	}

print "Watching files for '$id'\n" ;

# we try to register all files, files that can't be watched are given  a special 'always not up to date' state
$clients->{$id} = {} ; # register client
my $client = $clients->{$id} ; 

my $new_files = 0 ;
my $new_non_watchable_files = 0 ;
for my $file (@files)
	{
	if(exists $watched_files->{$file})
		{
		# already watched, but might be deleted
		for my $file (keys %$deleted_files)
			{
			if($watcher->WatchFile($file))
				{
				delete $deleted_files->{$file} ;
				}
			else
				{
				$files_that_could_not_be_watched->{$file} = WATCH_TYPE_DIRECTORY ;
				}
			}
		}
	else
		{
		$new_files++ ;
		
		my $watch_added = $watcher->WatchFile($file) ;
			
		unless($watch_added)
			{
			$files_that_could_not_be_watched->{$file} = WATCH_TYPE_DIRECTORY ;
			$new_non_watchable_files++ ;
			
			my $system_error = chomp($!) ;
			
			print "Error while adding watcher for '$file': $system_error\n" ;
			}
			
		$watched_files->{$file}++ ;
		}
		
	$client->{FILES}{$file}++ ;
	
	#~ print "Added Watcher for '$file' from '$pbs'\n" ;
	}
	
my $number_of_file = scalar(@files) ;
my $message = "Watching $number_of_file files ($new_non_watchable_files non watchable). $new_files new files" ;

print "'$id': $message\n" ;
print $socket join($separator, '1', $message) ;
}

#--------------------------------------------------------------

sub GetModifiedFilesList
{
# returns a string of modified files back to PBS.

my ($socket, $watcher, $id, @commands) = @_ ;

unless(defined $id && $id ne '')
	{
	my $error = "Invalid client identification!\n" ;
	
	print $error ;
	print $socket "0$separator$error\n" ;
	return ;
	}

print "GetModifiedFilesList for '$id'.\n" ;

if(exists $clients->{$id})
	{
	Synch($watcher) ;
	
	my $client = $clients->{$id} ;
	
	my @modified_files ;
	
	for (keys %{$client->{MODIFIED_FILES}})
		{
		push @modified_files, "$_" . WATCH_TYPE_SEPARATOR . "$client->{MODIFIED_FILES}{$_}" ;
		}
		
	my $packed_modified_files = join($separator, @modified_files) ;
	
	my $number_of_modified_files = scalar(keys %{$client->{MODIFIED_FILES}}) ;
	my $number_of_watches = scalar(keys %{$client->{FILES}}) ;
		
	print $socket join($separator, '1', $number_of_watches, $number_of_modified_files, $packed_modified_files) ;
	print "$number_of_modified_files modified files, $number_of_watches watches\n" ;
	#todo: pass and display the number of  unregistrable files

	$client->{ACCESS}++ ;
	}
else
	{
	print $socket join($separator, '0', "'$id', You are not registred") ;
	print "'$id' is not registred!\n" ;
	}
	
# try to register the deleted files again
for my $file (keys %$deleted_files)
	{
	my $watch_added = $watcher->WatchFile($file) ;
	delete $deleted_files->{$file} if($watch_added) ;
	}

#todo: could try to register the unregistrable files again
}

#--------------------------------------------------------------

sub ClearModifiedFilesList
{
# this is called by PBS when it has finished building. we would otherwise consider the files
# pbs has regenerated to be modified.

my ($socket, $watcher, $id, @commands) = @_ ;

unless(defined $id && $id ne '')
	{
	my $error = "Invalid client identification!\n" ;
	
	print $error ;
	print $socket "0$separator$error\n" ;
	return ;
	}

print "ClearModifiedFilesList for '$id'\n" ;

if(exists $clients->{$id})
	{
	Synch($watcher) ;
	Synch($watcher) ; # borrrrrrrring! some timing problem with the notification system are hard lived
	
	my $client = $clients->{$id} ;
	
	print "cleared " . scalar(keys %{$client->{MODIFIED_FILES}}) . " modified flags.\n" ;
	
	$client->{MODIFIED_FILES} = {} ;
	$client->{ACCESS}++ ;
	
	print $socket "1\n" ;
	}
else
	{
	print $socket join($separator, '0', "'$id', You are not registred") ;
	print "'$id' is not registred!\n" ;
	}
	
# try to register the deleted files again
for my $file (keys %$deleted_files)
	{
	my $watch_added = $watcher->WatchFile($file) ;
	delete $deleted_files->{$file} if($watch_added) ;
	}

#todo: could try to register the unregistrable files again
}

#--------------------------------------------------------------

sub DumpState
{
# debugging function

my ($socket, $watcher) = @_ ;

print "Dumping state:\n" ;
print "=============\n" ;

if($watcher->NeedsSynch())	
	{
	my $message = "Inotify events waiting to be synchronized.\n" ;
	print $message ;
	print $socket $message;
	}
	
if(keys %$modified_files)
	{
	my $message = "Recorded modifications waiting to be synchronized with clients\n" ;
	print $message ;
	print $socket $message;
	}

print "Clients:\n\n" ;

for my $client_id (keys %$clients)
	{
	my $client = $clients->{$client_id} ;
	my $number_of_modified_files = scalar(keys %{$client->{MODIFIED_FILES}}) ;
	my $number_of_watched_files = scalar(keys %{$client->{FILES}}) ;
	
	my $state = <<EOI ;
	id: $client_id
	access: $client->{ACCESS} ;
	number of watched files: $number_of_watched_files 
	number of modified files: $number_of_modified_files
	
EOI

	print $state ;
	print $socket $state ;
	}
	
print "\n" ;
}

#--------------------------------------------------------------

