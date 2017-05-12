use strict;
use warnings;
use Test::More tests => 7;
use lib 't/lib';
use MyTestHelpers;

use_ok('Rose::DBx::Object::Indexed');

SKIP: {

    # is executable present?
    eval { require SWISH::Prog::Native::Indexer; };
    if ($@) {
        skip "SWISH::Prog::Native::Indexer required to test Native features",
            6;
    }
    my $test = SWISH::Prog::Native::Indexer->new;
    my $swish_version = $test->swish_check;
    if ( !$swish_version ) {
        skip "swish-e not installed", 6;
    }
    elsif ( $swish_version =~ m/^2\.[45]/ ) {
        skip "swish-e with incremental index support required (BDB or 2.4/5 with --build-incremental)", 6;
    }

    # create a temp db
    ok( my $db = MyTestHelpers->new_db(), "new RDB object" );

    {

        package NativeIndexer;
        @NativeIndexer::ISA = qw( Rose::DBx::Object::Indexed::Indexer );
        sub init_invindex      {'t/test.index'}
        sub init_indexer_class {'SWISH::Prog::Native::Indexer'}
    }

    END {

        # clean up after ourselves
        unless ( $ENV{PERL_DEBUG} ) {
            Path::Class::dir( 't', 'test.index' )->rmtree;
        }
    }

    # monkeypatch our main indexed class to allow it to be indexed.
    sub MyTest::Product::index_eligible     {1}
    sub MyTest::Product::init_indexer_class {'NativeIndexer'}

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
