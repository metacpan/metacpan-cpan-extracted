use strict;
use warnings;

use Test::More tests => 6;
use FindBin;
use lib "$FindBin::Bin/lib";

use Template;
use Template::Provider::PerContextDBIC;
use TestSchema;

my $ok;
my $output;
my $schema = TestSchema->connect('dbi:SQLite:dbname=:memory:', '', '');
$schema->deploy;

$schema->populate('TemplateSite', [
    [qw/id name/],
    [1, 'AU'],
    [2, 'NZ'],
]);

my $au_id  = $schema->resultset('TemplateSite')->find({name => 'AU'})->get_column('id');
my $nz_id = $schema->resultset('TemplateSite')->find({name => 'NZ'})->get_column('id');

$schema->populate('Template3', [
    [qw/site_id tmpl_name  content modified/],
    [$au_id, 'test', 'AU Content', 0],
    [$nz_id, 'test', 'NZ Content: Default', 0],
    [$au_id, 'test2', 'AU Content: Foo', 0],
]);

my $provider = Template::Provider::PerContextDBIC->new(
    RESULTSET   => $schema->resultset('Template3')->search_rs({
        'site.name' => 'NZ',
    }, {
        prefetch => 'site',
    }),
    RESTRICTBY_NAME => 'site-NZ',
);

my $template = Template->new(
    LOAD_TEMPLATES => [ $provider ],
);

$output = '';
$ok = $template->process('test2', {}, \$output);
ok(!$ok, "NZ shouldn't see AU's templates");

$output = '';
$ok = $template->process('test', {}, \$output);
ok($ok, "Template should have processed successfully") || diag($template->error);
is $output, 'NZ Content: Default';

$provider->resultset(
	$schema->resultset('Template3')->search_rs(
		{ 'site.name' => 'AU' },
		{
			prefetch => 'site',
		}
	),
	'site-AU'
);
$output = '';
$ok = $template->process('test', {}, \$output);
ok($ok, 'Template should have processed successfully') || diag($template->error);
is $output, 'AU Content', "AU shouldn't see NZ's cached templates";

$provider->resultset(
	$schema->resultset('Template3')->search_rs(
		{ 'site.name' => 'UK' },
		{
			prefetch => 'site',
		}
	),
	'site-UK'
);
$output = '';
$ok = $template->process('test', {}, \$output);
ok(!$ok, "Should not load template for non-existent site");
