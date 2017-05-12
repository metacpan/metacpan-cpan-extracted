use strict;
use warnings;

use Test::More tests => 10;

use FindBin;
use lib "$FindBin::Bin/lib";

use Template;
use Template::Provider::PrefixDBIC;
use TestSchema;

my $ok;
my $output;
my $schema = TestSchema->connect('dbi:SQLite:dbname=:memory:', '', '');
$schema->deploy;

$schema->populate('Template', [
    [qw/name prefix content modified/ ],
    ['test', '', 'Test content', 0 ],
    ['test', 'default', 'Default content', 0 ],
    ['test', 'default/', 'Default content (with a slash!)', 0 ],
    ['test', 'foo', 'Foo content', 0 ],
    ['test', 'foo/', 'Foo content (with a slash!)', 0 ],
    ['test2', 'default', 'Default content: The Sequel', 0 ],
]);

my $provider = Template::Provider::PrefixDBIC->new(
    RESULTSET => $schema->resultset('Template'),
);

my $template = Template->new({
    LOAD_TEMPLATES => [ $provider ],
});

$output = '';
$ok = $template->process('test', {}, \$output);
ok($ok, "Template should have processed successfully") || diag($template->error);
is $output, 'Test content';

$provider->prefixes(['foo', 'default']);
$output = '';
$ok = $template->process('test', {}, \$output);
ok($ok, "Template should have processed successfully") || diag($template->error);
is $output, 'Foo content';

$output = '';
$ok = $template->process('test2', {}, \$output);
ok($ok, "Template should have processed successfully") || diag($template->error);
is $output, 'Default content: The Sequel';

$provider->prefixes('default');
$output = '';
$ok = $template->process('test2', {}, \$output);
ok($ok, "Template should have processed successfully") || diag($template->error);
is $output, 'Default content: The Sequel';

$provider = Template::Provider::PrefixDBIC->new(
    RESULTSET => $schema->resultset('Template'),
    PREFIXES  => 'default',
);

$template = Template->new({
    LOAD_TEMPLATES => [ $provider ],
});

$output = '';
$ok = $template->process('test2', {}, \$output);
ok($ok, "Template should have processed successfully") || diag($template->error);
is $output, 'Default content: The Sequel';
