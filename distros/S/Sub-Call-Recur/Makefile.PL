use 5.008001;
use strict;
use warnings;


use inc::Module::Install 0.91;
use ExtUtils::Depends;

name 'Sub-Call-Recur';
all_from 'lib/Sub/Call/Recur.pm';

requires_external_cc;

requires 'parent';
configure_requires 'ExtUtils::Depends' => 0.302; #minimum version that works on Win32+gcc

foreach my $mod qw(B::Hooks::OP::Check::EntersubForCV) {
	configure_requires $mod;
	build_requires $mod;
	requires $mod;
}

test_requires 'Test::More' => 0.88;
test_requires 'Test::use::ok';

my $pkg = ExtUtils::Depends->new('Sub::Call::Recur' => 'B::Hooks::OP::Check::EntersubForCV');

makemaker_args(
    $pkg->get_makefile_vars,
    DL_FUNCS => { 'Sub::Call::Recur' => [] },
);

repository 'git://github.com/nothingmuch/Sub-Call-Recur.git';

ppport;

WriteAll;

