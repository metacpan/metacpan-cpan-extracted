#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2012 Kevin Ryde

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


use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

if (! eval { require ProgressMonitor }) {
  plan skip_all => "ProgressMonitor package not available: $@";
}
plan tests => 8;

require ProgressMonitor::Stringify::ToEscStatus;

my $want_version = 11;
is ($ProgressMonitor::Stringify::ToEscStatus::VERSION, $want_version,
    'VERSION variable');
is (ProgressMonitor::Stringify::ToEscStatus->VERSION,  $want_version,
    'VERSION class method');
ok (eval { ProgressMonitor::Stringify::ToEscStatus->VERSION($want_version); 1},
    "VERSION class check $want_version");
{ my $check_version = $want_version + 1000;
  ok(!eval{ProgressMonitor::Stringify::ToEscStatus->VERSION($check_version);1},
     "VERSION class check $check_version");
}
{ my $te = ProgressMonitor::Stringify::ToEscStatus->new;
  is ($te->VERSION, $want_version, 'VERSION object method');
  $te->VERSION ($want_version);
  my $check_version = $want_version + 1000;
  ok (! eval { $te->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

ok (ProgressMonitor::Stringify::ToEscStatus->new,
    'creation');

ok (! eval { ProgressMonitor::Stringify::ToEscStatus->new({stream=>123}); 1},
    'not with bad "stream" file handle');

exit 0;
