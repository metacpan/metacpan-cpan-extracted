use strict;
use warnings;
use Test::More 'no_plan';
use Data::Dumper;

BEGIN { chdir 't' if -d 't' }
BEGIN { use lib '../lib'    }

### DECLARE
my $Class   = 'Params::Profile';
my $DV_profile = {
                'required'              => [ qw/paramone
                                                paramtwo
                                            /
                                            ],
                'optional'              => [ qw/paramopt/ ],
                'constraint_methods'    => {
                        'paramone'  => qr/^[a-z]+$/,
                        'paramopt'  => qr/^[0-9]+$/,
                    },
            };
my $PC_profile = {
                paramone    => {
                                required    => 1,
                                allow       => qr/^[a-z]+$/,
                            },
                paramtwo    => {
                                required    => 1,
                            },
                paramopt    => {
                                required    => 0,
                                allow       => qr/^[0-9]+$/,
                            },
            };

### USE CLASS
use_ok( $Class );

### Subroutines
ok($Class->register_profile(
                        'method'                => 'hello_world',
                        'profile'               => {
                                                        'required' => [qw/hello/],
                                                        'optional' => [qw/world/],
                                                        'constraint_methods'    => {
                                                                'hello'     => qr/\w+/,
                                                            },
                                                    }
                    ), 'Register hello_world profile');
sub hello_world {
    my (%opt) = @_;
    ok($Class->validate('params' => \%opt), 'hello_world: All parameters are valid');
    ok($Class->check('params' => \%opt)->valid('hello'), 'hello_world: option hello is valid');
}

{
    $Class->register_profile(
            'method'                => 'hello_world_extra',
            'profile'               => [
                                        'hello_world',
                                        {
                                            'required' => [qw/extra/],
                                            'constraint_methods'    => {
                                                    'extra'     => qr/\w+/,
                                                },
                                        }
                                    ],
        );

    sub hello_world_extra {
        my (%opt) = @_;
        return $Class->validate('params' => \%opt);
    }
}

### CHECKS
hello_world('hello' => 'world');
ok(!hello_world_extra('hello' => 'world'), 'Combined profile, not enough parameters');
ok(hello_world_extra('hello' => 'world', 'extra' => 'nee'), 'Combined profile, enough parameters');
