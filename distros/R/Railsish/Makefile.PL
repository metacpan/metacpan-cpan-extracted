
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'Railsish',
  NAME      => 'Railsish',
  AUTHOR    => 'Liu\ Kang\-min\ \<gugod\@gugod\.org\>',
  ABSTRACT  => 'A web application framework.',
  VERSION   => '0.21',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'mit') : ()),
  PREREQ_PM    => {
    "String::CamelCase" => '0.01',
    "XML::Simple" => '2.18',
    "Data::Visitor" => '0.24',
    "JSON::XS" => '2.232',
    "Path::Router" => '0.06',
    "Perl6::Junction" => '1.4000',
    "YAML::Any" => '0.67',
    "Mouse" => '0.22',
    "HTTP::Engine" => '0.1.7',
    "Class::Implant" => '0.01',
    "File::Spec::Functions" => '3.29',
    "Moose" => '0.75',
    "Binding" => '0.04',
    "Hash::Merge" => '0.10',
    "Module::Refresh" => '0.13',
    "Template" => '2.20',
    "Devel::Symdump" => '2.08',
    "Module::Loaded" => '0.01',
    "MooseX::Types" => '0.10',
    "Any::Moose" => '0.07',
    "MouseX::Types" => '0.01',
    "Log::Dispatch" => '2.22',
    "Lingua::En::Inflect::Number" => '0',
    "UNIVERSAL::require" => '0',
  },
);
