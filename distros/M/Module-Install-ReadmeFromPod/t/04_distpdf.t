use strict;
use warnings;
use Test::More; #tests => 1;
use File::Temp      qw[tempdir];
use File::Path      qw[rmtree];
use Capture::Tiny   qw[capture_merged];
use Config;
use IO::All -binary;

unless ( -e 'have_make' ) {
  plan skip_all => 'No network tests';
}

eval { require App::pod2pdf; };
plan skip_all => 'App::pod2pdf not installed' if $@;

plan tests => 13;

{
my $make = $Config{make};
mkdir 'dist';
my $tmpdir = tempdir( DIR => 'dist', CLEANUP => 1 );
chdir $tmpdir or die "$!\n";
io->file('README.pm')->print(<<README);
=head1 NAME

Foo::Bar - Putting the Foo into Bar

=head1 DESCRIPTION

It is like chocolate, but not.

=cut
README
io->file('Makefile.PL')->print(<<'EOF');
use if ! ( grep { $_ eq '.' } @INC ), qw[lib .];
use strict;
use inc::Module::Install;
name 'Foo-Bar';
version '0.01';
author 'Foo Bar';
abstract 'This module does something';
license 'perl';
readme_from 'README.pm';
readme_from 'README.pm', undef, 'htm';
readme_from 'README.pm', '', 'man';
readme_from 'README.pm', 0, 'pdf';
WriteAll;
EOF
my $merged = capture_merged { system "$^X Makefile.PL" };
diag("$merged");
# Copied /usr/lib/perl5/site_perl/5.8.8/Devel/CheckOS.pm to
#        inc/Devel/CheckOS.pm
# Copied /usr/lib/perl5/site_perl/5.8.8/Devel/AssertOS.pm to
#        inc/Devel/AssertOS.pm
# Copied /usr/lib/perl5/site_perl/5.8.8/Devel/AssertOS/NetBSD.pm to
#        inc/Devel/AssertOS/NetBSD.pm
my @tests = (
'inc/Module/Install/ReadmeFromPod.pm',
);
ok( -e $_, "Exists: '$_'" ) for @tests;
ok( -e 'README', 'There is a README file' );
ok( -e 'README.htm', 'There is a README.htm file' );
ok( -e 'README.1', 'There is a README.1 file' );
ok( -e 'README.pdf', 'There is a README.pdf file' );

unlike io->file($_)->all, qr/\r\n/, "$_ contains only unix newlines"
  for qw( README README.htm README.1 README.pdf );

my $distclean = capture_merged { system "$make distclean" };
diag("$distclean");

ok( -e 'README', 'There is a README file' );
ok( -e 'README.htm', 'There is a README.htm file' );
ok( -e 'README.1', 'There is a README.1 file' );
ok( -e 'README.pdf', 'There is a README.pdf file' );

}
exit 0;
