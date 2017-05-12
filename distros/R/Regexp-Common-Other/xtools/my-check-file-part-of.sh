#!/bin/sh

# my-check-file-is-part-of.sh -- grep for spelling errors

# Copyright 2009, 2010, 2011, 2012 Kevin Ryde

# my-check-file-is-part-of.sh is shared by several distributions.
#
# my-check-file-is-part-of.sh is free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3, or (at your
# option) any later version.
#
# my-check-file-is-part-of.sh is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.


exit 0

set -e
set -x

# $(MY_EXTRA_FILE_PART_OF)

if grep --text 'This file is'' part of ' -r . | egrep -iv '$DISTNAME'
then false
else true
fi

