use strict;
use warnings;

use Test::More tests => 3;
use FindBin;
use lib "$FindBin::Bin/lib";

use Template;
use Template::Provider::PrefixDBIC;
use TestSchema;

my $ok;
my $output;
my $schema = TestSchema->connect('dbi:SQLite:dbname=:memory:', '', '');
$schema->deploy;

$schema->populate('Template2', [
    [qw/owner name prefix content modified/],
    ['Rob', 'test', '', 'Rob Content', 0],
    ['John', 'test', 'default', 'John Content: Default', 0],
    ['Rob', 'test', 'foo', 'Rob Content: Foo', 0],
]);

my $provider = Template::Provider::PrefixDBIC->new(
    RESULTSET => $schema->resultset('Template2')->search_rs({owner => 'John'}),
);

my $template = Template->new(
    LOAD_TEMPLATES => [ $provider ],
);

$output = '';
$ok = $template->process('test', {}, \$output);
ok !$ok, "John shouldn't see Rob's templates";

$provider->prefixes(['foo', 'default']);
$output = '';
$ok = $template->process('test', {}, \$output);
ok($ok, 'Template should have processed successfully') || diag($template->error);
is $output, 'John Content: Default', "John shouldn't see Rob's templates";
