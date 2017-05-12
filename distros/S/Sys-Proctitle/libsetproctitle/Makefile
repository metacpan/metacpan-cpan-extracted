#
# $Id: Makefile,v 1.1.1.1 2004/06/06 09:40:45 ldv Exp $
# Copyright (C) 2001-2004  Dmitry V. Levin <ldv@altlinux.org>
# 
# Makefile for the setproctitle project
#
# This file is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
# 
# This file is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307, USA
#

PROJECT = setproctitle

SHLIB = $(PROJECT).so
MAP = $(PROJECT).map

TARGETS = $(SHLIB)

INSTALL = install
libdir = ../blib/arch/auto/Sys/Proctitle

CFLAGS = $(RPM_OPT_FLAGS)

all: $(TARGETS)

%.o: %.c
	$(COMPILE.c) -fPIC $< $(OUTPUT_OPTION)

$(SHLIB): $(PROJECT).o $(MAP)
	ld -shared -soname=$(SHLIB) --version-script=$(MAP) -lc $< $(OUTPUT_OPTION)

$(PROJECT).o: $(PROJECT).c setproctitle.h

install: all
	$(INSTALL) -pD -m755 $(SHLIB) $(libdir)/$(SHLIB)

clean:
	$(RM) $(TARGETS) core *.o *~
