use strict;
use Test;
BEGIN { plan tests => 9 }
use NetworkInfo::Discovery::Rendezvous;

# check that the following functions are available
ok( exists &NetworkInfo::Discovery::Rendezvous::new     );  #01
ok( exists &NetworkInfo::Discovery::Rendezvous::do_it   );  #02

# create an object
my $scanner = undef;
eval { $scanner = new NetworkInfo::Discovery::Rendezvous };
ok( $@, ''                                              );  #03
ok( defined $scanner                                    );  #04
ok( $scanner->isa('NetworkInfo::Discovery::Rendezvous') );  #05
ok( ref $scanner, 'NetworkInfo::Discovery::Rendezvous'  );  #06
 
# check that the following object methods are available
ok( ref $scanner->can('can')                   , 'CODE' );  #07
ok( ref $scanner->can('new')                   , 'CODE' );  #08
ok( ref $scanner->can('do_it')                 , 'CODE' );  #09
