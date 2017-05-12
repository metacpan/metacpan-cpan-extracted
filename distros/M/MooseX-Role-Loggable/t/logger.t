#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 10;

{
    package Foo;
    use Moo;
    with 'MooseX::Role::Loggable';
}

{
    package Bar;
    use Moo;
    with 'MooseX::Role::Loggable';
    has '+logger_ident' => ( default => sub {'MyLogger'} );
}

my $foo = Foo->new;
isa_ok( $foo, 'Foo'    );
can_ok( $foo, 'logger' ),
isa_ok( $foo->logger, 'Log::Dispatchouli' );
is( $foo->logger_ident, 'Foo', 'correct ident' );

my $bar = Bar->new( log_file => 'logname' );
isa_ok( $bar, 'Bar'    );
can_ok( $bar, 'logger' );
isa_ok( $bar->logger, 'Log::Dispatchouli' );
is( $bar->logger_ident, 'MyLogger', 'Correct ident'    );
is( $bar->log_file,     'logname',  'Correct log_file' );
is( $bar->log_path,     undef,      'Correct log_path' );

