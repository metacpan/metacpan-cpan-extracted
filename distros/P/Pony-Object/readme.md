# Pony::Object

Pony::Object - An object system for Perl.

If you wanna protected methods, abstract classes and other OOP stuff,
you may use Pony::Object. Also Pony::Objects are strict and modern.

# Installation

Supports Perl>=5.014

```perl
cpan Pony::Object
```

See full documentation on [metacpan](https://metacpan.org/pod/Pony::Object).

# Usage

New-style objects:

```Perl
package User {
  use Pony::Object;

  protected 'name';
  protected 'age';

  sub init($self, $name, $age) {
    $self->name = $name;
    $self->age = $age;
  }

  sub hello($self) {
    print("Hello, " + $self->name);
  }
}
```

Exceptions:

```Perl
package InvalidAgeException {
  use Pony::Object qw/Pony::Object::Throwable/;
}


package User {
  use Pony::Object;

  protected 'name';
  protected 'age';

  sub init($self, $name, $age) {
    $self->name = $name;

    throw InvalidAgeException if $age < 0;
    $self->age = $age;
  }
}


package main {
  use Pony::Object qw(:exceptions);

  try {
    my $user = new User('Joe', -1);
  } catch {
    my $e = shift; # get exception object

    if ($e->isa('InvalidAgeException')) {
      # handle exception
    }
  };
}
```

And many other features.

# COPYRIGHT AND LICENSE

Copyright (C) 2011 - 2018, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.
