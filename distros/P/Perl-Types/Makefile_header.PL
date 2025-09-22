#our $VERSION = 0.042_000;  # DEV NOTE: comment to avoid potential conflict w/ Dist::Zilla & friends

# DEV NOTE, CORRELATION #pt000: minimum Perl version to support "my array @foo;" & "my hash %bar;" Perl::Types syntax
use 5.012;

BEGIN { 
    use Config;
    use English qw(-no_match_vars);  # for $OSNAME
}

# choose correct C++11 compiler for each OS and/or Perl configuration;
# if unsupported compiler, `exit 0` to avoid creating any CPAN Testers failure or report at all
my $min_cxx_versions = {
    'g++' => 4.7,
    'clang++' => 3.3
};
my $cxx = 'g++';
if ($OSNAME eq 'freebsd') {
    $cxx = 'c++';
}
if ($Config{cc} =~ /clang/) {
    $cxx = 'clang++';
}

=begin COMPILER_VERSION_OUTPUT_EXAMPLES

$ g++ --version
g++ (Ubuntu 5.4.0-6ubuntu1~16.04.4) 5.4.0 20160609
...

$ g++ --version
g++ (i686-posix-sjlj, built by strawberryperl.com project) 4.9.2
Copyright (C) 2014 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

$ clang++ --version
Ubuntu clang version 3.4-1ubuntu3 ...
...

=end COMPILER_VERSION_OUTPUT_EXAMPLES

=cut

# run external compiler command to get version info
my $version_retval = `$cxx --version`;
#print {*STDERR} '<<< DEBUG >>>: have $version_retval = ', "\n", $version_retval, "\n";
if ((not defined $version_retval) or ($version_retval eq q{})) {
    print {*STDERR} 'C++ compiler ', $cxx, ' not found, bailing out!', "\n";
    exit 0;
}

# FreeBSD c++ is sometimes g++, sometimes clang++
my $cxx_real = $cxx;
if ($cxx eq 'c++') {
    if ($version_retval =~ m/clang/xms) {
        $cxx_real = 'clang++';
    }
    elsif ($version_retval =~ m/Free\ Software\ Foundation/xms) {
        $cxx_real = 'g++';
    }
    else {
        print {*STDERR} 'C++ compiler ', $cxx, ' does not seem to provide the known g++ or clang++ compilers, bailing out!', "\n";
        exit 0;
    }
}
#print {*STDERR} '<<< DEBUG >>>: have $cxx_real = ', $cxx_real, "\n";

# must meet minimum compiler version requirements
$version_retval =~ m/(\d+\.\d+)/xms;
my $version = $1 + 0;
#print {*STDERR} '<<< DEBUG >>>: have $version = ', $version, "\n";
if ($version < $min_cxx_versions->{$cxx_real}) {
    print {*STDERR} 'C++ compiler ', $cxx_real, ' version ', $version, ' found, does not meet minimum version requirement ', $min_cxx_versions->{$cxx_real} , ', bailing out!', "\n";
    exit 0;
}

# fix read-only blib/lib in MS Windows
BEGIN {
    require ExtUtils::MakeMaker;  # ensure EUMM is actually loaded before modifying "@ExtUtils::MakeMaker::Overridable"
    if ( $OSNAME eq 'MSWin32' ) {
        push( @ExtUtils::MakeMaker::Overridable, qw(pm_to_blib) );
    }
}
