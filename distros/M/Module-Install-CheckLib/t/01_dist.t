use strict;
use warnings;
use Test::More tests => 1;
use File::Temp      qw[tempdir];
use File::Path      qw[rmtree];
use Capture::Tiny   qw[capture_merged];

{
my $tmpdir = tempdir( CLEANUP => 1 );
chdir $tmpdir or die "$!\n";
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
checklibs lib => 'jpeg';
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
'inc/Devel/CheckLib.pm',
);
ok( -e $_, "Exists: '$_'" ) for @tests;
}
