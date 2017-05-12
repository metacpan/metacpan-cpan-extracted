Program tdns.pl in a bin subdirectory is a simple (full functional) 
nameserver for domain example.com. All configuration files are placed 
in an "etc" subdirectory, log is stored in "var/log" subdirectory. 

Feel free to modify this software on Your own.

To run server, type:

	cd bin
	perl tdns.pl

and to check if it is working, type i.e.:

	dig @127.0.0.1 www.example.com
	
	dig @127.0.0.1 srv.example.com

	dig @127.0.0.1 example.com mx
	
	dig @127.0.0.1 example.com ns
	
	dig @127.0.0.1 example.com soa
	
	dig @127.0.0.1 example.com axfr
 
Have fun!
