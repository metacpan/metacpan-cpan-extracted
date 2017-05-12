use t::Util;
use Test::More;

my $service = service();

my $title = join(' - ', 'test for folder', scalar localtime);

ok my $folder = $service->add_item(
    {
        title => $title,
        kind => 'folder',
    }
);

ok my $found = $service->item(
    { 
        title => $title,
        category => 'folder',
    },
);
is $found->id, $folder->id;
like $found->alternate, qr{^https?://.+\.google\.com/}, $found->alternate;

{
    my $subfolder_title = join(' - ', 'test for subfolder', scalar localtime);
    ok my $subfolder = $found->add_folder(
        {
            title => $subfolder_title,
        }
    );
    ok my $found_subfolder = $found->folder({title => $subfolder_title});

    my $doc_title =  join(' - ', 'test for move item', scalar localtime);
    my $doc = $found->add_item(
        {
            kind => 'document',
            title => $doc_title,
        }
    );
    ok my $found_doc = $found->item(
        {
            title => $doc_title,
            'title-exact' => 'true',
        }
    );
    is $found_doc->id, $doc->id;

    ok $doc->move_to($found_subfolder);
    ok my $moved_doc = $found_subfolder->item(
        {
            title => $doc_title,
            'title-exact' => 'true',
        }
    );
    is $moved_doc->id, $doc->id;

    $moved_doc->move_out_of($found_subfolder);

    ok ! $found_subfolder->item(
        {
            title => $moved_doc->title,
            'title-exact' => 'true',
        }
    );
    ok ! grep {$_->title eq $moved_doc->title} $found_subfolder->items;
    ok my $moved_again = $found->item(
        {
            title => $doc_title,
            'title-exact' => 'true',
        }
    );

    is $found, $moved_again->container;
    $moved_again->delete;

    ok $service->item(
        {
            title => $doc_title,
            category => 'trashed',
            'title-exact' => 'true',
        }
    );
}
$found->delete({delete => 'ture'});
ok ! $service->item(
    {
        title => $title,
        category => 'folder',
    }
);

{
    my $title = join(' - ', 'test for root folder', scalar localtime);
    ok my $doc = $service->add_item(
        {
            title => $title,
            kind => 'document',
        }
    );
    ok my $found = $service->root_item(
        {
            title => $title,
            'title-exact' => 'true',
            category => 'document',
        }
    );
    is $found->id, $doc->id;

    ok my @in_root = $service->root_items;
    ok grep {$_->id eq $doc->id} @in_root;
    ok $doc->delete({delete => 'true'});
    ok ! grep {$_->id eq $doc->id} $service->root_items;
}

done_testing;
