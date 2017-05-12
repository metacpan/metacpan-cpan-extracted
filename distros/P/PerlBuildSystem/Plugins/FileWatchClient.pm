
use strict ;
use warnings ;

use Time::HiRes qw(gettimeofday tv_interval) ;

use PBS::Watch::Client ;

#-------------------------------------------------------------------------------

=head1 Plugin FileWatchClient.pm

This plugin handles the following PBS defined switches:

=over 2

=item  --use_watch_server

=item  --watch_server_double_check_with_md5

=item  --watch_server_verbose

=back

=cut

use PBS::PBSConfigSwitches ;
use PBS::PBSConfig ;
use PBS::Information ;
use PBS::Constants ;

use Data::TreeDumper ;

#-------------------------------------------------------------------------------

my $use_watch_server ;
my $watch_server_double_check_with_md5 ;
my $watch_server_verbose ;

PBS::PBSConfigSwitches::RegisterFlagsAndHelp
	(
	  'use_watch_server'
	, \$use_watch_server
	, 'Uses file watch server to speed up file verification.'
	, ''
	
	, 'watch_server_double_check_with_md5'
	, \$watch_server_double_check_with_md5 
	, 'As use_watch_server but also does and md5 verification.'
	, ''
	
	, 'watch_server_verbose'
	, \$watch_server_verbose
	, 'Will display what files the server has been notfied for.'
	, ''
	) ;
	

#-------------------------------------------------------------------------------

sub GetWatchedFilesChecker
{
my ($pbs_config, $warp_signature, $nodes) = @_ ;

unless($use_watch_server)
	{
	return(\&PBS::Digest::IsFileModified)
	}

my $t0 = [gettimeofday];

my @modified_files ;
my $is_registred ;
my $files_checker = \&PBS::Digest::IsFileModified ;

eval
	{
	# check if nodes for this warp are watched
	($is_registred, my $number_of_watches, my $number_of_modified_files, @modified_files)
		= PBS::Watch::Client::GetModifiedFiles($warp_signature) ;
	
	if($is_registred)
		{
		#We were registred.
		PrintInfo "Watcher: $number_of_modified_files modified files. $number_of_watches watches\n";
		$PBS::pbs_run_information->{WATCH_SERVER}{WATCHES} = $number_of_watches ;
		$PBS::pbs_run_information->{WATCH_SERVER}{MODIFIED} = $number_of_modified_files ;
		
		if(@modified_files && $watch_server_verbose)
			{
			PrintInfo "\twatcher detected: " . join("\n\twatcher detected: ",@modified_files) . "\n" ;
			}
		}
	else
		{
		# Not registred
		my $error_from_the_watch_server = $number_of_watches ; # error is second argument.
		PrintInfo "Watcher: '$error_from_the_watch_server'.\n" ;
		
		# Compute list of files to watch
		my @watched_files ;
		for my $node (keys %$nodes)
			{
			unless('VIRTUAL' eq $nodes->{$node}{__MD5})
				{
				# rebuild the build name
				if(exists $nodes->{$node}{__BUILD_NAME})
					{
					# use this one
					}
				elsif(exists $nodes->{$node}{__LOCATION})
					{
					$nodes->{$node}{__BUILD_NAME} = $nodes->{$node}{__LOCATION} . substr($node, 1) ;
					}
				else
					{
					$nodes->{$node}{__BUILD_NAME} = $node ;
					}
					
				push @watched_files, CollapsePath($nodes->{$node}{__BUILD_NAME}) ;
				}
			}
			
		# register files.
		my ($success, $message) = PBS::Watch::Client::WatchFiles($warp_signature, @watched_files) ;
		if($success)
			{
			PrintInfo "Watcher: '$message'.\n" ;
			}
		else
			{
			PrintError "Watcher: Couldn't watch files! '$message'.\n" ;
			}
		}
	} ;

if($@)
	{
	PrintError "Couldn't connect to watch Server! $@\n" ;
	$PBS::pbs_run_information->{WATCH_SERVER}{STATUS} = 'Not running' ;
	$files_checker = \&PBS::Digest::IsFileModified ;
	}
elsif(! $is_registred)
	{
	$files_checker = \&PBS::Digest::IsFileModified ;
	}
else
	{
	my %modified_files ;
	for my $modified_file (@modified_files)
		{
		my ($name, $type) =  split(WATCH_TYPE_SEPARATOR, $modified_file) ;
		 
		$modified_files{$name} = $type ;
		}
		
	if($watch_server_double_check_with_md5)
		{
		$files_checker = 
			sub
				{
				my ($pbs_config, $node_name, $node_md5) = @_ ;
				
				$node_name = CollapsePath($node_name) ;
				
				my $file_is_modified = 0 ;
				my $md5_mismatch = PBS::Digest::IsFileModified($pbs_config, $node_name, $node_md5) ;
				
				if(exists $modified_files{$node_name})
					{
					if(! $md5_mismatch)
						{
						PrintWarning "watch FP: '$node_name'\n" ;
						}
					else
						{
						$file_is_modified++ ;
						}
					}
					
				if((! exists $modified_files{$node_name}) && $md5_mismatch)
					{
					PrintError "!!! watch FN: '$node_name'\n" ;
					$file_is_modified++ ;
					}
					
				return($file_is_modified) ;
				} ;
		}
	else
		{
		if(@modified_files)
			{
			$files_checker = 
				sub
					{
					my ($pbs_config, $node_name, $node_md5) = @_ ;
					
					$node_name = CollapsePath($node_name) ;
					
					my $file_is_modified = 0 ;
					
					if(exists $modified_files{$node_name})
						{
						if($modified_files{$node_name} == WATCH_TYPE_FILE)
							{
							$file_is_modified++ ;
							}
						else
							{
							# may be modified check md5
							$file_is_modified = PBS::Digest::IsFileModified($pbs_config, $node_name, $node_md5) ;
							}
						}
						
					return($file_is_modified) ;
					} ;
			}
		else
			{
			$files_checker = 0 ; #  returning a non sub means that nothing was changed
			}
		}
	}

if($pbs_config->{DISPLAY_PBS_TIME})
	{
	my $watch_server_time = tv_interval ($t0, [gettimeofday]) ;
	PrintInfo sprintf("Watch server time: %0.2f\n", $watch_server_time) ;
	$PBS::pbs_run_information->{WATCH_SERVER}{TIME} = $watch_server_time ;
	}

return($files_checker) ;
}

#--------------------------------------------------------------

sub ClearWatchedFilesList
{
return unless $use_watch_server ;

my ($pbs_config, $warp_signature) = @_ ;

eval
	{
	# check if nodes for this warp are watched
	my ($is_registred, $error_message) = PBS::Watch::Client::GetServerData('CLEAR_MODIFIED_FILES_LIST', $warp_signature) ;
	
	unless($is_registred)
		{
		PrintInfo "Watcher: '$error_message'.\n" ;
		}
	} ;

if($@)
	{
	PrintError "Couldn't connect to watch Server! $@\n" ;
	}
}

#-------------------------------------------------------------------------------

1 ;

