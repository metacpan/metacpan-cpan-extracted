use strict;
use warnings;

use Test;
use IPC::Run 'run';

plan tests => 2;

my @cmd = ($^X => qw(t/hi -t 80 test1 bold-blue));

my $in = "test: " . ("test1 test2" x 25) . "\n";
run \@cmd, \$in, \&check_ok, sub { die "@_" };

sub check_ok {
    my $stuff = shift;

    ok( length($stuff), 81 );
    ok( $stuff, qr/\e\[1(?:m\e\[|;)34mtest1\e\[0?m/ );
}
