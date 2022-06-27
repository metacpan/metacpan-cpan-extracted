package MooseX::LocalAttribute;

use strict;
use warnings;

use Scope::Guard 'guard';
use Exporter 'import';

our @EXPORT = qw/ local_attribute /;

our $VERSION = '0.05';

=head1 NAME

MooseX::LocalAttribute - local-ize attributes on Moose-ish objects

=head1 SYNOPSIS

    use MooseX::LocalAttribute;

    my $freddy = Person->new( name => 'Freddy' );
    print $freddy->name; # Freddy
    {
        my $temporary_name = 'Mr Orange';
        my $guard = local_attribute( $freddy, "name", $temporary_name );
        print $freddy->name; # Mr Orange
        steal_diamonds( $freddy );
    }
    print $freddy->name; # Freddy

=head1 DESCRIPTION

This module provides a mechanism to temporarily replace the value of an
object attribute with a different variable. In typical object oriented Perl
code, an object contains a blessed hash reference, so it's possible to reach
into the internals to localise data.

    my $local_bar;
    local $foo->{bar} = \$local_bar;

This has a few problems though. It is generally a better idea to use accessors
rather than to rumage around in the internals of an object. This is especially
true if one does not know whether the object is in fact a hash reference under
the hood.

When a variable is localised with C<local>, a backup of that variable is made.
Perl then places a directive on the stack that restores the variable when it
is goes out of scope. This module does the same thing for attributes of
objects.

=head1 WHICH OBJECTS DOES THIS WORK FOR

While this module is called MooseX::LocalAttribute, it will work for all kinds
of objects, as long as there is a read/write accessor. It has been tested for
L<Moose>, L<Mouse>, L<Moo>, L<Mo>, L<Mojo::Base>, L<Class::Accessor>,
L<Util::H2O>, L<Object::PAD> and classic Perl OO code using C<bless> with
hand-rolled accessors. There is a good chance it will work on other object
implementations too.

=head1 EXPORTS

=head2 local_attribute($obj, $attr, $val)

Takes an object C<$obj> and temporarily localizes the attribute C<$attr> on
it to C<$val>. It returns a L<Scope::Guard> object that will restore the
original value of C<$attr> when it goes out of scope.

    my $guard = local_attribute( $bob, 'name', 'joe' ); # $bob->name eq 'joe'

You B<must> always capture the return value of C<local_attribute> and store it
in a variable. It will die if called in void context, because the underlying
L<Scope::Guard> object cannot work in void context. Your attribute would be
replaced permanently.

    local_attribute( $foo, 'attr', 'new value' ); # BOOM

This function is exported by default.

=cut

sub local_attribute {
    my $obj  = shift;
    my $attr = shift;
    my $val  = shift;    ## optional, default to undef

    die qq{local_attribute must not be called in void context}
      unless defined wantarray;
    die qq{Attribute '$attr' does not exist} unless $obj->can($attr);

    my $backup = $obj->$attr();
    my $guard  = guard {
        $obj->$attr($backup)
    };

    $obj->$attr($val);

    return $guard;
}

=head1 OBJECTS THIS DOES NOT WORK FOR

=over

=item *

L<Class::Std> - this does not support combined getter/setter methods

=item *

L<Object::Tiny> - this creates read-only accessors

=back

=head1 SEE ALSO

=over

=item *

L<Scope::Guard>

=item *

L<Moose>

=item *

L<Moo>

=back

=head1 AUTHOR

Julien Fiegehenn <simbabque@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2022, Julien Fiegehenn.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut

1;
