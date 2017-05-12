use 5.004; # Sane minimum, I think.
use strict;
use warnings;

use Module::Build;

# -----------------------------------------------

my $class = Module::Build->subclass(code => <<'EOF');

sub ACTION_authortest
{
	my($self) = @_;

	$self->depends_on('build');
	$self->depends_on('manifest');
	$self->depends_on('distmeta');

	$self->test_files( qw< t xt/author > );
	$self->recursive_test_files(1);

	$self->depends_on('test');

	return;
}
EOF

$class -> new
(
	module_name    => 'Pod::Webserver',
	license        => 'artistic_2',
	dist_abstract  => 'Minimal web server for local Perl documentation',
	dist_author    => 'Sean M. Burke C<sburke@cpan.org>',
	build_requires =>
	{
		'Test::More' => 1.001014,
		'Test::Pod' => 1.48,
		'Test::TCP' => 2.02,
		'Test::Version' => 1.002003,
	},
	configure_requires =>
	{
		'Module::Build' => 0.4211,
	},
	requires =>
	{
		'File::Spec' => 0,
		'File::Spec::Unix' => 0,
		'IO::Socket' => 0,
		'Pod::Simple' => 3.01,
		'Pod::Simple::HTML' => 0,
		'Pod::Simple::HTMLBatch' => 0,
		'Pod::Simple::Progress' => 0,
		'strict' => 0,
		'Test::Version' => 1.002003,
		'warnings' => 0,
	},
	resources =>
	{
		'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Webserver',
		'license' => 'http://opensource.org/licenses/Artistic-2.0',
		'repository' => 'https://github.com/ronsavage/Pod-Webserver',
	},
) -> create_build_script();
