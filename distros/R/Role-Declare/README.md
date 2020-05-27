## COPYRIGHT NOTICE

'Role::Declare' is Copyright (C) 2020, Perceptyx Inc, Szymon Nieznański

# Role::Declare

Declarative parameter and return type checking

## Usage

In the interface Role:

```perl
    package My::Class::interface;
    
    use Role::Declare;
    use Types::Standard qw/:all/;
    
    class_method create_object ( Str $name, Int $age ) : Returns( InstanceOf['My::Class'] ) {
        die "Age cannot be negative: $age" if $age < 0;
    };
```

In the interface implementation:

```perl
    package My::Class;
    use Role::Declare::StrictWith;
    
    strict_with 'My::Class::interface';
    
    sub create_object { ...  }
```

or:

```perl
    package My::Class;
    use Role::Tiny::With;
    
    with 'My::Class::interface';
    
    sub create_object { ...  }
```

## About

Perl doesn't provide a way to describe an interface,
much less validate its implementation. This module aims to fill that gap
by providing an easy way to build a validation layer with subroutine
attributes and [Function::Parameters](https://metacpan.org/pod/Function::Parameters) syntax.

## LICENSE INFORMATION

This package is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.

This package is distributed in the hope that it will be useful, but it is
provided “as is” and without any express or implied warranties.

For details, see the full text of the license in the file LICENSE.
