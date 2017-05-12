package MooseX::CurriedHandles;
use Moose;
use Scalar::Util qw(blessed);
our $VERSION = '0.03';
extends 'Moose::Meta::Attribute';

has curried_handles => ( is => 'ro', isa => 'HashRef', default => sub { {} } );

after 'attach_to_class' => sub {
    my ($attr, $class) = @_;

    foreach my $method_name (keys %{ $attr->curried_handles }) {
        $class->add_method($method_name, 
            $attr->generate_curried_accessor($attr->curried_handles->{$method_name})
        );
    }
};

sub generate_curried_accessor {
    my ($attr, $spec) = @_;
    my $attrname = $attr->name;
    my ($delegate_method, $callbacks) = %$spec;
    
    sub { 
        my $self = shift; 
        my $value = $self->$attrname;
        my @method_params = map { $self->$_ } @$callbacks;
        return $value->$delegate_method( @method_params, @_ );
    };
}

1;

package Moose::Meta::Attribute::Custom::MyCurriedHandles;

sub register_implementation {
    'MooseX::CurriedHandles'
}

1;


__END__
=head1 NAME

MooseX::CurriedHandles - Delegate methods to member objects, curried with more methods!

=head1 VERSION

Version 0.03

=cut



=head1 SYNOPSIS

    package MyClass;

    use Moose;
    use MooseX::CurriedHandles;

    has foo => (
        isa => 'Str',
        is => 'ro',
        required => 0,
    );

    has delegate => (
        isa => 'Foo',
        metaclass => 'MooseX::CurriedHandles',
        is => 'ro',
        default => sub { Foo->new },
        required => 0,
        lazy => 1,
        curried_handles => {
            'bar' => { 'blah' => [ sub { $_[0]->foo }, ], },
        },
    );

=head1 INTERFACE

This is the module formerly known as C<MooseX::DeepAccessors>. This is a much better and more Moose-consistent name
for it.

The C<curried_handles> attribute takes parameters in the form:

    curried_handles => { 
        'LOCALMETHOD' => { 'DELEGATEMETHOD' => [ sub { $_[0]->OTHERLOCALMETHOD } ] }
    }

Where C<LOCALMETHOD> is the method on this class to create, C<DELEGATEMETHOD> is the method on the object whose 
accessor is being described, and C<OTHERLOCALMETHOD> is a method on this class, which will be called with the object
passed to C<LOCALMETHOD> and whose return value will be passed to C<DELEGATEMETHOD>.

To put it another way, it allows you to write:
    $object->localmethod;

Rather than:
    $object->delegate->delegatemethod( $object->otherlocalmethod );

Any extra arguments passed to C<localmethod> will be passed to the C<delegatemethod>:

    $object->localmethod(@foo) 

is equivalent to:

    $object->delegate->delegatemethod( $object->anotherlocalmethod, @foo );

And thus can be thought of as providing another kind of currying for Moose methods.

=head1 AUTHOR

Joel Bernstein, C<< <rataxis at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-moosex-curriedhandles at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooseX-CurriedHandles>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooseX::CurriedHandles


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooseX-CurriedHandles>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooseX-CurriedHandles>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooseX-CurriedHandles>

=item * Search CPAN

L<http://search.cpan.org/dist/MooseX-CurriedHandles>

=back


=head1 ACKNOWLEDGEMENTS

This module was written to scratch an itch I had, but the actual code idea comes from C<t0m> and the 
impetus to release it from C<nothingmuch>. So thankyou, C<#moose>.

Really, this shouldn't be necessary, and hopefully the next L<Moose> release will integrate this 
functionality making this module redundant.

Thanks to C<t0m> and C<autarch> for suggesting a better name.

=head1 COPYRIGHT & LICENSE

(C) Copyright 2008 Joel Bernstein, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of MooseX::CurriedHandles
