#!perl -w
use strict;
use PPerl qw(send_fd recv_fd s_pipe);

$| = 1;

s_pipe(my ($in, $out));

if (my $kid = fork()) { #papa
    open FOO, '<t/stevens.plx';
    send_fd($in, fileno FOO);
    waitpid $kid, 0;
}
else { # nicole
    my $fd = recv_fd($out);
    open BAR, "<&=$fd";
    while (<BAR>) {
        print "child: $_";
    }
}
