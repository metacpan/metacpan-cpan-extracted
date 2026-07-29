# Net-Connection

This module crates a object that basically serves as a means to store basic
connection information and retrieve it.

```perl
    use Net::Connection;

    #create a hash ref with the desired values
    my $args={
              'foreign_host' => '1.2.3.4',
              'local_host' => '4.3.2.1',
              'foreign_port' => '22',
              'local_port' => '11132',
              'sendq' => '1',
              'recvq' => '0',
              'pid' => '34342',
              'uid' => '1000',
              'state' => 'ESTABLISHED',
              'proto' => 'tcp4'
              };
    
    # create the new object using the hash ref
    my $conn=Net::Connection->new( $args );
    
    # the same thing, but this time resolve the UID to a username
    $args->{'uid_resolve'}='1';
    $conn=Net::Connection->new( $args );
    
    # now with PTR lookup
    $args->{'ptrs'}='1';
    $conn=Net::Connection->new( $args );
    
    # prints a bit of the connection information...
    print "L Host:".$conn->local_host."\n".
    "L Port:".$conn->local_host."\n".
    "F Host:".$conn->foreign_host."\n".
    "F Port:".$conn->foreign_host."\n";
```

# INSTALLATION

To install this module, run the following commands:

```shell
	perl Makefile.PL
	make
	make test
	make install
```
