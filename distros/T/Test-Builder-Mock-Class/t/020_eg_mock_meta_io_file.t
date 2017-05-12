#!/usr/bin/perl

use strict;
use warnings;

use Carp ();

$SIG{__WARN__} = sub { local $Carp::CarpLevel = 1; Carp::confess("Warning: ", @_) };

use Test::More;
use Test::Moose;

use constant::boolean;

require IO::File;
require Moose;

plan tests => (Moose->VERSION >= 1.05 ? 17 : 16);

use_ok 'Test::Builder::Mock::Class', ':all';

eval {
    isa_ok( my $mock = mock_anon_class( 'IO::File' ), 'Test::Builder::Mock::Class', 'mock_anon_class' );

    does_ok( my $io = $mock->new_object, 'Test::Builder::Mock::Class::Role::Object', '$io does Test::Builder::Mock::Class::Role::Object' );

    is( $io->mock_return( open => TRUE, args => [qr//, 'r'] ), $io, '$io->mock_return [1]' );
    is( $io->mock_return( open => undef, args => [qr//, 'w'] ), $io, '$io->mock_return [2]' );
    is( $io->mock_return_at( 0, getline => 'root:x:0:0:root:/root:/bin/bash' ), $io, '$io->mock_return_at' );
    is( $io->mock_expect_never( 'close' ), $io, '$io->mock_expect_never' );
    
    # ok
    ok( $io->open('/etc/passwd', 'r'), '$io->open' );
    
    # first line
    like( $io->getline, qr/^root:[^:]*:0:0:/, '$io->getline' );
    
    # eof
    is( $io->getline, undef, '$io->getline' );
    
    # access denied
    ok( ! $io->open('/etc/passwd', 'w'), '$io->open' );
    
    # close was not called
    $io->mock_tally;
};
if ($@) {
    BAIL_OUT($@);
};
