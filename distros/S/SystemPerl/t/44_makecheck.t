#!/usr/bin/perl -w
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2001-2014 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

use strict;
use Test;

BEGIN { plan tests => 4 }
BEGIN { require "t/test_utils.pl"; }

run_system("rm -rf test_dir");
mkdir 'test_dir',0777;

write_file ("test_dir/a", "#\n");
write_file ("test_dir/b", "#\n");
write_file ("test_dir/b.d", "b.o: a\n", "b.d: a\n");
write_file ("test_dir/c.d", "c.d: b\n");
write_file ("test_dir/lost.o", "#\n");
write_file ("test_dir/lost.d", "lost.d: missing\nlost.o: missing\n");
write_file ("test_dir/lostl2.o", "#\n");
write_file ("test_dir/lostl2.d", "lostl2.o: lost.o\n");
ok(1);

# Run makecheck
run_system ("cd test_dir && ${PERL} ../sp_makecheck --verbose *.d");
ok(1);

# Did it keep the right files?
ok(1
   && -r  "test_dir/a"
   && -r  "test_dir/b"
   && -r  "test_dir/b.d"
   && -r  "test_dir/c.d"
   );
# Did it remove the files
ok(1
   && !-r "test_dir/lost.o"
   && !-r "test_dir/lost.d"
   && !-r "test_dir/lostl2.o"
   && !-r "test_dir/lostl2.d"
   );
