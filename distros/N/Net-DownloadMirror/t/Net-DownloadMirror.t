# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-DownloadMirror.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

# use Test::More "no_plan";
 use Test::More tests => 97;
BEGIN { use_ok('Net::DownloadMirror') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
#-------------------------------------------------
 use_ok('Storable');
# this section will test the methods in the baseclass Net::MirrorDir
 my $mirror = Net::DownloadMirror->new(
 	localdir		=> 'TestA',
 	remotedir	=> 'TestD',
 	ftpserver		=> 'www.net.de',
 	user		=> 'e-mail@address.de',
 	pass		=> 'xyz', 	
 	);
#-------------------------------------------------
# can we use the methods of the base class Net::MirrorDir
 isa_ok($mirror, 'Net::MirrorDir');
 can_ok($mirror, 'Connect');
 can_ok($mirror, 'IsConnection');
 can_ok($mirror, 'Quit');
 can_ok($mirror, 'ReadLocalDir');
 ok($mirror->ReadLocalDir('.'));
 can_ok($mirror, 'ReadRemoteDir');
 can_ok($mirror, 'LocalNotInRemote');
 ok($mirror->LocalNotInRemote({}, {}));
 can_ok($mirror, 'RemoteNotInLocal');
 ok($mirror->RemoteNotInLocal({}, {}));
 can_ok($mirror, 'AUTOLOAD');
 can_ok($mirror, 'DESTROY');
#-------------------------------------------------
# test attribute 'remotedir' and 'localdir'
 ok($mirror->Set_Remotedir('TestA'));
 ok('TestA' eq $mirror->get_remotedir());
 ok($mirror->SetLocaldir('TestB'));
 ok("TestB" eq $mirror->GetLocaldir());
#-------------------------------------------------
# test attribute 'subset'
 ok($mirror->SetSubset([]));
 ok($mirror->AddSubset('test_1'));
 ok('test_1' eq $mirror->GetSubset()->[0]);
 ok($mirror->AddSubset('test_2'));
 ok('test_2' eq $mirror->GetSubset()->[1]);
 ok($mirror->add_subset('test_3'));
 ok('test_3' eq $mirror->get_subset()->[2]);
 my $count = 0;
 for my $regex (@{$mirror->{_regex_subset}})
 	{
 	for('---test_1---', '---test_2---', '---test_3---')
 		{
 		$count++ if(/$regex/)
 		}
 	}
 ok($count == 3);
#-------------------------------------------------
# test attribute 'exclusions'
 ok($mirror->SetExclusions([qr/test_1/]));
 ok($mirror->AddExclusions(qr/test_2/));
 ok($mirror->add_exclusions(qr/test_3/));
 $count = 0;
 for my $regex (@{$mirror->get_regex_exclusions()})
 	{
 	for('xxxtest_1xxx', 'xxxtest_2xxx', 'xxxtest_3xxx')
 		{
 		$count++ if(/$regex/);
 		}
 	}
 ok($count == 3);
#-------------------------------------------------
# tests for Net::DownloadMirror methods
 isa_ok($mirror, 'Net::MirrorDir');
 isa_ok($mirror, 'Net::DownloadMirror');
 can_ok($mirror, '_Init');
 ok($mirror->_Init());
 can_ok($mirror, 'Download');
 can_ok($mirror, 'StoreFiles');
 ok(!$mirror->StoreFiles([]));
 can_ok($mirror, 'CheckIfModified');
 ok($mirror->CheckIfModified({}));
 can_ok($mirror, 'MakeDirs');
 ok(!$mirror->MakeDirs([]));
 can_ok($mirror, 'DeleteFiles');
 ok($mirror->SetDelete('enable'));
 ok(!$mirror->DeleteFiles([]));
 can_ok($mirror, 'RemoveDirs');
 ok(!$mirror->RemoveDirs([]));
 ok($mirror->SetDelete('disabled'));
 can_ok($mirror, 'UpdateLastModified');
#-------------------------------------------------
# tests for method CleanUp([...])
 can_ok($mirror, 'CleanUp');
 ok(store(
 	{
 	keyA	=> 1234,
 	keyB	=> 'xyz',
 	keyC	=> undef,
 	keyD	=> 56789
 	}, 'times'));
 ok($mirror->SetFileName('times'));
 ok($mirror->CleanUp(['keyA', 'keyB', 'keyC']));
 ok(defined($mirror->{_last_modified}{keyA}));
 ok(!defined($mirror->{_last_modified}{keyB})) for(qw/keyB keyC keyD/);
 ok(unlink('times'));
#-------------------------------------------------
# test for method (ref_array_local_paths) RtoL (ref_array_remote_paths)
 can_ok($mirror, 'RtoL');
 ok($mirror->SetLocalDir('Home'));
 ok($mirror->SetRemoteDir('www.server.de/public'));
 ok(my $ra_ld = $mirror->RtoL(
 	[
 	'www.server.de/public/pageA',
 	'www.server.de/public/pageB',
 	'www.server.de/public/pageC',
 	]));
 ok($ra_ld->[0] eq 'Home/pageA');
 ok($ra_ld->[1] eq 'Home/pageB');
 ok($ra_ld->[2] eq 'Home/pageC');
#-------------------------------------------------
# tests for method (ref_array_remote_paths) LtoR (ref_array_local_paths)
 can_ok($mirror, 'LtoR');
 ok($mirror->SetRemoteDir('ftp.org.de/html/usr/local/name'));
 ok($mirror->SetLocalDir('C:\\Doc/html/homepage'));
 ok(my $ra_rd = $mirror->LtoR(
 	[
 	'C:\\Doc/html/homepage/index.html',
	'C:\\Doc/html/homepage/style.css',
	'C:\\Doc/html/homepage/info.html',
 	]));
 ok($ra_rd->[0] eq 'ftp.org.de/html/usr/local/name/index.html');
 ok($ra_rd->[1] eq 'ftp.org.de/html/usr/local/name/style.css');
 ok($ra_rd->[2] eq 'ftp.org.de/html/usr/local/name/info.html');
#-------------------------------------------------
# tests for attribute 'filename'
 ok($mirror->SetFileName('lastmodified_remote'));
 ok($mirror->GetFileName() eq 'lastmodified_remote');
 ok($mirror->SetFileName('modtime'));
 ok($mirror->GetFileName() eq 'modtime');
 ok(unlink("modtime"));
#-------------------------------------------------
# tests for attribute 'delete'
 ok('disabled' eq $mirror->GetDelete());
#-------------------------------------------------
# tests for attribute 'current_modified'
 ok('HASH' eq ref($mirror->GetCurrent_Modified()));
#-------------------------------------------------
 SKIP:
 	{
 	my $m = Net::DownloadMirror->new(
 		localdir		=> 'TestA',
 		remotedir	=> '/authors/id/K/KN/KNORR/Remote/TestA',
 		ftpserver		=> 'www.cpan.org',
 		user		=> 'anonymous',
 		pass		=> 'create-soft@tiscali.de', 	
 		exclusions	=> ['CHECKSUMS']
 		);
 	skip("no tests with www.cpan.org\n", 16) unless($m->Connect());
 	my $ra_lf = [
 		'TestA/TestB/TestC/Dir1/test1.txt',
 		'TestA/TestB/TestC/Dir2/test2.txt',
 		'TestA/TestB/TestC/Dir2/test2.subset',
 		'TestA/TestB/TestC/Dir3/test3.txt',
 		'TestA/TestB/TestC/Dir4/test4.txt',
 		'TestA/TestB/TestC/Dir4/test4.exclusions',
 		'TestA/TestB/TestC/Dir5/test5.txt'
 		];
 	ok($m->UpdateLastModified($m->LtoR($ra_lf)));
 	ok(
 		defined($m->{_last_modified}{$_})
 		&&
 		$m->{_last_modified}{$_} =~ m/^\d+$/
 		) for(@{$m->LtoR($ra_lf)});
 	ok($m->Download());
 	ok(-f $_) for(@$ra_lf);
 	}
#-------------------------------------------------
 SKIP:
 	{
	skip("no tests with user prompt\n", 2) if($ENV{AUTOMATED_TESTING});
 	my $oldfh = select(STDERR);
 	$| = 1;
	print("\nWould you like to  test the module with a ftp-server?[y|n]: ");
 	my $response = <STDIN>;
 	skip("no tests with ftp-server\n", 2) if(!($response =~ m/^y/i));
 	print("\nPlease enter the hostname of the ftp-server: ");
 	my $s = <STDIN>;
 	chomp($s);
 	print("\nPlease enter your user name: ");
 	my $u = <STDIN>;
 	chomp($u);
 	print("\nPlease enter your ftp-password : ");
 	my $p = <STDIN>;
 	chomp($p);
	print("\nPlease enter the local-directory : ");
 	my $l = <STDIN>;
 	chomp($l);
 	print("\nPease enter the remote-directory : ");
 	my $r = <STDIN>;
 	chomp($r);
 	ok(my $m = Net::DownloadMirror->new(
 		localdir		=> $l,
 		remotedir	=> $r,
 		ftpserver		=> $s,
 		user		=> $u,
 		pass		=> $p, 	
 		filename		=> "mtimes"
 		));
 	ok($m->Download());
	select($oldfh);
 	}
#-------------------------------------------------
