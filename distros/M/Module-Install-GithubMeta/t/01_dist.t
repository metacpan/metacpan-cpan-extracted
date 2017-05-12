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

plan tests => 1;

my $make = $Config{make};

mkdir 'dist' or die "$!\n";
chdir 'dist' or die "$!\n";
open MFPL, '>Makefile.PL' or die "$!\n";
print MFPL <<EOF;
use strict;
use inc::Module::Install;
name 'Foo-Bar';
version '0.01';
author 'Foo Bar';
abstract 'This module does something';
license 'perl';
githubmeta;
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
'inc/Module/Install/GithubMeta.pm',
);
ok( -e $_, "Exists: '$_'" ) for @tests;

exit 0;
