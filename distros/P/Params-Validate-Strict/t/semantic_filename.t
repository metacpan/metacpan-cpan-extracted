#!/usr/bin/env perl

# semantic => 'filename': a single path component (no directory part).

use strict;
use warnings;
use Test::Most;

use Params::Validate::Strict qw(validate_strict);

my $schema = { f => { type => 'string', semantic => 'filename' } };

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

foreach my $ok ('report.txt', '.hidden', 'a', 'my file (1).tar.gz', '..foo', 'foo..', 'caf' . "\x{e9}" . '.txt', 'a' x 255) {
	lives_ok { validate_strict(schema => $schema, input => { f => $ok }) }
		'accepts ' . (length($ok) > 40 ? 'a 255-byte name' : "'$ok'");
}

foreach my $case (
	['empty string',       '',                     qr/Invalid filename/],
	['dot',                '.',                    qr/Invalid filename/],
	['dot-dot',            '..',                   qr/Invalid filename/],
	['relative path',      'dir/file.txt',         qr/Invalid filename/],
	['absolute path',      '/etc/passwd',          qr/Invalid filename/],
	['path traversal',     '../../etc/passwd',     qr/Invalid filename/],
	['trailing slash',     'dir/',                 qr/Invalid filename/],
	['embedded NUL',       "foo\0.txt",            qr/Invalid filename/],
	['256 bytes',          'a' x 256,              qr/Invalid filename/],
	['multibyte over 255 bytes', "\x{e9}" x 128,   qr/Invalid filename/],	# 256 bytes in UTF-8
) {
	my ($name, $value, $re) = @{$case};
	throws_ok { validate_strict(schema => $schema, input => { f => $value }) } $re,
		"rejects $name";
}

is(scalar(@warnings), 0, 'filename is a supported semantic: no "not yet supported" warning');

lives_ok { validate_strict(schema => { f => { type => 'string', optional => 1, semantic => 'filename' } }, input => {}) }
	'absent optional parameter is skipped';
lives_ok { validate_strict(schema => { f => { type => 'string', optional => 1, semantic => 'filename' } }, input => { f => undef }) }
	'undef optional parameter is skipped';

done_testing();
