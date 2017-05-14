#!/usr/bin/perl

use ExtUtils::MakeMaker;

$usage = <<USAGE
Usage: ./Makefile.PL [-rsaref] [OpenSSL installation path]
           -rsaref    links against rsaref
eg.:   ./Makefile.PL /usr/local/openssl

USAGE
    ;
die $usage if grep /^--?[hv?]/i, @ARGV;

$rsaref  = shift if $ARGV[0] eq '-rsaref';

if (@ARGV) {
    $openssl_path = shift;
} else {
    $openssl_path = '/usr' if -x '/usr/bin/openssl' || -x '/usr/sbin/openssl';
    $openssl_path = '/opt/ssl' if -x '/opt/ssl/bin/openssl' || -x '/opt/ssl/sbin/openssl';
    $openssl_path = '/usr/local/ssl' if -x '/usr/local/ssl/bin/openssl';
}

$libs = $rsaref ? "-lssl -lcrypto -lRSAglue -lrsaref" : "-lssl -lcrypto";

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $platform = `uname -sm`;
chomp($platform);
$platform =~ s/ /-/g;

WriteMakefile(
    'NAME'		=> 'Net::TCLink',
    'VERSION_FROM'	=> 'TCLink.pm', 
    'PREREQ_PM'		=> {}, 
    'DEFINE'		=> '-DPERL5 -DTCLINK_VERSION=\"3.4-Perl-' . $platform . '\"', 
    'LIBS'	=> ["-L$openssl_path -L$openssl_path/lib $libs"],
    'INC' 	=> "-I$openssl_path/include"
);

