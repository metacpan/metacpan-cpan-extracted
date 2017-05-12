# $Id: Build.PL,v 1.9 2008/08/03 17:08:39 asc Exp $

use strict;
use Module::Build;

my $build = Module::Build->new(module_name => 'Net::Flickr::Geo',
			       # dist_author
			       # dist_abstract
			       dist_version_from => 'lib/Net/Flickr/Geo.pm',
			       license           => 'perl',
			       requires => {
                                            'Config::Simple'  => '0',
                                            'Date::Calc' => '0',
                                            'Flickr::Upload' => '1.31',
                                            'GD' => '>= 2.35',
                                            'Geo::Coordinates::DecimalDegrees' => '0',
                                            'Geo::Distance' => 0,
                                            'Geo::Geotude' => '>=1.0',
                                            'HTTP::Request' => 0,
                                            'Image::Size' => 0,
                                            'Imager' => '>= 0.62',
                                            'List::Util' => '0',
                                            'LWP::Simple' => '0',
                                            'LWP::UserAgent' => '0',
                                            'MIME::Base64' => '0',
                                            'Net::Flickr::API' => '>= 1.67',
                                            'Net::ModestMaps' => '>= 1.1',
                                            'POSIX' => '0',
                                            'URI' => 0,
			       },
			       build_requires => {
				   'Test::Simple'              => '>= 0.47',
			       },
			       create_readme      => 1,
			       create_makefile_pl => 'passthrough');

$build->create_build_script();
