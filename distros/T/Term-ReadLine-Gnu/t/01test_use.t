# -*- perl -*-
#	01test_use.t - reject 'use Term::ReadLine::Gnu'
#
#	$Id: 00checkver.t 518 2016-05-18 16:33:37Z hayashi $
#
#	Copyright (c) 2017 Hiroo Hayashi.  All rights reserved.
#
#	This program is free software; you can redistribute it and/or
#	modify it under the same terms as Perl itself.

use strict;
use warnings;
use Test::More tests => 2;
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

my $e;
$e = eval "use Term::ReadLine::Gnu; 1";
{
    no warnings;
    ok($e != 1, 'reject "use Term::ReadLine::Gnu"');
}

$e = eval "use Term::ReadLine; 1";
ok($e == 1, '"use Term::ReadLine"');
$loaded = 1;

exit 0;

