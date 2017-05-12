#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use 5.010000;
use autodie;

&main; exit;

sub main {
    my @consts = read_consts();
    write_pm(@consts);
    write_h(@consts);
}

sub write_pm {
    my @consts = @_;

    open my $fh, '>', 'lib/Perl6/PVIP/_consts.pm';
    print $fh "package Perl6::PVIP::_consts;\n";
    print $fh "use warnings;\n";
    print $fh "use strict;\n";
    print $fh "\n";
    print $fh '@Perl6::PVIP::EXPORT = qw(' . "\n";
    for (@consts) {
        print $fh "    $_\n";
    }
    print $fh ");\n\n1;\n";
}

sub write_h {
    my @consts = @_;

    open my $fh, '>', 'lib/Perl6/const.h';
    print $fh "#define PConst(c) newCONSTSUB(stash, #c, newSViv(c))\n";
    print $fh "static void setup_pvip_const() {\n";
    print $fh qq!  HV* stash = gv_stashpvn("Perl6::PVIP", strlen("Perl6::PVIP"), TRUE);\n!;
    for (@consts) {
        print $fh "    PConst($_);\n";
    }
    print $fh "#undef PConst\n";
    print $fh "}\n";
}

sub read_consts {
    open my $fh, '<', 'pvip/src/pvip.h';
    my @ret;
    while (<$fh>) {
        if (/(PVIP_(NODE|CATEGORY)_\w+)/) {
            push @ret, $1;
        }
    }
    @ret;
}
