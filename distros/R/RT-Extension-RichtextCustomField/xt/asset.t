use strict;
use warnings;

use RT::Extension::RichtextCustomField::Test tests => 15;

use Test::WWW::Mechanize;

my $catalog = RT::Catalog->new(RT->SystemUser);
$catalog->Load('General assets');

my ($base, $m) = RT::Extension::RichtextCustomField::Test->started_ok;
ok($m->login, 'Logged in agent');

$m->get_ok($m->rt_base_url . 'Asset/Create.html?Catalog=' . $catalog->id, 'Create asset form');
$m->content_lacks('CKEDITOR.replace', 'CKEDITOR is not here without CF Richtext');

my $cf_richtext = RT::CustomField->new(RT->SystemUser);
my ($cf_id, $msg) = $cf_richtext->Create(Name => 'Taylor', LookupType => 'RT::Catalog-RT::Asset', Type => 'RichtextSingle');
ok($cf_id, "CF Richtext created");
my $ok;
($ok, $msg) = $cf_richtext->AddToObject($catalog);
ok($ok, "CF Richtext added to General catalog");

$m->get_ok($m->rt_base_url . 'Asset/Create.html?Catalog=' . $catalog->id, 'Create asset form');
$m->content_contains('CKEDITOR.replace', 'CKEDITOR is here with CF Richtext');

$m->submit_form(
    form_id => "CreateAsset",
    fields    => {
        Name => 'test_asset',
        "Object-RT::Asset--CustomField-$cf_id-Value" => '<strong>rich</strong>',
    },
);
(my $asset_id) = ($m->uri =~ /id=(\d+)/);
$m->content_contains("Asset #$asset_id created", 'Asset created');
$m->content_contains('<strong>rich</strong>', 'CF Richtext displayed in HTML');

undef $m;
