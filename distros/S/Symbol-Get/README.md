# NAME

Symbol::Get - Read Perl’s symbol table programmatically

# SYNOPSIS

    package Foo;

    our $name = 'haha';
    our @list = ( 1, 2, 3 );
    our %hash = ( foo => 1, bar => 2 );

    use constant my_const => 'haha';

    use constant my_const_list => qw( a b c );

    sub doit { ... }

    my $name_sr = Symbol::Get::get('$Foo::name');    # \$name
    my $list_ar = Symbol::Get::get('@Foo::list');    # \@list
    my $hash_hr = Symbol::Get::get('%Foo::hash');    $ \%hash

    #Defaults to __PACKAGE__ if none is given:
    my $doit_cr = Symbol::Get::get('&doit');

    #Constants:
    my $const_val = Symbol::Get::copy_constant('Foo::my_const');
    my @const_list = Symbol::Get::copy_constant('Foo::my_const_list');

    #The below return the same results since get_names() defaults
    #to the current package if none is given.
    my @names = Symbol::Get::get_names('Foo');      # keys %Foo::
    my @names = Symbol::Get::get_names();

# DESCRIPTION

Occasionally I have need to reference a variable programmatically.
This module facilitates that by providing an easy, syntactic-sugar-y,
read-only interface to the symbol table.

The SYNOPSIS above should pretty well cover usage.

# ABOUT PERL CONSTANTS

Previous versions of this module endorsed constructions like:

    my $const_sr = Symbol::Get::get('Foo::my_const');
    my $const_ar = Symbol::Get::get('Foo::my_const_list');

… to read constants from the symbol table. This isn’t reliable across
Perl versions, though, so don’t do it; instead, use `copy_constant()`.

# SEE ALSO

- [Symbol::Values](https://metacpan.org/pod/Symbol%3A%3AValues)

# LICENSE

This module is licensed under the MIT License.
