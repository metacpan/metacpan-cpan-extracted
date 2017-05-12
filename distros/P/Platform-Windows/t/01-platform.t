use Test::More tests => 1;
ok( $ENV{PERL_PLATFORM_OVERRIDE}||($^O =~ /^(MSWin32|cygwin)$/i) );
