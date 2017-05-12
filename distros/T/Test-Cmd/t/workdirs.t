# Copyright 1999-2001 Steven Knight.  All rights reserved.  This program
# is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

######################### We start with some black magic to print on failure.

use Test;
BEGIN { $| = 1; plan tests => 10, onfail => sub { $? = 1 if $ENV{AEGIS_TEST} } }
END {print "not ok 1\n" unless $loaded;}
use Test::Cmd;
$loaded = 1;
ok(1);

######################### End of black magic.

my $test = Test::Cmd->new;
ok($test);
ok(! $test->workdir);

$wdir_1 = $test->workdir('');
ok($wdir_1);
ok(-d $wdir_1);

$wdir_2 = $test->workdir('');
ok($wdir_2);
ok(-d $wdir_2);
ok(-d $wdir_1);

$test->cleanup;
ok(! -d $wdir_2);
ok(! -d $wdir_1);
