use strict;
use warnings;
use Test::More; #tests => 1;
use File::Temp      qw[tempdir];
use File::Path      qw[rmtree];
use Capture::Tiny   qw[capture_merged];
use Config;

unless ( -e 'have_make' ) {
  plan skip_all => 'No network tests';
}

plan tests => 4;

{
my $make = $Config{make};
mkdir 'dist';
my $tmpdir = tempdir( DIR => 'dist', CLEANUP => 1 );
chdir $tmpdir or die "$!\n";
open MFPL, '>Makefile.PL' or die "$!\n";
print MFPL <<'EOF';
use if ! ( grep { $_ eq '.' } @INC ), qw[lib .];
use strict;
use inc::Module::Install;
name 'Foo-Bar';
version '0.01';
author 'Foo Bar';
author 'Moo Cow';
abstract 'This module does something';
license 'perl';
auto_license;
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
'inc/Module/Install/AutoLicense.pm',
);
ok( -e $_, "Exists: '$_'" ) for @tests;
ok( -e 'LICENSE', 'There is a LICENSE file' );

{
  open my $license, '<', 'LICENSE' or die "$!\n";
  local $/;
  my $contents = <$license>;
  close $license;
  like( $contents, qr/Foo Bar\, Moo Cow/s, 'Foo Bar and Moo Cow are contained in the license file' );
}

my $distclean = capture_merged { system "$make distclean" };
diag("$distclean");

ok( !-e 'LICENSE', 'The LICENSE file has been removed' );

exit 0;
# Need to make a manifest

my $manifest = capture_merged { system "$make manifest" };
diag("$manifest");

my $distdir = capture_merged { system "$make distdir" };
diag("$distdir");
}
