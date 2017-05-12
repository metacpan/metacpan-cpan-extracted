#!/usr/bin/env perl
use warnings;
use strict;

# Tests for the Perl module Shell::Tools
# 
# Copyright (c) 2014 Hauke Daempfling (haukex@zero-g.net).
# 
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl 5 itself.
# 
# For more information see the "Perl Artistic License",
# which should have been distributed with your copy of Perl.
# Try the command "perldoc perlartistic" or see
# http://perldoc.perl.org/perlartistic.html .

use FindBin ();
use lib $FindBin::Bin;
use Shell_Tools_Testlib;

use Test::More tests=>5;

use warnings FATAL=>'redefine';

sub rootdir { return "<<ROOTDIR>>" }

# test the exclusion of a single module (Exporter tag)
use Shell::Tools qw/ !:File::Spec /;

sub updir { return "<<UPDIR>>" }

is rootdir, '<<ROOTDIR>>', 'rootdir wasn\'t redefined';
is updir, '<<UPDIR>>', 'updir wasn\'t redefined';
ok !defined(&splitdir), 'splitdir wasn\'t imported';
ok defined(&find), 'find was imported';
ok defined(&fileparse), 'fileparse was imported';


done_testing;

