#!/usr/bin/env perl 

use lib '/home/misha/git/NetSDS/perl-NetSDS/NetSDS/lib';

MyApp->run;

1;

package MyApp;

use base 'NetSDS::App::JSRPC';

sub sum {

	my ($this, $params) = @_;

	return $$params[0] + $$params[1];
}

1;

