# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl SharePoint-SOAPHandler.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests=>45; #require and import instead of use, since what is imported changes as
				#we decide whether we want to do live tests or not
#use Test::More tests => 1;
BEGIN { use_ok('SharePoint::SOAPHandler') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


BEGIN { use_ok('CopyTree::VendorProof') };

BEGIN { use_ok('Term::ReadKey') };
my %config;
#default configuration
$config{authroot} ||='https://www.yoursharepointsite.org:443/sitedir/the_dir_right_above_your_Shared_Documents';
$config{sharepointdomain} ||='www.yoursharepointsite.org:443';
$config{domuser} ||='DOMAIN_CAPS\username';
$config{no_proxies} ||='y';

open my $config_fh, "<", "test.config" or die "Could not open test configuration!";
while(<$config_fh>) {
  chomp;
  my ($key, $value) = split /\s+/, $_, 2;
   $config{$key} = $value;
}
close $config_fh;

SKIP:{

skip 'skipping online tests', 42 if (!$config{'live_tests'});
#if(!$config{live_tests}) {
#  # import Test::More tests => 1;
#  # ok(1);
#	done_testing();
#	
#   exit;
#}
#import Test::More 'no_plan';

	
	my $cpobj = CopyTree::VendorProof->new;
	isa_ok ($cpobj, "CopyTree::VendorProof", 'cpobj is a correct obj');
	
	my $soaphandler_inst=SharePoint::SOAPHandler->new;
	isa_ok ($soaphandler_inst, "SharePoint::SOAPHandler", 'connector_inst is a correct SharePoint::SOAPHandler obj');


#	warn "\n";
#	warn "========================================================================\n";
#	warn "|      We need to connect to your sharepoint site                      |\n";
#	warn "|      Would you rather enter the filename of a cred_file 'f' or       |\n";
#	warn "|      Would you prefer to enter your creds here 'h'                   |\n";
#	warn "|                                                                      |\n";
#	warn "=======================================================================|\n";
#	chomp(my $file_cred =<STDIN>);
	my ($u, $p, $creds_dom, $authroot, $no_https_proxy);
#	if ($file_cred eq 'f'){
#		my @creds;
#		warn("in a plain text file, please enter, line by line, your:\n");
#		warn ("DOMAIN_CAPS\\username\n");
#		warn ("password\n");
#		warn ("www.yoursharepointsite.org:443\n");
#		warn ("https://www.yoursharepointsite.org:443/sitedir/the_dir_right_above_your_Shared_Documents\n");
#		warn ("'y' for deleting your \$ENV{'https_proxy'}");
#		warn ("please enter the full path of this plain text file\n");
#		chomp(my $fn = <STDIN>);
#		open my $FH, "<", $fn or Carp::croak ("cannot open cred file $!");
#		while (<$FH>){
#			chomp;
#			push @creds, $_;
#		}
#		($u, $p, $creds_dom, $authroot, $no_https_proxy)=@creds[0..4];
#	}
#	else{
		print STDERR "\n";
		print STDERR "========================================================================\n";
		print STDERR "|      We need to connect to your sharepoint site                      |\n";
		print STDERR "|      Please enter your sharepoint username:                          |\n";
		print STDERR "|      Note: it must be in this format: DOMAIN_ALLCAPS\\username        |\n";
		print STDERR "|                                                                      |\n";
		print STDERR "=======================================================================|\n";
		print STDERR "DOMAIN\\username [".$config{domuser}."]: ";
		chomp($u = <STDIN>);
		$config{domuser}=$u if $u;
		print STDERR "\n";
		print STDERR "========================================================================\n";
		print STDERR "|      Now please enter your password for sharepoint:                  |\n";
		print STDERR "=======================================================================|\n";
		print STDERR "password (will not echo on screen): ";
		Term::ReadKey::ReadMode('noecho');
		chomp ($p=<STDIN>);
		print STDERR "\n";
		Term::ReadKey::ReadMode(0);
		print STDERR "========================================================================\n";
		print STDERR "|      enter your sp_creds_domain as such:                             |\n";
		print STDERR "|      (no 'http://' and no trailing '/' )                             |\n";
		print STDERR "|      www.sharepointsite.org:443                                      |\n";
		print STDERR "|                                                                      |\n";
		print STDERR "=======================================================================|\n";
		print STDERR "sp_creds_domain [".$config{sharepointdomain}."]: ";
		chomp ($creds_dom=<STDIN>);
		$creds_dom =~ s/\/$//;#clears trailing slashes
		$config{sharepointdomain}=$creds_dom if $creds_dom;
		print STDERR "\n";
		print STDERR "========================================================================\n";
		print STDERR "|      enter your sp_authorizedroot as such:                           |\n";
		print STDERR "| https://www.sharepointsite.org:443/dir_just_above_Shared_documents   |\n";
		print STDERR "|     Use plain spaces (don't escape with %20) and                     |\n";
		print STDERR "|     Please, NO trailing slashes.                                     |\n";
		print STDERR "=======================================================================|\n";
		print STDERR "sp_authorizedroot [".$config{authroot}."]: ";
		chomp ($authroot=<STDIN>);
		$authroot =~ s/\/$//;#clears trailing slashes
		$config{authroot}=$authroot if $authroot;
		print STDERR "\n";
		print STDERR "========================================================================\n";
		print STDERR "|      do you normally use a proxy server, but want to AVOID           |\n";
		print STDERR "|      using it for your https sharepoint connection? (y/n)            |\n";
		print STDERR "|        [that is, enter 'y' to avoid proxy, or 'n' to use it]         |\n";
		print STDERR "|      your config could be:                                           |\n";
		print STDERR "|      you don't know what a proxy is --> type 'n'                     |\n";
		print STDERR "|      your sharepoint is outside your proxy --> type 'n'              |\n";
		print STDERR "|      your sharepoint is inside your proxy --> type 'y'               |\n";
		print STDERR "|                                                                      |\n";
		print STDERR "=======================================================================|\n";
		print STDERR "no_https_proxy [".$config{no_proxies}. "]: ";
		chomp ($no_https_proxy=<STDIN>);
		$config{no_proxies}=$no_https_proxy if $no_https_proxy;
#	} #end else
	if ($config{no_proxies} eq 'y'){
		delete $ENV{'https_proxy'};
		delete $ENV{'http_proxy'};
	}
	print STDERR "\n";
	#save config
	open $config_fh, ">", "test.config";
	for my $key (keys %config) {
	#   print "$key ".$config{$key} ."\n";
	   print $config_fh "$key ".$config{$key} ."\n";
	}





	print "*******************************\n";
	
	isnt ($config{domuser}, '', 'has a sp username');
	isnt ($p, '', 'has a sp password');
	isnt ($config{sharepointdomain}, '', 'has a sp_creds_domain');
	isnt ($config{authroot}, '', 'has a sp_authrized_root');
	
	$soaphandler_inst->sp_creds_domain ($config{sharepointdomain});
	$soaphandler_inst ->sp_creds_user($config{domuser});
	$soaphandler_inst ->sp_creds_password($p);
	$soaphandler_inst ->sp_authorizedroot($config{authroot});
	
	my $content = "somecontent\n";
#	use Data::Dumper;
#	open my $FH, ">", "diag_withmod";
	#print $FH Dumper( $soaphandler_inst->sp_connect_lwp);	
	$soaphandler_inst -> cust_mkdir ('Shared Documents/script_qc')or clunk();
	
	my $path='Shared Documents/script_qc/somepath';
	$soaphandler_inst -> write_from_memory(\$content, $path);
	my $readmemscalarref=$soaphandler_inst -> read_into_memory($path);
	is ($$readmemscalarref, "somecontent\n","test read content to be same as written");
	my $newpath='Shared Documents/script_qc/somepath2';
	$soaphandler_inst -> copy_local_files( $path, $newpath);
	#new content should overwrite
	my $newcontent="newcontent\n";
	$soaphandler_inst -> write_from_memory(\$newcontent, $newpath);
	$readmemscalarref=$soaphandler_inst -> read_into_memory($newpath);
	is ($$readmemscalarref, "newcontent\n","test read, new content overwrite old content");
	$soaphandler_inst -> copy_local_files( $path, $newpath);
	$readmemscalarref=$soaphandler_inst -> read_into_memory($newpath);
	is ($$readmemscalarref, "somecontent\n","copy_local_files will overwrite content (newcontent back to somecontent)");

	my $newdirpath ='Shared Documents/script_qc/targetdir';

	$soaphandler_inst -> cust_mkdir ($newdirpath)or clunk();
	$soaphandler_inst -> write_from_memory(\$newcontent, 'Shared Document/script_qc/targetdir');
	my @emptyarr = $soaphandler_inst -> fdls('',$newdirpath);
	
	is (scalar (@emptyarr), "0","write_from_memory should fail on dir target");
	@emptyarr = $soaphandler_inst -> fdls('',$newdirpath);

	$soaphandler_inst -> copy_local_files( $path, $newdirpath);
	is (scalar (@emptyarr), "0","copy_local_files should fail on dir target");
	
	
	
	
	isa_ok (ref $cpobj ->src ($path,$soaphandler_inst), 'CopyTree::VendorProof', 'src returns self');
	is (ref $cpobj ->{'source'}{$path}, 'SharePoint::SOAPHandler', 'src stores connector_inst with path as key');
	my @testpath= keys %{$cpobj ->{'source'}};
	is ($testpath[0], $path, 'src stores actual path key');
	#dst is getter and setter, does not return self
	$path ='Shared Documents/script_qc/someotherpath';
	$cpobj ->dst ($path,$soaphandler_inst); #setter
	is (ref $cpobj ->{'destination'}{$path}, 'SharePoint::SOAPHandler', 'dst stores path and connector_inst');
	my ($returnpath, $returninst) = $cpobj ->dst ();
	is ($returnpath, $path,'first part of dst() returns path');
	is (ref $returninst,'SharePoint::SOAPHandler' ,'second part of dst() returns connector_inst');
	my $newcpobj = CopyTree::VendorProof->new;
	eval {$newcpobj ->cp;};
	like ($@, qr"^dest file is not defined\.", 'no dst object/file');
	$newcpobj = CopyTree::VendorProof->new;
	$newcpobj -> dst ('', $soaphandler_inst);
	eval {$newcpobj ->cp;};
	like ($@, qr"^dest file is not defined\.", 'dst obj, no fd_ls meth, no path. no path fails first');
	$newcpobj = CopyTree::VendorProof->new;
	$newcpobj -> dst ('Shared Documents/script_qc/someotherpath', $soaphandler_inst);
	eval {$newcpobj ->cp;};
	like ($@, qr/you don't have a source/, 'copy local to local, somepath to someotherpath, no src declair');
	$newcpobj ->src ('Shared Documents/script_qc/somepath', 'nobj');
	eval {$newcpobj ->cp;};
	like ($@, qr/Can't locate object method "is_fd"/, 'copy local to local, somepath to someotherpath, src inst no methods');
	$newcpobj = CopyTree::VendorProof->new;
	$newcpobj -> dst ('Shared Documents/script_qc/someotherpath', $soaphandler_inst);
	$newcpobj ->src ('Shared Documents/script_qc/somepath', $soaphandler_inst);
	eval {$newcpobj ->cp;};
	is ($@, '', 'copy local to local, somepath to someotherpath');
	is ($soaphandler_inst -> is_fd ('Shared Documents/script_qc/somepath') , 'f', 'file test f on src');
	is ($soaphandler_inst -> is_fd ('Shared Documents/script_qc/someotherpath') , 'f', 'file test f on src');
	#use base qw/CopyTree::VendorProof/;
	my @files;
	@files = $soaphandler_inst ->fdls ('f', '.');
	isnt ($files[0], '', 'fdls f, . shoudld get somepath and someotherpath');	
	$soaphandler_inst->cust_mkdir("Shared Documents/script_qc/testdir");
	my @dirs = $soaphandler_inst ->fdls ('d', 'Shared Documents/script_qc/testdir/../');
	isnt ($dirs[0], '', 'fdls f, ../ use of .. and ending slash auto removed');	
	is ($soaphandler_inst -> is_fd ("Shared Documents/script_qc/testdir"), 'd', "is_fd returns 'd' on dir");
	$newcpobj ->reset;
	$newcpobj ->src ('Shared Documents/script_qc/someotherpath', $soaphandler_inst);
	$newcpobj ->dst ('Shared Documents/script_qc/testdir', $soaphandler_inst);
	$newcpobj ->cp;
	is ($soaphandler_inst->is_fd('Shared Documents/script_qc/testdir/someotherpath'), 'f','cp file to dir');
	
	$newcpobj ->reset;
	$newcpobj ->src ('Shared Documents/script_qc/someotherpath', $soaphandler_inst);
	$newcpobj ->dst ('Shared Documents/script_qc/testdir/diffname', $soaphandler_inst);
	$newcpobj ->cp;
	is ($soaphandler_inst->is_fd('Shared Documents/script_qc/testdir/diffname'), 'f','cp file to different file name');
	
	$newcpobj ->reset;
	$newcpobj ->src ('Shared Documents/script_qc/testdir', $soaphandler_inst);
	$newcpobj ->dst ('Shared Documents/script_qc/testdir2', $soaphandler_inst);
	eval {$newcpobj ->cp;};
	like ($@, qr/you cannot copy a dir \[Shared Documents\/script_qc\/testdir] into a non \/ non-existing dir \[Shared Documents\/script_qc\/testdir2]/,'cp dir to dir copy, check non existing dest dir copy shoudl fail' );
	
	$soaphandler_inst ->cust_mkdir ('Shared Documents/script_qc/testdir2');
	$newcpobj ->cp;
	is ($soaphandler_inst->is_fd('Shared Documents/script_qc/testdir2/testdir'), 'd','cp dir to dir copy, check source dir inside dest');
	is ($soaphandler_inst->is_fd('Shared Documents/script_qc/testdir2/testdir/diffname'), 'f','cp dir to dir copy, check source dir, file inside dest');
	is ($soaphandler_inst->is_fd('Shared Documents/script_qc/testdir2/testdir/someotherpath'), 'f','cp dir to dir copy, check source dir, file inside dest');
	is ($soaphandler_inst->is_fd('Shared Documents/script_qc/nonexist/bsfile'), 0,'cp dir to dir copy, check source dir, file inside dest');
	$soaphandler_inst ->write_from_memory($soaphandler_inst->read_into_memory('Shared Documents/script_qc/testdir2/testdir/diffname'), 'Shared Documents/script_qc/testdir2/written');
	$soaphandler_inst ->copy_local_files('Shared Documents/script_qc/testdir2/testdir/diffname',  'Shared Documents/script_qc/testdir2/written_local');
	is ($soaphandler_inst->is_fd('Shared Documents/script_qc/testdir2/written'), 'f','write_from_memory, read_into_memory test');
	is ($soaphandler_inst->is_fd('Shared Documents/script_qc/testdir2/written_local'), 'f','copy_local_files test');
	my ($arrf, $arrd) = $soaphandler_inst ->fdls ('fdarrayrefs', '.');
	is (ref $arrf, 'ARRAY', 'fdarrayrefs test');
	is (ref $arrd, 'ARRAY', 'fdarrayrefs test');
	
	eval{$soaphandler_inst -> cust_rmdir ('non-existingdir');};
	like ($@,qr/wait\. you told me to delete something that's not a dir\. I'll stop for your protection/, 'removing an non existing dir dies'); 
	$soaphandler_inst->cust_rmdir ("Shared Documents/script_qc/testdir");
	$soaphandler_inst->cust_rmdir ("Shared Documents/script_qc/testdir2");
	$soaphandler_inst->cust_rmfile ('Shared Documents/script_qc/somepath');
	is ($soaphandler_inst -> is_fd('Shared Documents/script_qc/somepath'), 'pd', 'successful single file delete');

	#kinda afraid to test these:
	#eval {$soaphandler_inst->cust_rmdir ("/");};
	#like ($@, qr'should not be rmdiring a root', 'do not rmdir / no matter what you say test');
	#eval {$soaphandler_inst->cust_mkdir ("/");};
	#like ($@, qr'should not be mkdiring a root', 'do not mkdir / no matter what you say test');
	is ($soaphandler_inst -> is_fd ("Shared Documents/script_qc/testdir"), 'pd', "is_fd returns 'pd' on non-existing");
	
	$soaphandler_inst->cust_rmdir ("Shared Documents/script_qc");
	
	is ($soaphandler_inst -> is_fd ("Shared Documents/script_qc"), 'pd', "is_fd returns 'pd' on non-existing");
}

done_testing();
