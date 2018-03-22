#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Capture::Tiny qw(capture);
use Progress::Any;
use Progress::Any::Output;

subtest default => sub {
    local $ENV{PROGRESS} = 1;
    Progress::Any::Output->set('TermProgressBarColor');
    my $progress = Progress::Any->get_indicator(task=>'', target=>10);
    my ($out, $err, $exit) = capture {
        $progress->update(message => "foo");
    };
    like($err, qr/foo/);
    like($err, qr/10%/);
};

subtest "fh option" => sub {
    local $ENV{PROGRESS} = 1;
    Progress::Any::Output->set('TermProgressBarColor', fh=>\*STDOUT);
    my $progress = Progress::Any->get_indicator(task=>'', target=>10);
    my ($out, $err, $exit) = capture {
        $progress->update(message => "foo");
    };
    like($out, qr/foo/);
    like($out, qr/20%/);
};

subtest "default (wide)" => sub {
    local $ENV{PROGRESS} = 1;
    plan skip_all => 'Text::ANSI::WideUtil not available'
        unless eval { require Text::ANSI::WideUtil; 1 };

    Progress::Any::Output->set('TermProgressBarColor', wide=>1);
    my $progress = Progress::Any->get_indicator(task=>'', target=>10);
    my ($out, $err, $exit) = capture {
        $progress->update(message => "foo");
    };
    like($err, qr/foo/);
    like($err, qr/30%/);
};

done_testing;
