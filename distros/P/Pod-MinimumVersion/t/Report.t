#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

# This file is part of Pod-MinimumVersion.
#
# Pod-MinimumVersion is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Pod-MinimumVersion is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Pod-MinimumVersion.  If not, see <http://www.gnu.org/licenses/>.


use 5.004;
use strict;
use Test;
BEGIN { plan tests => 7; }

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Pod::MinimumVersion::Report;

#------------------------------------------------------------------------------
{
  my $want_version = 50;
  ok ($Pod::MinimumVersion::Report::VERSION, $want_version, 'VERSION variable');
  ok (Pod::MinimumVersion::Report->VERSION,  $want_version, 'VERSION class method');
  {
    ok (eval { Pod::MinimumVersion::Report->VERSION($want_version); 1 },
        1,
        "VERSION class check $want_version");
    my $check_version = $want_version + 1000;
    ok (! eval { Pod::MinimumVersion::Report->VERSION($check_version); 1 },
        1,
        "VERSION class check $check_version");
  }
  { my $pmv = Pod::MinimumVersion::Report->new;
    ok ($pmv->VERSION, $want_version, 'VERSION object method');
    ok (eval { $pmv->VERSION($want_version); 1 },
        1,
        "VERSION object check $want_version");
    my $check_version = $want_version + 1000;
    ok (! eval { $pmv->VERSION($check_version); 1 },
        1,
        "VERSION object check $check_version");
  }
}

exit 0;
