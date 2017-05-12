use strict;
use warnings;

use Test::Most 'no_plan';

use Package::Pkg;
use Package::Pkg::Lexicon;

my ( $lexicon );

$lexicon = Package::Pkg::Lexicon->new;

ok( $lexicon );

my $apple = sub { 'apple' };
my $banana = sub { 'banana' };
my $cherry = sub { 'cherry' };
my $grape = sub { 'grape' };

$lexicon->add( apple => $apple, banana => $banana );
is( scalar $lexicon->get, 2 );
cmp_deeply( { $lexicon->copy->prefix( '' )->export }, { _apple => $apple, _banana => $banana } );
cmp_deeply( { $lexicon->copy->prefix( 'prefix' )->export },
    { prefix_apple => $apple, prefix_banana => $banana } );

$lexicon->add( cherry => $cherry, grape => $grape );
is( scalar $lexicon->get, 4 );
cmp_deeply( { $lexicon->copy->prefix( '' )->slice },
    { apple => $apple, banana => $banana, cherry => $cherry, grape => $grape } );

{
    my $lexicon = $lexicon->copy->remove(qw/ apple grape /);
    cmp_deeply( { $lexicon->copy->prefix( '' )->slice },
        { banana => $banana, cherry => $cherry } );
}

cmp_deeply( { $lexicon->copy->prefix( '' )->prefix( undef )->slice },
    { apple => $apple, banana => $banana, cherry => $cherry, grape => $grape } );

$lexicon = pkg->lexicon;
cmp_deeply( { $lexicon->export }, {} );

$lexicon = pkg->lexicon(
    apple => $apple, banana => $banana, cherry => $cherry, grape => $grape );
cmp_deeply( { $lexicon->export }, 
    { apple => $apple, banana => $banana, cherry => $cherry, grape => $grape } );
