use utf8;
use t::Util;
use Test::More;

my $service = service();

ok my $metadata = $service->metadata;
ok my $cs = $metadata->largest_changestamp;

{
    my @changes = $service->changes({'max-results' => 10});

}

ok my @last = $service->changes({'start-index' => $cs, 'max-results' => 5});
is scalar @last, 1;
ok ! $service->changes({'start-index' => $cs + 1, 'max-results' => 5});

ok my $doc = $service->add_item({title => 'test for changes'.localtime, kind => 'document'});

{
    ok my @changes = $service->changes({'start-index' => $cs + 1});
    is scalar @changes, 1;
    ok my $last_changed_item = $changes[0]->item;
    is $last_changed_item->resource_id, $changes[0]->resource_id;
    is $last_changed_item->resource_id, $doc->resource_id;
    ok $changes[0]->changestamp > $cs;
}

ok $doc->title('title change '.$doc->title);

{
    ok my $change = $service->change({'start-index' => $cs + 2, 'max-results' => 1});
    is $change->resource_id, $doc->resource_id;
    ok ! $change->deleted;
}


ok $doc->delete;

{
    ok my $change = $service->change({'start-index' => $cs + 3, 'max-results' => 1});
    is $change->resource_id, $doc->resource_id;
    ok $change->deleted;
}

ok $doc->delete({delete => 1});

{
    ok my $change = $service->change({'start-index' => $cs + 4, 'max-results' => 1});
    like $change->resource_id, qr/^unknown:/;
    ok ! $change->deleted;
    ok $change->removed;
}

done_testing;
