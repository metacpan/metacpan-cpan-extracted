use Module::Build;

Module::Build -> new
(
 module_name    => 'Set::Array',
 license        => 'artistic_2',
 dist_abstract  => 'Arrays as objects with lots of handy methods',
 dist_author    => 'Ron Savage <ron@savage.net.au>',
 build_requires =>
 {
	 Test::Deep => 0.108,
	 Test::More=> 0.47,
#	 Test::Pod  => 1.45, # Make it optional. See t/pod.t
 },
 configure_requires =>
 {
 	 Module::Build => 0.3800,
 },
 requires =>
 {
 	attributes => 0.06,
	Carp       => 0,
	overload   => 1.01,
	strict     => 1.03,
	subs       => 1.00,
	Try::Tiny  => 0.11,
	Want       => 0,
	warnings   => 1.03,
 },
) -> create_build_script();
