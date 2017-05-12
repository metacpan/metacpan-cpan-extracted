#!perl

use Test::More;
use Test::Exception;
use strict;
use warnings;
our $es;
my $r;

# version 0.16 is sometimes failing when creating a new index during
# bulk indexing.

$es->create_index( index => 'es_test_3' );
wait_for_es();

ok $es->reindex(
    source => $es->scrolled_search(
        index       => 'es_test_1',
        search_type => 'scan',
        version     => 1,
        scroll      => '2m'
    ),
    dest_index => 'es_test_3',
    transform  => sub {
        my $doc = shift;
        return if $doc->{_id} > 10;
        $doc->{_source}{num} += 1000;
        return $doc;
    }
    ),
    'Reindex';

wait_for_es();

$r = $es->search(
    index   => 'es_test_3',
    version => 1,
    sort    => { num => 'desc' }
);

my $first = $r->{hits}{hits}[0];
is $r->{hits}{total},      6,    ' - skip docs';
is $first->{_source}{num}, 1011, ' - transform';
is $first->{_version}, 1, ' - version';

throws_ok sub {
    $es->reindex(
        source => $es->scrolled_search(
            index       => 'es_test_1',
            search_type => 'scan',
            version     => 1,
            scroll      => '2m'
        ),
        dest_index => 'es_test_3'
    );
}, qr/VersionConflictEngineException/, 'Reindexing version conflicts';

ok $es->reindex(
    source => $es->scrolled_search(
        index       => 'es_test_1',
        search_type => 'scan',
        version     => 1,
        scroll      => '2m'
    ),
    dest_index  => 'es_test_3',
    on_conflict => 'IGNORE'
    ),
    'Reindexing ignore version conflicts';

1;
