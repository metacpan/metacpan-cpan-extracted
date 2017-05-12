use t::Util;
use Test::More;

ok my $service = service();

for my $kind (qw(document spreadsheet presentation )) {
    my $title = join('-', 'test for N::G::DL', $kind, scalar localtime);

    ok my $d = $service->add_item(
        {
            title => $title,
            kind => $kind,
        }
    ), "creating $kind";

    ok my $found = $service->item({title => $title, 'title-exact' => 'true'});
    like $found->alternate, qr{^https?://.+\.google\.com/}, $found->alternate;
    is $found->id, $d->id;
    is $found->etag, $d->etag;

    ok my $by_resource_id = $service->item({resource_id => $d->resource_id});
    is $by_resource_id->id, $d->id;
    is $by_resource_id->etag, $d->etag;
    is $by_resource_id->resource_id, $d->resource_id;

    ok my $cat_found = $service->item(
        {
            title => $title, 
            'title-exact' => 'true',
            category => $kind,
        }
    );
    is $cat_found->id, $d->id;
    is $cat_found->etag, $d->etag;

    my $updated_title = join('-', 'update title', scalar localtime);
    ok my $old_etag = $d->etag;
    ok $d->title($updated_title);
    is $d->title, $updated_title;
    isnt $d->etag, $old_etag;

    ok my $updated = $service->item({title => $updated_title, 'title-exact' => 'true'});
    is $updated->title, $updated_title;
    is $updated->id, $d->id;
    is $updated->etag, $d->etag;

    ok $d->delete, 'trash';

#    ok my $d1 = $service->item({title => $updated_title, 'title-exact' => 'true'});
#    is $d1->deleted, 1;

    ok my $trashed = $service->item(
        {
            title => $updated_title,
            'title-exact' => 'true',
            category => [$kind, 'trashed'],
        }
    ), 'find trashed item';
    is $trashed->deleted, 1;

    ok $trashed->delete({delete => 1}), 'delete';
    ok ! $service->item(
        {
            title => $updated_title, 
            'title-exact' => 'true',
            category => $kind,
        }
    );
    ok ! $service->item(
        {
            title => $updated_title, 
            'title-exact' => 'true',
            category => [$kind, 'trashed'],
        }
    );
}

done_testing;
