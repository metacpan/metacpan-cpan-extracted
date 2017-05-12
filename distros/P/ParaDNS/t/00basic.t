#!/usr/bin/perl -w

use Test::More tests => 5;

$|++;

use_ok('ParaDNS');

my $done = 0;

Danga::Socket->SetPostLoopCallback(
    sub {
        return 1 unless $done >= 4;
        return 0; # causes EventLoop to exit
    });

my $got_answer = 0;
ParaDNS->new(
    host     => 'google.com',
    callback => sub {
        print "Got answer google.com => $_[0]\n";
        return if $got_answer++;
        ok($_[0], "google.com => $_[0]");
        $done++;
        my $got_cached_answer = 0;
        ParaDNS->new(
            host => 'google.com',
            callback => sub {
                print "Got cached answer google.com => $_[0]\n";
                return if $got_cached_answer++;
                ok($_[0], "cached google.com => $_[0]");
                $done++;
            },
        );
    },
);

my $nx_got_answer = 0;
ParaDNS->new(
    host => 'nosuchhost.axkit.org',
    callback => sub {
        print "Got no answer: $_[0]\n";
        return if $nx_got_answer++;
        ok($_[0] eq "NXDOMAIN", "Got nosuchhost.axkit.org doesn't exist ($_[0])");
        $done++;
    },
);

my $got_cname = 0;
ParaDNS->new(
    host => 'mail.sergeant.org', # CNAME
    callback => sub {
        print "Got answer mail.sergeant.org => $_[0]\n";
        return if $got_cname++;
        ok($_[0] =~ /^\d+\.\d+\.\d+\.\d+$/, "translated mail.sergeant.org through a CNAME to an IP ($_[0])");
        $done++;
    },
);

Danga::Socket->EventLoop;

