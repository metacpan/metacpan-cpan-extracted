
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'POE-Component-Server-Postfix',
  NAME      => 'POE::Component::Server::Postfix',
  AUTHOR    => 'Hans\ Dieter\ Pearcey\ \<hdp\@cpan\.org\>',
  ABSTRACT  => 'Postfix (MTA) server toolkit',
  VERSION   => '0.001',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "Test::More" => '0',
    "MooseX::POE" => '0',
    "POE::Wheel::SocketFactory" => '0',
    "POE::Filter::Postfix" => '0',
  },
);
