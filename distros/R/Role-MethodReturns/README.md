## COPYRIGHT NOTICE

'Role::MethodReturns' is Copyright (C) 2019, Perceptyx Inc, Theo van Hoesel

# Perl - Role MethodReturns

around Method Modifiers with Parameter & Return Type Check

## Usage


In the Interface Role:

```perl
    package My::Class::interface;
    
    use Role::MethodReturns;
    use Types::Standard qw/:all/;
    
    around create_object => class_method ( Str $name, Int $age ) {
        returns( InstanceOf['My::Class'] ,
            $original->( $class => ( $name, $age )
        )
    };
```

In the Interface consuming Class:

```perl
    package My::Class;
    
    use Role::Tiny::With;
    
    with My::Class::interface unless $ENV{ROLE_METHOD_RETURN}
    
    sub create_object {
        ...
    }
```

## About

The interfaces being defined as roles
( using [Role::Tiny](https://metacpan.org/pod/Role::Tiny) )
and use `around` method modifiers, instead of `require`, we do want to wrap the
method in type checking
( using [Type::Tiny](https://metacpan.org/pod/Type::Tiny) and friends ).


## LICENSE INFORMATION

This package is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.

This package is distributed in the hope that it will be useful, but it is
provided “as is” and without any express or implied warranties.

For details, see the full text of the license in the file LICENSE.
