#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN {
	use_ok( 'MySQL::Workbench::DBIC' );
}

my @methods = qw(
    new
    create_schema
);

can_ok( 'MySQL::Workbench::DBIC', @methods );

my $error;
eval {
    MySQL::Workbench::DBIC->new;
    1;
} or $error = $@;
like $error, qr/Missing required arguments: file/, 'check required params';

my %options = (
    file        =>  './test.mwb',
    namespace   => 'My::DB',
    output_path => '/any/path',
);

my $foo = MySQL::Workbench::DBIC->new(
    %options,
);

isa_ok( $foo, 'MySQL::Workbench::DBIC', 'object is type M::W::D' );

is( $options{file}, $foo->file, 'Checking file()' );
is( $options{namespace}, $foo->namespace, 'Checking namespace()' );
is( $options{output_path}, $foo->output_path, 'Checking output_path()' );

done_testing();
