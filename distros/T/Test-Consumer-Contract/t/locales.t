#!/usr/bin/env perl

# The operating system's words in the messages, under different locales.  The
# module puts the OS error for a path it cannot use into what it reports, and
# the expected text is taken from Perl's own $! - never from POSIX::strerror(),
# whose C library can word an errno differently from the string Perl hands the
# module - so the comparison is between two things Perl produced.
#
# This module has no country- or address-based behaviour (it reads source
# files), so there is nothing GeoIP-shaped to test here.

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Errno qw(EINVAL ENOENT ENOTDIR);
use File::Spec;
use File::Temp qw(tempdir);
use POSIX qw(setlocale LC_ALL);
use Test::Most;
use Test::Consumer::Contract;

my %MINIMAL = (source => 'S', guaranteed => [], methods => []);

# English, German and an East Asian language.  A locale that is not installed
# leaves the C locale in force, which is still a locale the module must work
# in, so the subtest runs either way and says which it got.
my @LOCALES = qw(en_US.UTF-8 de_DE.UTF-8 ja_JP.UTF-8);

my $dir = tempdir(CLEANUP => 1);
my $missing = File::Spec->catdir($dir, 'No-Such-Distribution');
my $file = File::Spec->catfile($dir, 'plain-file');
open(my $fh, '>', $file) or die "Cannot write $file: $!";
close($fh) or die "Cannot close $file: $!";

my $saved = setlocale(LC_ALL);

foreach my $locale (@LOCALES) {
	subtest "the OS error is reported as Perl renders it, under $locale" => sub {
		local $ENV{LC_ALL} = $locale;
		my $in_force = setlocale(LC_ALL, '') // 'C';
		note("LC_ALL=$locale gives the locale '$in_force'");

		my $enoent = do { local $! = ENOENT; "$!" };
		# Opening a plain file as a directory is ENOTDIR on POSIX systems but
		# EINVAL on Windows.  The module reports whichever the OS gave, so
		# either text is right; both are still taken from Perl's own $!.
		my $not_a_dir = join('|', map { local $! = $_; quotemeta("$!") } (ENOTDIR, EINVAL));

		throws_ok { Test::Consumer::Contract->new(%MINIMAL, dist_root => $missing) }
			qr/dist_root '\Q$missing\E' is not a directory: \Q$enoent\E/, 'a root that is not there';
		throws_ok { Test::Consumer::Contract->new(%MINIMAL, workspace => $file) }
			qr/workspace '\Q$file\E' is not a directory: (?:$not_a_dir)/, 'a root that is a file';

		# The same words reach a check's diagnostic, through the reader the
		# checks share.  White-box: the reader is private.
		local $Sub::Private::BYPASS = 1;
		my $read = Test::Consumer::Contract->new(%MINIMAL)->_read_source($missing);
		is($read->{'error'}, $enoent, 'an unreadable file') or diag(explain($read));
	};
}

setlocale(LC_ALL, $saved);

done_testing();
