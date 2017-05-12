# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

my $msg_group = defined $ENV{'OVO_MSG_GROUP'} ? $ENV{'OVO_MSG_GROUP'} : 'OVO_test_group' ;
my $application = defined $ENV{'OVO_APPLICATION'} ? $ENV{'OVO_APPLICATION'} : 'application' ;
my $object = defined $ENV{'OVO_OBJECT'} ? $ENV{'OVO_OBJECT'} : 'object' ;

if ( $msg_group eq 'OVO_test_group'  )
{
   print "export OVO_MSG_GROUP=<a valid ovo msg_group> to see results of test in OVO monitoring application\n" ;
}

use Test;
BEGIN { plan tests => 11 };
#use Openview::Message::opcmsg;
use Openview::Message::Sender qw(
   OPC_SEV_NORMAL
   OPC_SEV_WARNING
   OPC_SEV_MINOR
   OPC_SEV_MAJOR
   OPC_SEV_CRITICAL
);
ok(1); # If we made it this far, we're ok.

#########################

my $ov = new Openview::Message::Sender { severity=>OPC_SEV_NORMAL
                           ,object=>$object
                           ,application=>$application
                           ,group=>$msg_group
                          };
ok(1) if $ov; #2

ok(0,$ov->send( "Openview::Message test normal" ) );
ok(0,$ov->send( severity=>'warning' ,text=>"Openview::Message test warning" ) );
ok(0,$ov->send( severity=>OPC_SEV_WARNING ,text=>"Openview::Message test OPC_SEV_WARNING" ) );
ok(0,$ov->send( severity=>'minor' ,text=>"Openview::Message test minor" ) );                     #6
ok(0,$ov->send( severity=>OPC_SEV_MINOR ,text=>"Openview::Message test OPC_SEV_MINOR" ) ); 
ok(0,$ov->send( severity=>'major' ,text=>"Openview::Message test major" ) );
ok(0,$ov->send( severity=>OPC_SEV_MAJOR ,text=>"Openview::Message test OPC_SEV_MAJOR" ) );
ok(0,$ov->send( severity=>'critical' ,text=>"Openview::Message test critical" ) );               #10
ok(0,$ov->send( severity=>OPC_SEV_CRITICAL ,text=>"Openview::Message test OPC_SEV_CRITICAL" ) ); 

