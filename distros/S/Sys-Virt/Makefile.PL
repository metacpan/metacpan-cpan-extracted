use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $libvirtver = "3.8.0";
my $stat = system "pkg-config --atleast-version=$libvirtver libvirt";
die "cannot run pkg-config to check libvirt version" if $stat == -1;
die "libvirt >= $libvirtver is required\n" unless $stat == 0;

my $LIBVIRT_LIBS = `pkg-config --libs libvirt`;
my $LIBVIRT_CFLAGS = `pkg-config --cflags libvirt`;

my $gccflags = "-W -Waddress -Wall -Warray-bounds -Wattributes \\
 -Wbad-function-cast -Wbuiltin-macro-redefined -Wcast-align \\
 -Wchar-subscripts -Wclobbered -Wcomment -Wcomments \\
 -Wcoverage-mismatch -Wcpp -Wdeprecated-declarations \\
 -Wdisabled-optimization -Wdiv-by-zero -Wdouble-promotion \\
 -Wempty-body -Wendif-labels -Wextra -Wformat-contains-nul \\
 -Wformat-extra-args -Wformat-security -Wformat-y2k \\
 -Wformat-zero-length -Wformat=2 -Wfree-nonheap-object \\
 -Wignored-qualifiers -Wimplicit -Wimplicit-function-declaration \\
 -Wimplicit-int -Winit-self -Wint-to-pointer-cast \\
 -Winvalid-memory-model -Winvalid-pch -Wjump-misses-init \\
 -Wlogical-op -Wmain -Wmaybe-uninitialized -Wmissing-braces \\
 -Wmissing-declarations -Wmissing-field-initializers \\
 -Wmissing-format-attribute -Wmissing-include-dirs \\
 -Wmissing-noreturn -Wmissing-parameter-type \\
 -Wmultichar -Wnarrowing -Wnonnull \\
 -Wnormalized=nfc -Wold-style-declaration -Wold-style-definition \\
 -Woverflow -Woverride-init -Wpacked-bitfield-compat -Wparentheses \\
 -Wpointer-arith -Wpointer-sign -Wpointer-to-int-cast -Wpragmas \\
 -Wreturn-type -Wsequence-point -Wno-shadow -Wstrict-aliasing \\
 -Wstrict-prototypes -Wsuggest-attribute=const \\
 -Wsuggest-attribute=noreturn -Wsuggest-attribute=pure -Wswitch \\
 -Wsync-nand -Wtrampolines -Wtrigraphs -Wtype-limits -Wuninitialized \\
 -Wunknown-pragmas -Wunused -Wunused-but-set-parameter \\
 -Wunused-but-set-variable -Wunused-function -Wunused-label \\
 -Wunused-local-typedefs -Wno-unused-parameter -Wunused-result \\
 -Wunused-value -Wunused-variable -Wvariadic-macros \\
 -Wvector-operation-performance -Wvolatile-register-var \\
 -Wwrite-strings -Wno-sign-compare -Wjump-misses-init \\
 -Wno-format-nonliteral -Wframe-larger-than=8192 \\
 -Wno-suggest-attribute=pure -Wno-suggest-attribute=const -Werror";

my $cflags;
if ($ENV{TEST_MAINTAINER}) {
    $cflags = $gccflags;
} else {
    $cflags = "-Wall";
}

WriteMakefile(
	      'NAME' => 'Sys::Virt',
	      'VERSION_FROM' => 'lib/Sys/Virt.pm',
	      'PREREQ_PM' => {
		  'Test::More'  => 0,
		  'Test::Pod'  => 0,
		  'Test::Pod::Coverage'  => 0,
		  'Test::CPAN::Changes'  => 0,
		  'Time::HiRes'  => 0,
		  'XML::XPath' => 0,
		  },
	      'AUTHOR' => 'Daniel Berrange <dan@berrange.com>',
	      'LIBS' => [$LIBVIRT_LIBS],
	      'INC' => "$cflags $LIBVIRT_CFLAGS",
	      'depend' => {
		  Sys-Virt.spec => '$(VERSION_FROM)',
		  Makefile => '$(VERSION_FROM)',
	      },
              'NO_META' => 1,
	      'realclean' => {
		  FILES => 'Sys-Virt.spec',
	      },
);

package MY;

sub libscan
  {
    my ($self, $path) = @_;
    ($path =~ /\~$/ || $path =~ m,/CVS/,) ? undef : $path;
  }

__END__
