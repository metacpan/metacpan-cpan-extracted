#!/usr/bin/perl
use strict;
use warnings;
use Test::More 'no_plan';
use lib qw (lib ../lib);
use Petal::Mail;

$Petal::Mail::Sendmail = 'perl fake_sendmail.pl';
my $formatter = new Petal::Mail (
    base_dir  => [ './t/data', './data' ],
    file      => 'en.xml'
);

if ($ENV{SERVER_ADMIN})
{
    ok (1)
}
else
{
    eval { $formatter->send() };
    like ($@, qr/^No authorized sender/);

    $formatter->send (AUTH_SENDER => 'william@knowmad.com');

    $ENV{SERVER_ADMIN} = 'william@knowmad.com';
    $formatter->send();
    ok (not $@);
}


1;


__END__
