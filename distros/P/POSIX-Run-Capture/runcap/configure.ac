# This file is part of runcap.             -*- Autoconf -*-
# Copyright (C) 2017-2024 Sergey Poznyakoff
#
# Runcap is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3 of the License, or (at your
# option) any later version.
#
# Runcap is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Runcap. If not, see <http://www.gnu.org/licenses/>.

AC_PREREQ(2.63)
AC_INIT([libruncap], [m4_esyscmd_s([git describe])], [gray+runcap@gnu.org.ua])
AC_CONFIG_SRCDIR([runcap.c])
AM_INIT_AUTOMAKE([1.11 foreign tar-ustar silent-rules])

# Enable silent rules by default:
AM_SILENT_RULES([yes])

# Checks for programs.
AC_PROG_CC

RUNCAP_SETUP([.],m4_esyscmd_s([echo ${RUNCAP_BUILD:-install}]))
	      
# Generate files
AC_OUTPUT
