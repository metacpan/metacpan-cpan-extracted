# t/02_tar.t; load Software::Packager and create a Tar package.

$|++; 

# need to test for the rpm program here.
if (-f "/bin/rpm")
{
	print "1..24\n";
}
else
{
	print "1..24\n";
#	print "1..0\n";
#	exit 0;
}
my $test_number = 1;
my $comment = "# Using Software::Packager::Rpm";
use Software::Packager;
use Cwd;

# test 1
my $packager = new Software::Packager('rpm');
print_status($packager);

# test 2
$packager->version("1.0.0 \nAlpha-1");
my $version = $packager->version();
same('1.0.0Alpha1', $version);

# test 3
$packager->program_name("Software - Packager - Rpm");
my $program_name = $packager->program_name();
same('SoftwarePackagerRpm', $program_name);

# test 3
#$packager->package_name('RPMTestPackage');
my $package_name = $packager->program_name();
$package_name .= "-" . $packager->version();
$package_name .= "-" . $packager->release();
$package_name .= "." . `uname -m`;
$package_name =~ s/\n//g;
$package_name .= ".rpm";
same($package_name, $packager->package_name());

# test 3
$packager->copyright("Perl");
my $copyright = $packager->copyright();
same('Perl', $copyright);

# test 3
$packager->homepage("http://bernard.gondwana.com.au");
my $homepage = $packager->homepage();
same("http://bernard.gondwana.com.au", $homepage);

# test 3
$packager->source("$homepage/sp/Software-Packager-$version.tar.gz");
my $source = $packager->source();
same("$homepage/sp/Software-Packager-$version.tar.gz", $source);

# test 4
$packager->description("This is a description\n\nIt can go over many lines\n\n and have\n some formatting\n");
my $description = $packager->description();
same("This is a description\n\nIt can go over many lines\n\n and have\n some formatting\n", $description);

# test 5
$packager->short_description("This is a short description");
my $short_description = $packager->short_description();
same("This is a short description", $short_description);

# test 6
my $cwd_output_dir = getcwd();
$packager->output_dir($cwd_output_dir);
my $output_dir = $packager->output_dir();
same("$cwd_output_dir", $output_dir);

# test 7
$packager->category("Applications");
my $category = $packager->category();
same("Applications", $category);

# test 8
my $arch = `uname -m`;
$arch =~ s/\n//g;
$packager->architecture($arch);
my $architecture = $packager->architecture();
same($arch, $architecture);

# test 9
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
$packager->tmp_dir("t/rpm_tmp_build_dir");
my $tmp_dir = $packager->tmp_dir();
same("t/rpm_tmp_build_dir", $tmp_dir);

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
$hardlink{'SOURCE'} = "lib/Software/Packager/Rpm.pm";
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
my $package_file = $packager->package_name();
print_status(-f $package_file);

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


