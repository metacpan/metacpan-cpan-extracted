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

plan tests => (Moose->VERSION >= 1.05 ? 19 : 18);

use_ok 'Test::Builder::Mock::Class', ':all';

eval {
    isa_ok( mock_class( 'IO::File' => 'IO::File::Mock' ), 'Test::Builder::Mock::Class', 'mock_class' );
    IO::File::Mock->meta->add_mock_method('BUILDALL');

    isa_ok( my $io = IO::File::Mock->new, 'IO::File::Mock', '$io' );
    does_ok( $io, 'Test::Builder::Mock::Class::Role::Object', '$io does Test::Builder::Mock::Class::Role::Object' );

    is( $io->mock_return( open => TRUE, args => [qr//, 'r'] ), $io, '$io->mock_return [1]' );
    is( $io->mock_return( open => undef, args => [qr//, 'w'] ), $io, '$io->mock_return [2]' );
    is( $io->mock_return_at( 0, getline => 'root:x:0:0:root:/root:/bin/bash' ), $io, '$io->mock_return_at' );
    is( $io->mock_expect_never( 'close' ), $io, '$io->mock_expect_never' );

    # ok
    ok( $io->open('/etc/passwd', 'r'), '$io->open [1]' );

    # first line
    like( $io->getline, qr/^root:[^:]*:0:0:/, '$io->getline [1]' );

    # eof
    is( $io->getline, undef, '$io->getline [2]' );

    # access denied
    ok( ! $io->open('/etc/passwd', 'w'), '$io->open [2]' );

    # close was not called
    $io->mock_tally;
};
if ($@) {
    BAIL_OUT($@);
};
