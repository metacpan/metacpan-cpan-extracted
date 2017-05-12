# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-MirrorDir.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

 use Test::More tests => 262;
# use Test::More "no_plan";
 BEGIN { use_ok('Net::MirrorDir') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
 my $mirror = Net::MirrorDir->new(
 	localdir		=> "TestA",
 	remotedir	=> "TestD",
 	ftpserver		=> "www.net.de",
 	user		=> 'e-mail@address.de',
 	pass		=> "xyz", 	
 	);
 isa_ok($mirror, "Net::MirrorDir");
#-------------------------------------------------
# tests for methods
 can_ok($mirror, "_Init");
 ok(!$mirror->_Init());
 can_ok($mirror, "Connect");
 can_ok($mirror, "IsConnection");
 can_ok($mirror, "Quit");
 ok($mirror->Quit());
#-------------------------------------------------
# tests for ReadLocalDir()
 can_ok($mirror, "ReadLocalDir");
 ok(my ($rh_lf, $rh_ld) = $mirror->ReadLocalDir());
 warn("local files : $_\n") for(sort keys(%{$rh_lf}));
 warn("local dirs : $_\n") for(sort keys(%{$rh_ld}));
#-------------------------------------------------
 can_ok($mirror, "ReadRemoteDir");
 my $rh_test_rf =
 	{
	"TestD/TestB/TestC/Dir1/test1.txt"		=> 1,
 	"TestD/TestB/TestC/Dir2/test2.txt"		=> 1,
 	"TestD/TestB/TestC/Dir2/test2.subset"	=> 1,
 	#"TestD/TestB/TestC/Dir3/test3.txt"	=> 1,
 	"TestD/TestB/TestC/Dir4/test4.txt"		=> 1,
 	"TestD/TestB/TestC/Dir4/test4.exclusions"	=> 1,
 	"TestD/TestB/TestC/Dir5/test5.txt"		=> 1,
 	};
 my $rh_test_rd =
 	{
 	"TestD/TestB"		=> 1,
 	"TestD/TestB/TestC"	=> 1,
 	"TestD/TestB/TestC/Dir1"	=> 1,
 	"TestD/TestB/TestC/Dir2"	=> 1,
 	#"TestD/TestB/TestC/Dir3"	=> 1,
 	"TestD/TestB/TestC/Dir4" 	=> 1,
 	"TestD/TestB/TestC/Dir5"	=> 1,
 	};
#-------------------------------------------------
# tests for compare files or directories
 can_ok($mirror, "LocalNotInRemote");
 ok($mirror->LocalNotInRemote({}, {}));
 ok(my $ra_lfnir = $mirror->LocalNotInRemote($rh_lf, $rh_test_rf));
 ok("TestA/TestB/TestC/Dir3/test3.txt" eq $ra_lfnir->[0]);
 ok(my $ra_ldnir = $mirror->LocalNotInRemote($rh_ld, $rh_test_rd));
 ok("TestA/TestB/TestC/Dir3" eq $ra_ldnir->[0]);
 can_ok($mirror, "RemoteNotInLocal");
 ok($mirror->RemoteNotInLocal({}, {}));
 $rh_test_rf->{"TestD/TestB/TestC/Dir6/test6.txt"} = 1;
 $rh_test_rd->{"TestD/TestB/TestC/Dir6"} = 1;
 ok(my $ra_rfnil = $mirror->RemoteNotInLocal($rh_lf, $rh_test_rf));
 ok("TestD/TestB/TestC/Dir6/test6.txt" eq $ra_rfnil->[0]);
 ok(my $ra_rdnil = $mirror->RemoteNotInLocal($rh_ld, $rh_test_rd));
 ok("TestD/TestB/TestC/Dir6" eq $ra_rdnil->[0]);
 ok($mirror->SetExclusions([]));
 ok($mirror->SetSubset([]));
 ok($mirror->ReadLocalDir("TestA"));
 ok($mirror->SetRemoteDir("TestD"));
 ok($mirror->SetLocalDir("TestA"));
 ok($mirror->GetLocalFiles());
 ok($mirror->GetLocalDirs());
 ok($ra_lfnir = $mirror->LocalNotInRemote($mirror->GetLocalFiles(), $rh_test_rf));
 ok("TestA/TestB/TestC/Dir3/test3.txt" eq $ra_lfnir->[0]);
 ok($ra_ldnir = $mirror->LocalNotInRemote($mirror->GetLocalDirs(), $rh_test_rd));
 ok("TestA/TestB/TestC/Dir3" eq $ra_ldnir->[0]);
 ok($ra_rfnil = $mirror->RemoteNotInLocal($mirror->GetLocalFiles(), $rh_test_rf));
 ok("TestD/TestB/TestC/Dir6/test6.txt" eq $ra_rfnil->[0]);
 ok($ra_rdnil = $mirror->RemoteNotInLocal($mirror->GetLocalDirs(), $rh_test_rd));
 ok("TestD/TestB/TestC/Dir6" eq $ra_rdnil->[0]);
#-------------------------------------------------
# tests for set and get
 ok(!$mirror->set_Item());
 ok(!$mirror->get_Item());
 ok(!$mirror->GETItem());
 ok(!$mirror->Get_Item());
 ok($mirror->SET____Remotedir("Homepage"));
 ok(!$mirror->WrongFunction());
 ok(Net::MirrorDir::SetExclusions($mirror, ["sys"]));
 ok(Net::MirrorDir::GetExclusions($mirror)->[0] eq "sys");
 ok(Net::MirrorDir::SetSubset($mirror, ["my_files"]));
 ok(Net::MirrorDir::GetSubset($mirror)->[0] eq "my_files");
 ok(Net::MirrorDir::SetSubset($mirror, []));
#-------------------------------------------------
# test for attribute "debug"
 ok($mirror->set_debug(0));
 ok(!$mirror->get_debug());
 ok($mirror->setdebug(''));
 ok(!$mirror->getdebug());
 ok($mirror->SetDebug(10));
 ok($mirror->GetDebug() == 10);
#-------------------------------------------------
# tests for attribute "localdir"
 ok($mirror->Set_localdir("home"));
 ok($mirror->GetLocalDir() eq "home");
#-------------------------------------------------
#tests for attribute "remotedir"
 ok($mirror->Setremotedir("website"));
 ok($mirror->GetRemotedir() eq "website");
#-------------------------------------------------
# tests for attribute "ftpserver"
 ok($mirror->SetFtpServer("home.perl.de"));
 ok($mirror->GetFtpServer() eq "home.perl.de");
 ok($mirror->Set_ftpserver("ftp.net.de"));
 ok($mirror->Get_Ftpserver() eq "ftp.net.de");
#-------------------------------------------------
# tests for attribute "user"
 ok($mirror->set_user("myself"));
 ok($mirror->get_user() eq "myself");
#-------------------------------------------------
# tests for attribute "pass"
 ok($mirror->SetPass("xyz"));
 ok($mirror->getpass() eq "xyz");
#-------------------------------------------------
# tests for attribute "timeout"
 ok($mirror->SetTimeOut(120));
 ok($mirror->gettimeout() == 120);
#-------------------------------------------------
# tests for class-attribute "connection"
 ok($mirror->SetConnection("connection"));
 ok($mirror->GetConnection() eq "connection");
 ok($Net::MirrorDir::_connection eq "connection");
 ok($mirror->setconnection(undef));
 ok(!$mirror->getconnection());
 ok(!$Net::MirrorDir::_connection);
#-------------------------------------------------
# tests with multiple instances
 my @instances = map
 	{
 	Net::MirrorDir->new(
		ftpserver	=> "www.net.de",
 		user	=> 'e-mail@address.de',
 		pass	=> "xyz", 	
 		);
 	} 1..5;
 ok(@instances == 5);
 ok($instances[$_]->SetConnection($_)) for(0..4);
 ok($instances[$_]->GetConnection() == 4) for(0..4);
#-------------------------------------------------
# tests with wrong values
 ok($mirror->SetLocalDir());
 ok($mirror->GetLocalDir() eq '.');
 ok($mirror->SetRemoteDir());
 ok($mirror->GetRemoteDir() eq '');
 ok($mirror->SetExclusions());
# will not intercept
# ok($mirror->SetExlusions("wrong_value"));	
 ok($mirror->AddExclusions(".sys"));
 ok($mirror->SetSubset());
# will not intercept 
# ok($mirror->SetSubset("wrong_value"));
 ok($mirror->AddSubset(".jpg"));
#-------------------------------------------------
# tests for add
 ok(Net::MirrorDir::SetExclusions($mirror, []));
 ok(Net::MirrorDir::SetSubset($mirror, []));
 my $count = 0;
 for(A..Z)
 	{
 	ok($mirror->add_exclusions($_));
 	ok($mirror->add_subset($_));
 	ok($#{$mirror->get_exclusions()} == $count);
 	ok($#{$mirror->get_subset()} == $count++);
 	}
 ok(!$mirror->add_timeout(30));
 ok(!$mirror->add_wrong("txt"));
#-------------------------------------------------
# tests for "exclusions"
 ok($mirror->SetLocalDir("TestA"));
 ok($mirror->Set_exclusions(["exclusions"]));
 ok(my $ref_exclusions = $mirror->Get_exclusions());
 ok($ref_exclusions->[0] eq "exclusions");
 ok($mirror->ReadLocalDir());
# PrintFound();
 ok(!("TestA/TestB/TestC/Dir4/test4.exclusions" eq $_)) for(keys(%{$mirror->GetLocalFiles()}));
 ok($mirror->SetExclusions([qr/TXT/i]));
 ok($mirror->ReadLocalDir());
# PrintFound();
 ok(MyCount() == 2);
 ok($mirror->AddExclusions(qr/SuBsEt/i));
 ok($mirror->ReadLocalDir());
# PrintFound();
 ok(MyCount() == 1);
 ok($mirror->add_exclusions("exclusions"));
 ok($mirror->ReadLocalDir());
# PrintFound();
 ok(MyCount() == 0);
#-------------------------------------------------
# tests for "subset"
 ok($mirror->Set_exclusions([]));
 ok($mirror->Set_subset(["subset"]));
 ok(my $ref_subset = $mirror->Get_subset());
 ok($ref_subset->[0] eq "subset");
 ok($mirror->ReadLocalDir());
# PrintFound();
 ok("TestA/TestB/TestC/Dir2/test2.subset" eq $_) for(keys(%{$mirror->GetLocalFiles()}));
 ok($mirror->SetSubset([qr/TXT/i]));
 ok($mirror->ReadLocalDir());
# PrintFound();
 ok(MyCount() == 5);
 ok($mirror->SetSubset([qr/SUBSET/i, qr/EXCLUSIONS/i]));
 ok($mirror->ReadLocalDir());
# PrintFound();
 ok(MyCount() == 2);
 ok($mirror->AddSubset(qr/TXT/i));
 ok($mirror->ReadLocalDir());
# PrintFound();
 ok(MyCount() == 7);
 ok($mirror->AddExclusions("txt"));
 ok($mirror->ReadLocalDir());
# PrintFound();
 ok(MyCount() == 2);
#-------------------------------------------------
# tests with ftp-server
 SKIP:
 	{
 	my $m = Net::MirrorDir->new(
 		localdir		=> 'TestA',
 		remotedir	=> '/authors/id/K/KN/KNORR/Remote/TestA',
 		ftpserver		=> 'www.cpan.org',
 		user		=> 'anonymous',
 		pass		=> 'create-soft@tiscali.de', 	
 		exclusions	=> ['CHECKSUMS']
 		);
 	skip("no tests with www.cpan.org\n", 12) unless($m->Connect());
 	ok($m->IsConnection());
 	ok(my ($rh_rf, $rh_rd) = $m->ReadRemoteDir());
	ok($m->Quit());
 	warn("remote files: $_\n") for(sort keys %{$rh_rf});
 	warn("remote dirs: $_\n") for(sort keys %{$rh_rd});
 	ok(($rh_lf, $rh_ld) = $m->ReadLocalDir());
 	warn("local files: $_\n") for(sort keys %{$rh_lf});
 	warn("local dirs: $_\n") for(sort keys %{$rh_ld});
 	ok($ra_lfnir = $m->LocalNotInRemote($rh_lf, $rh_rf));
 	ok($ra_ldnir = $m->LocalNotInRemote($rh_ld, $rh_rd));
 	ok($ra_rfnil = $m->RemoteNotInLocal($rh_lf, $rh_rf));
 	ok($ra_rdnil = $m->RemoteNotInLocal($rh_ld, $rh_rd));
 	warn("\n");
 	warn("local file not in remote: $_\n") for(@{$ra_lfnir});
 	warn("local dir not in remote: $_\n") for(@{$ra_ldnir});
 	warn("remote file not in local: $_\n") for(@{$ra_rfnil});
 	warn("remtoe dir not in local: $_\n") for(@{$ra_rdnil});
 	ok(@{$ra_lfnir} == 0);
 	ok(@{$ra_ldnir} == 0);
 	ok(@{$ra_rfnil} == 0);
 	ok(@{$ra_rdnil} == 0);
 	}
#-------------------------------------------------
 SKIP:
 	{
 	skip("no tests with user prompt\n", 10) if($ENV{AUTOMATED_TESTING});
 	my $oldfh = select(STDERR);
 	$| = 1;
 	print("\nWould you like to  test the module with a ftp-server?[y|n]: ");
 	my $response = <STDIN>;
 	skip("no tests with ftp-server\n", 10) unless($response =~ m/^y/i);
 	print("\nPlease enter the hostname of the ftp-server: ");
 	my $s = <STDIN>;
 	chomp($s);
 	print("\nPlease enter your user name: ");
 	my $u = <STDIN>;
 	chomp($u);
 	print("\nPlease enter your password: ");
 	my $p = <STDIN>;
 	chomp($p);
	print("\nPlease enter the local-directory which is to be compared: ");
 	my $l = <STDIN>;
 	chomp($l);
 	print("\nPease enter the remote-directory which is to be compared: ");
 	my $r = <STDIN>;
 	chomp($r);
 	ok($m = Net::MirrorDir->new(
 		localdir		=> $l,
 		remotedir	=> $r,
 		ftpserver		=> $s,
 		user		=> $u,
 		pass		=> $p, 	
 		));
 	ok($m->Connect());
 	ok($m->IsConnection());
 	ok(($rh_lf, $rh_ld) = $m->ReadLocalDir());
 	ok(($rh_rf, $rh_rd) = $m->ReadRemoteDir());
	ok($m->Quit());
 	ok($ra_lfnir = $m->LocalNotInRemote($rh_lf, $rh_rf));
 	ok($ra_ldnir = $m->LocalNotInRemote($rh_ld, $rh_rd));
 	ok($ra_rfnil = $m->RemoteNotInLocal($rh_lf, $rh_rf));
 	ok($ra_rdnil = $m->RemoteNotInLocal($rh_ld, $rh_rd));
 	print("\n");
 	print("local file not in remote: $_\n") for(@{$ra_lfnir});
 	print("local dir not in remote: $_\n") for(@{$ra_ldnir});
 	print("remote file not in local: $_\n") for(@{$ra_rfnil});
 	print("remote dir not in local: $_\n") for(@{$ra_rdnil});	    
 	select($oldfh);
 	}
#-------------------------------------------------
 sub MyCount
 	{
 	#my $count = 0;
 	#for(keys(%{$mirror->GetLocalFiles()})){$count++;}
 	#return($count);
 	my @count = %{$mirror->GetLocalFiles()}; 
 	return(@count / 2);
 	}
#-------------------------------------------------
 sub PrintFound
 	{
 	 warn("\nfound: $_\n")for(keys(%{$mirror->GetLocalFiles()}));
 	}
#-------------------------------------------------

