package My::Target::patch::p2;

use parent qw(Module::Patch);

our %config;

sub patch_data {
    return {
        v => 3,
        patches => [
            {
                action => 'wrap',
                mod_version => '0.12',
                sub_name => 'foo',
                code => sub { "foo from p2" },
            },
        ],
    };
}

1;
# ABSTRACT: Patch module for My::Target
