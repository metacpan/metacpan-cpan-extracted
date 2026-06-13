use v5.40.0;
use common::sense;
use feature 'signatures';

use Test::More;
use lib 'lib';
use Mojo::PrettyTidy;

my $pt = Mojo::PrettyTidy->new;

isa_ok( $pt, 'Mojo::PrettyTidy' );
can_ok( $pt, qw(tidy check) );

is( $pt->tidy( undef ), '', 'undef input returns empty string' );
is( $pt->tidy( '' ),    '', 'empty input returns empty string' );

my $html  = "<div><span>alpha</span></div>\n";
my $once  = $pt->tidy( $html );
my $twice = $pt->tidy( $once );

is( $twice, $once, 'tidy output is stable when tidied again' );

ok( $pt->check( $once ), 'check returns true for already-tidied output' );

ok( !$pt->check( $html ),
    'check returns false when tidy output would change', );

done_testing;
