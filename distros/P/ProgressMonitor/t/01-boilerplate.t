#!perl

use strict;
use warnings;
use Test::More tests => 20;

sub not_in_file_ok {
    my ($filename, %regex) = @_;
    open my $fh, "<", $filename
        or die "couldn't open $filename for reading: $!";

    my %violated;

    while (my $line = <$fh>) {
        while (my ($desc, $regex) = each %regex) {
            if ($line =~ $regex) {
                push @{$violated{$desc}||=[]}, $.;
            }
        }
    }

    if (%violated) {
        fail("$filename contains boilerplate text");
        diag "$_ appears on lines @{$violated{$_}}" for keys %violated;
    } else {
        pass("$filename contains no boilerplate text");
    }
}

not_in_file_ok(README =>
    "The README is used..."       => qr/The README is used/,
    "'version information here'"  => qr/to provide version information/,
);

not_in_file_ok(Changes =>
    "placeholder date/time"       => qr(Date/time)
);

sub module_boilerplate_ok {
    my ($module) = @_;
    not_in_file_ok($module =>
        'the great new $MODULENAME'   => qr/ - The great new /,
        'boilerplate description'     => qr/Quick summary of what the module/,
        'stub function definition'    => qr/function[12]/,
    );
}

module_boilerplate_ok('lib/ProgressMonitor.pm');
module_boilerplate_ok('lib/ProgressMonitor/AbstractConfiguration.pm');
module_boilerplate_ok('lib/ProgressMonitor/AbstractStatefulMonitor.pm');
module_boilerplate_ok('lib/ProgressMonitor/Exceptions.pm');
module_boilerplate_ok('lib/ProgressMonitor/Null.pm');
module_boilerplate_ok('lib/ProgressMonitor/State.pm');
module_boilerplate_ok('lib/ProgressMonitor/Stringify/AbstractMonitor.pm');
module_boilerplate_ok('lib/ProgressMonitor/Stringify/Fields/AbstractDynamicField.pm');
module_boilerplate_ok('lib/ProgressMonitor/Stringify/Fields/AbstractField.pm');
module_boilerplate_ok('lib/ProgressMonitor/Stringify/Fields/Bar.pm');
module_boilerplate_ok('lib/ProgressMonitor/Stringify/Fields/Counter.pm');
module_boilerplate_ok('lib/ProgressMonitor/Stringify/Fields/ETA.pm');
module_boilerplate_ok('lib/ProgressMonitor/Stringify/Fields/Fixed.pm');
module_boilerplate_ok('lib/ProgressMonitor/Stringify/Fields/Percentage.pm');
module_boilerplate_ok('lib/ProgressMonitor/Stringify/Fields/Spinner.pm');
module_boilerplate_ok('lib/ProgressMonitor/Stringify/ToStream.pm');
module_boilerplate_ok('lib/ProgressMonitor/Stringify/ToCallback.pm');
module_boilerplate_ok('lib/ProgressMonitor/SubTask.pm');
