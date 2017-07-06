use Module::Build;
use strict;
use warnings;

my $build =  Module::Build->new
    ( dist_name     => 'REST-Neo4p',
      dist_abstract => 'Perl bindings for a Neo4j graph database',
      dist_version_from => 'lib/REST/Neo4p.pm',
      dist_author => 'Mark A. Jensen',
      license => 'perl',
      requires => {
	'JSON' => 2.0,
	'JSON::XS' => 2.0,
	'HOP::Stream' => 0,
	'URI::Escape' => 3.3,
	'LWP::UserAgent' => 6.04,
	'LWP::Protocol::https' => 6.06,
	'Exception::Class' => 1.3,
	'Tie::IxHash' => 0,
	'experimental' => 0,
	perl => 5.010001
       },
      recommends => {
	'Mojo::UserAgent' => 0,
	'HTTP::Thin' => 0
       },
      configure_requires => {
	'Module::Build' => 0
       },
      build_requires => {
	'Module::Build' => 0,
	'Test::More' => 0,
	'Test::Exception' => 0,
	'Test::NoWarnings' => 0,
	'Mock::Quick' => 0,
	'List::MoreUtils' => 0,
	'Mojo::Exception' => 0,
	experimental => 0

       },
      build_recommends => {
	 'Test::Pod' => 1.0,
#         'Test::Memory::Usage' => 0,
	 'Mojo::UserAgent' => 0,
	 'HTTP::Thin' => 0
	},
      meta_merge => {
	resources => {
	  bugtracker => 'http://rt.cpan.org/Public/Dist/Display.html?Name=REST-Neo4p',
	  repository  => 'http://github.com/majensen/rest-neo4p.git',
         }
       },
      perl => 5.010
     );

$build->notes( test_server => $ENV{REST_NEO4P_TEST_SERVER} // $build->prompt("Server for live tests:", "http://127.0.0.1:7474"));
$build->notes( user => $ENV{REST_NEO4P_TEST_USER} // $build->prompt("Username:", "neo4j") );
$build->notes( pass => $ENV{REST_NEO4P_TEST_PASS} // $build->prompt("Pass:", "neo4j") );
$build->create_build_script;
