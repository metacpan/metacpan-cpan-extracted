# Object::Simple - Simplest class builder, Mojo::Base porting, fast and less memory

- **Simplest class builder**. All you learn is only *has* function!
- **Mojo::Base porting**. Do you like Mojolicious? If so, this is good choices!
- **Fast and less memory**. Fast *new* and accessor method. Memory saving implementation.

```
    package SomeClass;
    use Object::Simple -base;
    
    # Create accessor
    has 'foo';
    
    # Create accessor with default value
    has foo => 1;
    has foo => sub { [] };
    has foo => sub { {} };
    has foo => sub { OtherClass->new };
    
    # Create accessors at once
    has [qw/foo bar baz/];
    has [qw/foo bar baz/] => 0;
```

If you learn more, See [public doucumentation on cpan](http://search.cpan.org/~kimoto/Object-Simple/lib/Object/Simple.pm).
