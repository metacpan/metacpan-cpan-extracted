use Module::Build;

Module::Build -> new
(
 module_name    => 'Search::InvertedIndex::Simple',
 license        => 'artistic',
 dist_abstract  => 'Build indexes for a set of search keys',
 dist_author    => 'Ron Savage <ron@savage.net.au>',
 build_requires =>
 {
	 Test::More => 0,
	 Test::Pod  => 0,
 },
 configure_requires =>
 {
 	 Module::Build => 0.3800,
 },
 requires =>
 {
	Set::Array => 0.19,
	strict     => 1.03,
	warnings   => 1.03,
 },
) -> create_build_script();
