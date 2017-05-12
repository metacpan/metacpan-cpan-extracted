#!/usr/bin/env perl 

MyApp->run(
	daemon => 0,
	conf_file => './app_feature.conf',
	auto_features => 1,
);

1;

package MyApp;

use 5.8.0;
use warnings;
use strict;

use Data::Dumper;

use base 'NetSDS::App';

sub process {
	my ($this) = @_;

	print Dumper($this);

	$this->dbh->log("info", "feature logging");

}

1;
