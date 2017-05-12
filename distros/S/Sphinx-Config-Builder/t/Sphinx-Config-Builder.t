use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok( 'Sphinx::Config::Builder', q{Loading Sphinx::Config::Builder} );
}

my $builder = new_ok q{Sphinx::Config::Builder};

can_ok( $builder,
    qw/new push_index pop_index push_source pop_source index_list source_list indexer searchd as_string/
);

my $index = new_ok q{Sphinx::Config::Entry::Index};
can_ok( $index, qw/new as_string name kv_push kv_pop/ );

my $source = new_ok q{Sphinx::Config::Entry::Source};
can_ok( $source, qw/new as_string name kv_push kv_pop/ );

my $indexer = new_ok q{Sphinx::Config::Entry::Indexer};

my $searchd = new_ok q{Sphinx::Config::Entry::Searchd};

isa_ok( $builder->indexer, q{Sphinx::Config::Entry::Indexer} );

isa_ok( $builder->searchd, q{Sphinx::Config::Entry::Searchd} );

ok( ref $builder->index_list eq q{ARRAY}, q{Index list is array ref} );

ok( ref $builder->source_list eq q{ARRAY}, q{Source list is array ref} );

my $INDEXPATH = q{/path/to/indexes};
my $XMLPATH   = q{/path/to/xmlpipe2/output};

$builder = Sphinx::Config::Builder->new();

# %categories may be stored elsewhere, e.g. a .ini file or MySQL database
my $categories =
  { cars => [qw/sedan truck ragtop/], boats => [qw/sail row motor/] };
foreach my $category ( keys %$categories ) {
    foreach my $document_set ( @{ $categories->{$category} } ) {
        my $xmlfile     = qq{$document_set-$category} . q{.xml};
        my $source_name = qq{$document_set-$category} . q{_xml};
        my $index_name  = qq{$document_set-$category};
        my $src         = new_ok q{Sphinx::Config::Entry::Source};
        my $index       = new_ok q{Sphinx::Config::Entry::Index};

        ok $src->name($source_name), q{Set source name};
        ok $src->kv_push(
            { type            => q{xmlpipe} },
            { xmlpipe_command => qq{/bin/cat $XMLPATH/$xmlfile} },
          ),
          q{Add key/value pairs to source};

        ok $builder->push_source($src), q{Add source to Source list};

        ok $index->name($index_name), q{Set index name};
        ok $index->kv_push(
            { source       => qq{$source_name} },
            { path         => qq{$INDEXPATH/$document_set} },
            { charset_type => q{utf-8} },
          ),
          q{Add key/value pairs to index};

        ok $builder->push_index($index), q{Add index to Index list};
    }
}
ok $builder->indexer->kv_push( { mem_limit => q{64m} } ),
  q{Adding key/value pairs to indexer};
ok $builder->searchd->kv_push(
    { compat_sphinxql_magics => 0 },
    { listen                 => q{192.168.0.41:9312} },
    { listen                 => q{192.168.0.41:9306:mysql41} },
    { log                    => q{/var/log/sphinx/searchd.log} },
    { query_log              => q{/var/log/sphinx/log/query.log} },
    { read_timeout           => 30 },
    { max_children           => 30 },
    { pid_file               => q{/var/log/sphinx/searchd.pid} },
    { seamless_rotate        => 1 },
    { preopen_indexes        => 1 },
    { unlink_old             => 1 },
    { workers     => q{threads} },           # for RT to work
    { binlog_path => q{/var/log/sphinx} },
  ),
  q{Adding key/value pairs to searchd};

foreach my $s ( @{ $builder->source_list() } ) {
    isa_ok $s, q{Sphinx::Config::Entry};
    isa_ok $s, q{Sphinx::Config::Entry::Source};
    ok $s->as_string() ne q{}, q{Ensuring $source->as_string() is not empty};
}

foreach my $i ( @{ $builder->index_list() } ) {
    isa_ok $i, q{Sphinx::Config::Entry};
    isa_ok $i, q{Sphinx::Config::Entry::Index};
    ok $i->as_string() ne q{}, q{Ensuring $index->as_string() is not empty};
}

ok $builder->indexer->as_string() ne q{},
  q{Ensuring $builder->indexer->as_string() is not empty};

ok $builder->searchd->as_string() ne q{},
  q{Ensuring $builder->searchd->as_string() is not empty};

ok $builder->as_string() ne q{}, q{Ensuring $builder->as_string() is not empty};

while (my $s = $builder->pop_source()) {
    isa_ok $s, q{Sphinx::Config::Entry};
    isa_ok $s, q{Sphinx::Config::Entry::Source};
    foreach my $kv_pair ($s->kv_pop()) {
       ok ref $kv_pair eq q{HASH}, q{source's kv_pop'd item is a HASH ref}; 
    }
}

while (my $i = $builder->pop_index()) {
    isa_ok $i, q{Sphinx::Config::Entry};
    isa_ok $i, q{Sphinx::Config::Entry::Index};
    foreach my $kv_pair ($i->kv_pop()) {
       ok ref $kv_pair eq q{HASH}, q{index's kv_pop'd item is a HASH ref}; 
    }
}

done_testing();
