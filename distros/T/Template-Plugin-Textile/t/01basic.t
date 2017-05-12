#!/usr/bin/perl

use strict;
use Test::More tests => 3;
use Text::Textile qw(textile);
use Template;


test("this is _like_ *so* *cool*", "basic");

test(<<'ENDOFTEMPLATE', "bigger");
Reasons to use the Template Toolkit:

* Seperation of concerns.
* It's written in Perl.
* Badgers are Still Cool.
ENDOFTEMPLATE

test(<<'ENDOFTEMPLATE', "biggest");
The "Template Toolkit":http://www.tt2.org was written by Andy Wardly.
!http://www.perl.com/supersnail/os2002/images/small/os6_d5_5268_w2_sm.jpg!
This image (c) Julian Cash 2002
ENDOFTEMPLATE

sub test {
	my $source = shift;
	my $desc   = shift;

	# make errors come from the right place
	local $Test::Builder::Level = $Test::Builder::Level + 1;

	my $src = '[% USE Textile %][% FILTER textile %]'.$source.'[% END %]';
	my $output = "";
	my $tt = Template->new();
	unless ($tt->process(\$src, {}, \$output)) {
		$output = $tt->error;
	}

	is($output, textile($source), $desc);
}
