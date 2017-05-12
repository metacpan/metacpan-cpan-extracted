
package PBS::Watch::Client ;

use strict ;
use warnings ;

use 5.006 ;

require Exporter ;
use AutoLoader qw(AUTOLOAD) ;

our @ISA = qw(Exporter) ;
our %EXPORT_TAGS = ('all' => [ qw() ]) ;
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;
our @EXPORT = qw() ;
our $VERSION = '0.03' ;

use IO::Socket::INET ;
use PBS::Digest ;
use PBS::Output ;
use PBS::PBSConfig ;

#-------------------------------------------------------------------------------

#move to some config and add switches

my $separator = '_stop_' ;
my $host = 'localhost' ;
my $port = '12001' ;

#-------------------------------------------------------------------------------

sub WatchFiles
{
#  @_ should contain id and a list of files to watch

return(GetServerData('WATCH_FILES', @_)) ;
}

#---------------------------------------------------------------------------------------

sub GetModifiedFiles
{
#  @_ should contain id
return(GetServerData('GET_MODIFIED_FILES_LIST', @_)) ;
}

#---------------------------------------------------------------------------------------

sub GetServerData
{
#~ use Data::TreeDumper ;
#~ print DumpTree(\@_) ;
my $answer = SendCommand($host, $port, join($separator, @_)) ;

my ($result, @files) = split($separator, $answer) ;

return ($result, @files) ;
}

#---------------------------------------------------------------------------------------

sub SendCommand
{
my ($host, $port, $command) = @_ ;

my $socket = new IO::Socket::INET->new("$host:$port") or die $@ ;

print $socket "$command\n" ;

my $answer = <$socket> ;

return($answer) ;
}

#--------------------------------------------------------------

1 ;

__END__
=head1 NAME

PBS::Watch::Client - Access to a PBS watch server

=head1 DESCRIPTION

=head2 EXPORT

None.

=head1 AUTHOR

Khemir Nadim ibn Hamouda. nadim@khemir.net

=head1 SEE ALSO

B<script/watch_server.pl>.

=cut
