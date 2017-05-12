#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 5657;
use Plucene::Store::InputStream;
use Plucene::Store::OutputStream;
use_ok("Plucene::Bitvector");
use File::Temp qw(tmpnam);

my $vector = tmpnam();

test_count(8);
test_count(20);
test_count(100);
test_count(1000);

sub test_count {
	my $size = shift;
	my $bv = new Plucene::Bitvector(size => $size);
	for (0 .. $bv->{size}) {
		ok(!$bv->get($_), "Not set prior to work");
		is($bv->count, $_, "Precisely $_ bits set");
		$bv->set($_);
		ok($bv->get($_), "Now it's set");
		is($bv->count, $_ + 1, "And count is updated");
	}
}

test_write_read(8);
test_write_read(20);
test_write_read(100);
test_write_read(1000);

sub test_write_read {
	my $bv = new Plucene::Bitvector(size => shift);
	for (0 .. $bv->{size} - 1) {
		$bv->set($_);
		$bv->write(Plucene::Store::OutputStream->new($vector));
		my $compare =
			Plucene::Bitvector->read(Plucene::Store::InputStream->new($vector));
		is_deeply($bv->display, $compare->display,
			"Compared vectors were equivalent: $_");
	}

}
