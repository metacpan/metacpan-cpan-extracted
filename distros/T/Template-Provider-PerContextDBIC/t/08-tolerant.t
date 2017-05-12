use strict;
use warnings;

use Test::More tests => 4;
use FindBin;
use lib "$FindBin::Bin/lib";

use Template;
use Template::Provider::PerContextDBIC;
use TestSchema;

my $ok;
my $output;
my $schema = TestSchema->connect('dbi:SQLite:dbname=:memory:', '', '');
$schema->deploy;

$schema->populate('Template2', [
    [qw/site tmpl_name content modified/],
    ['AU', 'test',  'AU Content', 0],
    ['NZ', 'test',  'NZ Content', 0],
    ['AU', 'test2', 'AU Content: Foo', 0],
    ['NZ', 'test2', 'NZ Content: Foo', 0],
]);

my $provider = Template::Provider::PerContextDBIC->new(
    RESULTSET => $schema->resultset('Template2'),
    TOLERANT_QUERY => 0,
);

my $template = Template->new(
    LOAD_TEMPLATES => [ $provider ],
    COMPILE_EXT => '.ttc',
);

$output = '';
$ok = $template->process('test', {}, \$output);
ok(!$ok, "Should not get a template");
is $template->error, 'file error - More then one template matching \'test\' was found in the resultset', 
	"Should get an error about more than one template";

$provider->{TOLERANT_QUERY} = 1;
$output = '';
$ok = $template->process('test2', {}, \$output);
ok(!$ok, "Should not get a template");
is $template->error, 'file error - test2: not found', 
	"Should get an error about template not found";


