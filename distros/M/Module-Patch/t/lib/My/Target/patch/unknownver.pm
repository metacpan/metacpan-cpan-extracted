package My::Target::patch::unknownver;

use parent qw(Module::Patch);

our %config;

sub patch_data {
    return {
        v => 3,
        patches => [
            {
                action => 'wrap',
                mod_version => '0.13',
                sub_name => 'foo',
                code => sub { "foo from unknownver" },
            },
        ],
    };
}

1;
# ABSTRACT: Patch module for My::Target
