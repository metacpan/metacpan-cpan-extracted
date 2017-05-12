use strict;
use Test;
BEGIN { plan tests => 11 }
use NetworkInfo::Discovery::Nmap;

# check that the following functions are available
ok( exists &NetworkInfo::Discovery::Nmap::new           );  #01
ok( exists &NetworkInfo::Discovery::Nmap::do_it         );  #02

# create an object
my $scanner = undef;
eval { $scanner = new NetworkInfo::Discovery::Nmap };
ok( $@, ''                                              );  #03
ok( defined $scanner                                    );  #04
ok( $scanner->isa('NetworkInfo::Discovery::Nmap')       );  #05
ok( ref $scanner, 'NetworkInfo::Discovery::Nmap'        );  #06
 
# check that the following object methods are available
ok( ref $scanner->can('can')                   , 'CODE' );  #07
ok( ref $scanner->can('new')                   , 'CODE' );  #08
ok( ref $scanner->can('do_it')                 , 'CODE' );  #09
ok( ref $scanner->can('hosts')                 , 'CODE' );  #10
ok( ref $scanner->can('ports')                 , 'CODE' );  #11
