use strict;
use warnings;

use Test::Fatal;
use Test::More;

use lib 't/lib';
use Silki::Test::RealSchema;

use DateTime;
use DateTime::Format::Pg;
use Digest::SHA qw( sha512_base64 );
use List::AllUtils qw( any );
use Silki::Schema;
use Silki::Schema::Permission;
use Silki::Schema::Role;
use Silki::Schema::User;
use Silki::Schema::Wiki;

my $wiki = Silki::Schema::Wiki->new( short_name => 'first-wiki' );

{
    my $email = 'user@example.com';
    my $pw    = 's3cr3t';

    my $user = Silki::Schema::User->insert(
        email_address => $email,
        display_name  => 'Example User',
        password      => $pw,
        time_zone     => 'America/New_York',
        user          => Silki::Schema::User->SystemUser(),
    );

    like(
        $user->password(), qr/^{CRYPT}/,
        'user password is encrypted on insert'
    );

    is(
        $user->username(), $email,
        'username defaults to email_address insert()'
    );

    ok(
        $user->check_password($pw),
        'check_password returns true for valid pw'
    );

    ok(
        !$user->check_password('junk'),
        'check_password returns false for invalid pw'
    );

    is(
        $user->created_by_user_id(),
        Silki::Schema::User->SystemUser()->user_id(),
        'created_by_user_id matches system user'
    );

    $user->update(
        password => 'new pw',
        user     => $user,
    );

    ok(
        $user->check_password('new pw'),
        'updating password works'
    );

    # Simulates what happens when the user preferences form is submitted
    # without a new pw.
    $user->update(
        password          => q{},
        preserve_password => 1,
        user              => $user,
    );

    ok(
        $user->check_password('new pw'),
        'password is unchanged with preserve_password flag'
    );

    ok( $user->has_valid_password(), 'user has valid password' );

    ok( $user->has_login_credentials(), 'user has login credentials' );

    $user->update(
        disable_login => 1,
        user          => $user,
    );

    ok(
        !$user->has_login_credentials(),
        'user does not have login credentials'
    );

    ok(
        !$user->is_guest(),
        'regular user is not a guest'
    );

    ok(
        !$user->is_system_user(),
        'regular user is not a system user'
    );

    ok(
        $user->is_authenticated(),
        'regular user is authenticated'
    );

    is(
        $user->set_time_zone_for_dt( DateTime->now( time_zone => 'UTC' ) )
            ->time_zone()->name(),
        'America/New_York',
        'set_time_zone_for_dt sets dt to the correct time zone'
    );
}

{
    is( Silki::Schema::User->Count(), 5, 'Count finds 5 usersx' );

    my @wikis = Silki::Schema::User->All()->all();

    my $hostname   = Silki::Schema::Domain->DefaultDomain()->email_hostname();
    my $admin_user = 'admin@' . $hostname;
    my $joe_user   = 'joe@' . $hostname;

    is_deeply(
        [ sort map { $_->username() } @wikis ],
        [
            $admin_user,
            'guest-user',
            $joe_user,
            'system-user',
            'user@example.com',
        ],
        'All returns all users'
    );
}

{
    my $system = Silki::Schema::User->SystemUser();
    ok(
        !$system->check_password('anything'),
        'check_password is always false for system user'
    );

    ok(
        !$system->is_guest(),
        'system user is not a guest'
    );

    ok(
        !$system->is_authenticated(),
        'system user is not authenticated'
    );

    my $guest = Silki::Schema::User->GuestUser();
    ok(
        $guest->is_guest(),
        'guest user is a guest'
    );

    ok(
        !$guest->is_authenticated(),
        'guest user is not authenticated'
    );
}

{
    my $email = 'user2@example.com';

    my $user = Silki::Schema::User->insert(
        email_address => $email,
        display_name  => 'Example User',
        disable_login => 1,
        user          => Silki::Schema::User->SystemUser(),
    );

    ok(
        !$user->_password_is_encrypted(),
        'password is not encrypted when disable_login is passed to insert()'
    );

    ok( !$user->has_valid_password(), 'user does not have valid password' );

    ok(
        !$user->check_password('anything'),
        'check_password is always false for disabled login'
    );
}

{
    my $email = 'user3@example.com';
    my $pw    = 's3cr3t';

    my $user = Silki::Schema::User->insert(
        email_address       => $email,
        display_name        => 'Example User',
        requires_activation => 1,
        user                => Silki::Schema::User->SystemUser(),
    );

    ok(
        length $user->confirmation_key(),
        'user has an confirmation_key when requires_confirmation is passed to insert()'
    );

    ok(
        $user->requires_activation(),
        'requires_activation is true'
    );

    is(
        $user->confirmation_uri(),
        '/user/'
            . $user->user_id()
            . '/confirmation/'
            . $user->confirmation_key()
            . '/preferences_form',
        'default confirmation_uri() is for preferences form'
    );

    is(
        $user->confirmation_uri( view => 'status' ),
        '/user/'
            . $user->user_id()
            . '/confirmation/'
            . $user->confirmation_key()
            . '/status',
        'confirmation_uri() with explicit view'
    );

    $user->update(
        confirmation_key => undef,
        user             => $user,
    );

    like(
        exception { $user->confirmation_uri() },
        qr/^\QCannot make a confirmation uri for a user who does not have a confirmation key/,
        'cannot get a confirmation_uri for a user without a confirmation_key'
    );
}

{
    like(
        exception {
            Silki::Schema::User->insert(
                email_address => 'fail@example.com',
                display_name  => 'Faily McFail',
                user          => Silki::Schema::User->SystemUser(),

            );
        },
        qr/\QYou must provide a password or OpenID./,
        'Cannot insert a user without a pw or openid'
    );

    like(
        exception {
            Silki::Schema::User->insert(
                email_address => 'fail@example.com',
                display_name  => 'Faily McFail',
                openid_uri    => q{},
                user          => Silki::Schema::User->SystemUser(),
            );
        },
        qr/\QYou must provide a password or OpenID./,
        'Cannot insert a user without a pw or openid'
    );
}

{
    my $email = 'user4@example.com';
    my $pw    = 's3cr3t';

    my $user = Silki::Schema::User->insert(
        email_address => $email,
        display_name  => 'Example User',
        password      => $pw,
        user          => Silki::Schema::User->SystemUser(),
    );

    like(
        exception {
            $user->update(
                password => undef,
                user     => $user,
            );
        },
        qr/\QYou must provide a password or OpenID./,
        'Cannot update a user to not have a password'
    );

    is(
        exception {
            $user->update(
                openid_uri => 'http://example.com',
                password   => undef,
                user       => $user,
            );
        },
        undef,
        'Can update a user to unset the password but add an openid_uri'
    );

    is(
        exception {
            $user->update(
                password => undef,
                user     => $user,
            );
        },
        undef,
        'Can update a user to not have a password if they have an openid_uri in the dbms'
    );

    like(
        exception {
            $user->update(
                openid_uri => undef,
                password   => q{},
                user       => $user,
            );
        },
        qr/\QYou must provide a password or OpenID./,
        'Cannot update a user to not have a password or openid'
    );

    ok( !$user->has_valid_password(), 'user does not have valid password' );

    ok(
        $user->has_login_credentials(),
        'user has login credentials (openid)'
    );

    like(
        exception {
            $user->update(
                openid_uri => 'not a uri',
                user       => $user,
            );
        },
        qr/\QThe OpenID you provided is not a valid URI./,
        'Cannot update a user with an invalid openid_uri (not a uri at all)'
    );

    like(
        exception {
            $user->update(
                openid_uri => 'ftp://example.com/dir',
                user       => $user,
            );
        },
        qr/\QThe OpenID you provided is not a valid URI./,
        'Cannot update a user with an invalid openid_uri (ftp uri)'
    );

    like(
        exception {
            $user->update(
                openid_uri => undef,
                user       => $user,
            );
        },
        qr/\QYou must provide a password or OpenID./,
        'Cannot update a user to not have a password or openid'
    );

    like(
        exception {
            Silki::Schema::User->insert(
                email_address => 'user5@example.com',
                display_name  => 'Example User',
                openid_uri    => 'http://example.com',
                user          => Silki::Schema::User->SystemUser(),
            );
        },
        qr/The OpenID URI you provided is already in use by another user./,
        'Cannot insert a user with the same openid_uri as an existing usre',
    );

    is(
        exception {
            $user->update(
                openid_uri => 'http://example.com',
                user       => $user,
            );
        },
        undef,
        q{can update a user's openid to the same openid it already has}
    );

    my $user5 = Silki::Schema::User->insert(
        email_address => 'userr@example.com',
        display_name  => 'Example User',
        openid_uri    => 'http://example.com/foo',
        user          => Silki::Schema::User->SystemUser(),
    );

    like(
        exception {
            $user5->update(
                openid_uri => 'http://example.com',
                user       => $user5,
            );
        },
        qr/The OpenID URI you provided is already in use by another user./,
        'Cannot update a user to the same openid_uri as an existing usre',
    );

    like(
        exception {
            Silki::Schema::User->insert(
                email_address => 'user4@example.com',
                display_name  => 'Example User',
                password      => 'whatever',
                user          => Silki::Schema::User->SystemUser(),
            );
        },
        qr/The email address you provided is already in use by another user./,
        'Cannot insert a user with the same email_address as an existing user',
    );

    is(
        exception {
            $user->update(
                email_address => $email,
                user          => $user,
            );
        },
        undef,
        q{can update a user's email address to the same email address it already has}
    );

    like(
        exception {
            $user->update(
                email_address => 'user@example.com',
                user          => $user,
            );
        },
        qr/The email address you provided is already in use by another user./,
        'Cannot update a user to the same email_address as an existing user',
    );

    $user->update(
        password   => 'foo',
        openid_uri => undef,
        user       => $user,
    );

    is(
        exception {
            $user->update(
                openid_uri => undef,
                user       => $user,
            );
        },
        undef,
        'Can update a user to not have an openid_uri if they have a password in the dbms'
    );

    like(
        exception {
            $user->update(
                openid_uri => undef,
                password   => undef,
                user       => $user,
            );
        },
        qr/\QYou must provide a password or OpenID./,
        'Cannot update a user to not have a password or openid_uri'
    );
}

{
    my $admin = Silki::Schema::User->insert(
        email_address => 'admin@example.com',
        password      => 'foo',
        is_admin      => 1,
        user          => Silki::Schema::User->SystemUser(),
    );

    my $reg1 = Silki::Schema::User->insert(
        email_address => 'reg1@example.com',
        password      => 'foo',
        user          => Silki::Schema::User->SystemUser(),
    );

    my $reg2 = Silki::Schema::User->insert(
        email_address => 'reg2@example.com',
        password      => 'foo',
        user          => Silki::Schema::User->SystemUser(),
    );

    ok( $admin->can_edit_user($admin), 'admin can edit self' );
    ok( $admin->can_edit_user($reg1),  'admin can edit other users' );

    ok( $reg1->can_edit_user($reg1), 'regular user can edit self' );
    ok(
        !$reg1->can_edit_user($reg2),
        'regular user cannot edit other users'
    );

    ok(
        !$admin->can_edit_user( Silki::Schema::User->SystemUser() ),
        'cannot edit system users'
    );
}

{
    my $user
        = Silki::Schema::User->new( email_address => 'reg1@example.com' );

    my %perms = (
        Read   => 1,
        Edit   => 1,
        Delete => 0,
        Upload => 0,
        Invite => 0,
        Manage => 0,
    );

    test_permissions( $user, $wiki, \%perms );

    ok(
        !$user->is_wiki_member($wiki),
        'user is not a member of the first wiki'
    );

    is(
        $user->role_in_wiki($wiki)->name(), 'Authenticated',
        'user role in First Wiki is Authenticated'
    );

    is(
        Silki::Schema::User->GuestUser()->role_in_wiki($wiki)->name(),
        'Guest',
        'guest user role in First Wiki is Guest'
    );

    is(
        $user->member_wiki_count(), 0,
        'user is not a member of any wikis'
    );

    is(
        $user->all_wiki_count(), 0,
        'user is not a participant in any wikis'
    );

    Silki::Schema::Page->new(
        wiki_id => $wiki->wiki_id(),
        title   => 'Front Page'
        )->add_revision(
        content => 'whatever',
        user_id => $user->user_id(),
        );

    is(
        $user->all_wiki_count(), 1,
        'user is a participant in one wiki'
    );

    $wiki->add_user( user => $user, role => Silki::Schema::Role->Member() );

    ok( $user->is_wiki_member($wiki), 'user is a member of the first wiki' );

    is(
        $user->role_in_wiki($wiki)->name(), 'Member',
        'user role in First Wiki is Member'
    );

    is(
        $user->member_wiki_count(), 1,
        'user is a member of one wiki'
    );

    is(
        $user->all_wiki_count(), 1,
        'user is a participant in one wiki'
    );
}

{
    my $user
        = Silki::Schema::User->new( email_address => 'reg1@example.com' );

    my $wiki = Silki::Schema::Wiki->new( short_name => 'second-wiki' );

    my %perms = (
        Read   => 0,
        Edit   => 0,
        Delete => 0,
        Upload => 0,
        Invite => 0,
        Manage => 0,
    );

    test_permissions( $user, $wiki, \%perms );

    $wiki->add_user( user => $user, role => Silki::Schema::Role->Member() );

    @perms{qw( Read Edit Upload )} = (1) x 5;
    test_permissions( $user, $wiki, \%perms );

    is(
        $user->member_wiki_count(), 2,
        'user is a member of two wikis'
    );

    is(
        $user->all_wiki_count(), 2,
        'user is a participant in two wikis'
    );

    Silki::Schema::Wiki->new( short_name => 'first-wiki' )
        ->remove_user( user => $user );

    is(
        $user->member_wiki_count(), 1,
        'user is a member of one wiki after being removed from First Wiki'
    );

    is(
        $user->all_wiki_count(), 2,
        'user is still a participant in two wikis after being removed from First Wiki'
    );
}

sub test_permissions {
    my $user  = shift;
    my $wiki  = shift;
    my $perms = shift;

    my $member_desc
        = $user->role_in_wiki($wiki)->name() eq 'Authenticated'
        ? 'non-member'
        : 'member';

    my $perm_name = $wiki->permissions_name();

    for my $perm ( sort keys %{$perms} ) {
        if ( $perms->{$perm} ) {
            ok(
                $user->has_permission_in_wiki(
                    wiki       => $wiki,
                    permission => Silki::Schema::Permission->$perm(),
                ),
                "$member_desc user has $perm permission in $perm_name wiki"
            );
        }
        else {
            ok(
                !$user->has_permission_in_wiki(
                    wiki       => $wiki,
                    permission => Silki::Schema::Permission->$perm(),
                ),
                "$member_desc user does not have $perm permission in $perm_name wiki"
            );
        }
    }
}

{
    my $reg3 = Silki::Schema::User->insert(
        email_address => 'reg3@example.com',
        password      => 'foo',
        user          => Silki::Schema::User->SystemUser(),
    );

    my $reg4 = Silki::Schema::User->insert(
        email_address => 'reg4@example.com',
        password      => 'foo',
        user          => Silki::Schema::User->SystemUser(),
    );

    my @wikis = $reg3->wikis_shared_with($reg4)->all();
    is(
        scalar @wikis, 0,
        'reg3 and reg4 user do not share any wikis'
    );

    @wikis = $reg4->wikis_shared_with($reg3)->all();

    is(
        scalar @wikis, 0,
        'reg3 and reg4 user do not share any wikis'
    );

    my $wiki1 = Silki::Schema::Wiki->new( short_name => 'first-wiki' );
    my $wiki2 = Silki::Schema::Wiki->new( short_name => 'second-wiki' );
    my $wiki3 = Silki::Schema::Wiki->new( short_name => 'third-wiki' );

    $wiki1->add_user( user => $reg3, role => Silki::Schema::Role->Member() );
    $wiki2->add_user( user => $reg4, role => Silki::Schema::Role->Member() );

    @wikis = $reg4->wikis_shared_with($reg3)->all();

    is(
        scalar @wikis, 0,
        'reg3 and reg4 user still do not share any wikis'
    );

    $wiki1->add_user( user => $reg4, role => Silki::Schema::Role->Member() );

    @wikis = $reg4->wikis_shared_with($reg3)->all();

    is(
        scalar @wikis, 1,
        'reg3 and reg4 user share one wiki'
    );

    is_deeply(
        [ sort map { $_->title() } @wikis ],
        ['First Wiki'],
        'the shared wiki is First Wiki'
    );

    $wiki2->add_user( user => $reg3, role => Silki::Schema::Role->Member() );

    @wikis = $reg4->wikis_shared_with($reg3)->all();

    is(
        scalar @wikis, 2,
        'reg3 and reg4 user share two wikis'
    );

    is_deeply(
        [ sort map { $_->title() } @wikis ],
        [ 'First Wiki', 'Second Wiki' ],
        'the shared wikis are First and Second Wiki'
    );

}

{
    my $account = Silki::Schema::Account->new( name => 'Default Account' );

    my $domain = Silki::Schema::Domain->insert(
        web_hostname   => 'urth.org',
        email_hostname => 'urth.org',
    );

    my $wiki = Silki::Schema::Wiki->insert(
        title      => 'Alt Domain',
        short_name => 'alt',
        account_id => $account->account_id(),
        domain_id  => $domain->domain_id(),
        user       => Silki::Schema::User->SystemUser(),
    );

    my $reg5 = Silki::Schema::User->insert(
        email_address => 'reg5@example.com',
        password      => 'foo',
        user          => Silki::Schema::User->SystemUser(),
    );

    is(
        $reg5->domain()->web_hostname(),
        Silki::Schema::Domain->DefaultDomain()->web_hostname(),
        'default domain for user with no wikis is the default domain'
    );

    $wiki->add_user( user => $reg5, role => Silki::Schema::Role->Member() );

    is(
        $reg5->domain()->web_hostname(),
        $domain->web_hostname(),
        'default domain for user in a wiki is domain of the first wiki they belong to'
    );
}

{
    my $to_del = Silki::Schema::User->insert(
        email_address => 'delete@example.com',
        password      => 'foo',
        user          => Silki::Schema::User->SystemUser(),
    );

    my $to_keep = Silki::Schema::User->insert(
        email_address => 'keep@example.com',
        password      => 'foo',
        user          => Silki::Schema::User->SystemUser(),
    );

    my $page = Silki::Schema::Page->insert_with_content(
        wiki_id => $wiki->wiki_id(),
        title   => 'Page for Testing',
        content => 'good1',
        user_id => $to_keep->user_id(),
    );

    $page->add_revision(
        content => 'spam1',
        user_id => $to_del->user_id(),
    );

    $page->add_revision(
        content => 'spam2',
        user_id => $to_del->user_id(),
    );

    $page->add_revision(
        content => 'good2',
        user_id => $to_keep->user_id(),
    );

    $page->add_revision(
        content => 'good3',
        user_id => $to_keep->user_id(),
    );

    $page->add_revision(
        content => 'spam3',
        user_id => $to_del->user_id(),
    );

    $to_del->delete( user => $to_keep );

    my @revisions = $page->revisions()->all();

    is_deeply(
        [ map { $_->revision_number() } @revisions ],
        [ 3, 2, 1 ],
        'page has four revisions after bad user is deleted'
    );

    ok(
        ( !any { $_->content() =~ /spam/ } @revisions ),
        'all content from bad revisions is gone'
    );
}

done_testing();
