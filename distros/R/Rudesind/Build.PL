use strict;

use lib 'lib', 'inc';

use Rudesind::Build;

my $dist = $ARGV[0] && $ARGV[0] eq '--dist';

my $build =
    Rudesind::Build->new( module_name   => 'Rudesind',
                          license       => 'perl',
                          sign          => 1,
                          requires      =>
                          { 'Apache::Request'  => 0,
                            'Class::Roles'     => 0,
                            'Config::Auto'     => 0,
                            'File::Find::Rule' => 0,
                            'File::Slurp'      => 0,
                            'HTML::Mason'      => '1.10',
                            'Image::Magick'    => 0,
                            'Image::Size'      => 0,
                            'MasonX::WebApp'   => '0.04',
                            'Params::Validate' => 0,
                            'Path::Class'      => 0,
                            'Text::WikiFormat' => 0,
                          },
                          create_makefile_pl => 'passthrough',
                        );

$build->get_html_dir unless $dist;
$build->get_config_dir unless $dist;

print "\n" unless $dist;

$build->create_build_script;
