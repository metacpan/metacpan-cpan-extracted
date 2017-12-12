noinst_LIBRARIES=libruncap.a
libruncap_a_SOURCES = \
 getc.c\
 getl.c\
 runcap.c\
 seek.c\
 tell.c
noinst_HEADERS=runcap.h
check:
	$(MAKE) -C t check
SUBDIRS = . t
