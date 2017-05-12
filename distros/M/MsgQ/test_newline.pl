
use IO::Socket;

$server_con = new IO::Socket::INET (  
	   PeerAddr => 'LOCALHOST',
	   PeerPort => 6001,
	   Proto    => 'tcp'
     			) or print  "$!";
			
while(1)
{

			for (0 .. 25)
			{
				$i++;
				print $server_con "abcdefghijklmno" or print "no";
				print $server_con "pqrstuvwxyz12345678" if server_con;
				print $server_con "####$i\n" if $server_con;
				$record_time = localtime;
				print $record_time,"\n";
			}
			sleep 4;

}




