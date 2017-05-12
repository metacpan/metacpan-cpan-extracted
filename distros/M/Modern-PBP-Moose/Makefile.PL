use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Modern::PBP::Moose',
    AUTHOR              => 'Juergen von Brietzke <juergen.von.brietzke@t-online.de>',
    VERSION_FROM        => 'lib/Modern/PBP/Moose.pm',
    ABSTRACT_FROM       => 'lib/Modern/PBP/Moose.pm',
    PL_FILES            => {},
    MIN_PERL_VERSION    => '5.012000',
    PREREQ_PM => {
      'perl'                                 => 5.012000,
      'Hook::AfterRuntime'                   => 0,
      'Modern::PBP::Perl'                    => 0,
      'Moose'                                => 0,
      'Moose::Exporter'                      => 0,
      'Moose::Util::TypeConstraints'         => 0,
      'MooseX::AttributeShortcuts'           => 0,
      'MooseX::DeclareX'                     => 0,
      'MooseX::DeclareX::Keyword::interface' => 0,
      'MooseX::DeclareX::Plugin::abstract'   => 0,
      'MooseX::DeclareX::Plugin::singleton'  => 0,
      'MooseX::DeclareX::Privacy'            => 0,
      'MooseX::HasDefaults::RO'              => 0,
      'namespace::autoclean'                 => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'          => 0,
        'Test::Perl::Critic'  => 0,
        'Test::Pod'           => 1.14,
        'Test::Pod::Coverage' => 1.04,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Modern-PBP-Moose-*' },
);
