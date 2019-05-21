use strict;
use warnings;

use RT::Extension::RichtextCustomField::Test tests => 18;

use Test::WWW::Mechanize;

my $class = RT::Class->new(RT->SystemUser);
$class->Load('General');

my ($base, $m) = RT::Extension::RichtextCustomField::Test->started_ok;
ok($m->login, 'Logged in agent');

$m->get_ok($m->rt_base_url . 'Articles/Article/Edit.html?Class=' . $class->id, 'Create article form without CF Richtext');
$m->content_lacks('CKEDITOR.replace', 'CKEDITOR is not here without CF Richtext');

my $cf_richtext = RT::CustomField->new(RT->SystemUser);
my ($cf_id, $msg) = $cf_richtext->Create(Name => 'Taylor', LookupType => 'RT::Class-RT::Article', Type => 'RichtextSingle');
ok($cf_id, "CF Richtext created");
my $ok;
($ok, $msg) = $cf_richtext->AddToObject($class);
ok($ok, "CF Richtext added to General class");

$m->get_ok($m->rt_base_url . 'Articles/Article/Edit.html?Class=' . $class->id, 'Create article form with CF Richtext');
$m->content_contains('CKEDITOR.replace', 'CKEDITOR is here with CF Richtext');

$m->submit_form(
    form_name => "EditArticle",
    fields    => {
        Name => 'test_article',
        "Object-RT::Article--CustomField-$cf_id-Value" => '<strong>rich</strong>',
    },
);
my $article_id = $m->form_name('EditArticle')->value('id');
$m->content_contains("Article $article_id created", 'Article created');

$m->follow_link_ok({ id => 'page-display' }, 'Article display link');
$m->content_contains('<strong>rich</strong>', 'CF Richtext displayed in HTML');

my $ticket = RT::Ticket->new(RT->SystemUser);
$ticket->Create(Queue => 'General', Subject => 'Ticket To Extract Article From');
$ticket->Correspond(Content => "Maybe you can do this" );
$m->get_ok($m->rt_base_url . 'Articles/Article/ExtractFromTicket.html?Ticket=' . $ticket->id . '&Class=' . $class->id . '&EditTopics=1', 'Extract article from ticket with CF Richtext');
$m->content_contains('<option value="' . $cf_id . '">' . $cf_richtext->Name .'</option>', 'CF Richtext can be chosen');

undef $m;
