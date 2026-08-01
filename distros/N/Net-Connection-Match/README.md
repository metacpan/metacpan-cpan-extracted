# Net-Connection-Match

Provides a easy to use method for checking if a Net::Connection
object mathes a series of checks.

Currently can do matching based off of the following.

- CIDR
- Command
- PctCPU
- Ports
- Protocol
- State
- RegexPTR
- PTR
- UID
- Username
- WChan

```perl
    use Net::Connection::Match;
    use Net::Connection;
    
    my $connection_args={
                         foreign_host=>'10.0.0.1',
                         foreign_port=>'22',
                         local_host=>'10.0.0.2',
                         local_port=>'12322',
                         proto=>'tcp4',
                         state=>'LISTEN',
                        };
    my $conn=Net::Connection->new( $connection_args );
    
    my %args=(
              checks=>[
                       {
                        type=>'Ports',
                        invert=>0,
                        args=>{
                               ports=>[
                                       '22',
                                      ],
                               lports=>[
                                        '53',
                                       ],
                               fports=>[
                                        '12345',
                                       ],
                        }
                       },
                       {
                        type=>'Protos',
                        invert=>0,
                        args=>{
                               protos=>[
                                        'tcp4',
                                       ],
                        }
                       }
                      ]
             );
    
    my $checker;
    eval{
        $checker=Net::Connection::Match->new( \%args );
    } or die "New failed with...".$@;
    
    if ( $check->match( $conn ) ){
        print "It matched!\n";
    }
```

# INSTALLATION

To install this module, run the following commands:

```shell
	perl Makefile.PL
	make
	make test
	make install
```