#!/usr/bin/env perl

use lib 'lib';
use Pod::Definitions;

use strict;
use warnings;

use Test::More;

{
    my $p = new_ok ( 'Pod::Definitions' ); # Pod::Definitions->new();

    my $source_pod = 'lib/Pod/Headings.pm';
    my $x = $p->parse_file($source_pod);

    ok (defined $x, 'Parse our own POD file');

    ok ($x->source_dead(), 'Read to end of input POD file');
    is ($p->file(), $source_pod, 'Parsed correct file');
    is ($p->manpage(), 'Pod::Headings', 'Found proper POD Name');
    is ($p->module(), 'Headings', 'Found correct POD module name from format');
}

{
    my $p = new_ok ( 'Pod::Definitions' ); # Pod::Definitions->new();

    my $source_pod = 'lib/Pod/Definitions.pm';
    my $x = $p->parse_file($source_pod);

    ok (defined $x, 'Parse our own POD file');

    ok ($x->source_dead(), 'Read to end of input POD file');
    is ($p->file(), $source_pod, 'Parsed correct file');
    is ($p->manpage(), 'Pod::Definitions', 'Found proper POD Name');
    is ($p->module(), 'Definitions', 'Found correct POD module name from format');

    ok (scalar keys %{$p->sections()}, 'POD has sections');
    ok (scalar @{$p->sections->{Methods}} > 5, 'POD has six or more sections');

    ok (ref $p->sections('Methods') eq 'ARRAY', '"Methods" section exists');
    ok ($p->sections('Methods')->[0]->{sequence} >= 0, 'Headings have sequence numbers');
    ok ($p->sections('Methods')->[0]->{sequence} < $p->sections('Methods')->[1]->{sequence}, 'Heading sequence numbers are incremented');

    my $found_parse = 0;
    foreach my $section ( @{$p->sections->{Methods}} ) {
        $found_parse = 1 if ($section->{cooked} eq 'parse_file');
    }
    ok ($found_parse, 'Found the parse_file method documentation in the podfile');
}

done_testing();

1;
