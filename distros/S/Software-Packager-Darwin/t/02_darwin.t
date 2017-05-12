# t/04_darwin.t; load Software::Packager and create a MacOS X package

$|++; 
my $test_number = 1;
use Software::Packager;
use Cwd;
use Config;
use File::Path;

if ($Config{'osname'} =~ /darwin/i)
{
	print "1..20\n";
}
else
{
	print "1..0\n";
	exit 0;
}

# test 1
my $packager = new Software::Packager();
print_status($packager);

# test 2
$packager->package_name('MacOSXTestPackage');
my $package_name = $packager->package_name();
same('MacOSXTestPackage', $package_name);

# test 3
$packager->program_name('Software Packager');
my $program_name = $packager->program_name();
same('Software Packager', $program_name);

# test 4
$packager->description("This is a description");
my $description = $packager->description();
same("This is a description", $description);

# test 5
$packager->version('1.0.0');
my $version = $packager->version();
same('1.0.0', $version);

# test 6
$packager->output_dir(".");
my $output_dir = $packager->output_dir();
same(".", $output_dir);

# test 7
$packager->category("Applications");
my $category = $packager->category();
same("Applications", $category);

# test 8
$packager->architecture("None");
my $architecture = $packager->architecture();
same("None", $architecture);

# test 9
$packager->icon("t/test_icon.tiff");
my $icon = $packager->icon();
same("t/test_icon.tiff", $icon);

# test 10
$packager->prerequisites("None");
my $prerequisites = $packager->prerequisites();
same("None", $prerequisites);

# test 11
$packager->vendor("Gondwanatech");
my $vendor = $packager->vendor();
same("Gondwanatech", $vendor);

# test 12
$packager->email_contact('rbdavison@cpan.org');
my $email_contact = $packager->email_contact();
same('rbdavison@cpan.org', $email_contact);

# test 13
$packager->creator('R Bernard Davison');
my $creator = $packager->creator();
same('R Bernard Davison', $creator);

# test 14
$packager->install_dir("perllib");
my $install_dir = $packager->install_dir();
same("/perllib", $install_dir);

# test 15
$packager->tmp_dir("t/darwin_tmp_build_dir");
my $tmp_dir = $packager->tmp_dir();
same("t/darwin_tmp_build_dir", $tmp_dir);

# test 16
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

# test 17
my %hardlink;
$hardlink{'TYPE'} = 'Hardlink';
$hardlink{'SOURCE'} = "lib/Software/Packager/Darwin.pm";
$hardlink{'DESTINATION'} = "HardLink.pm";
print_status($packager->add_item(%hardlink));

# test 18
my %softlink;
$softlink{'TYPE'} = 'softlink';
$softlink{'SOURCE'} = "lib/Software";
$softlink{'DESTINATION'} = "SoftLink";
print_status($packager->add_item(%softlink));

# test 19
print_status($packager->package());

# test 20
my $package_file = $packager->output_dir();
$package_file .= "/" . $packager->package_name();
$package_file .= ".pkg";
print_status(-d $package_file);

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
