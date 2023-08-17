#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Module::ScanDeps qw/scan_line/;

my @tests = (
    {
        chunk    => 'use strict;',
        expected => 'strict.pm',
    },
    {
        chunk    => 'require 5.10;',
        expected => 'feature.pm',
    },
    {  #  use 5.010 in one-liners was only returning feature.pm (actually, 5.9.5 or higher)
        chunk    => 'use 5.010; use MyModule::PlaceHolder1;',
        expected => 'feature.pm MyModule/PlaceHolder1.pm',
        comment  => 'got more than just feature.pm when "use 5.010" in one-liner',
    },
    {  #  use 5.009 in one-liners should not return feature.pm
        chunk    => 'use 5.009; use MyModule::PlaceHolder1;',
        expected => 'MyModule/PlaceHolder1.pm',
        comment  => 'did not get feature.pm when "use 5.009" in one-liner',
    },
    {  #  avoid early return when pragma is found in one-liners
        chunk    => 'use if 1, MyModule::PlaceHolder2; use MyModule::PlaceHolder1;',
        expected => 'if.pm MyModule/PlaceHolder1.pm MyModule/PlaceHolder2.pm',
        comment  => 'if-pragma used in one-liner',
    },
    {  #  avoid early return when pragma is found in one-liners
        chunk    => 'use autouse "MyModule::PlaceHolder2"; use MyModule::PlaceHolder1;',
        expected => 'autouse.pm MyModule/PlaceHolder1.pm MyModule/PlaceHolder2.pm',
        comment  => 'autouse pragma used in one-liner',
    },
    {
        chunk    => "{ package foo; use if 1, 'warnings' }",
        expected => 'if.pm warnings.pm',
    },
    {
        chunk    => "{ use if 1, 'warnings' }",
        expected => 'if.pm warnings.pm',
    },
    {
        chunk    => " do { use if 1, 'warnings' }",
        expected => 'if.pm warnings.pm',
    },
    {
        chunk    => " do { use foo }",
        expected => 'foo.pm',
    },
    {
        chunk    => " eval { require Win32::WinError };",
        expected => 'Win32/WinError.pm',
    },
    {
        chunk    => ' if ( eval { require Win32::WinError } ) {',
        expected => 'Win32/WinError.pm',
    },
    {
        chunk    => " eval { require Win32::WinError; 1 };",
        expected => 'Win32/WinError.pm',
    },
    {
        chunk    => ' if ( eval { require Win32::WinError; 1 } ) {',
        expected => 'Win32/WinError.pm',
    },
    {
        chunk    => ' eval "require Win32::WinError; 1";',
        expected => 'Win32/WinError.pm',
    },
    {
        chunk    => ' eval q(require Win32::WinError; 1);',
        expected => 'Win32/WinError.pm',
    },
    {
        chunk    => ' eval qq[require Win32::WinError; 1];',
        expected => 'Win32/WinError.pm',
    },
    {
        chunk    => ' eval qq {require Win32::WinError; 1};',
        expected => 'Win32/WinError.pm',
    },
    {
        chunk    => ' if ( eval "require Win32::WinError; 1" ) {',
        expected => 'Win32/WinError.pm',
    },
    {
        chunk    => ' eval "require Win32::WinError";',
        expected => 'Win32/WinError.pm',
    },
    {
        chunk    => ' if ( eval "require Win32::WinError" ) {',
        expected => 'Win32/WinError.pm',
    },
);

plan tests => 1+@tests;

# RT#48151
eval { scan_line('require __PACKAGE__ . "SomeExt.pm";') };
is($@,'');

foreach my $t (@tests)
{
    my @got = scan_line($t->{chunk});
    my @exp = split(' ', $t->{expected});
    is_deeply([sort @got], [sort @exp], $t->{comment} || $t->{chunk});
}
