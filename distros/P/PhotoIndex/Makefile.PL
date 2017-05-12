use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

print "Checking for Imager perl module...";
eval 
{
    require Imager;
};
if ($@) 
{
    print " failed\n";
    print <<EOT;
$@
Imager is required for making the thumbnails you can download it from CPAN

EOT
exit(1);
} 
else 
{
    print " ok\n";
}

WriteMakefile(
    'NAME'	=> 'Apache::PhotoIndex',
    'VERSION_FROM' => 'PhotoIndex.pm', # finds $VERSION
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
);
