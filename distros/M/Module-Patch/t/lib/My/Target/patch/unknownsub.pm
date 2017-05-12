package My::Target::patch::unknownsub;

use parent qw(Module::Patch);

our %config;

sub patch_data {
    return {
        v => 3,
        patches => [
            {
                action => 'wrap',
                mod_version => '0.12',
                sub_name => 'qux',
                code => sub { "qux from unknownsub" },
            },
        ],
    };
}

1;
# ABSTRACT: Patch module for My::Target
