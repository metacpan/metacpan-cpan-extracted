use v5.40.0;
use common::sense;
use feature 'signatures';
use Test::More;
use lib 'lib';

use_ok( 'Mojo::PrettyTidy' );

my $pt = new_ok( 'Mojo::PrettyTidy' );
can_ok( $pt, qw(tidy check) );

done_testing;
