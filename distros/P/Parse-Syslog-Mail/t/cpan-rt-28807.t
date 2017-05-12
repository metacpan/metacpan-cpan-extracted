#!/usr/bin/perl -w
use strict;
use File::Spec::Functions;
use Test::More;
use Parse::Syslog::Mail;


my @expected = (
    {
        delay   => 0,
        host    => 'DalekGate',
        id      => '84179E35',
        program => 'postfix/smtp',
        relay   => 'none',
        status  => 'bounced (Host or domain name not found. Name service error for name=gmail.coml type=A: Host not found)',
        text    => '84179E35: to=<secdalek@gmail.coml>, relay=none, delay=0, status=bounced (Host or domain name not found. Name service error for name=gmail.coml type=A: Host not found)',
        to  => '<secdalek@gmail.coml>',
    },
    {
        from    => '<bcfxhdfyrey4l@easterndalek.com>',
        to      => '<service@exterminate.com>',
        helo    => '<realmail.iiiiiii.com>: Message content rejected',
        host    => 'DalekGate',
        id      => '8B7EF2BB7',
        program => 'postfix/cleanup',
        proto   => 'ESMTP',
        status  => 'reject: header Date: Mon, 18 Jan 2038 19:07:11 +0800 from unknown[192.168.7.245]',
        text    => '8B7EF2BB7: reject: header Date: Mon, 18 Jan 2038 19:07:11 +0800 from unknown[192.168.7.245]; from=<bcfxhdfyrey4l@easterndalek.com> to=<service@exterminate.com> proto=ESMTP helo=<realmail.iiiiiii.com>: Message content rejected',
    }, 
);

plan tests => scalar @expected;

my $logfile = catfile("t", "cpan-rt-28807.log");
my $maillog = Parse::Syslog::Mail->new($logfile, year => 2007);

while (my $log = $maillog->next) {
    my $expected = shift @expected;
    delete $log->{timestamp};
    is_deeply($log, $expected, "[CPAN-RT 28807] checking parsed log against expected structures");
}

