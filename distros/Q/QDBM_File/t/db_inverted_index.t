#!perl -w

# QDBM_File::InvertedIndex test script

use strict;
use Test::More tests => 36;
use Fcntl;
use File::Path;
use File::Spec;

BEGIN {
    use_ok('QDBM_File');
}

my $class = 'QDBM_File::InvertedIndex';
my $tempdir = "t/db_inverted_index_temp";
mkpath($tempdir);
my $tempfile = File::Spec->catfile($tempdir, "db_inverted_index_test");

END {
    rmtree($tempdir);
}

my $db = $class->new($tempfile, O_RDWR|O_CREAT);
isa_ok($db, $class);

my $uri = "http://invertedtest.tmp/test.txt";

my $doc = $class->create_document($uri);
isa_ok($doc, "QDBM_File::InvertedIndex::Document");

$doc->set_attribute("test_attr", "testing");
is( $doc->get_attribute("test_attr"), "testing" );

my @words = $class->analyze_text("There is more than one way to do it.");

for my $word (@words) {
    my $normal = $class->normalize_word($word);
    $doc->add_word($normal, $word);
}

ok( $db->store_document($doc) );
ok( $db->exists_document_by_uri($uri) );

my $doc2 = $db->get_document_by_uri($uri);
isa_ok($doc2, "QDBM_File::InvertedIndex::Document");

my $doc2_id = $doc2->get_id();

ok($doc2_id);
ok( $db->exists_document_by_id($doc2_id) );
is( $doc2->get_attribute("test_attr"), "testing" );

my $doc2_id2 = $db->get_document_id($uri);
ok($doc2_id2);
is($doc2_id2, $doc2_id);

my @nwords = $doc2->get_normalized_words();
is( scalar(@nwords), 9 );
my @awords = $doc2->get_appearance_words();
is( scalar(@awords), 9 );

my @doc_id = $db->search_document("way", 1);
is( scalar(@doc_id), 1 );
is( $doc_id[0], $doc2_id );

my @doc_id2 = $db->search_document("foo", 1);
is( scalar(@doc_id2), 0 );

is( $db->search_document_count("more"), 1 );

ok( $db->init_iterator() );
my $doc3 = $db->get_next_document();
isa_ok($doc3, "QDBM_File::InvertedIndex::Document");
is( $doc3->get_id(), $doc->get_id() );

my @doc_id3 = $db->query("There | more");
is( scalar(@doc_id3), 1 );
is( $doc_id3[0], $doc->get_id() );

my @doc_id4 = $db->query("There & foo");
is( scalar(@doc_id4), 0 );

ok( $db->sync() );
ok( $db->optimize() );
ok( $db->get_name =~ /db_inverted_index_test/ );
ok( 0 < $db->get_size() );
ok( 0 < $db->count_documents() );
ok( 0 < $db->count_words() );
ok( $db->is_writable() );
ok( !$db->is_fatal_error() );
ok( $db->get_mtime() );

my $uri2 = "http://invertedtest.tmp/test2.txt";
my $doc4 = $class->create_document($uri2);

my @words2 = $class->analyze_text("This is a pen.");

for my $word (@words2) {
    my $normal = $class->normalize_word($word);
    $doc4->add_word($normal, $word);
}

$db->store_document($doc4);
my $doc5 = $db->get_document_by_uri($uri2);
ok($doc5);

my %scores = $db->get_scores($doc5, 4);

is( scalar( keys %scores ), 4 );
is( scalar( values %scores ), 4 );

undef $db;
