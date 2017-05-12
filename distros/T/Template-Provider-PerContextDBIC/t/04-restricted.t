use strict;
use warnings;

use Test::More tests => 6;
use FindBin;
use lib "$FindBin::Bin/lib";

use Template;
use Template::Provider::PerContextDBIC;
use TestSchema;
TestSchema->load_components(qw/ Schema::RestrictWithObject  /);

my $ok;
my $output;
my $schema = TestSchema->connect('dbi:SQLite:dbname=:memory:', '', '');
$schema->deploy;

$schema->populate('TemplateSite', [
    [qw/id name/],
    [1, 'AU'],
    [2, 'NZ'],
]);

my $au_site = $schema->resultset('TemplateSite')->find({name => 'AU'});
my $nz_site = $schema->resultset('TemplateSite')->find({name => 'NZ'});
my $uk_site = $schema->resultset('TemplateSite')->find({name => 'UK'});

my $au_id = $au_site->get_column('id');
my $nz_id = $nz_site->get_column('id');
#my $uk_id = $uk_site->get_column('id'); # site doesn't exist

$schema->populate(
	'Template3', [
		[qw/site_id tmpl_name  content modified/],
		[$au_id, 'test',  'AU Content',          0],
		[$nz_id, 'test',  'NZ Content: Default', 0],
		[$au_id, 'test2', 'AU Content: Foo',     0],
	]
);

my $schema_site_au = $schema->restrict_with_object($au_site);
my $schema_site_nz = $schema->restrict_with_object($nz_site);
my $schema_site_uk = $schema->restrict_with_object($uk_site);

my $provider = Template::Provider::PerContextDBIC->new(
    RESULTSET   => $schema_site_nz->resultset('Template3')->search_rs,
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

$provider->resultset( $schema_site_au->resultset('Template3')->search_rs );
$output = '';
$ok = $template->process('test', {}, \$output);
ok($ok, 'Template should have processed successfully') || diag($template->error);
is $output, 'AU Content', "AU shouldn't see NZ's cached templates";

$provider->resultset( $schema_site_uk->resultset('Template3')->search_rs );
$output = '';
$ok = $template->process('test', {}, \$output);
ok(!$ok, "Should not load template when more than one is found (site restriction failed)");
