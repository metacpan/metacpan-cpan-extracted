use Module::Build;

my $class = Module::Build->subclass(code => <<'EOF');

sub ACTION_build
{
	my $self = shift;
	$self->SUPER::ACTION_build(@_);
	$self->run_perl_script('scripts/copy.config.pl');
}
EOF

$class -> new
(
 module_name    => 'Module::Metadata::CoreList',
 license        => 'artistic',
 dist_abstract  => 'Scripts to cross-check Build.PL/Makefile.PL with Module::CoreList, etc',
 dist_author    => 'Ron Savage <ron@savage.net.au>',
 build_requires =>
 {
	 "Test::More" => 0,
	 'Test::Pod'  => 0,
 },
 configure_requires =>
 {
 	 Module::Build => 0,
 },
 requires =>
 {	# Deliberately do not use version numbers in most cases.
	# This makes it easier to test the module on itself.
	# See t/test.corelist.t for details.
	Capture::Tiny    => 0,
	Config           => 0,
	Config::Tiny     => 0,
	Date::Simple     => 0,
	File::Copy       => 0,
	File::HomeDir    => 0.99,
	File::Spec       => 0,
	Getopt::Long     => 0,
	Hash::FieldHash  => 0,
	Module::CoreList => 2.61,
	Path::Class      => 0,
	Pod::Usage       => 0,
	strict           => 0,
	Text::Xslate     => 0,
	warnings         => 0,
 },
) -> create_build_script();
