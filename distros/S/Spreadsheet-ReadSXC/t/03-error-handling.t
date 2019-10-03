#!perl
use strict;
use Test::More tests => 10;
use File::Basename 'dirname';
use Spreadsheet::ReadSXC;

my $d = dirname($0);
my $sxc_file = "$d/t.sxc";

sub dies_ok {
    my( $code, $error_msg, $name ) = @_;
    $name ||= $error_msg;

    my $old_handler = Archive::Zip::setErrorHandler(sub {});

    my $died = eval {
        $code->();
        1
    };
    my $err = $@;
    is $died, undef, $name;
    like $err, $error_msg, $name;

    Archive::Zip::setErrorHandler($old_handler);
};

is Spreadsheet::ReadSXC::read_sxc('no-such-file.sxc'), undef, "Default silent API";

dies_ok sub { Spreadsheet::ReadSXC::read_sxc('no-such-file.sxc', { StrictErrors => 1 }) }, qr/Couldn't open 'no-such-file.sxc':/,"Non-existent file";
dies_ok sub { Spreadsheet::ReadSXC::read_sxc_fh(undef) }, qr//, "undef filehandle";

is Spreadsheet::ReadSXC::read_xml_file('no-such-file.xml'), undef, "Default silent API";
dies_ok sub { Spreadsheet::ReadSXC::read_xml_file('no-such-file.xml', { StrictErrors => 1 })}, qr/Couldn't open no-such-file.xml:/, "Non-existent XML file";

dies_ok sub { Spreadsheet::ReadSXC::read_xml_string('<invalid_xml>')}, qr/no element found at line 1/, "Invalid XML string";
