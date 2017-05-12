use inc::Module::Install::DSL 1.06;

all_from      lib/ORLite/Mirror.pm
requires_from lib/ORLite/Mirror.pm
requires      File::Spec              3.2701 if winlike
requires      IO::Uncompress::Gunzip  2.008
requires      IO::Uncompress::Bunzip2 2.008
test_requires URI                     1.35
test_requires Test::More              0.47
test_requires IO::Compress::Gzip      2.008
test_requires IO::Compress::Bzip2     2.008
install_share module ORLite::Mirror::Test share
