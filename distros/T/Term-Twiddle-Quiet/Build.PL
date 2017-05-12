
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
  module_name   => 'Term::Twiddle::Quiet',
  license       => 'perl',
  dist_abstract => "Twiddles\ a\ thingy\ while\-u\-wait\ if\ run\ interactively",
  dist_name     => "Term\-Twiddle\-Quiet",
  dist_author   => [
"Jerome\ Quelin",
  ],
  requires      => {
    "perl" => '5.008',
    "Test::MockObject" => '0',
    "Test::More" => '0',
    "English" => '0',
    "File::Find" => '0',
    "Term::Twiddle" => '0',
    "IO::Interactive" => '0',
  },
  script_files => [ qw() ],
);

$build->create_build_script;
