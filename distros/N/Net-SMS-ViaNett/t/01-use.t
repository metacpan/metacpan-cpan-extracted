use strict;
use Test::More tests => 5;
use Data::Dumper;


my $username = 'boo';
my $password = 'boo';

BEGIN { use_ok('Net::SMS::ViaNett') };

require_ok( 'Net::SMS::ViaNett' );

my $obj;
eval {
  $obj = Net::SMS::ViaNett->new;
};
ok( $@, 'no-args-instantiate' ); 

eval {
  $obj = Net::SMS::ViaNett::new();
};
ok( $@, 'no-constructor-as-package-sub' );


$obj = Net::SMS::ViaNett->new( username => $username, password => $password );
isa_ok( $obj, 'Net::SMS::ViaNett' );

