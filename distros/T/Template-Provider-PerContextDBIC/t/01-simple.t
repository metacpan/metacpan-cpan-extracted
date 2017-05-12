use strict;
use warnings;

use Test::More tests => 10;

use FindBin;
use lib "$FindBin::Bin/lib";

use Template;
use Template::Provider::PerContextDBIC;
use TestSchema;

my $ok;
my $output;
my $schema = TestSchema->connect('dbi:SQLite:dbname=:memory:', '', '');
$schema->deploy;

$schema->populate(
	'Template', [
		[qw/tmpl_name site content modified/],
		['test',  '',        'Test content',                0],
		['test',  'default', 'Default content',             0],
		['test',  'foo',     'Foo content',                 0],
		['test2', 'default', 'Default content: The Sequel', 0],
	]
);

my $provider = Template::Provider::PerContextDBIC->new(
    RESULTSET => $schema->resultset('Template')->search_rs({site=>''}),
);

my $template = Template->new({
    LOAD_TEMPLATES => [ $provider ],
    COMPILE_EXT => '.ttc',
});

$output = '';
$ok = $template->process('test', {}, \$output);
ok($ok, "Template should have processed successfully") || diag($template->error);
is $output, 'Test content';

$provider->resultset( $schema->resultset('Template')->search_rs({site=>'foo'}), 'site-foo' );
$output = '';
$ok = $template->process('test', {}, \$output);
ok($ok, "Template should have processed successfully") || diag($template->error);
is $output, 'Foo content';

$provider->resultset( $schema->resultset('Template')->search_rs({site=>'default'}), 'site-default' );
$output = '';
$ok = $template->process('test', {}, \$output);
ok($ok, "Template should have processed successfully") || diag($template->error);
is $output, 'Default content';

$output = '';
$ok = $template->process('test2', {}, \$output);
ok($ok, "Template should have processed successfully") || diag($template->error);
is $output, 'Default content: The Sequel';

$provider = Template::Provider::PerContextDBIC->new();

$template = Template->new({
    LOAD_TEMPLATES => [ $provider ],
    COMPILE_EXT => '.ttc',
});

$provider->resultset( $schema->resultset('Template')->search_rs({site=>'default'}), 'site-default'  );
$output = '';
$ok = $template->process('test2', {}, \$output);
ok($ok, "Template should have processed successfully") || diag($template->error);
is $output, 'Default content: The Sequel';
