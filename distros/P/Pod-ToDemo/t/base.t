#!/usr/bin/perl

use strict;
use warnings;

chdir 't';
use lib 'lib';

use Test::More tests => 14;
use Test::Exception;

END
{
    unless ($ENV{TEST_DEBUG})
    {
        1 while unlink(qw( foo bar filename some_file ));
    }
}

my $module = 'Pod::ToDemo';
use_ok( $module ) or exit;

throws_ok { Pod::ToDemo::write_demo() } qr/^Usage:/,
    'write_demo() should die with Usage error without a filename';

throws_ok { Pod::ToDemo::write_demo( 'base.t' ) }
    qr/Cowardly refusing to overwrite 'base.t'/,
    '... or with overwriting error if destination file exists';

Pod::ToDemo::write_demo( 'bar', 'here is more text' );
ok( -e 'bar', '... and should write file if everything is sane' );

my $text = slurp( 'bar' );

is( $text, 'here is more text', '... writing demo file accurately' );

use_ok( 'DemoUser' );
ok( ! -e 'foo',
    'defined caller() check should protect against accidental usage' );

my $flag = 0;
Pod::ToDemo->import( sub { $flag++ } );
diag( "import() should import a passed sub into the caller's namespace" );
can_ok( __PACKAGE__, 'import' );
__PACKAGE__->import();
ok( $flag, '... the correct sub' );

package Foo;

Pod::ToDemo->import( 'This is more text' );
__PACKAGE__->import( 'filename' );

package main;

my $exists = -e 'filename';
ok( $exists, 'default import() should write to the pased-in filename' );

$text      = ::slurp( 'filename' );
like( $text, qr/^#!\Q$^X\E/,                  '... with a Perl header' );
like( $text, qr/use strict;.+use warnings;/s, '... strictures and warnings' );
like( $text, qr/..This is more text/s,        '... and the given text' );

SKIP:
{
    my @commands = ( $^X, '-Ilib', '-MDemoUser=some_file', '-e 1' );
    skip( "Couldn't execute subprocess: (@commands)", 1 )
        if system @commands;
    ok( -e 'some_file', 'executing in separate process should work' )
        or diag( "Hmm: (@commands): $!" );
}

sub slurp
{
    my $filename = shift;
    open( my $file, $filename ) or die "Cannot read demo $filename: $!\n";
    return scalar do { local $/; <$file> };
}
