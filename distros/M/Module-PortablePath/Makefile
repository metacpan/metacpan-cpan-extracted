MPPMAJOR = $(shell perl -Ilib -MModule::PortablePath -e 'print Module::PortablePath->VERSION =~ /^(\d+)/')
MPPMINOR = $(shell perl -Ilib -MModule::PortablePath -e 'print Module::PortablePath->VERSION =~ /(\d+)$$/')

machine    = $(shell uname -m)
servername = $(shell uname -n)
OS         = $(shell uname -s)

arch = $(machine)

ifeq ($(arch), x86_64)
	arch := amd64
endif

all:	setup
	./Build

setup:	manifest
	perl Build.PL

manifest: partclean lib t Build.PL Makefile spec.header
	find . -type f | grep -vE 'DS_Store|git|_build|META.yml|Build|cover_db|svn|blib|\~|\.old|CVS|mpp.*gz|mod.*rpm|rpmbuild|build.tap|tap.harness' | sed 's/^\.\///' | sort > MANIFEST
	[ -f Build.PL ] && echo "Build.PL" >> MANIFEST

partclean:
	[ ! -e Makefile.PL ] || rm -f Makefile.PL
	[ ! -e spec ] || rm -f spec
	[ ! -d rpmbuild ] || rm -rf rpmbuild
	touch mpp.gz
	rm mpp*gz

clean:	setup
	./Build clean
	[ ! -e build.tap ]  || rm -f build.tap
	[ ! -e MYMETA.yml ] || rm -f MYMETA.yml
	[ ! -d _build ]     || rm -rf _build
	[ ! -e Build ]      || rm -f Build
	[ ! -e rpmbuild ]   || rm -rf rpmbuild
	[ ! -e cover_db ]   || rm -rf cover_db
	touch mod.rpm
	rm mod*rpm
	touch mod.deb
	rm mod*deb

test:	setup
	TEST_AUTHOR=1 ./Build test verbose=1

cover:	setup
	[ ! -d cover_db ] || rm -rf cover_db
	HARNESS_PERL_SWITCHES=-MDevel::Cover prove -Ilib -v t/*t
	cover

install:	setup
	./Build install

dist:	setup
	./Build dist

pardist:	setup
	./Build pardist

rpm:	clean manifest
	cp spec.header spec
	perl -i -pe 's/MPPMAJOR/$(MPPMAJOR)/g' spec
	perl -i -pe 's/MPPMINOR/$(MPPMINOR)/g' spec
	mkdir -p rpmbuild/BUILD rpmbuild/RPMS rpmbuild/SOURCES rpmbuild/SPECS rpmbuild/SRPMS
	perl Build.PL
	./Build dist
	mv Mod*gz rpmbuild/SOURCES/libmodule-portablepath-$(MPPMAJOR)-$(MPPMINOR).tar.gz
	cp rpmbuild/SOURCES/libmodule-portablepath-$(MPPMAJOR)-$(MPPMINOR).tar.gz rpmbuild/BUILD/
	rpmbuild -v --define="_topdir `pwd`/rpmbuild" \
		    --buildroot `pwd`/rpmbuild/libmodule-portablepath-$(MPPMAJOR)-$(MPPMINOR)-root \
		    --target=$(arch)-redhat-linux        \
		    -ba spec
	cp rpmbuild/RPMS/*/libmod*.rpm .

deb:	rpm
	fakeroot alien  -d libmodule-portablepath-$(MPPMAJOR)-$(MPPMINOR).$(arch).rpm
