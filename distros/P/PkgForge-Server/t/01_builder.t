#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

use PkgForge::BuildCommand::Builder::RPM;

my $builder = PkgForge::BuildCommand::Builder::RPM->new(
  platform     => "f13",
  architecture => "i386",
);

isa_ok( $builder, 'PkgForge::BuildCommand::Builder::RPM' );

can_ok( $builder, ('run') );

can_ok( $builder, ('build') );

can_ok( $builder, ('verify_environment') );

can_ok( $builder, ('filter_sources') );

is( $builder->name, 'f13-i386', 'name correctly built' );

is_deeply( $builder->accepts, ['SRPM'], 'accepts correct types' );

done_testing();
