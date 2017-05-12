# t/02_tar.t; load Software::Packager and create a Tar package.

$|++; 

my $load_module = "require Archive::Tar;\n";
$load_module .= "import Archive::Tar;\n";
eval $load_module;

if ($@)
{
	print "1..0\n";
	warn "Module Archive::Tar not found. ";
	exit 0;
}
else
{
	print "1..19\n";
}
my $test_number = 1;
my $comment = "";
use Software::Packager;
use Cwd;

# test 1
my $packager = new Software::Packager('tar');
print_status($packager);

# test 2
$packager->version('1.0.0');
my $version = $packager->version();
same('1.0.0', $version);

# test 3 the package name should be what we pass-version
$packager->package_name('TarTestPackage');
my $package_name = $packager->package_name();
same('TarTestPackage-1.0.0', $package_name);

# test 4
$packager->description("This is a description");
my $description = $packager->description();
same("This is a description", $description);

# test 5
my $cwd_output_dir = getcwd();
$packager->output_dir($cwd_output_dir);
my $output_dir = $packager->output_dir();
same("$cwd_output_dir", $output_dir);

# test 6
$packager->category("Applications");
my $category = $packager->category();
same("Applications", $category);

# test 7
$packager->architecture("None");
my $architecture = $packager->architecture();
same("None", $architecture);

# test 8
$packager->icon("None");
my $icon = $packager->icon();
same("None", $icon);

# test 9
$packager->prerequisites("None");
my $prerequisites = $packager->prerequisites();
same("None", $prerequisites);

# test 10
$packager->vendor("Gondwanatech");
my $vendor = $packager->vendor();
same("Gondwanatech", $vendor);

# test 11
$packager->email_contact('rbdavison@cpan.org');
my $email_contact = $packager->email_contact();
same('rbdavison@cpan.org', $email_contact);

# test 12
$packager->creator('R Bernard Davison');
my $creator = $packager->creator();
same('R Bernard Davison', $creator);

# test 13
$packager->install_dir("$ENV{'HOME'}/perllib");
my $install_dir = $packager->install_dir();
same("$ENV{'HOME'}/perllib", $install_dir);

# test 14
$packager->tmp_dir("t/tar_tmp_build_dir");
my $tmp_dir = $packager->tmp_dir();
same("t/tar_tmp_build_dir", $tmp_dir);

# test 15
# so we have finished the configuration so add the objects.
open (MANIFEST, "< MANIFEST") or warn "Cannot open MANIFEST: $!\n";
my $add_status = 1;
my $cwd = getcwd();
while (<MANIFEST>)
{
	my $file = $_;
	chomp $file;
	my @stats = stat $file;
	my %data;
	$data{'TYPE'} = 'File';
	$data{'TYPE'} = 'Directory' if -d $file;
	$data{'SOURCE'} = "$cwd/$file";
	$data{'DESTINATION'} = $file;
	$data{'MODE'} = sprintf "%04o", $stats[2] & 07777;
	$add_status = undef unless $packager->add_item(%data);
}
print_status($add_status);
close MANIFEST;

# test 16
my %hardlink;
$hardlink{'TYPE'} = 'Hardlink';
$hardlink{'SOURCE'} = "lib/Software/Packager.pm";
$hardlink{'DESTINATION'} = "HardLink.pm";
print_status($packager->add_item(%hardlink));

# test 17
my %softlink;
$softlink{'TYPE'} = 'softlink';
$softlink{'SOURCE'} = "lib/Software";
$softlink{'DESTINATION'} = "SoftLink";
print_status($packager->add_item(%softlink));

# test 18
print_status($packager->package());

# test 19
my $package_file = $packager->output_dir();
$package_file .= "/" . $packager->package_name();
$package_file .= ".tar";
print_status(-f $package_file);

unlink "TarTestPackage-1.0.0.tar";

####################
# Functions to use
sub same
{
	my $expected = shift;
	my $got = shift;
	if ($expected eq $got)
	{
		print_status(1);
	}
	else
	{
		$comment = " # Expected:\"$expected\" but Got:\"$got\"" unless $comment;
		print_status(0, $comment);
	}
	$comment = "";
}

sub print_status
{
	my $value = shift;
	if ($value)
	{
		print "ok $test_number\n";
	}
	else
	{
		print "not ok $test_number $comment\n";
	}
	$test_number++;
	$comment = "";
}


