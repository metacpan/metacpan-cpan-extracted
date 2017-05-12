#!perl -w

use strict;
use Test::Simple tests => 8;

use Net::Marathon;

my $marathon = Net::Marathon->new;

ok(defined $marathon);
ok($marathon->isa('Net::Marathon'));
ok(defined $marathon->{_ua});
ok($marathon->{_ua}->isa('LWP::UserAgent'));

# it should take a parameter with a default

ok(defined $marathon->{_url});
ok($marathon->{_url} eq 'http://localhost:8080/');

my $test_ip = 'http://169.254.47.11:8080/';
$marathon = undef;
$marathon = Net::Marathon->new( url => $test_ip );

ok($marathon->{_url} eq $test_ip);

# it should take sloppy urls and fix them

my $sloppy_test_ip = '169.254.11.47:8080';
$marathon = undef;
$marathon = Net::Marathon->new( url => $sloppy_test_ip );

ok($marathon->{_url} eq 'http://' . $sloppy_test_ip . '/');
