#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok 'Template::Declare::Anon';
use Template::Declare::Tags 'HTML';

my $sub_template = anon_template {
	row {
		cell { "Hello, world!" }
	}
};

my $template = anon_template {
	link {}
	table { &$sub_template }
	img { attr { src => 'cat.gif' } }
};

like( process($template), qr{link.*table.*tr.*td.*Hello, world!.*/td.*/tr.*/table.*img.*cat.gif}si, "process template and sub template" );
like( "$sub_template", qr{tr.*td.*Hello, world!.*/td.*/tr}si, "stringification" );

