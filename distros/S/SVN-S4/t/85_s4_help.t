#!/usr/bin/perl -w
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2002-2017 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

use strict;
use Test::More;
use Cwd;

BEGIN { plan tests => 6 }
BEGIN { require "./t/test_utils.pl"; }

{
    my $cmd = "${PERL} s4 help";
    my $help = `$cmd`;
    like ($help, qr/s4 unique commands/i, 'help');
}
{
    my $cmd = "${PERL} s4 help add";  # Modified cmd
    my $help = `$cmd`;
    like ($help, qr/--no-fixprop/, 'help add');
}
{
    my $cmd = "${PERL} s4 help fixprop";  # New cmd
    my $help = `$cmd`;
    like ($help, qr/fixprop/, 'help fixprop');
}
{
    my $cmd = "${PERL} s4 help rm";
    my $help = `$cmd`;
    like ($help, qr/delete.*remove files/i, 'help rm');
}
{
    my $cmd = "${PERL} s4 help ci";  # check alias expansion
    my $help = `$cmd`;
    like ($help, qr/--unsafe/i, 'help ci');
}
{
    my $cmd = "${PERL} s4 --orig help fixprop 2>&1";  # New command, with --orig mode
    my $help = `$cmd`;
    like ($help, qr/unknown command/i, 'help --orig');
}
