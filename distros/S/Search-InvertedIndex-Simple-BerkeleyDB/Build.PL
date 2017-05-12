use Module::Build;

Module::Build -> new
(
 module_name    => 'Search::InvertedIndex::Simple::BerkeleyDB',
 license        => 'artistic',
 dist_abstract  => 'Build indexes for a set of search keys; Search using BerkeleyDB',
 dist_author    => 'Ron Savage <ron@savage.net.au>',
 build_requires =>
 {
	 Test::More => 0.94,
	 Test::Pod  => 1.41,
 },
 configure_requires =>
 {
 	 Module::Build => 0.3800,
 },
 requires =>
 {
	 BerkeleyDB                    => 0.41,
	 Search::InvertedIndex::Simple => 1.03,
	 Set::Array                    => 0.19,
 },
) -> create_build_script();
