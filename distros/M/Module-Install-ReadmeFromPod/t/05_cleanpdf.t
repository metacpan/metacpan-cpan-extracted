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
io->file('Makefile.PL')->print(<<EOF);
use if ! ( grep { \$_ eq '.' } \@INC ), qw[lib .];
use strict;
use inc::Module::Install;
name 'Foo-Bar';
version '0.01';
author 'Foo Bar';
abstract 'This module does something';
license 'perl';
my \@options;
\@options = ( 'sentence' => 0, 'width' => 20 );
readme_from 'README.pm' => 'clean', 'text', 'Foobar.txt', \@options;
\@options = ( '--backlink', '--flush' );
readme_from 'README.pm' => 'clean', 'html', 'Foobar.htm', \@options;
\@options = ( 'release' => 1.03, 'section' => 8 );
readme_from 'README.pm' => 'clean', 'man', 'Foobar.man', \@options;
\@options = ( 'title' => 'MyModule.pm', 'page-orientation' => 'landscape' );
readme_from 'README.pm' => 'clean', 'pdf', 'Foobar.pdf', \@options;
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
ok( -e 'Foobar.txt', 'There is a Foobar.txt file' );
ok( -e 'Foobar.htm', 'There is a Foobar.htm file' );
ok( -e 'Foobar.man', 'There is a Foobar.man file' );
ok( -e 'Foobar.pdf', 'There is a Foobar.pdf file' );

unlike io->file($_)->all, qr/\r\n/, "$_ contains only unix newlines"
  for qw( Foobar.txt Foobar.htm Foobar.man Foobar.pdf );

my $distclean = capture_merged { system "$make distclean" };
diag("$distclean");

ok( !-e 'Foobar.txt', 'The Foobar.txt file has been removed' );
ok( !-e 'Foobar.htm', 'The Foobar.htm file has been removed' );
ok( !-e 'Foobar.man', 'The Foobar.man file has been removed' );
ok( !-e 'Foobar.pdf', 'There is a Foobar.pdf file' );

}
exit 0;
