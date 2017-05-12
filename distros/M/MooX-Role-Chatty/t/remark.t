#!/usr/bin/env perl

use Test::More;

package My::Test::Logger::Like_Log4perl;
use Moo;
my $Message_via_l4plike;
sub info { $Message_via_l4plike = $_[1]; }
sub warn { $Message_via_l4plike = $_[1]; }

package My::Test;
use Moo;
with 'MooX::Role::Chatty';

package main;

my $Warned;
$SIG{__WARN__} = sub { $Warned = shift; };

my $c = My::Test->new( verbose => 1 );

SKIP: {
    skip 'Log::Any::Adapter::Carp not installed', 5
      unless eval { require Log::Any::Adapter::Carp };

    $c->remark('Logged');
    like( $Warned, qr/\d{4}-.+:: Logged/, 'Default logger repeats remark' );

    undef $Warned;
    $c->verbose(0);
    $c->remark('Not Logged');
    ok( !defined $Warned, "Remark respects verbosity of 0" );

    $c->verbose(1);

    undef $Warned;
    $c->remark( { level => 1, message => 'Logged' } );
    like(
        $Warned,
        qr/\d{4}-.+:: Logged/,
        'Remark logs at explicit level when appropriate'
    );

    undef $Warned;
    $c->remark( { level => 2, message => 'Not Logged' } );
    ok( !defined $Warned, ". . . and doesn't when it's not" );

    undef $Warned;
    $c->remark( [ 'Logged %d %s', 1, 'thing' ] );
    like(
        $Warned,
        qr/\d{4}-.+:: Logged 1 thing/,
        "Arrayref of arguments handled"
    );

}

$c->verbose(0);

undef $Warned;
$c->remark( { level => 0, message => 'Not Logged' } );
ok( !defined $Warned, "Explicit level respects verbosity of 0" );

undef $Warned;
$c->remark( { level => -5, message => 'Not logged' } );
ok( !defined $Warned, ". . . even at high priority levels" );

$c->verbose(1);

undef $Message_via_l4plike;
$c->logger( My::Test::Logger::Like_Log4perl->new );
$c->remark('Logged');
is( $Message_via_l4plike, 'Logged', 'Log4perl-like logger remarks' );

undef $Message_via_l4plike;
$c->remark( [ 'Logged %d %s', 1, 'thing' ] );
is(
    $Message_via_l4plike,
    'Logged 1 thing',
    'Arrayref of arguments formatted for Log4perl-like logger'
);

done_testing;
