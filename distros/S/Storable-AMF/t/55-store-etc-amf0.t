#!perl 
# vim: ts=8 et sw=4 sts=4
use lib 't';
use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF0 qw(freeze thaw retrieve store nstore lock_store lock_nstore lock_retrieve);
use Storable::AMF3 qw();
use Fcntl qw(LOCK_SH LOCK_EX LOCK_UN);
use Time::HiRes qw(sleep);
use Config;

eval "use Test::More tests=>20;";
warn $@ if $@;

my $a = { test => "Hello World\n\r \r\n" };

my $file = "t/55-test-amf0.tmp";
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

check_lock( \&Storable::AMF0::store, \&Storable::AMF0::retrieve, \&Storable::AMF0::lock_store );
check_lock( \&Storable::AMF3::store, \&Storable::AMF3::retrieve, \&Storable::AMF3::lock_store );

# cleanup
unlink $file or warn "Can't unlink $file: $!";

sub check_lock {
    my ( $store, $retrieve, $lock_store ) = @_;
    my @pmain;
    no warnings 'redefine';
    local *store      = $store;
    local *retrieve   = $retrieve;
    local *lock_store = $lock_store;
    use warnings 'redefine';
    my @pchld;
    pipe $pmain[0], $pmain[1];
    pipe $pchld[0], $pchld[1];
    select( ( ( select $pmain[1] ), $| = 1 )[0] );
    select( ( ( select $pchld[1] ), $| = 1 )[0] );

    umask 0077;
    if ( $Config{osname} =~ m/Win32/i ) {
        ok( 1, "Win32 skipped" );
    }
    elsif ( my $pid = fork ) {
        open my $fh, ">", $file;
        flock $fh, LOCK_SH;
        store( $a, $file );
        print { $pchld[1] } "start\n";
        sysread $pmain[0], $b, 6;

        sleep(0.25);
        local $@;
        ok( defined( eval { retrieve($file) } ), "lockfree" );
        print STDERR "$@\n" if $@;
        close($fh);

        waitpid $pid, 0;
    }
    elsif ( defined $pid ) {
        sysread $pchld[0], $b, 6;
        print { $pmain[1] } "cont0\n";
        lock_store( $a, $file );
        exit 0;
    }
    else {
        ok( 1, "skipped" );
        1;
    }
}

