# NAME

MooX::Role::Parameterized - roles with composition parameters

[![Kwalitee](https://cpants.cpanauthors.org/dist/MooX-Role-Parameterized.svg)](https://cpants.cpanauthors.org/dist/MooX-Role-Parameterized)
[![tests](https://github.com/peczenyj/MooX-Role-Parameterized/actions/workflows/linux.yml/badge.svg)](https://github.com/peczenyj/MooX-Role-Parameterized/actions/workflows/linux.yml)
[![tests](https://github.com/peczenyj/MooX-Role-Parameterized/actions/workflows/windows.yml/badge.svg)](https://github.com/peczenyj/MooX-Role-Parameterized/actions/workflows/windows.yml)
[![tests](https://github.com/peczenyj/MooX-Role-Parameterized/actions/workflows/macos.yml/badge.svg)](https://github.com/peczenyj/MooX-Role-Parameterized/actions/workflows/macos.yml)
[![tests](https://github.com/peczenyj/MooX-Role-Parameterized/actions/workflows/perltidy.yml/badge.svg)](https://github.com/peczenyj/MooX-Role-Parameterized/actions/workflows/perltidy.yml)
[![tests](https://github.com/peczenyj/MooX-Role-Parameterized/actions/workflows/perlcritic.yml/badge.svg)](https://github.com/peczenyj/MooX-Role-Parameterized/actions/workflows/perlcritic.yml)
[![Coverage Status](https://coveralls.io/repos/github/peczenyj/MooX-Role-Parameterized/badge.svg?branch=master)](https://coveralls.io/github/peczenyj/MooX-Role-Parameterized?branch=master)
[![license](https://img.shields.io/cpan/l/MooX-Role-Parameterized.svg)](https://github.com/peczenyj/MooX-Role-Parameterized/blob/master/LICENSE)
[![cpan](https://img.shields.io/cpan/v/MooX-Role-Parameterized.svg)](https://metacpan.org/dist/MooX-Role-Parameterized)

## SYNOPSIS

    package Counter;
    use Moo::Role;
    use MooX::Role::Parameterized;
    use Types::Standard qw( Str );

    parameter name => (
        is       => 'ro',  # this is mandatory on Moo
        isa      => Str,   # optional type
        required => 1,     # mark the parameter "name" as "required"
    );

    role {
        my ( $p, $mop ) = @_;

        my $name = $p->name; # $p->{name} will also work
    
        $mop->has($name => (
            is      => 'rw',
            default => sub { 0 },
        ));
    
        $mop->method("increment_$name" => sub {
            my $self = shift;
            $self->$name($self->$name + 1);
        });
    
        $mop->method("reset_$name" => sub {
            my $self = shift;
            $self->$name(0);
        });
    };
    
    package MyGame::Weapon;
    use Moo;
    use MooX::Role::Parameterized::With;
    
    with Counter => {          # injects 'enchantment' attribute and
        name => 'enchantment', # methods increment_enchantment (+1)
    };                         # reset_enchantment (set to zero)
    
    package MyGame::Wand;
    use Moo;
    use MooX::Role::Parameterized::With;

    with Counter => {         # injects 'zapped' attribute and
        name => 'zapped',     # methods increment_zapped (+1)
    };                        # reset_zapped (set to zerà)

## DESCRIPTION

It is an **experimental** port of [MooseX::Role::Parameterized](https://metacpan.org/pod/MooseX::Role::Parameterized) to [Moo](https://metacpan.org/pod/Moo).

## FUNCTIONS

This package exports the following subroutines: `parameter`, `role`, `apply_roles_to_target` and `apply`.

### parameter

This function receive the same parameter as `Moo::has`. If present, the parameter hash reference will be blessed as a Moo class. This is useful to add default values or set some parameters as required.

### role

This function accepts just **one** code block. Will execute this code then we apply the Role in the
target class and will receive the parameter hash reference + one **mop** object.

The **params** reference will be blessed if there is some parameter defined on this role.

The **mop** object is a proxy to the target class.

It offer a better way to call `has`, `after`, `before`, `around`, `with` and `requires` without side effects.

Use `method` to inject a new method and `meta` to access `TARGET_PACKAGE->meta`

Please use:

    my ($p, $mop) = @_;
    ...
    $mop->has($p->{attribute} =>(...));

    $mop->method(name => sub { ... });

    $mop->meta->make_immutable;

### apply

Alias to `apply_roles_to_target`.

### apply_roles_to_target

When called, will apply the `/role` on the current package. The behavior depends of the parameter list.

This will install the role in the target package. Does not need call `with`.

Important, if you want to apply the role multiple times, like to create multiple attributes, please pass an **arrayref**.

    package My::Role;

    use Moo::Role;
    use MooX::Role::Parameterized;

    role {
        my ($params, $mop) = @_;

        $mop->has( $params->{attr} => ( is => 'rw' ));

        $mop->method($params->{method} => sub {
            1024;
        });
    };

    package My::Class;

    use Moo;
    use My::Role;

    My::Role->apply_roles_to_target([{ # original way of add this role
        attr   => 'baz',               # add attribute read-write called 'baz' 
        method => 'run'                # add method called 'run' and return 1024 
    }
     ,                                 # and if the apply receives one arrayref
    {   attr   => 'bam',               # will call the role block multiple times.
        method => 'jump'               # PLEASE CALL apply once
    }]);

## MooX::Role::Parameterized::VERBOSE

By setting `$MooX::Role::Parameterized::VERBOSE` with some true value we will carp on certain conditions
(method override, unable to load package, etc).

Default is false.

## DEPRECATED FUNCTIONS

### hasp

Deleted

### method

Deleted

## MooX::Role::Parameterized::With

See [MooX::Role::Parameterized::With](https://metacpan.org/pod/MooX::Role::Parameterized::With) package to easily load and apply roles.


Allow to do this:

    package FooWith;

    use Moo;
    use MooX::Role::Parameterized::With; # overrides Moo::with

    with "Bar" => {           # apply parameterized role Bar once
        attr => 'baz',
        method => 'run'
    }, "Other::Role" => [     # apply parameterized role "Other::Role" twice
        { ... },              # with different parameters
        { ... },
        ],
        "Some::Moo::Role",
        "Some::Role::Tiny";

    has foo => ( is => 'ro'); # continue with normal Moo code

## SEE ALSO

[MooseX::Role::Parameterized](https://metacpan.org/pod/MooseX::Role::Parameterized) - Moose version

## THANKS

* FGA <fabrice.gabolde@gmail.com>
* PERLANCAR <perlancar@gmail.com>
* CHOROBA <choroba@cpan.org>
* Ed J <mohawk2@users.noreply.github.com>

## LICENSE

The MIT License

    Permission is hereby granted, free of charge, to any person
    obtaining a copy of this software and associated
    documentation files (the "Software"), to deal in the Software
    without restriction, including without limitation the rights to
    use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to
    whom the Software is furnished to do so, subject to the
    following conditions:
     
     The above copyright notice and this permission notice shall
     be included in all copies or substantial portions of the
     Software.
      
      THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
      WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
      INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
      MERCHANTABILITY, FITNESS FOR A PARTICULAR
      PURPOSE AND NONINFRINGEMENT. IN NO EVENT
      SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
      LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
      LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
      TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
      CONNECTION WITH THE SOFTWARE OR THE USE OR
      OTHER DEALINGS IN THE SOFTWARE.

## AUTHOR

Tiago Peczenyj <tiago (dot) peczenyj (at) gmail (dot) com>

## BUGS

Please report any bugs or feature requests on the bugtracker website
