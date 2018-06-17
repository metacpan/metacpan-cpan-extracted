use Mojo::Base -strict;

use Test::More;
use Mojo::Util 'encode';
use Template;
use Template::Context;
use Template::Provider::Mojo;

use Mojolicious::Lite;

my $renderer = app->renderer;
my $provider = Template::Provider::Mojo->new({MOJO_RENDERER => $renderer});
my $context = Template::Context->new({LOAD_TEMPLATES => [$provider]});
my $tt = Template->new({CONTEXT => $context});

# Basic templates
my $output;
ok($tt->process(\'[% foo %] ☃', { foo => 'bar' }, \$output), 'processed inline template')
	or diag $tt->error;
is $output, 'bar ☃', 'right template output';

undef $output;
ok($tt->process('data_section.html.tt2', { foo => 'bar' }, \$output), 'processed data template')
	or diag $tt->error;
is $output, "bar ☃\n", 'right template output';

undef $output;
ok($tt->process('data_empty.html.tt2', { foo => 'bar' }, \$output), 'processed empty data template')
	or diag $tt->error;
is $output, '', 'right template output';

undef $output;
ok($tt->process('tmpl_file.html.tt2', { foo => 'bar' }, \$output), 'processed file template')
	or diag $tt->error;
is $output, "bar ☃\n", 'right template output';

# Includes from inline
undef $output;
ok($tt->process(\'[% INCLUDE data_section.html.tt2 %]baz', { foo => 'bar' }, \$output),
	'processed inline template with included data template') or diag $tt->error;
is $output, "bar ☃\nbaz", 'right template output';

undef $output;
ok($tt->process(\'[% INCLUDE data_empty.html.tt2 %]baz', { foo => 'bar' }, \$output),
	'processed inline template with included empty data template') or diag $tt->error;
is $output, "baz", 'right template output';

undef $output;
ok($tt->process(\'[% INCLUDE tmpl_file.html.tt2 %]baz', { foo => 'bar' }, \$output),
	'processed inline template with included file template') or diag $tt->error;
is $output, "bar ☃\nbaz", 'right template output';

# Includes from data section
undef $output;
ok($tt->process('data_include_data.html.tt2', { foo => 'bar' }, \$output),
	'processed data template with included data template') or diag $tt->error;
is $output, "bar ☃\nbaz\n", 'right template output';

undef $output;
ok($tt->process('data_include_empty.html.tt2', { foo => 'bar' }, \$output),
	'processed data template with included empty data template') or diag $tt->error;
is $output, "baz\n", 'right template output';

undef $output;
ok($tt->process('data_include_file.html.tt2', { foo => 'bar' }, \$output),
	'processed data template with included file template') or diag $tt->error;
is $output, "bar ☃\nbaz\n", 'right template output';

# Includes from file template
undef $output;
ok($tt->process('file_include_data.html.tt2', { foo => 'bar' }, \$output),
	'processed file template with included data template') or diag $tt->error;
is $output, "bar ☃\nbaz\n", 'right template output';

undef $output;
ok($tt->process('file_include_empty.html.tt2', { foo => 'bar' }, \$output),
	'processed file template with included empty data template') or diag $tt->error;
is $output, "baz\n", 'right template output';

undef $output;
ok($tt->process('file_include_file.html.tt2', { foo => 'bar' }, \$output),
	'processed file template with included file template') or diag $tt->error;
is $output, "bar ☃\nbaz\n", 'right template output';

my $inserted = encode $renderer->encoding, "[% foo %] ☃\n";

# Inserts from inline
undef $output;
ok($tt->process(\'[% INSERT data_section.html.tt2 %]baz', { foo => 'bar' }, \$output),
	'processed inline template with inserted data template') or diag $tt->error;
is $output, "${inserted}baz", 'right template output';

undef $output;
ok($tt->process(\'[% INSERT data_empty.html.tt2 %]baz', { foo => 'bar' }, \$output),
	'processed inline template with inserted empty data template') or diag $tt->error;
is $output, "baz", 'right template output';

undef $output;
ok($tt->process(\'[% INSERT tmpl_file.html.tt2 %]baz', { foo => 'bar' }, \$output),
	'processed inline template with inserted file template') or diag $tt->error;
is $output, "${inserted}baz", 'right template output';

# Inserts from data section
undef $output;
ok($tt->process('data_insert_data.html.tt2', { foo => 'bar' }, \$output),
	'processed data template with inserted data template') or diag $tt->error;
is $output, "${inserted}baz\n", 'right template output';

undef $output;
ok($tt->process('data_insert_empty.html.tt2', { foo => 'bar' }, \$output),
	'processed data template with inserted empty data template') or diag $tt->error;
is $output, "baz\n", 'right template output';

undef $output;
ok($tt->process('data_insert_file.html.tt2', { foo => 'bar' }, \$output),
	'processed data template with inserted file template') or diag $tt->error;
is $output, "${inserted}baz\n", 'right template output';

# Inserts from file template
undef $output;
ok($tt->process('file_insert_data.html.tt2', { foo => 'bar' }, \$output),
	'processed file template with inserted data template') or diag $tt->error;
is $output, "${inserted}baz\n", 'right template output';

undef $output;
ok($tt->process('file_insert_empty.html.tt2', { foo => 'bar' }, \$output),
	'processed file template with inserted empty data template') or diag $tt->error;
is $output, "baz\n", 'right template output';

undef $output;
ok($tt->process('file_insert_file.html.tt2', { foo => 'bar' }, \$output),
	'processed file template with inserted file template') or diag $tt->error;
is $output, "${inserted}baz\n", 'right template output';

done_testing;

__DATA__

@@ data_section.html.tt2
[% foo %] ☃
@@ data_empty.html.tt2
@@ data_include_data.html.tt2
[% INCLUDE data_section.html.tt2 %]baz
@@ data_include_empty.html.tt2
[% INCLUDE data_empty.html.tt2 %]baz
@@ data_include_file.html.tt2
[% INCLUDE tmpl_file.html.tt2 %]baz
@@ data_insert_data.html.tt2
[% INSERT data_section.html.tt2 %]baz
@@ data_insert_empty.html.tt2
[% INSERT data_empty.html.tt2 %]baz
@@ data_insert_file.html.tt2
[% INSERT tmpl_file.html.tt2 %]baz
__END__
