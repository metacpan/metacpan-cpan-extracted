use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin ();
use lib File::Spec->catdir($FindBin::Bin, 'testlib');
use FakeLogin;
use Shell::Guess;

my $sh  = File::Spec->catdir('', 'bin', 'sh');
my $csh = File::Spec->catdir('', 'bin', 'csh');

plan skip_all => 'test requires a /proc filesystem' unless -f File::Spec->catdir('', 'proc', $$, 'cmdline');
plan skip_all => 'test requires bourne shell in /bin/sh' unless -x $sh;
plan skip_all => 'test requires c shell in /bin/csh' unless -x $csh;
plan skip_all => 'test requires that PERL5OPT not be set' if defined $ENV{PERL5OPT};

plan tests => 3;

is(Shell::Guess->login_shell->is_bourne, 1, 'faked out a bourne shell');

my $testlib = File::Spec->catdir($FindBin::Bin, 'testlib');

$ENV{PERL5OPT} = "-I$testlib -MFakeLogin";

like `$^X -MShell::Guess -e 'print Shell::Guess->login_shell->name, "\n"'`, qr{bourne}, 'sub process still found fake bourne shell';

my $print_guess = File::Spec->catfile($testlib, 'print_guess.pl');
my $lib = -d File::Spec->catdir($FindBin::Bin, File::Spec->updir, 'blib') ? '-Mblib' : "-I" . File::Spec->catdir($FindBin::Bin, File::Spec->updir, 'lib');

note "lib = $lib";

like `$csh -c '$^X $lib $print_guess'`, qr{c}, 'sub process found real c shell';
