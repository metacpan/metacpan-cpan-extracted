use strict;
use warnings;
use Test::More; #tests => 1;
use File::Path      qw[rmtree];
use Capture::Tiny   qw[capture_merged];
use Config;

# Cleanup
eval { rmtree('dist') };

unless ( -e 'have_make' ) {
  plan skip_all => 'No network tests';
}

plan tests => 3;

my $make = $Config{make};

mkdir 'dist' or die "$!\n";
chdir 'dist' or die "$!\n";
open MFPL, '>Makefile.PL' or die "$!\n";
print MFPL <<'EOF';
use if ! ( grep { $_ eq '.' } @INC ), qw[lib .];
use strict;
use inc::Module::Install;
name 'Foo-Bar';
version '0.01';
author 'Foo Bar';
abstract 'This module does something';
license 'perl';
if ( auto_tester ) {
  print "AUTOMATED TESTER\n";
}
if ( cpan_tester ) {
  print "CPAN TESTER\n";
}
WriteAll;
EOF
close MFPL;
my $merged = capture_merged { system "$^X Makefile.PL" };
diag("$merged");
# Copied /usr/lib/perl5/site_perl/5.8.8/Devel/CheckOS.pm to
#        inc/Devel/CheckOS.pm
# Copied /usr/lib/perl5/site_perl/5.8.8/Devel/AssertOS.pm to
#        inc/Devel/AssertOS.pm
# Copied /usr/lib/perl5/site_perl/5.8.8/Devel/AssertOS/NetBSD.pm to
#        inc/Devel/AssertOS/NetBSD.pm
my @tests = (
'inc/Module/Install/AutomatedTester.pm',
);
ok( -e $_, "Exists: '$_'" ) for @tests;

# Need to make a manifest

my $manifest = capture_merged { system "$make manifest" };
diag("$manifest");

my $distdir = capture_merged { system "$make distdir" };
diag("$distdir");

$ENV{AUTOMATED_TESTING} = 1;
chdir 'Foo-Bar-0.01' or die "$!\n!";

my $foobar = capture_merged { system "$^X Makefile.PL" };
diag("$foobar");
like( $foobar, qr/AUTOMATED TESTER/s, 'AUTOMATED TESTER' );
like( $foobar, qr/CPAN TESTER/s, 'AUTOMATED TESTER' );
