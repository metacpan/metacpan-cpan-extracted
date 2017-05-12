use Test::Most;

use OpusVL::AppKit::Plugin::AppKit;

my $plugin = OpusVL::AppKit::Plugin::AppKit->new();

my @unrestricted = qw{
end
begin
default
login
logout
access_denied
appkit/admin/access/_END
TestApp::View::AppKitTT->process
not_found
appkit/admin/access/auto
};

note 'Checking unrestricted urls';
for my $url (@unrestricted)
{
    ok $plugin->is_unrestricted_action_name($url), "Should be unrestricted - $url";
}

my @restricted = qw{
test_default
search/test_default
search/index
appkit/admin/access/check_auto
};


note 'Checking restricted urls';
for my $url (@restricted)
{
    ok !$plugin->is_unrestricted_action_name($url), "Should be restricted - $url";
}


done_testing;

