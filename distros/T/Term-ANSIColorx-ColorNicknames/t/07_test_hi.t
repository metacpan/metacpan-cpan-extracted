use strict;
use warnings;

use Test;
use IPC::Run 'run';

plan tests => 2;

my @cmd = ($^X => qw(t/hi test1 sky test2 blood));

my $in = "test: test1 test2\n";
run \@cmd, \$in, \&check_ok, sub { die "@_" };

sub check_ok {
    my $stuff = shift;
    my $escaped_stuff = $stuff;
       $escaped_stuff =~ s/\e/\\e/g;
       $escaped_stuff =~ s/([^[:print:]])/sprintf('\x%02x', ord("$1"))/eg;

    ok( $stuff, qr/\e\[1;34mtest1\e\[0?m/, "\$stuff=$escaped_stuff" );
    ok( $stuff, qr/\e\[31mtest2\e\[0?m/,   "\$stuff=$escaped_stuff" );
}
