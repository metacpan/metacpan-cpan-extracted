package MooseX::DeepAccessors;
use Moose;
use Scalar::Util qw(blessed);
our $VERSION = '0.02';
extends 'Moose::Meta::Attribute';

has deep_accessors => ( is => 'ro', isa => 'HashRef', default => sub { {} } );

after 'attach_to_class' => sub {
    my ($attr, $class) = @_;

    foreach my $method_name (keys %{ $attr->deep_accessors }) {
        $class->add_method($method_name, 
            $attr->generate_deep_accessor($attr->deep_accessors->{$method_name})
        );
    }
};

sub generate_deep_accessor {
    my ($attr, $spec) = @_;
    my $attrname = $attr->name;
    my ($delegate_method, $callbacks) = %$spec;
    
    sub { 
        my $self = shift; 
        my $value = $self->$attrname;
        my @method_params = map { $self->$_ } @$callbacks;
        return $value->$delegate_method( @method_params );
    };
}

1;

package Moose::Meta::Attribute::Custom::MyDeepAccessors;

sub register_implementation {
    'MooseX::DeepAccessors'
}

1;


__END__
=head1 NAME

MooseX::DeepAccessors - Delegate methods to member objects, curried with more methods!

=head1 VERSION

Version 0.02

=cut



=head1 SYNOPSIS

    package MyClass;

    use Moose;
    use MooseX::DeepAccessors;

    has foo => (
        isa => 'Str',
        is => 'ro',
        required => 0,
    );

    has delegate => (
        isa => 'Foo',
        metaclass => 'MooseX::DeepAccessors',
        is => 'ro',
        default => sub { Foo->new },
        required => 0,
        lazy => 1,
        deep_accessors => {
            'bar' => { 'blah' => [ sub { $_[0]->foo }, ], },
        },
    );

=head1 INTERFACE

The C<deep_accessors> attribute takes parameters in the form:

    deep_accessors => { 
        'LOCALMETHOD' => { 'DELEGATEMETHOD' => [ sub { $_[0]->OTHERLOCALMETHOD } ] }
    }

Where C<LOCALMETHOD> is the method on this class to create, C<DELEGATEMETHOD> is the method on the object whose 
accessor is being described, and C<OTHERLOCALMETHOD> is a method on this class, which will be called with the object
passed to C<LOCALMETHOD> and whose return value will be passed to C<DELEGATEMETHOD>.

To put it another way, it allows you to write:
    $object->LOCALMETHOD;

Rather than:
    $object->DELEGATE->DELEGATEMETHOD( $object->OTHERLOCALMETHOD );

And thus can be thought of as providing another kind of currying for Moose methods.

=head1 AUTHOR

Joel Bernstein, C<< <rataxis at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-moosex-deepaccessors at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooseX-DeepAccessors>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooseX::DeepAccessors


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooseX-DeepAccessors>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooseX-DeepAccessors>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooseX-DeepAccessors>

=item * Search CPAN

L<http://search.cpan.org/dist/MooseX-DeepAccessors>

=back


=head1 ACKNOWLEDGEMENTS

This module was written to scratch an itch I had, but the actual code idea comes from C<t0m> and the 
impetus to release it from C<nothingmuch>. So thankyou, C<#moose>.

Really, this shouldn't be necessary, and hopefully the next L<Moose> release will integrate this 
functionality making this module redundant.

=head1 COPYRIGHT & LICENSE

(C) Copyright 2008 Joel Bernstein, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of MooseX::DeepAccessors
