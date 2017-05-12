#!/usr/bin/perl
# this is a utility script I use where I just copy API docs from my browser
# and this will edit it into mostly useful XS (still requires editing,
# but it's faster than doing it manually)
# I usually do this after init-class.pl, then
# ./genscripts/strip-api-docs.pl $CLASSNAME >> xs/$CLASSNAME.xs
# [paste API text]
# ^d

use strict;
use warnings;

main();
exit();

sub main {
    die "usage: $0 classname < [text]\n" unless @ARGV;
    my $class = shift @ARGV;

    while (<>) {
        # lines that begin with whitespace are documentation,
        # I turn them into blank lines
        $_ = $/ if /^\s/;

        # skip methods beginning with underscore
        $_ = $/ if / \t_/;

        s/\(void\)/()/;

        s/ \(/(/;

        s/\) const/)/;

        s/=0$//;

        s/virtual //;

        s/ushort/unsigned short/g;

        s/const String &/String /g;

        # space followed by tab always separates
        # the return value from the method name;
        # I put the method on the next line with classname prepended
        s/ {1,2}\t/\n${class}::/;


        print;
    }
}
