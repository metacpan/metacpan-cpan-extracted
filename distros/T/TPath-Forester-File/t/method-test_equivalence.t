use v5.10;
use strict;
use warnings;

use Test::More;
use TPath::Forester::File qw(tff);
use File::Temp ();
use Cwd qw(getcwd);

use FindBin qw($Bin);
use lib "$Bin/lib";
use TreeMachine;

my $dir = getcwd;

my %equivalents = (
    is_directory => 'd',
    is_file      => 'f',
    is_empty     => 'z',
    is_text      => 'T',
    is_binary    => 'B',
    real         => 'e',
    can_read     => 'r',
    can_write    => 'w',
    can_execute  => 'x',
);

my $td = File::Temp::tempdir();
chdir $td;

my $a;

file_tree( { name => 'a', children => [] } );
$a = tff->wrap('a');
test_equivalents( $a, 'directory' );

file_tree( { name => 'a', binary => 1 } );
$a = tff->wrap('a');
test_equivalents( $a, 'binary' );

file_tree( { name => 'a', text => '1' } );
$a = tff->wrap('a');
test_equivalents( $a, 'text' );

file_tree( { name => 'a', text => '' } );
$a = tff->wrap('a');
test_equivalents( $a, 'empty' );

file_tree( { name => 'a', children => [], mode => "0000" } );
$a = tff->wrap('a');
test_equivalents( $a, 'mode 0000 directory' );

file_tree( { name => 'a', binary => 1, mode => "0000" } );
$a = tff->wrap('a');
test_equivalents( $a, 'mode 0000 binary' );

file_tree( { name => 'a', text => '1', mode => "0000" } );
$a = tff->wrap('a');
test_equivalents( $a, 'mode 0000 text' );

file_tree( { name => 'a', text => '', mode => "0000" } );
$a = tff->wrap('a');
test_equivalents( $a, 'mode 0000 empty' );

chdir $dir;
rmtree($td);

done_testing();

sub test_equivalents {
    my ( $f, $type ) = @_;
    while ( my ( $method, $test ) = each %equivalents ) {
        ok !( $f->$method xor eval "-$test '$f'" ),
          "$method ~ -$test for $type";
    }
    -d $f ? rmdir $f : unlink $f;
    tff->clean;
}
