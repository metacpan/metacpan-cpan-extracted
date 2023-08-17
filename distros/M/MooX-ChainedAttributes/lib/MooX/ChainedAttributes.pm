package MooX::ChainedAttributes;
use 5.008001;
use strictures 2;
our $VERSION = '0.08';

=encoding utf8

=head1 NAME

MooX::ChainedAttributes - Make your attributes chainable.

=head1 SYNOPSIS

    package Foo;
    use Moo;
    use MooX::ChainedAttributes;
    
    has name => (
        is      => 'rw',
        chained => 1,
    );
    
    has age => (
        is => 'rw',
    );
    
    chain('age');
    
    sub who {
        my ($self) = @_;
        print "My name is " . $self->name() . "!\n";
    }
    
    my $foo = Foo->new();
    $foo->name('Fred')->who(); # My name is Fred!

=head1 DESCRIPTION

This module exists for your method chaining enjoyment.  It
was originally developed in order to support the porting of
L<MooseX::Attribute::Chained> using classes to L<Moo>.

In L<Moose> you would write:

    package Bar;
    use Moose;
    use MooseX::Attribute::Chained;
    has baz => ( is=>'rw', traits=>['Chained'] );

To port the above to L<Moo> just change it to:

    package Bar;
    use Moo;
    use MooX::ChainedAttributes;
    has baz => ( is=>'rw', chained=>1 );

=cut

use Moo ();
use Moo::Role ();
use Carp qw( croak );

my $role = 'MooX::ChainedAttributes::Role::GenerateAccessor';

sub import {
    my $class = shift;
    my $target = caller;

    if (my $acc = Moo->_accessor_maker_for($target)) {
        Moo::Role->apply_roles_to_object($acc, $role)
            unless $acc->does($role);
    }
    else {
        croak "MooX::ChainedAttributes can only be used in Moo classes.";
    }

    my $has = $target->can('has');

    no strict 'refs';
    *{"${target}::chain"} = sub {
        my $attr = shift;
        $has->("+$attr", (chained => 1));
        return;
    };
}

1;
__END__

=head1 AUTHOR

    Aran Clary Deltac <bluefeet@gmail.com>

=head1 CONTRIBUTORS

    Graham Knop <haarg@haarg.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
