#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 47;
use FindBin qw($Bin);

use lib "$Bin/../lib";

use SMB::File;

unlink("$Bin/../shares/test/test.tmp");

my $file = SMB::File->new(share_root => "$Bin/../shares/test", name => "test.tmp");
isa_ok($file, 'SMB::File');
ok(!$file->exists, "File does not exist");
like($file->filename, qr{/test\.tmp$}, "full filename includes name");
unlike($file->filename, qw{/\.\./}, "full filename is normalized");

sub test_open_method ($$) {
	my $method = shift;
	my $expected_action = shift;

	no strict 'refs';

	my $openfile = $method =~ /^DISPOSITION_/
		? $file->open_by_disposition(*{"SMB::File::$method"}->())
		: $file->$method();

	$expected_action
		? ok( $openfile, "$method success")
		: ok(!$openfile, "$method failure");

	unless ($openfile) {
		fail("skip after unexpected $method failure") if $expected_action;
	} elsif (!$expected_action) {
		diag("INFO: got unexpected $openfile instead of undef");
	} elsif (UNIVERSAL::isa($openfile, 'SMB::OpenFile')) {
		is($openfile->action, *{"SMB::File::$expected_action"}->(), "$method $expected_action");
		$openfile->close;
	} else {
		fail("got unexpected $openfile instead of SMB::OpenFile with $expected_action");
	}
}

test_open_method('create',       'ACTION_CREATED');
test_open_method('open',         'ACTION_OPENED');
test_open_method('open',         'ACTION_OPENED');

is(unlink($file->filename), 1, "unlink file");

test_open_method('open',         undef);
test_open_method('open_if',      'ACTION_CREATED');
test_open_method('open_if',      'ACTION_OPENED');
test_open_method('overwrite',    'ACTION_OVERWRITTEN');
test_open_method('overwrite_if', 'ACTION_OVERWRITTEN');

is(unlink($file->filename), 1, "unlink file");

test_open_method('overwrite_if', 'ACTION_CREATED');
test_open_method('supersede',    'ACTION_SUPERSEDED');
test_open_method('create',       undef);
test_open_method('open',         'ACTION_OPENED');

is(unlink($file->filename), 1, "unlink file");

test_open_method('overwrite',    undef);
test_open_method('supersede',    'ACTION_CREATED');
test_open_method('open_if',      'ACTION_OPENED');

is(unlink($file->filename), 1, "unlink file");

test_open_method('DISPOSITION_OPEN',         undef);
test_open_method('DISPOSITION_CREATE',       'ACTION_CREATED');
test_open_method('DISPOSITION_SUPERSEDE',    'ACTION_SUPERSEDED');
test_open_method('DISPOSITION_OVERWRITE',    'ACTION_OVERWRITTEN');
test_open_method('DISPOSITION_OPEN_IF',      'ACTION_OPENED');
test_open_method('DISPOSITION_OVERWRITE_IF', 'ACTION_OVERWRITTEN');

is(unlink($file->filename), 1, "unlink file");
