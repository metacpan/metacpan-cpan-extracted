use strict;
use warnings;
my $version = "0.05";	# for nomake versions
use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR            => 'Cosimo Streppone <cosimo@cpan.org>',
    NAME              => 'Test::Device::SerialPort',
    LICENSE           => 'perl',
    ABSTRACT_FROM     => 'lib/Test/Device/SerialPort.pm',
    VERSION_FROM      => 'lib/Test/Device/SerialPort.pm',
    PREREQ_PM         => {
		'Test::More' => 0,
	},
    META_MERGE => {
        resources => {
            repository => 'git://github.com/cosimo/perl5-test-device-serialport.git',
            bugtracker => 'mailto:bug-test-device-serialport@rt.cpan.org',
            license    => 'http://dev.perl.org/licenses/',
        },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Test-Device-SerialPort-* *.cfg t/*.cfg' },
    realclean       => { 'FILES' => "nomake_test nomake_install" },
);

print <<COMMENTS;
            Test::Device::SerialPort VERSION $version

A 'Makefile' is created for those with 'make' or CPAN.pm users.
The normal 'Mantra' would then apply:
        make
        make test
        make install

For those without 'make' or an equivalent like 'nmake' or 'dmake' there
are perl-only scripts which do the same things:
        Test with:    perl nomake_test
        Install with: perl nomake_install

Timeout tests can take up to 30 seconds per test.
COMMENTS

my $dfile = "nomake_test";
unlink $dfile;
print "Creating new $dfile\n";
open (DEFAULT, "> $dfile") or die "Can't create $dfile: $!\n";

print DEFAULT <<TEST4;
# Created by Makefile.PL
# VERSION $version

use Test::Harness;
runtests ("t/Test-Device-SerialPort.t", "t/test2.t", "t/test3.t");

# See README and other documentation for additional information.
TEST4

close DEFAULT;

$dfile = "nomake_install";
unlink $dfile;
print "Creating new $dfile\n";
open (DEFAULT, "> $dfile") or die "Can't create $dfile: $!\n";

print DEFAULT <<INST4;
# Created by Makefile.PL
# VERSION $version

use 5.006;

use Config;
use strict;
use warnings;
use ExtUtils::Install qw( install );

my \$FULLEXT = "Test/Device/SerialPort";
my \$INST_LIB = "./lib";
install({
	   read => "\$Config{sitearchexp}/auto/\$FULLEXT/.packlist",
	   write => "\$Config{installsitearch}/auto/\$FULLEXT/.packlist",
	   \$INST_LIB => "\$Config{installsitelib}",
	  },1,0,0);

__END__
INST4

close DEFAULT;

