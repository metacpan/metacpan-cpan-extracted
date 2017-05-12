use strict;
use warnings;

use Test::Most;

use lib 't/lib';
use Silki::Test::RealSchema;

use Silki::Schema::Page;
use Silki::Schema::PageRevision;
use Silki::Schema::User;
use Silki::Schema::Wiki;

my $wiki = Silki::Schema::Wiki->new( short_name => 'first-wiki' );
my $user = Silki::Schema::User->GuestUser();

{
    my $page = Silki::Schema::Page->insert_with_content(
        title   => 'Some Page',
        content => 'This is a page with a link to a ((Pending Page))',
        user_id => $user->user_id(),
        wiki_id => $wiki->wiki_id(),
    );

    my $rev1     = $page->most_recent_revision();
    my $page_uri = $page->uri();

    is(
        $rev1->uri(),
        "$page_uri/revision/" . $rev1->revision_number(),
        'got expected uri for page revision'
    );

    my $html = <<'EOF';
<p>This is a page with a link to a <a href="/wiki/first-wiki/new_page_form?title=Pending+Page" class="new-page" title="This page has not yet been created">Pending Page</a>
</p>
EOF

    chomp $html;

    is(
        $rev1->content_as_html( user => $user ),
        $html,
        'content as html - most recent revision'
    );

    $page->add_revision(
        content => 'New content',
        user_id => $user->user_id(),
    );

    $rev1->_clear_page();

    is(
        $rev1->content_as_html( user => $user ),
        $html,
        'content as html - older revision'
    );

    is_deeply(
        $rev1->serialize(), {
            page_id         => $rev1->page_id(),
            revision_number => 1,
            content => 'This is a page with a link to a ((Pending Page))',
            user_id => $user->user_id(),
            creation_datetime => $rev1->creation_datetime_raw(),
            comment           => undef,
            is_restoration_of_revision_number => undef,
        },
        'serialize method'
    );
}

{
    my $content1 = <<'EOF';
This is a block.

And another block.

Last block here.
EOF

    my $page = Silki::Schema::Page->insert_with_content(
        title   => 'Diff and Purge Testing',
        content => $content1,
        user_id => $user->user_id(),
        wiki_id => $wiki->wiki_id(),
    );

    my $rev1 = $page->most_recent_revision();

    my $content2 = <<'EOF';
This is a block.

And another block.
EOF

    my $rev2 = $page->add_revision(
        content => $content2,
        user_id => $user->user_id(),
    );

    my $diff
        = Silki::Schema::PageRevision->Diff( rev1 => $rev1, rev2 => $rev2 );

    is_deeply(
        $diff,
        [
            [ 'u', 'This is a block.',   'This is a block.' ],
            [ 'u', 'And another block.', 'And another block.' ],
            [ '-', 'Last block here.',   q{} ],
        ],
        'diff for two revisions, removed one block'
    );

    my $content3 = <<'EOF';
This is a block.

And another block.

New block!
EOF

    my $rev3 = $page->add_revision(
        content => $content3,
        user_id => $user->user_id(),
    );

    $diff = Silki::Schema::PageRevision->Diff( rev1 => $rev1, rev2 => $rev3 );

    is_deeply(
        $diff,
        [
            [ 'u', 'This is a block.',   'This is a block.' ],
            [ 'u', 'And another block.', 'And another block.' ],
            [ 'c', 'Last block here.',   'New block!' ],
        ],
        'diff for two revisions, added a block and removed a block (looks like a change)'
    );

    $rev2->delete( user => $user );

    is(
        $page->revision_count(), 2,
        'page now has two revisions'
    );

    my $max_rev = $page->most_recent_revision();

    is(
        $max_rev->revision_number(), 2,
        'most recent revision is now revision 2'
    );
    is(
        $max_rev->content(), $content3,
        'revision 3 became revision 2'
    );

    $_->delete( user => $user ) for $page->revisions()->all();

    ok(
        !Silki::Schema::Page->new(
            title   => 'Diff and Purge Testing',
            wiki_id => $wiki->wiki_id(),
        ),
        'page is deleted once it has no revisions'
    );
}

{
    my $page1 = Silki::Schema::Page->insert_with_content(
        title   => 'Page 1',
        content => 'This is a random page with no links',
        user_id => $user->user_id(),
        wiki_id => $wiki->wiki_id(),
    );

    my $page2 = Silki::Schema::Page->insert_with_content(
        title   => 'Page 2',
        content => 'This is a random page with a link to ((Page 1))',
        user_id => $user->user_id(),
        wiki_id => $wiki->wiki_id(),
    );

    my $page3 = Silki::Schema::Page->insert_with_content(
        title   => 'Page 3',
        content => 'This is a random page with no links',
        user_id => $user->user_id(),
        wiki_id => $wiki->wiki_id(),
    );

    my @incoming = $page1->incoming_links()->all();

    is(
        @incoming, 1,
        'Page 1 has one incoming link'
    );
    is(
        $incoming[0]->title(), 'Page 2',
        'incoming link is from Page 2'
    );

    my $rev2 = $page2->add_revision(
        content => 'Now linking to ((Page 3))',
        user_id => $user->user_id(),
    );

    is(
        $page1->incoming_link_count(), 0,
        'Page 1 no longer has any incoming links'
    );

    @incoming = $page3->incoming_links()->all();

    is(
        @incoming, 1,
        'Page 3 has one incoming link'
    );
    is(
        $incoming[0]->title(), 'Page 2',
        'incoming link is from Page 2'
    );

    $rev2->delete( user => $user );

    is(
        $page3->incoming_link_count(), 0,
        'Page 3 no longer has any incoming links after deleting rev 2 of Page 2'
    );

    @incoming = $page1->incoming_links()->all();

    is(
        @incoming, 1,
        'Page 1 has one incoming link again'
    );
    is(
        $incoming[0]->title(), 'Page 2',
        'incoming link is from Page 2'
    );
}

done_testing();
