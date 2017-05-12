
use ExtUtils::MakeMaker;
use Config;

print qq{
Part of the test suite performs possibly intrusive tests on 
the DHCP server.  Would you like me to perform the intrusive tests?
(Default is YES) >> };
chomp(my $resp = <STDIN>);
$resp ||= "yes";
if ($resp =~ /^[yY]/) {
    open F, ">", ".risky_tests" or die "Couldn't touch .risky_tests: $!\n";
    close F;
} else {
    1 while unlink ".risky_tests";
}

system("$Config{perlpath} ./config-tests") == 0
    or die "Couldn't run configurator; return status $?\n";

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Net::DHCP::Control',
    'VERSION_FROM'	=> 'lib/Net/DHCP/Control.pm',
    'PREREQ_PM'		=> {
    },

    ($] >= 5.005 ? (
        AUTHOR		=> 'Mark Jason Dominus (mjd@isc.upenn.edu)',
    ) : ()),

    'LIBS'		=> ['-L./LIBS -ldhcpctl -lomapi -ldst'],
    'DEFINE'		=> '',
    'INC'		=> '',
    'OPTIMIZE'          => '-g',
    'LDDLFLAGS'         => '-bundle -undefined dynamic_lookup',
    'LDFLAGS'           => '',
);


use ExtUtils::Constant qw (WriteConstants); 
WriteConstants( NAME => 'Net/DHCP/Control', 
		NAMES => [map "TP_$_", qw(INT UINT STRING UNSPECIFIED BOOL)],
		);
