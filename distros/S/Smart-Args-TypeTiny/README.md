[![Build Status](https://travis-ci.org/akiym/Smart-Args-TypeTiny.svg?branch=master)](https://travis-ci.org/akiym/Smart-Args-TypeTiny)
# NAME

Smart::Args::TypeTiny - We are smart, smart for you

# SYNOPSIS

    use Smart::Args::TypeTiny;
    use Types::Standard -all;

    sub func2 {
        args my $p => Int,
             my $q => {isa => Int, optional => 1},
             ;
    }
    func2(p => 3, q => 4); # p => 3, q => 4
    func2(p => 3);         # p => 3, q => undef

    sub func3 {
        args my $p => {isa => Int, default => 3};
    }
    func3(p => 4); # p => 4
    func3();       # p => 3

    package F;
    use Moo;
    use Smart::Args::TypeTiny;
    use Types::Standard -all;

    sub method {
        args my $self,
             my $p => Int,
             ;
    }
    sub class_method {
        args my $class => ClassName,
             my $p     => Int,
             ;
    }

    sub simple_method {
        args_pos my $self, my $p;
    }

    my $f = F->new();
    $f->method(p => 3);

    F->class_method(p => 3);

    F->simple_method(3);

# DESCRIPTION

Smart::Args::TypeTiny provides [Smart::Args](https://metacpan.org/pod/Smart::Args)-like argument validator using [Type::Tiny](https://metacpan.org/pod/Type::Tiny).

# IMCOMPATIBLE CHANGES WITH Smart::Args

## ISA TAKES Type::Tiny TYPE OBJECT OR INSTANCE CLASS NAME

This code is expected `$p` as InstanceOf\['Int'\], you should specify [Type::Tiny](https://metacpan.org/pod/Type::Tiny)'s type constraint.

    use Types::Standard -all;

    sub foo {
        args my $p => 'Int', # :( InstanceOf['Int']
             my $q => Int,   # :) Int
             my $r => 'Foo', # :) InstanceOf['Foo']
    }

## DEFAULT PARAMETER CAN TAKE CODEREF AS LAZY VALUE

    sub foo {
        args my $p => {isa => 'Foo', default => create_foo},         # :( create_foo is called every time even if $p is passed
             my $q => {isa => 'Foo', default => sub { create_foo }}, # :) create_foo is called only when $p is not passed
             ;
    }

# TIPS

## SKIP TYPE CHECK

For optimization calling subroutine in runtime type check, you can overwrite `check_rule` like following code:

    {
        no warnings 'redefine';
        sub Smart::Args::TypeTiny::check_rule {
            my ($rule, $value, $exists, $name) = @_;
            return $value;
        }
    }

# SEE ALSO

[Smart::Args](https://metacpan.org/pod/Smart::Args), [Params::Validate](https://metacpan.org/pod/Params::Validate), [Params::ValidationCompiler](https://metacpan.org/pod/Params::ValidationCompiler)

[Type::Tiny](https://metacpan.org/pod/Type::Tiny), [Types::Standard](https://metacpan.org/pod/Types::Standard)

# LICENSE

Copyright (C) Takumi Akiyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Takumi Akiyama <t.akiym@gmail.com>
