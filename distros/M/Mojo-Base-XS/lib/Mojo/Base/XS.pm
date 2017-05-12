package Mojo::Base::XS;

use strict;
use warnings;

use 5.010;
require feature;

our $VERSION = 0.07;
require XSLoader;

XSLoader::load('Mojo::Base::XS', $VERSION);

my $base_infected;

sub import {
    my $class = shift;
    my $flag = shift || '';

    if ($flag eq '-infect') {
        return if $base_infected++;

        # Check if no Mojo::Base loaded
        if (UNIVERSAL::can('Mojo::Base', 'new')) {
            require Carp;
            Carp::croak(
                "You must load Mojo::Base::XS before loading Mojo::Base");
        }

        # Load and monkey-patch Mojo::Base
        require Mojo::Base;

        no strict 'refs';
        no warnings 'redefine';

        newxs_attr('Mojo::Base::attr');
        newxs_constructor('Mojo::Base::new');
    }
    else {
        my $caller = caller;

        no strict 'refs';
        no warnings 'redefine';

        newxs_attr($caller . '::attr');
        newxs_constructor($caller . '::new');

        # TODO: turn this into XS code
        *{"${caller}::has"} = sub { attr($caller, @_) };
    }
}

1;

__END__

=head1 NAME

Mojo::Base::XS - very fast Mojo-styled accessors


=head1 SYNOPSIS

    # Replace Mojo::Base
    use Mojo::Base::XS -infect;
    package Foo;
    use Mojo::Base;

    has foo => 'bar';
    has [qw/x y z/] => 42;
    has foo_defaults => sub { Bar->new };

    # Or use as standalone accessor generator
    package Bar;
    use Mojo::Base::XS;

    has bar => 'bar';
    has [qw/x y z/] => 42;
    has bar_defaults => sub { Baz->new };

L<Mojo::Base::XS> also allows you to run existing applications
without any modifications:

    perl -MMojo::Base::XS=-infect script/your_app

=head1 DESCRIPTION

Mojo::Base::XS implements fast accessrors for Mojo-based software.
Code based on L<Class::XSAccessor> - fastes Perl accessors.

It can also be used as standalone Mojo-style accessors generator.

=head1 EXPORTS

L<Mojo::Base::XS> exports following functions:

=head2 has

    has 'name';
    has [qw/name1 name2 name3/];
    has name => 'foo';
    has name => sub {...};
    has [qw/name1 name2 name3/] => 'foo';
    has [qw/name1 name2 name3/] => sub {...};

Create attributes, just like the attr method.

=head1 FUNCTIONS

L<Mojo::Base::XS> implements following functions:

=head2 newxs_attr

    newxs_attr('Class', 'attr');
    Class->attr(foo => 'bar');
    print Class->foo; # bar

Installs XS attribute generator subroutine

=head2 newxs_constructor

    newxs_attr('Class', 'new');
    Class->new(foo => 'bar');
    print Class->{foo}; # bar

Installs XS constructor

=head2 accessor, accessor_init, constructor, constructor_init

Inherited from L<Class::XSAccessors> for internal use

=head1 METHODS

L<Mojo::Base::XS> implements following methods:

=head2 C<new>

    my $obj = Class->new;
    my $obj = Class->new(name => 'value');
    my $obj = Class->new({name => 'value'});

This base class provides a basic object constructor.
You can pass it either a hash or a hash reference with attribute values.

=head2 C<attr>

    __PACKAGE__->attr('name');
    __PACKAGE__->attr([qw/name1 name2 name3/]);
    __PACKAGE__->attr(name                    => 'foo');
    __PACKAGE__->attr(name                    => sub {...});
    __PACKAGE__->attr([qw/name1 name2 name3/] => 'foo');
    __PACKAGE__->attr([qw/name1 name2 name3/] => sub {...});

Create attributes.
An arrayref can be used to create more than one attribute.
Pass an optional second argument to set a default value, it should be a
constant or a sub reference.
The sub reference will be excuted at accessor read time if there's no set
value.

=head1 SEE ALSO

=over

=item * L<Class::XSAccessor>

L<Mojo::Base::XS> based on L<Class::XSAccessor> with some modifications
that imlement L<Mojo::Base> behavior

=item * L<Mojo::Base>

=back

=head1 AUTHOR

Yaroslav Korshak E<lt>yko@cpan.orgE<gt>

=head1 LICENCE AND COPYRIGHT

Copyright (C) 2011, Yaroslav Korshak

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
