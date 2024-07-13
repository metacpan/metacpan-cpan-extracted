#!perl
use strict;
use warnings;

use File::Temp qw{ tempfile };
use Perl::PrereqScanner;
use PPI::Document;
use Try::Tiny;

use Test::More;

sub prereq_is {
	my ($str, $want, $comment) = @_;
	$comment ||= $str;

	my $scanner = Perl::PrereqScanner->new({ extra_scanners => ['DistBuild'] });

	try {
		my $result = $scanner->scan_ppi_document( PPI::Document->new(\$str) );
		is_deeply($result->as_string_hash, $want, $comment);
	} catch {
		fail("scanner died on: $comment");
		diag($_);
	};

	try {
		my $result = $scanner->scan_string( $str );
		is_deeply($result->as_string_hash, $want, $comment);
	} catch {
		fail("scanner died on: $comment");
		diag($_);
	};

	try {
		my ($fh, $filename) = tempfile( UNLINK => 1 );
		print $fh $str;
		close $fh;
		my $result = $scanner->scan_file( $filename );
		is_deeply($result->as_string_hash, $want, $comment);
	} catch {
		fail("scanner died on: $comment");
		diag($_);
	};
}

prereq_is('', { }, '(empty string)');
prereq_is('load_module("Use::NoVersion")', { 'Use::NoVersion' => 0 });
prereq_is('load_module "Use::NoVersion" ', { 'Use::NoVersion' => 0 });
prereq_is('load_module(\'Use::NoVersion\')', { 'Use::NoVersion' => 0 });

prereq_is('load_module("Use::NoVersion", "1.23")', { 'Use::NoVersion' => '1.23' });
prereq_is('load_module("Use::NoVersion", 1.23)', { 'Use::NoVersion' => '1.23' });
prereq_is('load_module "Use::NoVersion", 1.23', { 'Use::NoVersion' => '1.23' });

done_testing;
