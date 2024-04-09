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
    };

use Data::Peek;
foreach my $mf (split m/##\n/ => do { local $/; <DATA> }) {
    delete $cve->{mf};
    $cve->_read_MakefilePL (\$mf);
    is_deeply ($cve->{mf}, $exp, "Correctly parsed");
    }

done_testing;
__END__
WriteMakeFile (
    NAME	=> "Foo",
    VERSION	=> "1.23",
    );
##
WriteMakeFile(
NAME=>"Foo",
VERSION=>"1.23",
);
##
WriteMakeFile(NAME=>"Foo",VERSION=>"1.23");
##
WriteMakeFile (NAME => "Foo", VERSION => "1.23");
##
WriteMakeFile( NAME => "Foo", VERSION => "1.23" );
##
WriteMakeFile (
    'NAME'	=> 'Foo',
    'VERSION'	=> '1.23',
    );
##
WriteMakeFile (VERSION => "1.23", NAME => "Foo", DISTNAME => "Foo");
##
WriteMakeFile (VERSION => "1.23", NAME => "Foo", DISTNAME => "Foo");
##
WriteMakeFile (
    "NAME"	,=> "Foo",
    "VERSION"	,=> "1.23",
    );
##
WriteMakeFile ( NAME	=> 
"Foo"

,VERSION
=> "1.23"
, ,, =>)
;
