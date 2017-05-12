
package PBS::Watch::InotifyWatcher ;

use strict;
use warnings ;

=head1 NAME

InotifyWatcher - linux watch mechanism for watch_server.pl

=head1 DESCRIPTION

This module is used by I<watch_server.pl> on linux. When queried, the watch server willl report all the  modifiedfile.

=cut

use Linux::Inotify2;
use IO::Select ;
use Data::TreeDumper ;

use PBS::Constants ;

our $VERSION = '0.1' ;

my $inotify_singleton ;

#-------------------------------------------------------------------------------------

sub new
{
die "multiple definitions of a singleton!" if defined $inotify_singleton ;

my ($class, $modified_files, $deleted_files) = @_ ;

my $inotify = new Linux::Inotify2 or die "Unable to create new inotify object: $!";
my $inotify_fd = $inotify->fileno() ;

my $self = 
	{
	  INOTIFY        => $inotify
	, INOTIFY_FD     => $inotify_fd
	, MODIFIED_FILES => $modified_files
	, DELETED_FILES  => $deleted_files
	} ;

$inotify_singleton = $self ;

return bless $self, $class ;
}

#-------------------------------------------------------------------------------------

sub WatchFile
{
my ($self, $file) = @_ ;

my $watch_added = $self->{INOTIFY}->watch
			(
			$file
			, IN_MODIFY | IN_DELETE_SELF
			, \&RememberModifiedFiles
			) ;

return($watch_added) ;
}

#-------------------------------------------------------------------------------------

sub RememberModifiedFiles
{
my $e = shift;
my $fullname = $e->fullname ;

#~ print "Event received for: '$fullname'\n\n" ;

$inotify_singleton->{MODIFIED_FILES}{$fullname} =  WATCH_TYPE_FILE if $e->IN_MODIFY;;
$inotify_singleton->{DELETED_FILES}{$fullname} = WATCH_TYPE_FILE  if $e->IN_DELETE_SELF;
}

#-------------------------------------------------------------------------------------

sub NeedsSynch
{
my ($self) = @_ ;

my $select_all = new IO::Select ;
$select_all->add($self->{INOTIFY_FD}) ;

return($select_all->can_read(0.01)) ;
}

#-------------------------------------------------------------------------------------

sub Synch
{
my ($self) = @_ ;

my $select_all = new IO::Select($self->{INOTIFY_FD}) ;

for my $synch (1)
	{
		
	if($select_all->can_read(0.01))
		{
		# synchronize $modified_files_ref with inotify
		$self->{INOTIFY}->poll() ;
		}
		
	#~ print "Multiple synch needed($synch).\n" if $synch > 1 ;
	}
}

#-------------------------------------------------------------------------------------
1 ;

=head1 AUTHOR

Khemir Nadim ibn Hamouda. nadim@khemir.net

=head1 SEE ALSO

PBS::PBS.

=cut

