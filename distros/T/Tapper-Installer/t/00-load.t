#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;

my @modules = (
               'Tapper::Installer',
               'Tapper::Installer::Base',
               'Tapper::Installer::Precondition',
               'Tapper::Installer::Precondition::Copyfile',
               'Tapper::Installer::Precondition::Exec',
               'Tapper::Installer::Precondition::Fstab',
               'Tapper::Installer::Precondition::Image',
               'Tapper::Installer::Precondition::Kernelbuild',
               'Tapper::Installer::Precondition::Package',
               'Tapper::Installer::Precondition::PRC',
               'Tapper::Installer::Precondition::Rawimage',
               'Tapper::Installer::Precondition::Repository',
               'Tapper::Installer::Precondition::Simnow',
              );

plan tests => 2*(int @modules);

foreach my $module(@modules) {
        require_ok($module);
        my $obj = $module->new;
        isa_ok($obj, $module, "Object");
}
