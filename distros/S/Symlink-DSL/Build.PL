
# This file was automatically generated by Dist::Zilla::Plugin::ModuleBuild v6.024.
use strict;
use warnings;

use Module::Build 0.28;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.28"
  },
  "configure_requires" => {
    "Module::Build" => "0.28"
  },
  "dist_abstract" => "a domain-specific language for setting up symbolic links.",
  "dist_author" => [
    "Shlomi Fish <shlomif\@cpan.org>"
  ],
  "dist_name" => "Symlink-DSL",
  "dist_version" => "0.4.0",
  "license" => "mit",
  "module_name" => "Symlink::DSL",
  "recursive_test_files" => 1,
  "requires" => {
    "Cwd" => 0,
    "File::Basename" => 0,
    "File::Path" => 0,
    "File::Spec" => 0,
    "Getopt::Long" => 0,
    "autodie" => 0,
    "perl" => "5.014",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [
    "bin/symlink-dsl"
  ],
  "test_requires" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => "0.88"
  }
);


my %fallback_build_requires = (
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Module::Build" => "0.28",
  "Test::More" => "0.88"
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);


$build->create_build_script;
