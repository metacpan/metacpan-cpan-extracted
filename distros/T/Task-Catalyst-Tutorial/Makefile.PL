
use strict;
use warnings;
use inc::Module::Install;

name('Task-Catalyst-Tutorial');
abstract('Everything you need to follow the Catalyst Tutorial');
version_from('lib/Task/Catalyst/Tutorial.pm');
license('perl');
requires( 
	 'Catalyst::Runtime' => '5.7015',
	 'Catalyst::Devel'   => '1.08',
	 'Catalyst::Plugin::Authentication' => 0.10008,
	 'Catalyst::Authentication::Store::DBIx::Class' => 0.07,
	 'Catalyst::Plugin::Authorization::ACL' => 0.10,
	 'Catalyst::Plugin::Authorization::Roles' => 0.07,
	 'Catalyst::Controller::HTML::FormFu' => 0.03004,
	 'Catalyst::Plugin::Session' => 0.19,
	 'Catalyst::Plugin::Session::State::Cookie' => 0.09,
	 'Catalyst::Plugin::Session::Store::FastMmap' => 0.05,
	 'Catalyst::Plugin::StackTrace' => 0.09,
	 'DBIx::Class' => 0.08010,
	 'Catalyst::View::TT' => 0.27,
	 'Catalyst::Model::DBIC::Schema' => 0.21,
	 'Catalyst::Manual' => 5.7014,
	);
build_requres('Test::More' => 0);
no_index(directory => 'examples');
eval{ install_share('examples') };
auto_install();
WriteAll();
