use strict;
use warnings;

use Test::More tests => 2;

use FindBin;
use lib "$FindBin::Bin/lib";

use Template;
use Template::Provider::PrefixDBIC;
use TestSchema;

my $ok;
my $output;
my $schema = TestSchema->connect('dbi:SQLite:dbname=:memory:', '', '');
$schema->deploy;

$schema->populate('Template4', [
    [qw/dog cat hamster gopher/ ],
    ['Test content', 1000, 'default', 'template_name'],
]);

my $provider = Template::Provider::PrefixDBIC->new(
    RESULTSET       => $schema->resultset('Template4'),
    COLUMN_NAME     => 'gopher',
    COLUMN_PREFIX   => 'hamster',
    COLUMN_CONTENT  => 'dog',
    COLUMN_MODIFIED => 'cat',
    PREFIXES        => ['default'],
);

my $template = Template->new({
    LOAD_TEMPLATES => [ $provider ],
});

$output = '';
$ok = $template->process('template_name', {}, \$output);
ok($ok, "Template should have processed successfully") || diag($template->error);
is $output, 'Test content', 'Template output should match database contents';
