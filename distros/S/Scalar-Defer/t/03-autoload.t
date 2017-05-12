use strict;
use warnings;
use Test::More;

eval { require IO::Capture::Stderr };
plan skip_all => 'this test requires IO::Capture::Stderr' if $@;

plan tests => 1;

local $UNIVERSAL::{AUTOLOAD} = 1;

my $capture = IO::Capture::Stderr->new;
$capture->start;
eval { require Scalar::Defer };
$capture->stop;
my $output = $capture->read || '';

unlike $output => qr/Subroutine AUTOLOAD redefined/, 'no warning';


