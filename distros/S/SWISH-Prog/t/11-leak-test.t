use strict;
use warnings;
use constant HAS_LEAKTRACE => eval { require Test::LeakTrace };
use Test::More HAS_LEAKTRACE
    ? ( tests => 3 )
    : ( skip_all => 'require Test::LeakTrace' );
use Test::LeakTrace;
use Data::Dump qw( dump );

#use Devel::LeakGuard::Object qw( GLOBAL_bless :at_end leakguard );

use_ok('SWISH::Prog');
use_ok('SWISH::Prog::Native::Indexer');

SKIP: {

    # is executable present?
    my $indexer = SWISH::Prog::Native::Indexer->new;
    my $version = $indexer->swish_check;
    if ( !$version ) {
        skip "swish-e not installed", 1;
    }

    diag("$version installed");

SKIP: {

        unless ( $ENV{TEST_LEAKS} ) {
            skip "set TEST_LEAKS to test memory leaks", 1;
        }

        leaks_cmp_ok {
            my $program = SWISH::Prog->new(
                invindex   => 't/testindex',
                aggregator => 'fs',
                indexer    => 'native',
                config     => 't/test.conf',
                filter     => sub { diag( "doc filter on " . $_[0]->url ) },
            );

            # skip our local config test files
            $program->config->FileRules('dirname contains config');

            $program->run('t/');

            # clean up header so other test counts work
            unlink('t/testindex/swish.xml') unless $ENV{PERL_DEBUG};

        }
        '<=', 2;    # 2 outside our control
    }

}
