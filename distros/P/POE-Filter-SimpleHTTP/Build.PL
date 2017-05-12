
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
  module_name   => 'POE::Filter::SimpleHTTP',
  license       => 'gpl',
  dist_abstract => "A\ simple\ filter\ for\ client\ and\ server\ HTTP\ contexts",
  dist_name     => "POE\-Filter\-SimpleHTTP",
  dist_author   => [
"Nicholas\ Perez\ \<nperez\@cpan\.org\>",
  ],
  requires      => {
    "Compress::Zlib" => '2.012',
    "URI" => '1.37',
    "perl" => '5.10.0',
    "Test::More" => '0',
    "Regexp::Common" => '2.122',
    "UNIVERSAL::isa" => '1.01',
    "LWP" => '5.822',
    "Moose" => '0.79',
  },
  script_files => [ qw() ],
);

$build->create_build_script;
