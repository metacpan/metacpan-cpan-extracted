#! perl

use 5.005;
use strict;
use ExtUtils::MakeMaker;
use Config;

my $usrbin = "/usr/bin";
my $installscript = $Config{installscript};

print STDERR <<EOD unless $installscript eq $usrbin;

WARNING: This Makefile will install user accessible scripts.
The location for these scripts is $installscript.
You may consider to pass INSTALLSCRIPT=$usrbin (or some other
convenient location) to "make install".

EOD

my @scripts = qw(csv2lsdb);

my $x =
WriteMakefile(
    'NAME'		=> 'Palm::ListDB::Writer',
    'VERSION_FROM'	=> 'lib/Palm/ListDB/Writer.pm',
    'PREREQ_PM'		=> {
			     'Getopt::Long' => 2.33,
			   },
     EXE_FILES		=> [ map { "script/$_" } @scripts ],
     ABSTRACT_FROM	=> 'lib/Palm/ListDB/Writer.pm',
     AUTHOR		=> 'Johan Vromans <jv@cpan.org>',
);

my $name    = $x->{NAME};
my $version = $x->{VERSION};

my $fh;
if ( open ($fh, "$name.spec.in") ) {
    print "Writing RPM spec file for $name\n";
    my $newfh;
    open ($newfh, ">perl-$name.spec");
    while ( <$fh> ) {
	s/%define modname \w+/%define modname $name/;
	s/%define modversion \d+\.\d+/%define modversion $version/;
	print $newfh $_;
    }
    close($newfh);
}




