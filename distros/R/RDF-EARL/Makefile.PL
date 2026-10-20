use strict;
use warnings;

use lib '.';
use inc::Module::Install;
use Module::Install::DOAPChangeSets;
use Module::Install::AuthorTests;

name				'RDF-EARL';
all_from			'lib/RDF/EARL.pm';
author				'Gregory Todd Williams <gwilliams@cpan.org>';
license				'perl';

build_requires		'Test::More'				=> 0.88;
build_requires		'Test::Exception'			=> 0;

perl_version		'5.008003';

requires			'Moose'						=> 2;
requires			'Scalar::Util'				=> 0;
requires			'Attean'					=> '0.039';

resources(
	'homepage'   => "http://search.cpan.org/dist/RDF-EARL/",
	'repository' => "https://github.com/kasei/rdf-earl",
	'bugtracker' => "https://github.com/kasei/rdf-earl/issues"
);

author_tests('xt');

write_doap_changes "meta/changes.ttl", "Changes", "turtle";

# On MacOS, prefer homebrew-installed GNU tar so that we don't include Mac-specific
# extended header data (which results in "Ignoring unknown extended header keyword"
# messages on non-Mac systems when extracting data.
if (-x '/opt/homebrew/bin/gtar') {
	makemaker_args(
		dist => {
			TAR => '/opt/homebrew/bin/gtar'
		}
	);
}

sign if ! exists $ENV{CI};
WriteAll;
