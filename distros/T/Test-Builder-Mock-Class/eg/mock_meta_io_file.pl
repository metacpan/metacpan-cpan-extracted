#!/usr/bin/perl

use lib 'lib', '../lib';

use strict;
use warnings;

use Moose 1.05 ();

use Test::More tests => 10;

use constant::boolean;
use Test::Builder::Mock::Class ':all';

require IO::File;

mock_class 'IO::File' => 'IO::File::Mock';

my $mock = mock_anon_class 'IO::File';
my $io = $mock->new_object;
$io->mock_return( open => TRUE, args => [qr//, 'r'] );
$io->mock_return( open => undef, args => [qr//, 'w'] );
$io->mock_return_at( 0, getline => 'root:x:0:0:root:/root:/bin/bash' );
$io->mock_expect_never( 'close' );

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
