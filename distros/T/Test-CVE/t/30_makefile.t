#!/usr/bin/perl

use 5.014000;
use warnings;

use Test::More;

use_ok ("Test::CVE");

ok (my $cve = Test::CVE->new, "New");

my $exp = {
    name    => "Foo",
    release => "Foo",
    version => "1.23",
    mpv     => "5.014000",
    };

foreach my $mf (split m/##\n/ => do { local $/; <DATA> }) {
    delete $cve->{mf};
    $cve->_read_MakefilePL (\$mf);
    is_deeply ($cve->{mf}, $exp, "Correctly parsed");
    }

done_testing;
__END__
use 5.14;
WriteMakeFile (
    NAME	=> "Foo",
    VERSION	=> "1.23",
    );
##
use 5.014000;
WriteMakeFile(
NAME=>"Foo",
VERSION=>"1.23",
);
##
use v5.14.0;
WriteMakeFile(NAME=>"Foo",VERSION=>"1.23");
##
WriteMakeFile (NAME => "Foo", VERSION => "1.23", MIN_PERL_VERSION => "5.014000");
##
use 5.14;
WriteMakeFile( NAME => "Foo", VERSION => "1.23" );
##
WriteMakeFile (
    'NAME'		=> 'Foo',
    'VERSION'		=> '1.23',
    'MIN_PERL_VERSION'	=> '5.014',
    );
##
require 5.014000;
WriteMakeFile (VERSION => "1.23", NAME => "Foo", DISTNAME => "Foo");
##
require 5.14.0;
WriteMakeFile (VERSION => "1.23", NAME => "Foo", DISTNAME => "Foo");
##
require 5.014;
WriteMakeFile (
    "NAME"	,=> "Foo",
    "VERSION"	,=> "1.23",
    );
##
require 5.014;
WriteMakeFile (
    "NAME"	,=> "Foo", # Comment
    "VERSION"	,=> "1.23",
    );
##
use v5.14.1;
WriteMakeFile ( NAME	=> 
"Foo"

,MIN_PERL_VERSION
=> "5.14"
,VERSION
=> "1.23"
, ,, =>)
;
