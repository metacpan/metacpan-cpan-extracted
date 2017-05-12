
AWK ?= gawk

NAME ?= $(shell $(AWK) -F= '/^SELINUXTYPE/{ print $$2 }' /etc/selinux/config)
SHAREDIR ?= /usr/share/selinux/devel
HEADERDIR := $(SHAREDIR)/include

include $(HEADERDIR)/Makefile
