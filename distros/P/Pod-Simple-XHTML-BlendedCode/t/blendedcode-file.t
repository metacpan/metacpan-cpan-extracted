#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 1;
use Test::LongString;
use IO::CaptureOutput qw(capture);
use File::Spec::Functions qw(catfile);
use Pod::Simple::XHTML::BlendedCode 1.000 qw();
use File::Slurp 9999.13 qw(read_file write_file);

my $parser = Pod::Simple::XHTML::BlendedCode->new();
$parser->internal_modules_hash({
	'Pod::Simple::XHTML::BlendedCode(.*)?' => 'Pod-Simple-XHTML-BlendedCode/',
});
$parser->internal_url_postfix('.pm.html');
$parser->internal_url_prefix('http://csjewell.comyr.com/perl/');
$parser->internal_url_divide_slashes(1);

my $output_test;
capture { $parser->parse_file(catfile(qw(lib Pod Simple XHTML BlendedCode.pm))) } \$output_test;

# When the module changes, uncomment this line, run the test once, then recomment it again.
# write_file(catfile(qw(t data test_data.html)), $output_test);

my $expected_output = read_file(catfile(qw(t data test_data.html)));
$expected_output =~ s(\x{0d}\x{0a})(\x{0a})g; # Deal with Windows line endings on my machine.
is_string($output_test, $expected_output, 'parse_file works');
