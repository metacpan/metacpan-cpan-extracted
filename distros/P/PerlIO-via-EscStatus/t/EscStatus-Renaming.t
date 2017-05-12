#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of PerlIO-via-EscStatus.
#
# PerlIO-via-EscStatus is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# PerlIO-via-EscStatus is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with PerlIO-via-EscStatus.  If not, see <http://www.gnu.org/licenses/>.

use 5.006;
use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

BEGIN {
  eval 'use Exporter::Renaming; 1'
    or plan skip_all => "due to Exporter::Renaming not available -- $@";
  plan tests => 4;
}

use PerlIO::via::EscStatus Renaming => [ print_status => 'pstat',
                                         make_status => 'sm' ];

ok (main->can('pstat'), 'pstat() imported');
ok (main->can('sm'), 'sm() imported');
my $str = 'some string';
my $status = sm('some string');
isnt ($status, $str, 'sm() changes string');
like ($status, qr/\Q$str/, 'sm() contains original');
exit 0;
