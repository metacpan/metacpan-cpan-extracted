use strict;
use Test::More;
use Test::Exception;

BEGIN
{
    

    if ( ! $ENV{KEYEDMUTEXD}) {
        my $default = '/tmp/keyedmutexd.sock';
        if (-S $default) {
            $ENV{KEYEDMUTEXD} = $default;
        }
    }

    if (! $ENV{KEYEDMUTEXD}) {
        plan( skip_all => "Define KEYEDMUTEXD to run this test" );
    } else {
        plan( tests => 10 );
    }

    use_ok("MooseX::KeyedMutex");
}

package MyClass;
use Moose;

with 'MooseX::KeyedMutex';

package main;

{
    my $obj = MyClass->new(
        mutex => {
            args => {
                sock => $ENV{KEYEDMUTEXD}
            }
        }
    );

    can_ok($obj, qw(lock));

    my $lock;
    $lock = $obj->lock("foo");
    ok( $lock, "lock() returned" );
    isa_ok( $lock, "KeyedMutex::Lock");
}

{
    throws_ok(sub {
        MyClass->new( 
         mutex => {
                args => {
                    sock => "/non-existent/directory/that/shouldnt/contain/keyedmutexd.sock"
                }
            }
        )
    }, qr/failed to connect to keyedmutexd/, 'bad sock should die');
}

{
    my $obj = MyClass->new(mutex => undef);
    ok($obj);

    my $lock = $obj->lock("foo");
    ok( $lock, "lock() returned");
    is( $lock, '0E0' );
}

{
    my $obj = MyClass->new(mutex => undef, mutex_required => 1);
    ok($obj);

    throws_ok( sub { $obj->lock("foo") }, qr/No mutex object provided, and mutex_required is on/, "mutex_required works");
}
