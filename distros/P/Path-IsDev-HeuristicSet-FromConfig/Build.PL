
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.4007"
  },
  "configure_requires" => {
    "Module::Build" => "0.4007"
  },
  "dist_abstract" => "A Custom Heuristic Set from a configuration file",
  "dist_author" => [
    "Kent Fredric <kentfredric\@gmail.com>"
  ],
  "dist_name" => "Path-IsDev-HeuristicSet-FromConfig",
  "dist_version" => "0.002000",
  "license" => "perl",
  "module_name" => "Path::IsDev::HeuristicSet::FromConfig",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Class::Tiny" => 0,
    "File::UserConfig" => 0,
    "JSON" => 0,
    "Path::IsDev::NegativeHeuristic::HomeDir" => "1.000000",
    "Path::IsDev::NegativeHeuristic::PerlINC" => "1.000000",
    "Path::IsDev::Role::HeuristicSet::Simple" => 0,
    "Path::Tiny" => 0,
    "Role::Tiny::With" => 0,
    "perl" => "5.006",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "File::Spec" => 0,
    "FindBin" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Path::IsDev::Object" => 0,
    "Test::File::ShareDir" => 0,
    "Test::More" => "0.99"
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
