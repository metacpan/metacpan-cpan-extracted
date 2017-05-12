#!perl 
# vim: ft=perl ts=8 sw=4 sts=4 et 
use lib 't';
use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF3 qw(freeze thaw retrieve store nstore lock_store lock_nstore lock_retrieve);

eval "use Test::More tests=>18;";
warn $@ if $@;

my $a = { test => "Hello World\n\r \r\n" };

my $file = "t/56-test-amf3.tmp";
ok( store( $a, $file ) );
ok( -e $file,       "exists file" );
ok( retrieve $file, "retrieve ok" );
is_deeply( retrieve $file, $a, "retrieve ok deeply" );

ok( lock_retrieve $file, "lock_retrieve ok" );
is_deeply( lock_retrieve $file, $a, "lock_retrieve ok deeply" );

unlink $file or die "Can' t unlink $file: $!";

ok( nstore( $a, $file ) );
ok( -e $file,       "exists file" );
ok( retrieve $file, "retrieve ok nstore" );
is_deeply( retrieve $file, $a, "retrieve ok deeply nstore" );
unlink $file or die "Can't unlink $file: $!";

ok( lock_nstore( $a, $file ) );
ok( -e $file,       "exists file" );
ok( retrieve $file, "retrieve ok lock_nstore" );
is_deeply( retrieve $file, $a, "retrieve ok deeply lock_nstore" );
unlink $file or die "Can't unlink $file: $!";

ok( lock_store( $a, $file ) );
ok( -e $file,       "exists file" );
ok( retrieve $file, "retrieve ok lock_store" );
is_deeply( retrieve $file, $a, "retrieve ok deeply lock_store" );
unlink $file or warn "Can't unlink $file: $!";
