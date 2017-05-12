use strict;
use warnings;
use Test::More tests => 3;
use File::Path      qw[rmtree];
use Capture::Tiny   qw[capture_merged];

# Cleanup
eval { rmtree('dist') };
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
assertos 'NetBSD';
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
'inc/Devel/CheckOS.pm',
'inc/Devel/AssertOS.pm',
'inc/Devel/AssertOS/NetBSD.pm',
);
ok( -e $_, "Exists: '$_'" ) for @tests;
