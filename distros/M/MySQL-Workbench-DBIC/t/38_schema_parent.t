#!/usr/bin/env perl

use strict;
use warnings;

use Capture::Tiny qw(capture_stderr);
use FindBin ();
use File::Basename;
use Test::More;
use Test::LongString;

use lib dirname(__FILE__) . '/../';

use MySQL::Workbench::DBIC;
use t::MySQL::Workbench::DBIC::Table;

my $bin  = $FindBin::Bin;
my $file = $bin . '/test.mwb';

{
    my $foo = MySQL::Workbench::DBIC->new(
        file                => $file,
        schema_name         => 'Schema',
        version             => '0.01',
        result_namespace    => 'Core',
        resultset_namespace => 'Core',
        version_add         => '',
        schema_base_class   => 'My::Custom::Schema',
    );

    my $got = $foo->_main_template();
    like_string $got, qr/package Schema;/;
    like_string $got, qr{use base qw/My::Custom::Schema/;};
}

{
    my $foo = MySQL::Workbench::DBIC->new(
        file                => $file,
        schema_name         => 'Schema',
        version             => '0.01',
        result_namespace    => 'Core',
        resultset_namespace => 'Core',
        version_add         => '',
    );

    my $got = $foo->_main_template();
    like_string $got, qr/package Schema;/;
    like_string $got, qr{use base qw/DBIx::Class::Schema/;};
}

{
    my $foo = MySQL::Workbench::DBIC->new(
        file                => $file,
        schema_name         => 'Schema',
        version             => '0.01',
        result_namespace    => 'Core',
        resultset_namespace => 'Core',
        version_add         => '',
        schema_base_class   => '',
    );

    my $got = $foo->_main_template();
    like_string $got, qr/package Schema;/;
    like_string $got, qr{use base qw/DBIx::Class::Schema/;};
}

done_testing;
