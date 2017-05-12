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

$schema->populate('TemplateOwner', [
    [qw/id name/],
    [1, 'Rob'],
    [2, 'John'],
]);

my $rob_id  = $schema->resultset('TemplateOwner')->find({name => 'Rob'})->get_column('id');
my $john_id = $schema->resultset('TemplateOwner')->find({name => 'John'})->get_column('id');

$schema->populate('Template3', [
    [qw/owner_id name prefix content modified/],
    [$rob_id, 'test', '', 'Rob Content', 0],
    [$john_id, 'test', 'default', 'John Content: Default', 0],
    [$rob_id, 'test', 'foo', 'Rob Content: Foo', 0],
]);

my $provider = Template::Provider::PrefixDBIC->new(
    RESULTSET   => $schema->resultset('Template3')->search_rs({
        'owner.name' => 'John',
    }, {
        prefetch => 'owner',
    }),
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
