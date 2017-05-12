use strict;
use warnings;
use Test::More tests => 8;
use lib 't/lib';
use MyTestHelpers;

use_ok('Rose::DBx::Object::Indexed');
use_ok('Rose::DBx::Object::Indexed::Indexer::KSx');

SKIP: {
    eval { require SWISH::Prog::KSx };
    if ($@) {
        skip "SWISH::Prog::KSx required for KSx Indexer tests", 6;
    }

    # create a temp db
    ok( my $db = MyTestHelpers->new_db(), "new RDB object" );

    {

        package KSIndexer;
        @KSIndexer::ISA = qw( Rose::DBx::Object::Indexed::Indexer::KSx );
        sub init_invindex      {'t/test.index'}
        sub init_indexer_class {'SWISH::Prog::KSx::Indexer'}
    }

    END {

        # clean up after ourselves
        unless ( $ENV{PERL_DEBUG} ) {
            Path::Class::dir( 't', 'test.index' )->rmtree;
        }
    }

    # monkeypatch our main indexed class to allow it to be indexed.
    sub MyTest::Product::index_eligible     {1}
    sub MyTest::Product::init_indexer_class {'KSIndexer'}

    # create some data

    ok( my $product = MyTest::Product->new( name => 'Sled', db => $db ),
        "new product" );
    ok( $product->vendor( name => 'Acme' ), "set vendor" );
    ok( $product->prices(
            { price => 1.23, region => 'US' },
            { price => 4.56, region => 'UK' }
        ),
        "set prices"
    );
    ok( $product->colors( { name => 'red' }, { name => 'green' } ),
        "set colors" );

    ok( $product->save, "write to index and db" );

}    # end SKIP
