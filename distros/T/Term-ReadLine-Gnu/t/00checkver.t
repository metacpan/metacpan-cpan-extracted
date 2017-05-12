# -*- perl -*-
#	00check.t - check versions
#
#	$Id: 00checkver.t 518 2016-05-18 16:33:37Z hayashi $
#
#	Copyright (c) 2008-2016 Hiroo Hayashi.  All rights reserved.
#
#	This program is free software; you can redistribute it and/or
#	modify it under the same terms as Perl itself.

use strict;
use warnings;
use Test::More tests => 4;
use vars qw($loaded);

BEGIN {
    $ENV{PERL_RL} = 'Gnu';	# force to use Term::ReadLine::Gnu
}
END {
    unless ($loaded) {
	ok(0, 'fail before loading');
	diag "\nPlease report the output of \'perl Makefile.PL\'\n"; 
    }
}

use Term::ReadLine;
ok(1, 'load done');
$loaded = 1;
print "# I'm testing Term::ReadLine::Gnu version $Term::ReadLine::Gnu::VERSION\n";

my $t = new Term::ReadLine 'ReadLineTest';
isa_ok($t, 'Term::ReadLine');
my $a = $t->Attribs;
isa_ok($a, 'Term::ReadLine', 'Attribs');

print  "# OS: $^O\n";
print  "# Perl version: $]\n";
printf "# GNU Readline Library version: $a->{library_version}, 0x%X\n", $a->{readline_version};
print  "# \$TERM=$ENV{TERM}\n";

ok(1, 'library_version and readline_version');

exit 0;

