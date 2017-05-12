use strict;
use warnings;

use Test::Most;

use lib 't/lib';
use Silki::Test::RealSchema;

use Archive::Tar::Wrapper;
use File::Slurp qw( read_file );
use Path::Class qw( dir file );
use Silki;
use Silki::JSON;
use Silki::Schema::Page;
use Silki::Schema::Role;
use Silki::Schema::User;
use Silki::Schema::Wiki;
use Silki::Wiki::Exporter;

my $wiki = Silki::Schema::Wiki->new( title => 'First Wiki' );
my $text = "Some random text\nin this file.\n";

{
    my $guest = Silki::Schema::User->GuestUser();

    my $fp = Silki::Schema::Page->new(
        title   => 'Front Page',
        wiki_id => $wiki->wiki_id(),
    );

    my $new_user1 = Silki::Schema::User->insert(
        display_name  => 'Bob Smith',
        email_address => 'bob@example.com',
        password      => 'foobar',
        user          => Silki::Schema::User->SystemUser(),
    );

    my $new_user2 = Silki::Schema::User->insert(
        display_name  => 'Lisa Smith',
        email_address => 'lisa@example.com',
        username      => 'lisa',
        disable_login => 1,
        is_disabled   => 1,
        user          => Silki::Schema::User->SystemUser(),
    );

    my $new_user3 = Silki::Schema::User->insert(
        email_address => 'ralph@example.com',
        openid_uri    => 'http://ralph.example.com/',
        user          => Silki::Schema::User->SystemUser(),
    );

    $wiki->add_user(
        user => $new_user1,
        role => Silki::Schema::Role->Member(),
    );

    $fp->add_revision(
        content => 'Spanking new content!',
        user_id => $new_user1->user_id(),
    );

    $fp->add_revision(
        content => 'Spanking newer content!',
        user_id => $new_user2->user_id(),
    );

    $fp->add_revision(
        content => 'Spanking newest content!',
        user_id => $new_user3->user_id(),
    );

    my $file1 = Silki::Schema::File->insert(
        filename  => 'test.txt',
        mime_type => 'text/plain',
        file_size => length $text,
        contents  => $text,
        user_id   => $guest->user_id(),
        page_id   => $fp->page_id(),
    );

    my $jpg   = read_file('t/share/data/test.jpg');
    my $file2 = Silki::Schema::File->insert(
        filename  => 'test.jpg',
        mime_type => 'image/jpeg',
        file_size => length $jpg,
        contents  => $jpg,
        user_id   => $guest->user_id(),
        page_id   => $fp->page_id(),
    );

    $fp->add_file($_) for $file1, $file2;
}

{
    my $tarball = $wiki->export();

    $wiki->delete( user => Silki::Schema::User->SystemUser() );

    # This lets us test that users which don't exist are created as part of
    # the import.
    Silki::Schema::User->new( email_address => $_ )
        ->delete( user => Silki::Schema::User->SystemUser() )
        for 'bob@example.com', 'lisa@example.com';

    Silki::Schema->ClearObjectCaches();

    ok(
        !Silki::Schema::Wiki->new( title => 'First Wiki' ),
        'First Wiki has been deleted'
    );

    my $wiki = Silki::Schema::Wiki->import_tarball( tarball => $tarball );

    _check_wiki($wiki);

    _check_users($wiki);

    _check_pages($wiki);

    _check_files($wiki);
}

sub _check_wiki {
    my $wiki = shift;

    is(
        $wiki->title(), 'First Wiki',
        'imported wiki title is First Wiki'
    );

    is(
        $wiki->short_name(), 'first-wiki',
        'imported wiki short name is first-wiki'
    );

    is(
        $wiki->user_id(), Silki::Schema::User->SystemUser()->user_id(),
        'wiki creator is system-user'
    );

    is(
        $wiki->domain_id(),
        Silki::Schema::Domain->DefaultDomain()->domain_id(),
        'wiki domain is default domain'
    );

    is(
        $wiki->permissions_name(), 'public',
        'wiki is public'
    );

    my @members;

    my $members = $wiki->members();
    while ( my ( $user, $role ) = $members->next() ) {
        push @members, [ $user->email_address(), $role->name() ];
    }

    my $hostname = Silki::Schema::Domain->DefaultDomain()->email_hostname();

    is_deeply(
        \@members,
        [
            [ 'admin@' . $hostname, 'Admin' ],
            [ 'bob@example.com',    'Member' ],
            [ 'joe@' . $hostname,   'Member' ],
        ],
        'wiki members have been restored'
    );
}

sub _check_users {
    my $wiki = shift;

    my $bob = Silki::Schema::User->new( email_address => 'bob@example.com' );

    is(
        $bob->display_name, 'Bob Smith',
        'display name for bob@example.com is correct'
    );

    ok(
        !$bob->check_password('foobar'),
        'old pw for bob@example.com does not work'
    );

    my $lisa
        = Silki::Schema::User->new( email_address => 'lisa@example.com' );

    ok( $lisa, 'lisa@example.com was created by importer' );

    is(
        $lisa->display_name, 'Lisa Smith',
        'display name for lisa@example.com is correct'
    );

    is(
        $lisa->username, 'lisa',
        'username for lisa@example.com is correct'
    );

    ok( $lisa->is_disabled(), 'lisa@example.com is disabled' );

    my $ralph
        = Silki::Schema::User->new( email_address => 'ralph@example.com' );

    ok( $ralph, 'ralph@example.com was created by importer' );

    is(
        $ralph->openid_uri(),
        'http://ralph.example.com/',
        'openid_uri for ralph@example.com is correct'
    );
}

sub _check_pages {
    my $wiki = shift;

    my $fp = Silki::Schema::Page->new(
        title   => 'Front Page',
        wiki_id => $wiki->wiki_id(),
    );

    ok( $fp, 'Front Page exists' );

    is(
        $fp->user()->username(), 'system-user',
        'Front Page creator is system-user'
    );

    ok(
        defined $fp->cached_content,
        'page has cached content'
    );

    my $revisions = $fp->revisions();

    my $rev6 = $revisions->next();

    is(
        $rev6->revision_number(), 6,
        'Front Page has six revisions'
    );

    is(
        $rev6->user()->username(),
        'system-user',
        'revision 6 was created by the system user'
    );

    like(
        $rev6->content(),
        qr/\n{{file:test.jpg}}\n/,
        'revision 6 has a link to test.jpg'
    );

    my $rev5 = $revisions->next();

    is(
        $rev5->user()->username(),
        'system-user',
        'revision 5 was created by the system user'
    );

    like(
        $rev5->content(),
        qr/\n{{file:test.txt}}\n/,
        'revision 5 has a link to test.txt'
    );

    my $rev4 = $revisions->next();

    is(
        $rev4->user()->email_address(),
        'ralph@example.com',
        'revision 4 was created by ralph@example.com'
    );

    like(
        $rev4->content(),
        qr/Spanking newest/,
        'revision 4 has the right content'
    );

    my $rev3 = $revisions->next();

    is(
        $rev3->user()->email_address(),
        'lisa@example.com',
        'revision 3 was created by bob@example.com'
    );

    like(
        $rev3->content(),
        qr/Spanking newer/,
        'revision 3 has the right content'
    );

    my $rev2 = $revisions->next();

    is(
        $rev2->user()->email_address(),
        'bob@example.com',
        'revision 2 was created by bob@example.com'
    );

    like(
        $rev2->content(),
        qr/Spanking new /,
        'revision 2 has the right content'
    );

    my $rev1 = $revisions->next();

    is(
        $rev1->user()->username(),
        'system-user',
        'revision 1 was created by the system user'
    );

    like(
        $rev1->content(),
        qr/Welcome/,
        'revision 1 has the right content'
    );

    ok( !$revisions->next(), 'retrieved 6 revisions and no more' );

    ok(
        Silki::Schema::Page->new(
            title   => 'Scratch Pad',
            wiki_id => $wiki->wiki_id(),
        ),
        'Scratch Pad page exists'
    );
}

sub _check_files {
    my $wiki = shift;

    my @files
        = sort { $a->filename() cmp $b->filename() } Silki::Schema::Page->new(
        title   => 'Front Page',
        wiki_id => $wiki->wiki_id(),
        )->files()->all();

    is(
        scalar @files,
        2,
        'Front Page has two attached files'
    );

    is(
        $files[0]->filename(),
        'test.jpg',
        'first file is test.jpg'
    );

    is(
        $files[0]->mime_type(),
        'image/jpeg',
        'mime type is image/jpeg'
    );

    is(
        $files[0]->contents(),
        scalar read_file('t/share/data/test.jpg'),
        'test.jpg file contains expected data'
    );

    is(
        $wiki->file_count(),
        2,
        'wiki has two files'
    );
}

done_testing();
