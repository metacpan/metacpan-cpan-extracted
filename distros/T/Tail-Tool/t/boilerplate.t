#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;

sub not_in_file_ok {
    my ($filename, %regex) = @_;
    open( my $fh, '<', $filename )
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

sub module_boilerplate_ok {
    my ($module) = @_;
    not_in_file_ok($module =>
        'the great new $MODULENAME'   => qr/ - The great new /,
        'boilerplate description'     => qr/Quick summary of what the module/,
        'stub function definition'    => qr/function[12]/,
    );
}

not_in_file_ok((-f 'README' ? 'README' : 'README.pod') =>
    "The README is used..."       => qr/The README is used/,
    "'version information here'"  => qr/to provide version information/,
);

not_in_file_ok(Changes =>
    "placeholder date/time"       => qr(Date/time)
);

module_boilerplate_ok('bin/tailt');
module_boilerplate_ok('lib/Tail/Tool.pm');
module_boilerplate_ok('lib/Tail/Tool/Config.pod');
module_boilerplate_ok('lib/Tail/Tool/File.pm');
module_boilerplate_ok('lib/Tail/Tool/Plugin/GroupLines.pm');
module_boilerplate_ok('lib/Tail/Tool/Plugin/Highlight.pm');
module_boilerplate_ok('lib/Tail/Tool/Plugin/Ignore.pm');
module_boilerplate_ok('lib/Tail/Tool/Plugin/Match.pm');
module_boilerplate_ok('lib/Tail/Tool/Plugin/Replace.pm');
module_boilerplate_ok('lib/Tail/Tool/Plugin/Spacing.pm');
module_boilerplate_ok('lib/Tail/Tool/PostProcess.pm');
module_boilerplate_ok('lib/Tail/Tool/PreProcess.pm');
module_boilerplate_ok('lib/Tail/Tool/Regex.pm');
module_boilerplate_ok('lib/Tail/Tool/RegexList.pm');
done_testing();
