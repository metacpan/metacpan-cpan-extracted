# NAME
`OOP::Private` - Private and protected methods.

# SYNOPSIS
```perl
package Foo;
use OOP::Private;

sub publicMethod { ... }

# Croaks when called from outside of the package
sub privateMethod: Private {
    ...
}

# Same as the one above, but allows access from child classes
sub protectedMethod: Protected {
    ...
}

1;
```

# INSTALLATION
```bash
git clone https://git.nixnet.xyz/john-smith/perl-oop-private.git
cd perl-oop-private
make Makefile.PL
make test && make install
```

```bash
cpan OOP::Private
cpanm OOP::Private
```

# COVERAGE
Inside the build directory:
```bash
cover -test
cover -report $format
```
For possible values of `$format` see `man cover`.
%%Don't waste your time, it's 100% covered%%

# DOCUMENTATION
```bash
perldoc OOP::Private
```

# AUTHOR
Copyright © Anonchique Aiteeshnique <anonymous@cpan.org>

# LICENSE
Artistic 2.0, see LICENSE

# VERSION
1.01
