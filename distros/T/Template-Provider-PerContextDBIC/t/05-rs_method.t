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
    ['NZ', 'test',  'NZ Content: Default', 0],
    ['AU', 'test2', 'AU Content: Foo', 0],
]);

my $provider = Template::Provider::PerContextDBIC->new(
	RESULTSET_METHOD => sub {
		my $name = shift;
		if ( $name eq 'test2' ) {
			return (
				$schema->resultset('Template2')->search_rs( { site => 'AU' } ),
				'site-AU'
			);
		} else {
			return (
				$schema->resultset('Template2')->search_rs( { site => 'NZ' } ),
				'site-NZ'
			);

		}
	}
);

my $template = Template->new(
    LOAD_TEMPLATES => [ $provider ],
    COMPILE_EXT => '.ttc',
);

$output = '';
$ok = $template->process('test2', {}, \$output);
ok($ok, "Template should have processed successfully") || diag($template->error);
is $output, 'AU Content: Foo';

$output = '';
$ok = $template->process('test', {}, \$output);
ok($ok, "Template should have processed successfully") || diag($template->error);
is $output, 'NZ Content: Default';
