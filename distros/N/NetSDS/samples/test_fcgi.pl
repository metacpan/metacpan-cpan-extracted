#!/usr/bin/env perl 

use Data::Dumper;

MyApp->run;

print Dumper($c);

1;

package MyApp;

use Data::Dumper;

use base 'NetSDS::App::FCGI';

sub process {

	my ($this) = @_;

	#$this->redirect("/here");
	$this->set_cookie(name => "name1", value => '123123');
	$this->set_cookie(name => "here", value => 'ggggg', expires => "+1h");

	$this->mime('text/xml');
	$this->charset('koi8-u');
	$this->data('<html>Here is some HTML ;-)</html>');

	print Dumper($this->get_cookie('val'));
}

1;

