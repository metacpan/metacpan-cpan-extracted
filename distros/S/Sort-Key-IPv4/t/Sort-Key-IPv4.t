# -*- Mode: Perl -*-

use Test::More tests => 2;

use Socket;
use Sort::Key::IPv4 qw(ipv4sort ripv4sort);

my $n = 10000;

my @address = map { join ('.', map {int rand 256 } 0..3) } 0..$n;

my @sorted = ipv4sort @address;
my @good = map inet_ntoa($_), sort map inet_aton($_), @address;

is ("@sorted", "@good");

@sorted = ripv4sort @address;
@good = map inet_ntoa($_), sort { $b cmp $a } map inet_aton($_), @address;

is ("@sorted", "@good");
