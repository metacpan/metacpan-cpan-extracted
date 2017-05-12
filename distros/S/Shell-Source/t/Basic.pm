#!/usr/local/bin/perl -w

# Copyright 2001, Paul Johnson (pjcj@cpan.org)

# This software is free.  It is licensed under the same terms as Perl itself.

# The latest version of this software should be available from my homepage:
# http://www.pjcj.net

# Version 0.01 - 2nd August 2001

use strict;

require 5.004;

package Basic;

use vars qw($VERSION);
$VERSION = "0.01";

use Config;
use Test;

use Shell::Source 0.01;

sub import
{
    my $class = shift;
    my ($shell, $script) = @_;

    my $available;
    for (split /$Config{path_sep}/, $ENV{PATH})
    {
        $available = 1, last if -x "$_/$shell";
    }

    unless ($available)
    {
        print "1..0 #Skipped: $shell unavailable\n";
        return;
    }

    $script = "t/$script" if -d "t";

    plan tests => 4;

    my $sh = Shell::Source->new(shell => $shell, file => $script);
    ok $sh;

    $sh->inherit;
    ok $ENV{qaz},   "qazaq";
    ok $sh->output, "qwerty\n";
    ok $sh->shell,  '/qaz="qazaq"/';
}
