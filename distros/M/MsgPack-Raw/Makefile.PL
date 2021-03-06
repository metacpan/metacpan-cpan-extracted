use strict;
use warnings;
use Config;

# compiler detection
my $is_gcc = length($Config{gccversion});
my $is_msvc = $Config{cc} eq 'cl' ? 1 : 0;
my $legacy_gcc = index ($Config{gccversion}, '4.2.1') != -1 ? 1 : 0;

# os detection
my $is_solaris = ($^O =~ /(sun|solaris)/i) ? 1 : 0;
my $is_windows = ($^O =~ /MSWin32/i) ? 1 : 0;
my $is_linux = ($^O =~ /linux/i) ? 1 : 0;
my $is_osx = ($^O =~ /darwin/i) ? 1 : 0;
my $is_bsd = ($^O =~ /bsd/i) ? 1 : 0;
my $is_openbsd = ($^O =~ /openbsd/i) ? 1 : 0;
my $is_gkfreebsd = ($^O =~ /gnukfreebsd/i) ? 1 : 0;

my $def = '';

my $lib = '';
my $otherldflags = '';
my $inc = '';
my $ccflags = '';

if ($is_windows)
{
	$def .= ' -D_WINSOCK_DEPRECATED_NO_WARNINGS -D_CRT_SECURE_NO_WARNINGS -DFD_SETSIZE=16384';
	$def .= ' -D_WIN32_WINNT=0x0600';

	$lib .= ' -lws2_32 -lrpcrt4 -liphlpapi msvcprt.lib';

	if ($is_msvc)
	{
		$ccflags .= ' -EHsc';
	}
}

my @c_srcs = (glob ('deps/msgpack-c/src/*.c'));
my @c_objs = map { substr ($_, 0, -1) . 'o' } (@c_srcs);

sub MY::c_o {
	my $out_switch = '-o ';

	if ($is_msvc) {
		$out_switch = '/Fo';
	}

	my $line = qq{
.c\$(OBJ_EXT):
	\$(CCCMD) \$(CCCDLFLAGS) "-I\$(PERL_INC)" \$(PASTHRU_DEFINE) \$(DEFINE) \$*.c $out_switch\$@
};

	if ($is_gcc) {
		# disable parallel builds
		$line .= qq{

.NOTPARALLEL:
};
	}
	return $line;
}

# This Makefile.PL for  was generated by Dist::Zilla.
# Don't edit it but the dist.ini used to construct it.
BEGIN { require 5.008; }
use strict;
use warnings;
use ExtUtils::MakeMaker 0;
use ExtUtils::Constant qw (WriteConstants);

my %WriteMakefileArgs = (
  "ABSTRACT" => "Perl bindings to the msgpack C library",
  "AUTHOR" => "Jacques Germishuys <jacquesg\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.63_03"
  },
  "DISTNAME" => "MsgPack-Raw",
  "INC" => "-I. -Ideps -Ideps/msgpack-c/include",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.008",
  "NAME" => "MsgPack::Raw",
  "OBJECT" => "\$(O_FILES)",
  "PREREQ_PM" => {
    "XSLoader" => 0,
    "overload" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Encode" => 0,
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => 0,
    "Test::Pod" => "0.0",
    "Test::Pod::Coverage" => "0.0"
  },
  "VERSION" => "0.05",
  "test" => {
    "TESTS" => "t/*.t"
  }
);

$WriteMakefileArgs{DEFINE}  .= $def;
$WriteMakefileArgs{LIBS}    .= $lib;
$WriteMakefileArgs{INC}     .= $inc;
$WriteMakefileArgs{CCFLAGS} .= $Config{ccflags} . ' '. $ccflags;
$WriteMakefileArgs{OBJECT}  .= ' ' . join ' ', (@c_objs);
$WriteMakefileArgs{dynamic_lib} = {
	OTHERLDFLAGS => $otherldflags
};

unless (eval { ExtUtils::MakeMaker->VERSION(6.56) }) {
	my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
	my $pp = $WriteMakefileArgs{PREREQ_PM};

	for my $mod (keys %$br) {
		if (exists $pp -> {$mod}) {
			$pp -> {$mod} = $br -> {$mod}
				if $br -> {$mod} > $pp -> {$mod};
		} else {
			$pp -> {$mod} = $br -> {$mod};
		}
	}
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
	unless eval { ExtUtils::MakeMaker -> VERSION(6.52) };

WriteMakefile (%WriteMakefileArgs);
exit (0);
