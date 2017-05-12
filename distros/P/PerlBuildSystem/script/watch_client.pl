
use strict;
use IO::Socket;
use Time::HiRes qw(gettimeofday tv_interval) ;

my $separator = '_stop_' ;

my $id = 'nadim' ;
my $host = 'localhost' ;
my $port = '12001' ;

my $file_list = join($separator, ('./watch_client.pl', './INSTALL', './doc/how_fast_is_it', './PBS/Prf.pm')) ;

my $answer = SendCommand($host, $port, "WATCH_FILES$separator$id$separator$file_list") ;
print $answer ;

$answer = SendCommand($host, $port, "GET_MODIFIED_FILES_LIST$separator$id") ;
print $answer ;

sub SendCommand
{
my ($host, $port, $command) = @_ ;

my $socket = new IO::Socket::INET->new("$host:$port") or die $@ ;

print $socket "$command\n" ;

my $answer = <$socket> ;

return($answer) ;
}

#--------------------------------------------------------------
