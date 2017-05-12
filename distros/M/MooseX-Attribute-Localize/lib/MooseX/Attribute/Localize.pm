package MooseX::Attribute::Localize;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: localize attribute values within a scope
$MooseX::Attribute::Localize::VERSION = '0.1.2';
use Moose::Role;

has _value_stack => (
    traits => [ qw/ Array / ],
    is => 'ro',
    default => sub { [] },
    handles => {
        _push_value => 'push',
        _pop_value => 'pop',
    },
);

has localize_push => ( is => 'ro', predicate => 'has_localize_push' );
has localize_pop  => ( is => 'ro', predicate => 'has_localize_pop' );

before '_canonicalize_handles' => sub {
    my( $self ) = @_;

    my $handles = $self->handles;

    $_ = sub { 
            my $object = shift;

            my $attr = $object->meta->get_attribute( $self->name );

            my ( $old ) = $attr->_push_value( $attr->get_value($object) );
            
            $attr->clear_value($object);

            my $new_value;

            $attr->set_value( $object, $new_value = shift ) if @_;

            warn "localize called in void context is a no-op\n"
                unless defined wantarray;

             if( my $method = $attr->localize_push ) {
                 my $func = ref $method ? $method :
                    sub { my $self = shift; $self->$method(@_) };
                 $func->( $object, $new_value, $old, $attr );
             }

            return MooseX::Attribute::Localize::Sentinel->new(
                attribute => $attr,
                object => $object,
            );
    } for grep { $_ eq 'localize' } values %$handles;

    $_ = sub { 
            my $object = shift;

            my $attr = $object->meta->get_attribute( $self->name );

            my @values = reverse @{ $attr->_value_stack };
            unshift @values, $attr->get_value($object) if $attr->has_value($object);

            return @values;

    } for grep { $_ eq 'localize_stack' } values %$handles;

};

{
package MooseX::Attribute::Localize::Sentinel;
our $AUTHORITY = 'cpan:YANICK'; 
$MooseX::Attribute::Localize::Sentinel::VERSION = '0.1.2';
use Moose;

    has [qw/ attribute object /] => ( is => 'ro' );

    sub DEMOLISH {
        my $self = shift;
        my $old_value = $self->attribute->get_value( $self->object );
        my $new_value = $self->attribute->_pop_value;
        $self->attribute->set_value( $self->object, $new_value );
        if( my $method = $self->attribute->localize_pop ) {
            my $func = ref $method ? $method : sub {
                my $self = shift;
                $self->$method(@_);
            };
            $func->($self->object,$new_value,$old_value,$self->attribute);
        }
    }
}

{
    package Moose::Meta::Attribute::Custom::Trait::Localize;
our $AUTHORITY = 'cpan:YANICK';
$Moose::Meta::Attribute::Custom::Trait::Localize::VERSION = '0.1.2';
sub register_implementation { 'MooseX::Attribute::Localize' }

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Attribute::Localize - localize attribute values within a scope

=head1 VERSION

version 0.1.2

=head1 SYNOPSIS

    package Foo; 

    use Moose;
    use MooseX::Attribute::Localize;

    has 'bar' => (
        traits => [ 'Localize' ],
        is => 'rw',
        handles => {
            set_local_bar => 'localize'
        },
    );

    my $foo = Foo->new( bar => 'a' );

    print $foo->bar;  # 'a'

    { 
        my $sentinel = $foo->set_local_bar( 'b' );
        print $foo->bar;  # 'b'

        $foo->bar('c');
        print $foo->bar;  # 'c'
    }

    print $foo->bar;  # 'a'

=head1 DESCRIPTION

Attributes that are given the trait C<Localize> can
handle a C<localize> delegation, which stashes away
the current value of the attribute and replaces it 
with a local value, mimicking the behavior of 
Perl's own C<local>.

The delegated method returns a sentinel variable.
Once this variable gets out of scope, the attribute
returns to its previous value. 

If the delegated method
is called in a void context, a warning will be issued as 
the sentinel will immediately get out of scope, which 
turns the whole thing into a glorious no-op.

=head1 PROVIDED DELEGATION METHODS

=head2 localize( $new_value )

Localizes the attribute. If a C<$new_value> is provided, initializes the newly localized 
value to it. 

The method returns a sentinel object that will return the attribute to its previous value once it gets
out of scope. The method will warn if it is called in a void context (as the sentinel will immediately
falls out of scope). 

=head2 localize_stack

Returns the stack of values for the attribute, including the current value.

    {
        package Foo;

        use Moose;
        use MooseX::Attribute::Localize;

        has bar => (
            traits => [ 'Localize' ],
            is => 'rw',
            handles => {
                local_bar => 'localize',
                bar_stack => 'localize_stack',
            },
        );
    }

    my $foo = Foo->new( bar => 'a' );
    
    {
        my $s = $foo->local_bar('b');
        my @stack = $self->bar_stack;  # ( 'a', 'b' )
    }

=head1 ATTRIBUTE ARGUMENTS

    has bar => (
            traits => [ 'Localize' ],
            is => 'rw',
            localize_push => 'spy_on_push',
            localize_pop  => sub { 
                my( $object, $new, $old, $attribute ) = @_;
                ...;
            },
            handles => {
                local_bar => 'localize',
                bar_stack => 'localize_stack',
            },
    );

    sub spy_on_push {
        my( $self, $new, $old, $attribute ) = @_;
        ...;
    }

=head2 localize_push

If defined, will be called when a new value is pushed unto the attribute's
stack. Can be the name of a method of the parent object, or a coderef. 

When called,
the associated function/method will be passed the object, the new pushed
value, the previous one, and the attribute object.

=head2 localize_pop

If defined, will be called when a new value is popped from the attribute's
stack. Can be the name of a method of the parent object, or a coderef. 

When called,
the associated function/method will be passed the object, the new popped
value, the previous one, and the attribute object.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
