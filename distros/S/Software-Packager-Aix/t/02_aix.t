# t/03_aix.t; load Software::Packager and create an AIX package

use Software::Packager;
use Cwd;
use Config;
use Test;

plan( tests => 29 );

$| = 1; 
my $test_number = 1;
my $comment = "";

warn "# Some warning and error messages are displayed as part of the tests and can be ignored.\n";

# test 1
my $packager = new Software::Packager('aix');
print_status($packager);

# test 2
$packager->package_name('AIXTestPackage');
my $package_name = $packager->package_name();
same('AIXTestPackage', $package_name);

# test 3
$packager->description("This is a description");
my $description = $packager->description();
same("This is a description", $description);

# test 4
$packager->version("12.12.1234.1234.123456789");
same("12.12.1234.1234.123456789", $packager->version());

# test 5
$packager->version("123.123.12345.12345.1234567890");
same("12.12.1234.1234.123456789", $packager->version());

# test 6
$packager->version("4.3.2.1");
same('4.3.2.1' ,$packager->version());

# test 7
$packager->version("2");
same('2.1.0.0', $packager->version());

# test 8
my $cwd_output_dir = getcwd();
$packager->output_dir($cwd_output_dir);
my $output_dir = $packager->output_dir();
same("$cwd_output_dir", $output_dir);

# test 9
$packager->category("Applications");
my $category = $packager->category();
same("Applications", $category);

# test 10
$packager->architecture("None");
my $architecture = $packager->architecture();
same("None", $architecture);

# test 11
$packager->icon("None");
my $icon = $packager->icon();
same("None", $icon);

# test 12
$packager->prerequisites("None");
my $prerequisites = $packager->prerequisites();
same("None", $prerequisites);

# test 13
$packager->vendor("Gondwanatech");
my $vendor = $packager->vendor();
same("Gondwanatech", $vendor);

# test 14
$packager->email_contact('rbdavison@cpan.org');
my $email_contact = $packager->email_contact();
same('rbdavison@cpan.org', $email_contact);

# test 15
$packager->creator('R Bernard Davison');
my $creator = $packager->creator();
same('R Bernard Davison', $creator);

# test 16
$packager->install_dir("perllib");
my $install_dir = $packager->install_dir();
same("perllib", $install_dir);

# test 17
$packager->program_name("softwarepackager");
same("softwarepackager", $packager->program_name());

# test 18
$packager->component_name("aix");
same("aix", $packager->component_name());

# test 19
$packager->tmp_dir("t/aix_tmp_build_dir");
my $tmp_dir = $packager->tmp_dir();
same("t/aix_tmp_build_dir", $tmp_dir);

# test 20
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
        if ($file =~ /etc/)
        {
                $data{'DESTINATION'} = $file;
        }
        else
        {
                $data{'DESTINATION'} = "/usr/lib/perl/$file";
        }
	$data{'MODE'} = sprintf "%04o", $stats[2] & 07777;
	$add_status = undef unless $packager->add_item(%data);
}
print_status($add_status);
close MANIFEST;

# test 21
foreach my $dir  ("lib", "lib/Software", "lib/Software/Packager", "lib/Software/Packager/Object", "t")
{
	my @stats = stat $dir;
	my %data;
	$data{'TYPE'} = 'Directory';
	$data{'DESTINATION'} = "/usr/lib/perl/$dir";
	$data{'MODE'} = sprintf "%04o", $stats[2] & 07777;
	$add_status = undef unless $packager->add_item(%data);
}
print_status($add_status);

# test 22
my %hardlink;
$hardlink{'TYPE'} = 'Hardlink';
$hardlink{'SOURCE'} = "/usr/lib/perl/lib/Software/Packager/Aix.pm";
$hardlink{'DESTINATION'} = "/usr/lib/perl/HardLink.pm";
print_status($packager->add_item(%hardlink));

# test 23
my %etcfile;
$etcfile{'TYPE'} = 'File';
$etcfile{'SOURCE'} = "$cwd/t/02_aix.t";
$etcfile{'MODE'} = '0640';
$etcfile{'DESTINATION'} = "/etc/Software/Packager/Aix.conf";
print_status($packager->add_item(%etcfile));

# test 24
my %error_object;
$error_object{'TYPE'} = 'File';
$error_object{'SOURCE'} = "t/02_aix.t";
$error_object{'MODE'} = '0640';
$error_object{'DESTINATION'} = "/etc/F,ail1.conf";
fail($packager->add_item(%error_object));

# test 25
$error_object{'DESTINATION'} = "/etc/Fai:l1.conf";
fail($packager->add_item(%error_object));

# test 26
my %softlink;
$softlink{'TYPE'} = 'softlink';
$softlink{'SOURCE'} = "/usr/lib/perl/lib/Software";
$softlink{'DESTINATION'} = "/usr/lib/perl/SoftLink";
print_status($packager->add_item(%softlink));

# test 27
my %etcdir;
$etcdir{'TYPE'} = 'directory';
$etcdir{'MODE'} = '0750';
$etcdir{'DESTINATION'} = "/etc/Software";
print_status($packager->add_item(%etcdir));

# test 28
print_status($packager->package());

# test 29
my $package_file = $packager->output_dir();
$package_file .= "/" . $packager->package_name();
$package_file .= ".bff";
print_status(-f $package_file);

# The tests are complete so cleanup
unlink $package_file;

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

sub fail
{
	my $value = shift;
	if ($value)
	{
		print "not ok $test_number $comment\n";
	}
	else
	{
		print "ok $test_number\n";
	}
	$test_number++;
	$comment = "";
}


