use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

open FILE,'./t/api.key';
my @lines = <FILE>;
close FILE;
my $default = $lines[0];
my $key;
if ($default) {
    $key = prompt("Enter your PicApp API Key:",$default);
} else {
    $key = prompt("Enter your PicApp API Key:");
    open FILE,'>./t/api.key';
    print FILE $key;
    close FILE;
}

unless ($key) {
    die "You must provide the system will an API Key";
}

WriteMakefile(
    'NAME'	=> 'Net::PicApp',
    'VERSION_FROM'	=> 'lib/Net/PicApp.pm',
    'ABSTRACT'  => "A library for interfacing with the PicApp service.",
    'AUTHOR'    => 'Byrne Reese <byrne@majordojo.com>',
    'DISTNAME'  => 'Net-PicApp',
    'LICENSE'   => 'perl',
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
    'PREREQ_PM' => {
        'XML::Simple' => 0,
        'LWP::UserAgent' => 0,
        'URI::Escape' => 0,
        'Class::Accessor' => 0
    },
);
__END__
