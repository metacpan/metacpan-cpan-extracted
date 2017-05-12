
BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use Test::More tests =>
  2 + 4 + 4 +
  2 + 4 +
  2 + 4 +
  2 + 4 +
  2 + 4 +
  2 + 4 + 1;
use strict;
use warnings;

# modules that we need
use Scalar::Util qw( reftype );
use String::Lookup;

# initializations
my $foo= 'foo';
my $bar= 'bar';
my $foobar= join ",", $foo, $bar;

# flush test logic
my $ok_list;
my $ok_todo;
my $flush= sub {
    my ( $list, $todo )= @_;
    is( reftype($list), 'ARRAY', 'first param in flush' );
    is( reftype($todo), 'ARRAY', 'second param in flush' );
    is( join( ',', @$list[ 1 .. $#$list ] ), $ok_list, 'expected list' );
    is( join( ',', @{$todo} ),               $ok_todo, 'expected todo' );
    return 1;
};

# set up the hash for autoflush every id
tie my %hash, 'String::Lookup',
  autoflush => 1,   # every new ID should flush
  flush     => $flush;
$ok_list= $foo;
$ok_todo= 1;
is( $hash{ \$foo }, 1, "first lookup/flush" );
$ok_list= $foobar;
$ok_todo= 2;
is( $hash{ \$bar }, 2, "second lookup/flush" );

# flush on scope exit without any autoflush
do {
    tie %hash, 'String::Lookup',
      autoflush => 0,   # deactivate autoflush
      flush     => $flush;
    $ok_list= $foobar;
    $ok_todo= "1,2";
    is( $hash{ \$foo }, 1, "first lookup" );
    is( $hash{ \$bar }, 2, "second lookup/flush" );
}; # should flush here

# autoflush every second ID
tie %hash, 'String::Lookup',
  autoflush => 2,   # every second new ID should flush
  flush     => $flush;
$ok_list= $foobar;
$ok_todo= "1,2";
is( $hash{ \$foo }, 1, "first lookup" );
is( $hash{ \$bar }, 2, "second lookup/flush" );

# flush on scope exit after 10 ID's
do {
    tie %hash, 'String::Lookup',
      autoflush => 10,   # every 10th new ID should flush
      flush     => $flush;
    $ok_list= $foobar;
    $ok_todo= "1,2";
    is( $hash{ \$foo }, 1, "first lookup" );
    is( $hash{ \$bar }, 2, "second lookup/flush" );
}; # should flush here

# set up the hash for autoflush every second
tie %hash, 'String::Lookup',
  autoflush => '1s',   # every second should flush
  flush     => $flush;
$ok_list= "SHOULD_NOT_FLUSH";
$ok_todo= "SHOULD_NOT_FLUSH";
is( $hash{ \$foo }, 1, "first lookup" );
sleep 2;
$ok_list= $foobar;
$ok_todo= "1,2";
is( $hash{ \$bar }, 2, "second lookup/flush" );
$ok_list= "SHOULD_NOT_FLUSH";
$ok_todo= "SHOULD_NOT_FLUSH";

# set up the hash without autoflush
tie %hash, 'String::Lookup',
  flush     => $flush;
$ok_list= "SHOULD_NOT_FLUSH";
$ok_todo= "SHOULD_NOT_FLUSH";
is( $hash{ \$foo }, 1, "first lookup" );
is( $hash{ \$bar }, 2, "second lookup/flush" );
$ok_list= $foobar;
$ok_todo= "1,2";
ok( ( tied %hash )->flush, 'specific flush' );
$ok_list= "SHOULD_NOT_FLUSH";
$ok_todo= "SHOULD_NOT_FLUSH";
