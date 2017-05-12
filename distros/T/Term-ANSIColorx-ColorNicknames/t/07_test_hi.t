use strict;
use warnings;

use Test;
use IPC::Run 'run';

plan tests => 2;

my @cmd = ($^X, -CA => qw(bin/hi test1 sky test2 blood));

my $in = "test: test1 test2\n";
run \@cmd, \$in, \&check_ok, sub { die "@_" };

sub check_ok {
    my $stuff = shift;

    ok( $stuff, qr/\e\[1;34mtest1\e\[0?m/ );
    ok( $stuff, qr/\e\[31mtest2\e\[0?m/ );
}
