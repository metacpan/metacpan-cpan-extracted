#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 9;

# catching carp()
local $SIG{'__WARN__'} = sub {
    my $msg = shift;
    ::like(
        $msg,
        qr/\Qlog_fields() is deprecated\E/,
        'Correct dep warning to carp',
    );
};

{
    package Foo;
    use Moo;
    with 'MooseX::Role::Loggable';
    # override log()
    sub log {
        my ( $class, $args, $msg ) = @_;
        ::isa_ok( $class, 'Foo'  );
        ::isa_ok( $args,  'HASH' );
        ::is_deeply( $args, { level => 'warning' }, 'Correct args to log' );
        ::like(
            $msg,
            qr/\Qlog_fields() is deprecated\E/,
            'Correct dep warning',
        );
    }

}

my $foo = Foo->new();
isa_ok( $foo, 'Foo'        );
can_ok( $foo, 'log_fields' );
my ( $key, $logger ) = $foo->log_fields;
is( $key, 'logger', 'Logger key returned' );
isa_ok( $logger, 'Log::Dispatchouli' );
