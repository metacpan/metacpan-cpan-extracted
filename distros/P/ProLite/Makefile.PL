use ExtUtils::MakeMaker;

# WriteMakefile's PREQ_PM is ugly...

my %req = (
  	Time::HiRes			=> "Provide delay capabilities for Serial Communications",
   	Device::SerialPort	=> "Provide for Asynchronous Serial Communications",
);



my($key, $missing);
print "Checking for prerequisite modules...\n";
foreach $key (keys %req)
{
	printf("  %-30s ", qq("$key"));
	eval ("require $key");
	if($@) {
		print "Missing!\n      needed to: $req{$key}\n";
		$missing++;
	}
	else {
		print "ok.\n";
	}
}

print STDERR "\n$missing modules not found.\nPlease see http://www.cpan.org to ".
"obtain missing modules before installation will succeed.\n" and exit 1 if $missing;

WriteMakefile(
    'NAME'			=> 'ProLite',
    'VERSION_FROM'	=> 'ProLite.pm', 
);
