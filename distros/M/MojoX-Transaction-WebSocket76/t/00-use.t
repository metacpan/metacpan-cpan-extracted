#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use CPAN::Version ();
use Mojolicious ();


my $mv = Mojolicious->VERSION;

if (CPAN::Version->vge($mv, '6.40')) {
	diag("\n\nWARNING!!!\n\nMojolicious $mv found. Mojolicious 6.40 and above not supported. Skip all tests.\n\n");
	plan(skip_all => 'Unsupported version of Mojolicious');
}
elsif (CPAN::Version->vge($mv, '5.00')) {
	diag("\n\nNOTICE!\n\nMojolicious $mv found. This code tested with Mojolicious 4.xx and below and might not works with higher versions.\n\n");
	plan(tests => 1);
}
else {
	plan(tests => 1);
}

use_ok('MojoX::Transaction::WebSocket76') or print("Bail out!\n");
diag("Testing MojoX::Transaction::WebSocket76 $MojoX::Transaction::WebSocket76::VERSION, Perl $], $^X");
