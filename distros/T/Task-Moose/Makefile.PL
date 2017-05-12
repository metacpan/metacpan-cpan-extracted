use strict;
use warnings;
use inc::Module::Install 0.75;

name 'Task-Moose';
all_from 'lib/Task/Moose.pm';
license 'perl';

requires 'Moose' => 0.92;


# Make Moose Stricter

feature 'Making Moose constructors stricter',
  -default                    => 0,
  'MooseX::StrictConstructor' => 0.08;

feature 'Moose-ish method parameter handling',
  -default                   => 0,
  'MooseX::Params::Validate' => 0.06;

# Traits / Roles

feature 'Runtime trait application in constructors',
  -default                         => 0,
  'MooseX::Role::TraitConstructor' => 0;

feature 'Easy creation of objects with traits',
  -default         => 0,
  'MooseX::Traits' => 0;

feature 'Moose-ish plugin system',
  -default                    => 0,
  'MooseX::Object::Pluggable' => 0;

feature 'Parameterized roles',
  -default                      => 0,
  'MooseX::Role::Parameterized' => 0;

# Instance Types

feature 'Globref instance type for Moose',
  -default          => 0,
  'MooseX::GlobRef' => 0;

feature 'Inside out instance type for Moose',
  -default            => 0,
  'MooseX::InsideOut' => 0;

feature 'Singleton instance type for Moose',
  -default            => 0,
  'MooseX::Singleton' => 0.20;

feature 'Subclassing of non-Moose classes',
  -default           => 0,
  'MooseX::NonMoose' => 0.06;

# Devel::Declare children

feature 'Declarative syntax with Devel::Declare',
  -default          => 0,
  'MooseX::Declare' => 0;

feature 'Declarative method syntax',
  -default                     => 0,
  'MooseX::Method::Signatures' => 0;

feature 'Declarative exception handling',
  -default   => 0,
  'TryCatch' => 0;

# Types

feature 'Moose type extensions',
  -default        => 0,
  'MooseX::Types' => 0.20;

feature 'Structured type constraints',
  -default                    => 0,
  'MooseX::Types::Structured' => 0;

feature 'Path::Class Moose type extension',
  -default                     => 0,
  'MooseX::Types::Path::Class' => 0;

feature 'Set::Object Moose type extension',
  -default                     => 0,
  'MooseX::Types::Set::Object' => 0;

feature 'DateTime Moose type extension',
  -default                  => 0,
  'MooseX::Types::DateTime' => 0;


# Command line integration

feature 'Better script writing with Moose',
  -default         => 0,
  'MooseX::Getopt' => 0;

feature 'Support for config with MooseX::Getopt',
  -default                 => 0,
  'MooseX::ConfigFromFile' => 0;

feature 'Config file support for MooseX::Getopt with Config::Any',
  -default               => 0,
  'MooseX::SimpleConfig' => 0;

feature 'App::Cmd integration for Moose',
  -default           => 0,
  'MooseX::App::Cmd' => 0;

feature 'Easily wrap command line apps with Moose',
  -default            => 0,
  'MooseX::Role::Cmd' => 0;


# Logging

feature 'Log::Dispatch support for Moose',
  -default              => 0,
  'MooseX::LogDispatch' => 0;

feature 'lazy loaded Log::Dispatch support for Moose',
  -default                  => 0,
  'MooseX::LazyLogDispatch' => 0;

feature 'Log::Log4perl support for Moose',
  -default                => 0,
  'MooseX::Log::Log4perl' => 0;

# Async

feature 'Moose wrapped POE',
  -default      => 0,
  'MooseX::POE' => 0;

feature 'Sub-process management for asynchronous tasks using Moose and POE',
  -default          => 0,
  'MooseX::Workers' => 0;

# Utility Roles

feature 'Daemonization support roles for Moose',
  -default            => 0,
  'MooseX::Daemonize' => 0;

feature 'CGI-style parameter role',
  -default        => 0,
  'MooseX::Param' => 0;

feature 'Moose-ish iterator support role',
  -default           => 0,
  'MooseX::Iterator' => 0;

feature 'More robust and flexible cloning support',
  -default        => 0,
  'MooseX::Clone' => 0;

feature 'Moose serialization',
  -default          => 0,
  'MooseX::Storage' => 0;


# Other

feature 'Autoboxing support',
  -default         => 0,
  'Moose::Autobox' => 0;

feature 'Class attributes for Moose',
  -default                 => 0,
  'MooseX::ClassAttribute' => 0;

feature 'Support for PBP style accessors',
  -default                         => 0,
  'MooseX::SemiAffordanceAccessor' => 0;

feature "Keep imported subroutines out of your class's namespace",
  -default               => 0,
  'namespace::autoclean' => 0.09;


# Utilities

feature 'Pod::Coverage support for Moose',
  -default               => 0,
  'Pod::Coverage::Moose' => 0;

auto_install;
WriteAll;

