# This file is part of runcap -*- autoconf -*-
# Copyright (C) 2017-2024 Sergey Poznyakoff
#
# Runcap is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.
#
# Runcap is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Runcap.  If not, see <http://www.gnu.org/licenses/>.
AC_DEFUN([RUNCAP_SETUP],[
  m4_pushdef([runcapdir],m4_if($1,[.],,$1,,[runcap/],$1/))
  AC_SUBST([RUNCAP_INC],['-I$(top_srcdir)/]runcapdir')
  AC_SUBST([RUNCAP_LDADD],['-L$(top_builddir)/]runcapdir -lruncap')
  AC_SUBST([RUNCAP_BUILD_TYPE])
  m4_if($2,[install],[
    LT_INIT
    RUNCAP_BUILD_TYPE=install
    RUNCAP_LDADD=['$(top_builddir)/]runcapdir[libruncap.la']
    AC_CONFIG_FILES(runcapdir[Makefile]:runcapdir[install.in])
  ],$2,[shared],[
    LT_INIT
    RUNCAP_BUILD_TYPE=shared
    RUNCAP_LDADD=['$(top_builddir)/]runcapdir[libruncap.la']
    AC_CONFIG_FILES(runcapdir[Makefile]:runcapdir[shared.in])
  ],[
    AC_PROG_RANLIB
    RUNCAP_BUILD_TYPE=static
    RUNCAP_LDADD=['$(top_builddir)/]runcapdir[libruncap.a']
    AC_CONFIG_FILES(runcapdir[Makefile]:runcapdir[static.in])
  ])
  
  AC_CONFIG_TESTDIR(runcapdir[t])
  AC_CONFIG_FILES(runcapdir[t/Makefile] runcapdir[t/atlocal])
  AM_MISSING_PROG([AUTOM4TE], [autom4te])
  
  m4_popdef([runcapdir])
])  
  
