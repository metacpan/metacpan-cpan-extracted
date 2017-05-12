#!/usr/bin/perl

use 5.008;
use strict;
use warnings;
BEGIN {
	$| = 1;
}

use Test::More tests => 14;
use File::Spec::Functions     ':ALL';
use File::Remove              'clear';
use ORDB::CPANMeta::Generator ();

my @archives = qw{
	cpanmeta.gz
	cpanmeta.bz2
	cpanmeta.lz
};
clear( @archives );
foreach my $file ( @archives ) {
	ok( ! -f $file, "File '$file' does not exist" );
}

my $minicpan = catdir( 't', 'minicpan' );
ok( -d $minicpan, 'Found minicpan directory' );

my $sqlite = catfile( 't', 'sqlite.db' );
clear( $sqlite );
ok( ! -f $sqlite, "Database '$sqlite' does not exist" );


 


#####################################################################
# Main Tests

# Create the generator
my $cpandb = new_ok( 'ORDB::CPANMeta::Generator' => [
	minicpan => $minicpan,
	sqlite   => $sqlite,
	trace    => 0,
] );
clear($cpandb->sqlite);

# Run the generator
ok( $cpandb->run, '->run ok' );

# Validate the tarballs
ok( -f $sqlite, "Created database '$sqlite'" );
foreach my $file ( qw{
	cpanmeta.gz
	cpanmeta.bz2
	cpanmeta.lz
} ) {
	ok( -f $file, "File '$file' exists" );
}

# Validate the database
my $dbh  = DBI->connect( $cpandb->dsn );
isa_ok( $dbh, 'DBI::db' );
my $distributions = $dbh->selectall_arrayref(
	'SELECT * FROM meta_distribution ORDER BY release',
	{},
);
my $dependencies = $dbh->selectall_arrayref(
	'SELECT * FROM meta_dependency ORDER BY release, module, phase',
	{},
);
$dbh->disconnect;

is_deeply( $distributions, [
	[
		'ADAMK/Acme-Terror-AU-0.01.tar.gz',
		'1',
		'Acme-Terror-AU',
		'0.01',
		'Fetch the current AU terror alert level',
		'Module::Install version 0.63',
		undef,
		'perl_5'
	],
	[
		'ADAMK/CSS-Tiny-1.15.tar.gz',
		'1',
		'CSS-Tiny',
		'1.15',
		'Read/Write .css files with as little code as possible',
		'ExtUtils::MakeMaker version 6.32',
		undef,
		'perl_5'
	],
	[
		'ADAMK/Config-Tiny-2.12.tar.gz',
		'1',
		'Config-Tiny',
		'2.12',
		'Read/Write .ini style files with as little code as possible',
		'ExtUtils::MakeMaker version 6.32',
		undef,
		'perl_5'
	],
	[
		'ANDYA/HTML-Tiny-1.05.tar.gz',
		'1',
		'HTML-Tiny',
		'1.05',
		'Lightweight, dependency free HTML/XML generation',
		'ExtUtils::MakeMaker version 6.48',
		undef,
		'perl_5'
	]
], 'Distributions ok' );
is_deeply( $dependencies, [
	[
		'ADAMK/Acme-Terror-AU-0.01.tar.gz',
		'File::Spec',
		'0.80',
		'build',
		'5.006001'
	],
	[
		'ADAMK/Acme-Terror-AU-0.01.tar.gz',
		'Test::More',
		'0.47',
		'build',
		'5.006002'
	],
	[
		'ADAMK/Acme-Terror-AU-0.01.tar.gz',
		'perl',
		'5.005',
		'runtime',
		'5.005'
	],
	[
		'ADAMK/CSS-Tiny-1.15.tar.gz',
		'Test::More',
		'0.47',
		'runtime',
		'5.006002'
	],
	[
		'ADAMK/Config-Tiny-2.12.tar.gz',
		'Test::More',
		'0.47',
		'runtime',
		'5.006002'
	],
	[
		'ANDYA/HTML-Tiny-1.05.tar.gz',
		'ExtUtils::MakeMaker',
		'0',
		'configure',
		'5'
	],
	[
		'ANDYA/HTML-Tiny-1.05.tar.gz',
		'Test::More',
		'0',
		'runtime',
		'5.006002'
	]
], 'Dependencies ok' );
