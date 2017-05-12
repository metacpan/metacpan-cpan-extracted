use Module::Build;

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
	module_name    => 'MojoX::ValidateHeadLinks',
	license        => 'artistic_2',
	dist_abstract  => 'Ensure CSS and JS links in web pages point to real files',
	dist_author    => 'Ron Savage <ron@savage.net.au>',
	build_requires =>
	{
		Test::More=> 0.94,
#		Test::Pod  => 1.45, # Make it optional. See t/pod.t
	},
	configure_requires =>
	{
		Module::Build => 0.3800,
	},
	meta_merge =>
	{
		resources =>
		{
			repository => 'https://github.com/ronsavage/MojoX-ValidateHeadLinks',
		},
	},
	requires =>
	{
		feature         => 1.20,
		Getopt::Long    => 2.38,
		Hash::FieldHash => 0.12,
		Log::Handler    => 0.75,
		Mojolicious     => 3.30,
		Pod::Usage      => 1.51,
		strict          => 1.03,
		Try::Tiny       => 0.11,
		warnings        => 1.03,
	},
) -> create_build_script();
