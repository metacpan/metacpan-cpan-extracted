#!/usr/bin/perl -w

use Test::More tests => 4;
use Compress::Zlib;
use LWP::Simple;

BEGIN {
        chdir 't' if -d 't';
        use lib '../blib/lib', 'lib/', '..';
}


my $mod = "Parse::DebControl";

#Object initialization - 2 tests

	use_ok($mod);
	ok($pdc = new Parse::DebControl(), "Parser object creation works fine");

#parse_web - 2 tests
#Even though testing with the web can be uncertain, we can be sure of two things
# - Debian is around
# - Debian has more than 1k packages


        SKIP: {
		skip "Skipping time-consuming web tests", 2 unless($ENV{alltests});

		my $url = "http://ftp.debian.org/dists/sid/main/binary-i386/Packages.gz";
		my $content = get($url);

                skip "Web test at debian not available", 2 unless($content);

		ok(my $data = $pdc->parse_web($url, {"tryGzip" => 1}), "parse_web is sane");
		ok(int(@$data) > 1000, "...data looks sane enough");
        }

