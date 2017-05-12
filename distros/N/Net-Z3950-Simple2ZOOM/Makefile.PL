# $Id: Makefile.PL,v 1.10 2009-06-08 15:31:35 mike Exp $

use 5.008;
use ExtUtils::MakeMaker;
use strict;

my $yazver = `yaz-config --version`;
if (!$yazver) {
    die qq[
ERROR: Unable to call script: yaz-config
If you are using a YAZ installation from the Debian package "yaz", you
will also need to install "libyaz-dev" in order to build this module.
];
}

chomp($yazver);
check_version($yazver, "3.0.10");

WriteMakefile(
    NAME          => 'Net::Z3950::Simple2ZOOM',
    VERSION_FROM  => 'lib/Net/Z3950/Simple2ZOOM.pm', # finds $VERSION
    PREREQ_PM     => {
	"Data::Dumper" => 2.121,
	"XML::Simple" => 2.14,
	"Net::Z3950::SimpleServer" => 1.08,
	"Net::Z3950::ZOOM" => 1.19,
	"LWP::UserAgent" => 2.033,
	"URI::Escape" => 3.28,
	"XML::LibXML" => 1.59,
	"MARC::Record" => 1.38,
	"MARC::File::XML" => 0.84, # Debian package libmarc-xml-perl
	"Time::HiRes" => 1.86,
    },
    ABSTRACT_FROM => 'lib/Net/Z3950/Simple2ZOOM.pm',
    AUTHOR        => 'Sebastian Hammer <quinn@indexdata.com> and colleagues',
    EXE_FILES    => [ 'bin/simple2zoom' ],
);


sub check_version {
    my($got, $want) = @_;

    my($gmajor, $gminor, $gtrivial) = ($got =~ /(\d+)\.(\d+)\.(\d+)/);
    my($wmajor, $wminor, $wtrivial) = ($want =~ /(\d+)\.(\d+)\.(\d+)/);
    if (($gmajor < $wmajor) ||
	($gmajor == $wmajor && $gminor < $wminor) ||
	($gmajor == $wmajor && $gminor == $wminor && $gtrivial < $wtrivial)) {
	print <<__EOT__;
*** ERROR!
Simple2ZOOM requires at least version $want of YAZ,
but you only have version $got.
__EOT__
	exit 1;
    }
}
