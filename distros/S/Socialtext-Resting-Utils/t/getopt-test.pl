#!/usr/bin/perl
use strict;
use warnings;
use lib 'lib';
use Socialtext::Resting::Getopt qw/get_rester/;
use Getopt::Long;

my $rester = get_rester();
my $monkey = '';
GetOptions( 'monkey' => \$monkey );

print "Monkey=$monkey ARGV=@ARGV\n";
if ($rester) {
    for my $attr (qw(server username password workspace)) {
        my $val = $rester->$attr();
        next unless $val;
        print "$attr=$val\n";
    }
}
exit;
