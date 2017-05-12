package TestModuleCompile;
use Test::Base -Base;

use lib -e 't' ? 't/lib' : 'test/lib';

use Module::Compile();

package TestModuleCompile::Filter;
use base 'Test::Base::Filter';

sub process_pm {
    Module::Compile->pmc_process(shift);
}

sub parse_pm {
    Module::Compile->pmc_parse_blocks(shift);
}

sub yaml_dump {
    require YAML;
    YAML::Dump(@_);
}
