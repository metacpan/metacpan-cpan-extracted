prefix?=../share/

PERL = perl
CC = gcc  # C compiler
CFLAGS = -fPIC -Wall -Wextra -O2 -g `$(PERL) -MAlien::libsdl2 -e "print Alien::libsdl2->cflags"` # C flags
LDFLAGS = -shared `$(PERL) -MAlien::libsdl2 -e "print Alien::libsdl2->libs"`  # linking flags
RM = rm -f   # rm command

bundle_cflags:=-std=c99 -Wall -Wextra -pedantic -Wno-unused-result -fPIC -g -O3 -D_XOPEN_SOURCE $(CFLAGS)
bundle_objects:=$(patsubst %.c,%.o,$(wildcard *.c))
bundle_so_version_abi:=1
bundle_so_version_minor_patch:=0.0
bundle_so:=libbundle.so
bundle_so_x:=$(bundle_so).$(bundle_so_version_abi)
bundle_so_x_y_z:=$(bundle_so_x).$(bundle_so_version_minor_patch)
bundle_ld_soname:=soname
bundle_a:=libbundle.a

ifeq ($(shell $(CC) -dumpmachine | grep -q apple && echo 1), 1)
	bundle_so:=libbundle.dylib
	bundle_so_x:=libbundle.$(bundle_so_version_abi).dylib
	bundle_so_x_y_z:=libbundle.$(bundle_so_version_abi).$(bundle_so_version_minor_patch).dylib
	bundle_ld_soname:=install_name
endif

all: $(bundle_a) $(bundle_so_x_y_z)

$(bundle_a): $(bundle_objects)
	$(AR) rcs $@ $(bundle_objects)

$(bundle_so_x_y_z): $(bundle_objects)
	echo $(CC) -shared -Wl,-$(bundle_ld_soname),$(bundle_so_x) $(bundle_objects) $(LDFLAGS) -o $@
	$(CC) -shared -Wl,-$(bundle_ld_soname),$(bundle_so_x) $(bundle_objects) $(LDFLAGS) -o $@
	ln -sf $@ $(bundle_so)

$(bundle_objects): %.o: %.c
	$(CC) -c $(bundle_cflags) $< -o $@    

install: $(bundle_a) $(bundle_so_x_y_z)
	install -d $(DESTDIR)$(prefix)/lib
	install -d $(DESTDIR)$(prefix)/include
	install -p -m 644 $(bundle_a) $(DESTDIR)$(prefix)/lib/$(bundle_a)
	install -p -m 755 $(bundle_so_x_y_z) $(DESTDIR)$(prefix)/lib/$(bundle_so_x_y_z)
	ln -sf $(bundle_so_x_y_z) $(DESTDIR)$(prefix)/lib/$(bundle_so_x)
	ln -sf $(bundle_so_x_y_z) $(DESTDIR)$(prefix)/lib/$(bundle_so)

clean:
	-$(RM) -f $(bundle_so_x_y_z) $(bundle_a) $(bundle_objects)

.PHONY: all install clean 