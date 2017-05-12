use strict;
use warnings;

use Test::Most;

use lib 't/lib';
use Silki::Test::RealSchema;

use DateTime;
use DateTime::Format::Pg;
use Lingua::EN::Inflect qw( PL_N );
use Silki::Schema::Account;
use Silki::Schema::Domain;
use Silki::Schema::Role;
use Silki::Schema::User;
use Silki::Schema::Wiki;

my $account = Silki::Schema::Account->new( name => 'Default Account' );
my $user = Silki::Schema::User->SystemUser();

{
    is(
        Silki::Schema::Wiki->PublicWikiCount(),
        1,
        'there is one public wiki'
    );

    my $wiki = Silki::Schema::Wiki->insert(
        title      => 'Public',
        short_name => 'public',
        domain_id  => Silki::Schema::Domain->DefaultDomain()->domain_id(),
        account_id => $account->account_id(),
        user       => $user,
    );

    $wiki->set_permissions('public');

    is(
        Silki::Schema::Wiki->PublicWikiCount(),
        2,
        'there are two public wikis'
    );

    my @wikis = Silki::Schema::Wiki->PublicWikis()->all();

    is_deeply(
        [ sort map { $_->title() } @wikis ],
        [ 'First Wiki', 'Public' ],
        'got expected set of public wikis'
    );
}

{
    is( Silki::Schema::Wiki->Count(), 4, 'Count finds 4 wikis' );

    my @wikis = Silki::Schema::Wiki->All()->all();

    is_deeply(
        [ sort map { $_->title() } @wikis ],
        [ 'First Wiki', 'Public', 'Second Wiki', 'Third Wiki' ],
        'All returns all wikis'
    );
}

{
    my $wiki = Silki::Schema::Wiki->new( title => 'First Wiki' );

    is(
        $wiki->uri(), "/wiki/first-wiki",
        'uri for wiki'
    );

    my $domain = Silki::Schema::Domain->DefaultDomain();

    my $hostname = $domain->web_hostname();

    is(
        $wiki->uri( with_host => 1 ), "http://$hostname/wiki/first-wiki",
        'uri with host for wiki'
    );

    my @pages = $wiki->pages()->all();

    is(
        scalar @pages, 2,
        'inserting a new wiki creates two pages'
    );

    is_deeply(
        [ sort map { $_->title() } @pages ],
        [ 'Front Page', 'Scratch Pad' ],
        'new pages are called Front Page and Scratch Pad'
    );
}

{
    my $wiki = Silki::Schema::Wiki->new( title => 'First Wiki' );

    my %perms = (
        Guest         => { map { $_ => 1 } qw( Read Edit ) },
        Authenticated => { map { $_ => 1 } qw( Read Edit ) },
        Member        => {
            map { $_ => 1 } qw( Read Edit Upload )
        },
        Admin => {
            map { $_ => 1 } qw( Read Edit Delete Upload Invite Manage )
        },
    );

    is_deeply(
        $wiki->permissions(), \%perms,
        'permissions hash matches expected perm set for public wiki'
    );

    is(
        $wiki->permissions_name(), 'public',
        'permissions name is public'
    );

    $wiki->set_permissions('private');

    %perms = (
        Member => { map { $_ => 1 } qw( Read Edit Upload ) },
        Admin  => {
            map { $_ => 1 } qw( Read Edit Delete Upload Invite Manage )
        },
    );

    is_deeply(
        $wiki->permissions(), \%perms,
        'permissions hash matches expected perm set for private wiki'
    );

    is(
        $wiki->permissions_name(), 'private',
        'permissions name is private'
    );
}

{
    my $wiki = Silki::Schema::Wiki->new( title => 'First Wiki' );

    my $admin_username
        = 'admin@' . Silki::Schema::Domain->DefaultDomain()->email_hostname();
    my $admin_user = Silki::Schema::User->new( username => $admin_username );

    my @active = $wiki->active_users()->all();
    is( scalar @active, 0, 'wiki has no active users' );

    is( $wiki->revision_count(), 2, 'wiki has two revisions' );

    my @revs = $wiki->revisions()->all();

    # We need to sort the revs because the creation_datetime for the two pages
    # could be identical.
    is_deeply(
        [
            map { [ $_->[0]->title(), $_->[1]->revision_number() ] }
            sort { $a->[0]->title() cmp $b->[0]->title() } @revs
        ],
        [
            [ 'Front Page',  1 ],
            [ 'Scratch Pad', 1 ],
        ],
        'revisions returns expected revisions'
    );

    is(
        $wiki->front_page_title(), 'Front Page',
        'front page title is Front Page'
    );

    is(
        $wiki->orphaned_page_count(), 0,
        'wiki has no orphaned pages'
    );

    Silki::Schema::Page->insert_with_content(
        title   => 'Orphan',
        wiki_id => $wiki->wiki_id(),
        user_id => $admin_user->user_id(),
        content => 'Whatever',
    );

    is(
        $wiki->orphaned_page_count(), 1,
        'wiki has one orphaned page'
    );

    Silki::Schema::Page->insert_with_content(
        title   => 'Orphan2',
        wiki_id => $wiki->wiki_id(),
        user_id => $admin_user->user_id(),
        content => 'Whatever',
    );

    my @orphans = $wiki->orphaned_pages()->all();
    is_deeply(
        [ sort map { $_->title() } map { $_->[0] } @orphans ],
        [ 'Orphan', 'Orphan2' ],
        'orphaned pages returns expected list of pages'
    );

    is(
        $wiki->wanted_page_count(), 0,
        'wiki has no wanted pages'
    );

    my $wants = Silki::Schema::Page->insert_with_content(
        title   => 'Wants',
        wiki_id => $wiki->wiki_id(),
        user_id => $admin_user->user_id(),
        content => 'A link to ((Something New))',
    );

    is(
        $wiki->wanted_page_count(), 1,
        'wiki has two wanted pages'
    );

    my @wanted = $wiki->wanted_pages()->all();
    is_deeply(
        [ sort map { $_->title() } @wanted ],
        ['Something New'],
        'wanted pages returns expected list of pages'
    );

    @active = $wiki->active_users()->all();
    is( scalar @active, 1, 'wiki has one active user' );
    is_deeply(
        [ map { $_->username() } @active ],
        [$admin_username],
        'active users returns expected user'
    );

    my $joe_username
        = 'joe@' . Silki::Schema::Domain->DefaultDomain()->email_hostname();
    my $joe_user = Silki::Schema::User->new( username => $joe_username );

    Silki::Schema::Page->insert_with_content(
        title   => 'Orphan3',
        wiki_id => $wiki->wiki_id(),
        user_id => $joe_user->user_id(),
        content => 'Whatever',
    );

    @active = $wiki->active_users()->all();
    is( scalar @active, 2, 'wiki has two active users' );
    is_deeply(
        [ map { $_->username() } @active ],
        [ $joe_username, $admin_username ],
        'active users returns expected users, ordered by revision creation_datetime'
    );
}

{
    my $wiki = Silki::Schema::Wiki->new( title => 'First Wiki' );

    is(
        $wiki->file_count(), 0,
        'wiki has no files'
    );

    my $page = Silki::Schema::Page->new(
        title   => 'Front Page',
        wiki_id => $wiki->wiki_id(),
    );

    my $text  = "This is some plain text.\n";
    my $file1 = Silki::Schema::File->insert(
        filename  => 'test1.txt',
        mime_type => 'text/plain',
        file_size => length $text,
        contents  => $text,
        user_id   => $user->user_id(),
        page_id   => $page->page_id(),
    );

    is(
        $wiki->file_count(), 1,
        'wiki has one file'
    );

    $text = "This is some more plain text.\n";
    my $file2 = Silki::Schema::File->insert(
        filename  => 'test2.txt',
        mime_type => 'text/plain',
        file_size => length $text,
        contents  => $text,
        user_id   => $user->user_id(),
        page_id   => $page->page_id(),
    );

    is(
        $wiki->file_count(), 2,
        'wiki has two files'
    );

    my @files = $wiki->files()->all();
    is_deeply(
        [ sort map { $_->filename() } @files ],
        [ 'test1.txt', 'test2.txt' ],
        'files returns all files in the wiki'
    );
}

{
    my $wiki = Silki::Schema::Wiki->insert(
        title      => 'New',
        short_name => 'new',
        domain_id  => Silki::Schema::Domain->DefaultDomain()->domain_id(),
        account_id => $account->account_id(),
        user       => $user,
    );

    check_members( $wiki, [] );

    $wiki->add_user(
        user => Silki::Schema::User->SystemUser(),
        role => Silki::Schema::Role->Admin(),
    );

    check_members( $wiki, [], 'cannot add a system user' );

    lives_ok(
        sub {
            $wiki->remove_user( user => Silki::Schema::User->SystemUser() );
        },
        'trying to remove a system user from a wiki is a no-op'
    );

    my $user1 = Silki::Schema::User->insert(
        email_address => 'user1@example.com',
        password      => 'foo',
        user          => Silki::Schema::User->SystemUser(),
    );

    $wiki->add_user( user => $user1, role => Silki::Schema::Role->Member() );

    check_members( $wiki, [ [ 'user1@example.com', 'Member' ] ] );

    my $user2 = Silki::Schema::User->insert(
        email_address => 'user2@example.com',
        password      => 'foo',
        user          => Silki::Schema::User->SystemUser(),
    );

    $wiki->add_user( user => $user2, role => Silki::Schema::Role->Member() );

    check_members(
        $wiki,
        [
            [ 'user1@example.com', 'Member' ],
            [ 'user2@example.com', 'Member' ],
        ]
    );

    $wiki->add_user( user => $user1, role => Silki::Schema::Role->Admin() );

    check_members(
        $wiki,
        [
            [ 'user1@example.com', 'Admin' ],
            [ 'user2@example.com', 'Member' ],
        ],
        're-add existing user with new role'
    );

    $wiki->remove_user( user => $user1 );

    check_members(
        $wiki,
        [
            [ 'user2@example.com', 'Member' ],
        ],
        'remove a user from the wiki'
    );

    $wiki->add_user( user => $user1, role => Silki::Schema::Role->Guest() );

    check_members(
        $wiki,
        [
            [ 'user2@example.com', 'Member' ],
        ],
        'cannot add a user in the Guest role'
    );

    $wiki->add_user(
        user => $user1,
        role => Silki::Schema::Role->Authenticated()
    );

    check_members(
        $wiki,
        [
            [ 'user2@example.com', 'Member' ],
        ],
        'cannot add a user in the Authenticated role'
    );

    lives_ok(
        sub { $wiki->remove_user( user => $user1 ) },
        'removing a user not in a wiki is a no-op'
    );
}

sub check_members {
    my $wiki   = shift;
    my $expect = shift;
    my $desc   = shift;

    my @members = $wiki->members()->all();

    my $count = scalar @{$expect};
    my $pl = PL_N( 'member', $count );

    is(
        scalar @members, $count,
        "wiki has $count $pl" . ( $desc ? " - $desc" : q{} )
    );

    return unless $count;

    is_deeply(
        [
            sort { $a->[0] cmp $b->[0] }
            map { [ $_->[0]->email_address(), $_->[1]->name() ] } @members
        ],
        $expect,
        'users and roles for wiki members match expected values'
            . ( $desc ? " - $desc" : q{} )
    );
}

{
    my $wiki = Silki::Schema::Wiki->insert(
        title      => 'Clean',
        short_name => 'clean',
        domain_id  => Silki::Schema::Domain->DefaultDomain()->domain_id(),
        account_id => $account->account_id(),
        user       => $user,
    );

    check_search(
        $wiki,
        'afkjadghasjgd',
        [],
        'garbage text'
    );

    check_search(
        $wiki,
        'page',
        ['Front Page'],
    );
}

sub check_search {
    my $wiki   = shift;
    my $query  = shift;
    my $expect = shift;
    my $desc   = shift;

    my $search = $wiki->text_search( query => $query );

    my @results = map { $_->[0]->title() } $search->all();

    my $count = scalar @{$expect};
    my $pl = PL_N( 'result', $count );

    is(
        scalar @results, $count,
        "$count $pl for '$query'" . ( $desc ? " - $desc" : q{} )
    );

    return unless $count;

    is_deeply(
        \@results,
        $expect,
        "search results for '$query'" . ( $desc ? " - $desc" : q{} )
    );
}

{
    my $wikis = Silki::Schema::Wiki->All();
    while ( my $wiki = $wikis->next() ) {
        $wiki->set_permissions('private');
    }

    is(
        Silki::Schema::Wiki->PublicWikiCount(), 0,
        'there are no public wikis'
    );
}

{
    throws_ok {
        Silki::Schema::Wiki->insert(
            title      => 'Has )) parens',
            short_name => 'public',
            domain_id  => Silki::Schema::Domain->DefaultDomain()->domain_id(),
            account_id => $account->account_id(),
            user       => $user,
        );
    }
    qr/\Qcannot contain the characters "))"/,
        q{wiki title cannot contain "))"};

    throws_ok {
        Silki::Schema::Wiki->insert(
            title      => 'Has a / slash',
            short_name => 'public',
            domain_id  => Silki::Schema::Domain->DefaultDomain()->domain_id(),
            account_id => $account->account_id(),
            user       => $user,
        );
    }
    qr{\Qcannot contain a slash (/)}, q{wiki title cannot contain a slash};
}

done_testing();
