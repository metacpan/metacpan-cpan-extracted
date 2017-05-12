#!perl

use 5.010;
use strict;
use warnings;

use Capture::Tiny qw(capture);
use Progress::Any;
use Progress::Any::Output;
use Test::More 0.98;

subtest default => sub {
    Progress::Any::Output->set('TermSpin');
    my $progress = Progress::Any->get_indicator(target=>10);
    my ($out, $err, $exit) = capture {
        $progress->update(message => "foo");
    };
    like($out, qr{\|});
};

subtest "fh option" => sub {
    Progress::Any::Output->set('TermSpin', fh=>\*STDERR);
    my $progress = Progress::Any->get_indicator(target=>10);
    my ($out, $err, $exit) = capture {
        $progress->update(message => "foo");
    };
    like($err, qr{\|});
};

# XXX test speed option
# XXX test style option
# XXX test show_delay option

DONE_TESTING:
done_testing;
