use 5.012004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'SVG::VCD',
    VERSION_FROM      => 'lib/SVG/VCD.pm', # finds $VERSION
    PREREQ_PM         => {
	SVG => 2.5,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT       => 'Generate schematic illustrations of vertebral columns',
       AUTHOR         => 'Mike Taylor <mike@miketaylor.org.uk>') : ()),
    EXE_FILES        => [ 'bin/VertFigure' ],
);

sub MY::postamble { q[
%.svg: %.vcd bin/VertFigure
	rm -f $@
	perl -I lib bin/VertFigure $< > $@
	chmod 444 $@

clean::
	rm -rf debian/files debian/libvcd-perl debian/libvcd-perl.debhelper.log debian/libvcd-perl.substvars \
		examples/bifurcation/bifurcation.svg examples/pbj/pbj.svg \
		lib/SVG/VCD/Format.html lib/SVG/VCD/pod2htmd.tmp lib/SVG/VCD/pod2htmi.tmp
]; }

# Note to self: dpkg-buildpackage -us -uc -rfakeroot
