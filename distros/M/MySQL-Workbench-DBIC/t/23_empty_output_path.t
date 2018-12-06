#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use FindBin;

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

my $bin     = $FindBin::Bin;
my $file    = $bin . '/misc.mwb';
my $test    = 'Test' . $$;
my %options = (
    file        => $file,
    namespace   => 't::' . $test . '::My::DB',
    output_path => '',
);

my $foo = MySQL::Workbench::DBIC->new(
    %options,
);

$foo->create_schema;

my ($table) = grep{ $_->name eq 'users' }@{ $foo->parser->tables };
use Data::Dumper;
#diag Dumper( $table->as_hash );

isa_ok( $foo, 'MySQL::Workbench::DBIC', 'object is type M::W::D' );

is( $options{file}, $foo->file, 'Checking file()' );
is( $options{namespace}, $foo->namespace, 'Checking namespace()' );
is( $options{output_path}, $foo->output_path, 'Checking output_path()' );

done_testing();
