# $Id: Makefile.PL 85 2016-05-18 10:34:46Z phil $

use strict;
use warnings;

use ExtUtils::MakeMaker;
use Pod::Text;
 
my $parser = new Pod::Text(sentence => 0, width => 78);
$parser->parse_from_file('lib/StartCom/API.pm', 'README');

require 'lib/StartCom/API.pm';
open SPECT, "<startapi.spec.tpl";
open SPEC, ">startapi.spec";
while (<SPECT>) {
	s/#VERSION#/$StartCom::API::VERSION/g;
	print SPEC $_
}
close SPECT;
close SPEC;

eval 'use ExtUtils::MakeMaker::Coverage';

WriteMakefile(
	'NAME' => 'StartCom::API',
	'AUTHOR' => 'Philippe Kueck <projects@unixadm.org>',
	'LICENSE' => 'LGPL',
	'VERSION_FROM' => 'lib/StartCom/API.pm',
	'ABSTRACT' => 'startapi connector',
	'PM' => {
		'lib/StartCom/API.pm' => '$(INST_LIB)/StartCom/API.pm'
	},
	'PREREQ_PM' => {
		'LWP::UserAgent' => 0,
		'MIME::Base64' => 0,
		'JSON' => 0,
		'IO::Socket::SSL' => 0
	},
	'dist' => {'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz'},
	'clean' => {'FILES' => 'bogus'}
);
