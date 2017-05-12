use t::Util;
use Test::More;
use Net::Google::DocumentsList::ACL;

t::Util::check_env('DOCUMENTSLIST_SHARE_USER') or exit 0;
my $share_user = $ENV{DOCUMENTSLIST_SHARE_USER};
ok my $service = service();

ok my $d = $service->add_item(
    {
        title => join(' - ', 'test for acl', scalar localtime),
        kind => 'document',
    }
);;
my @acl = $d->acls;
is scalar @acl, 1;

ok $acl[0]->title;
is $acl[0]->role, 'owner';
is $acl[0]->scope->{type}, 'user';
is $acl[0]->scope->{value}, config->{username};

{
    ok my $new_acl = $d->add_acl(
        {
            send_notification_emails => 'false',
            role => 'reader',
            scope => {
                type => 'user',
                value => $share_user,
            }
        }
    );
    is scalar $d->acls, 2;
    is $new_acl->role, 'reader';
    is $new_acl->scope->{type}, 'user';
    is $new_acl->scope->{value}, $share_user;

    $new_acl->role('writer');
    is $new_acl->role, 'writer';
    is scalar $d->acls, 2;
    ok grep {$_->role eq 'writer'} $d->acls;
    ok $new_acl->delete;
    is scalar $d->acls, 1;
}
{
    ok my $new_acl = $d->add_acl(
        {
            role => 'writer',
            scope => { type => 'default' },
            withKey => 1,
        }
    );
    is scalar $d->acls, 2;
    is $new_acl->role, 'writer';
    is $new_acl->scope->{type}, 'default';
    my $key = $new_acl->withKey;
    ok $key, "key is $key";

    $new_acl->role('reader');
    is scalar $d->acls, 2;
    is $new_acl->role, 'reader';
    ok grep {$_->role eq 'reader'} $d->acls;
    is $new_acl->withKey, $key;
    ok grep {$_->withKey eq $key} $d->acls;
    ok $new_acl->delete;
    is scalar $d->acls, 1;
}


ok $d->delete({delete => 'true'});

done_testing;
