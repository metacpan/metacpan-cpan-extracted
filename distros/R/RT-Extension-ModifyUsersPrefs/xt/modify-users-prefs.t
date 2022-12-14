use strict;
use warnings;

use RT::Extension::ModifyUsersPrefs::Test tests => 17;

use Test::WWW::Mechanize;

# Create user
my $user = RT::Test->load_or_create_user(Name => 'user', Password => 'password');
ok(RT::Test->set_rights({Principal => $user, Right => [qw(ModifySelf)]}), 'Set ModifySelf right');

# Login root
my ($base, $m) = RT::Extension::ModifyUsersPrefs::Test->started_ok;
ok($m->login('root', 'password'), 'Logged in root');

# Modify user's prefs
$m->get_ok($m->rt_base_url . 'Admin/Users/Modify.html?id=' . $user->id, 'Modify user');
my $user_id = $user->id;
$m->content_like(qr{<li id="li-page-userprefs"><a id="page-userprefs" class="menu-item[^"]*" href="/Admin/Users/Prefs\.html\?id=$user_id">Preferences</a></li>}, "Menu link to user's prefs");
$m->follow_link_ok({ id => 'page-userprefs' }, 'Modify user prefs link');
$m->submit_form_ok(
    {
        form_name => "ModifyUsersPreferences",
        fields    => {EmailFrequency => 'Suspended'},
        button    => 'Update'},
    'Submit form'
);
$m->content_contains('Preferences saved', 'Preferences saved');

# Logout root
$m->get_ok($m->rt_base_url . 'NoAuth/Logout.html', 'Logout root');

# Login user
ok($m->login('user', 'password'), 'Logged in user');

# Check user's prefs
$m->get_ok($m->rt_base_url . 'Prefs/Other.html', "Get user's own prefs");
my $prefs_form = $m->form_name('ModifyPreferences');
is($m->value('EmailFrequency'), 'Suspended', 'Email frequency correctly set');
