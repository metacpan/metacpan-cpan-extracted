# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-WhoisNG.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
BEGIN { use_ok('Net::WhoisNG') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


my $dom="perl.org";
my $w = new Net::WhoisNG($dom) or die "domain creation failed\n";
diag("** TESTING ON $dom **");
if(!$w->lookUp()){
    diag("perl.org should be alive and well this century\n");
   exit;
}
ok(defined $w->lookUp(),"Lookup succeeded!") and diag("\n","$dom Resolved fine");
diag("***** GETTING NAME SERVERS ******");
ok(defined $w->getNameServers(),"Name servers resolution") and printNameServers($w);
diag(" *** GETTING REGISTRANT INFO ***");
ok(defined $w->getPerson("registrant"),"No registrar") and printPerson($w,"registrant");

my $ex=$w->getExpirationDate();
diag("Expires: $ex\n");
my $p=$w->getPerson("tech") or die "No admin contact\n";
my $tc=$p->getCredentials();
my @c=@$tc;
diag("Tech Contact:\n",join("\n",@c));
my $status=$w->getStatus();

if($status){
   print "Domain is Active\n";
}
else{
   diag "Domain expire: $ex\n";
}
sub printNameServers{
   my $lw=shift;
   my $tns=$lw->getNameServers();
   my @myns=@$tns;
   diag("\n");
   diag(join("\n",@myns));
}

sub printPerson{
   my $lw=shift;
   my $mytype=shift;
   my $p=$lw->getPerson($mytype);
   diag("\n");
   diag("Name: ",$p->getName());
   diag("Phone: ",$p->getPhone());
}
ok(1);