#!/usr/bin/perl 
#
# development tool for examining ASTs

use lib qw(t lib);
use TPath::Grammar qw(parse);
use Data::Dumper;
use Perl::Tidy;

for my $expr (@ARGV) {
    my $parse = parse($expr);
    my $code  = Dumper $parse;
    my $ds;
    Perl::Tidy::perltidy(
        argv        => ['-l=0'],
        source      => \$code,
        destination => \$ds
    );
    print $ds;
}
