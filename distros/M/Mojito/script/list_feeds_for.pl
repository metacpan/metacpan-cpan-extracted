#!/usr/bin/env perl
use Mojito::Model::DB;
use 5.010;

my $feed = $ARGV[0] || 'ironman';

my $db = Mojito::Model::DB->new;
my $feed_docs = $db->collection->find({feeds => $feed})->sort( { last_modified => -1 } );
while (my $doc = $feed_docs->next) {
    say "Title: $doc->{title};  id: $doc->{'_id'}";
}
