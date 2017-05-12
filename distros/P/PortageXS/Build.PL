
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.4005"
  },
  "configure_requires" => {
    "Module::Build" => "0.4005"
  },
  "dist_abstract" => "Portage abstraction layer for perl",
  "dist_author" => [
    "Christian Hartmann <ian\@gentoo.org>",
    "Torsten Veller <tove\@gentoo.org>",
    "Kent Fredric <kentnl\@cpan.org>"
  ],
  "dist_name" => "PortageXS",
  "dist_version" => "0.3.1",
  "license" => "gpl",
  "module_name" => "PortageXS",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "IO::Handle" => 0,
    "Moo" => "1.000008",
    "Path::Tiny" => 0,
    "Role::Tiny" => 0,
    "Role::Tiny::With" => 0,
    "Scalar::Util" => 0,
    "Shell::EnvImporter" => 0,
    "Term::ANSIColor" => 0,
    "Tie::Hash::Method" => 0,
    "overload" => 0,
    "perl" => "v5.10.0",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Test::More" => "0.98",
    "Test::Simple" => 0,
    "lib" => 0
  }
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  my $tr = delete $module_build_args{test_requires};
  my $br = $module_build_args{build_requires};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
