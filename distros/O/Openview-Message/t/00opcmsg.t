# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl t/00opcmsg.t'

#########################

my $msg_group = defined $ENV{'OVO_MSG_GROUP'} ? $ENV{'OVO_MSG_GROUP'} : 'OVO_test_group' ;
my $application = defined $ENV{'OVO_APPLICATION'} ? $ENV{'OVO_APPLICATION'} : 'application' ;
my $object = defined $ENV{'OVO_OBJECT'} ? $ENV{'OVO_OBJECT'} : 'object' ;

if ( $msg_group eq 'OVO_test_group'  )
{
   print "export OVO_MSG_GROUP=<a valid ovo msg_group> to see results of test in OVO monitoring application\n" ;
}

#   OPC_SEV_UNKNOWN
#   OPC_SEV_UNCHANGED
#   OPC_SEV_NONE

use Test;
BEGIN { plan tests => 7 };
use Openview::Message::opcmsg qw( 
   opcmsg
   OPC_SEV_NORMAL
   OPC_SEV_WARNING
   OPC_SEV_MINOR
   OPC_SEV_MAJOR
   OPC_SEV_CRITICAL
); #':all';
ok(1); # If we made it this far, we're ok.
#ok( defined OPC_SEV_UNKNOWN );
#ok( defined OPC_SEV_UNCHANGED );
#ok( defined OPC_SEV_NONE );
ok( defined OPC_SEV_NORMAL );  #5
ok( defined OPC_SEV_WARNING );
ok( defined OPC_SEV_MINOR );
ok( defined OPC_SEV_MAJOR );
ok( defined OPC_SEV_CRITICAL );
$ENV{FAKE_OPC_VERBOSE} = 1;
ok( 0
   ,opcmsg( OPC_SEV_MINOR
          ,$application
          ,$object 
          ,"this is ia test of a perl XS implementation of opcmsg (test 2)" 
          ,$msg_group 
          ,$ENV{'HOSTNAME'} 
          )
); #10


