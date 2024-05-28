use 5.006001;
use ExtUtils::MakeMaker;
use Config;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# if use pcre regex library, use this command
# perl Makefile.PL DEFINE="-DUSE_PCRE_REGEX" LIBS="-lpcre2-8"
# print @ARGV, "\n";

my $LIBS=[];
foreach my $arg (@ARGV) {
  print "Input arg: $arg\n";

  if(($arg =~ m/-DUSE_PCRE_REGEX/ ) && ($arg =~ m/DEFINE=/)) {
    push @{$LIBS}, "-lpcre2-8";
    print "Use librar libpcre2-8.\n";
  }
}

my $CC, $LDDLFLAGS;
if ($Config{osname} eq 'darwin') {
 $CC = 'clang++';
 $LDDLFLAGS=$Config{lddlflags}." -mlinker-version=519";
}else{
 $CC = 'g++';
 # $CC = 'clang++';
 $LDDLFLAGS=$Config{lddlflags};
}
my $CCFLAGS=$Config{ccflags}." -std=c++11";

WriteMakefile(
    NAME              => 'Search::Fzf::AlgoCpp',
    VERSION_FROM      => 'lib/Search/Fzf/AlgoCpp.pm', # finds $VERSION
    PREREQ_PM         => {
      'ExtUtils::XSpp::Cmd' => '0',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Search/Fzf/AlgoCpp.pm', # retrieve abstract from module
       AUTHOR         => 'Liyao <liyao0117@qq.com>') : ()),
    LIBS              => $LIBS,
    # LIBS              => [], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
    OBJECT            => '$(O_FILES)', # link all the C files too
    XSOPT             => '-C++ -hiertype',
    #TYPEMAPS          => ['other_xs_typemap_files_here'],
    CC                => $CC,
    LD                => '$(CC)',
    CCFLAGS           => $CCFLAGS,
    LDDLFLAGS         => $LDDLFLAGS,
    # macro             => {TESTVAR => MakefileTest,},
);

