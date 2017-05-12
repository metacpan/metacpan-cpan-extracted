package Minions::Role;

require Minions::Implementation;

our @ISA = qw( Minions::Implementation );

sub update_args {
    my ($class, $arg) = @_;

    $arg->{role} = 1;    
}

1;

__END__

=head1 NAME

Minions::Role

=head1 SYNOPSIS

    package Foo::Role;

    use Minions::Role
        has  => {
            beans => { default => sub { [ ] } },
        }, 
        requires => {
            methods => [qw/some required methods/],
            attributes => [qw/some required attributes/],
        },
        roles => [qw/all these roles/],
        semiprivate => [qw/some internal subs/],
    ;

=head1 DESCRIPTION

Roles provide reusable implementation details, i.e. they solve the problem of what to do when the same implementation details are found in more than one implementation package.

=head1 CONFIGURATION

A role package can be configured either using Minions::Role or with a package variable C<%__meta__>. Both methods make use of the following keys:

=head2 has => HASHREF

This works the same way as in an implementation package.

=head2 requires => HASHREF

A hash with keys:

=head3 methods => ARRAYREF

Any methods listed here must be provided by an implementation package or a role.

=head3 attributes => ARRAYREF

Any attributes listed here must be provided by an implementation package or a role.

Variables with names corresponding to these attributes will be created in the role package to allow accessing the attributes e.g.

    use Minions::Role
        requires => {
            attributes => [qw/length width/]

        };

    sub area {
        my ($self) = @_;
        $self->{$LENGTH} * $self->{$WIDTH};
    }

=head2 roles => ARRAYREF

A list of roles which the current role is composed out of (roles can be built from other roles).

=head2 semiprivate => ARRAYREF

A list of semiprivate methods. These are methods provided by the role that are not indended
to be used by end users of the class that the role was used in.

Each implementation package has a corresponding semiprivate package where its semiprivate methods live. This package can be accessed from an object via the variable C<$__> which is created by Minions::Role (and also by Minions::Implementation).

A semiprivate method can then be called like this

    $self->{$__}->some_work($self, ...);

Since a semiprivate method is receives a package name as its first argument, the C<$self> variable must be explicitly passed to it, if it needs access to the object that called it.

As this syntax is somewhat cumbersome, it is also possible to call a semiprivate method via the usual method call syntax i.e.
 
    $self->some_work(...);

but this is only valid if called within the object's implementation package, or a role that the implementation is composed out of.

=head2 role => 1

Only needed if Minions::Role is not used. This indicates that the package is a Role.

=head1 EXAMPLES

=head2 Queueing and Stacking

First consider a queue which we would use like this:

    use Test::More;
    use Example::Roles::Queue_v1;

    my $q = Example::Roles::Queue_v1->new;

    is $q->size => 0;

    $q->push(1);
    is $q->size => 1;

    $q->push(2);
    is $q->size => 2;

    my $n = $q->pop;
    is $n => 1;
    is $q->size => 1;
    done_testing();

The Queue class:

    package Example::Roles::Queue_v1;

    use Minions
        interface => [qw( push pop size )],

        implementation => 'Example::Roles::Acme::Queue_v1',
    ;

    1;

And its implementation:

    package Example::Roles::Acme::Queue_v1;

    use Minions::Implementation
        has  => {
            items => { default => sub { [ ] } },
        }, 
    ;

    sub size {
        my ($self) = @_;
        scalar @{ $self->{$ITEMS} };
    }

    sub push {
        my ($self, $val) = @_;

        push @{ $self->{$ITEMS} }, $val;
    }

    sub pop {
        my ($self) = @_;

        shift @{ $self->{$ITEMS} };
    }

    1;

Now consider a stack with this usage:

    use Test::More;
    use Example::Roles::Stack;

    my $s = Example::Roles::Stack->new;

    is $s->size => 0;

    $s->push(1);
    is $s->size => 1;

    $s->push(2);
    is $s->size => 2;

    my $n = $s->pop;
    is $n => 2;
    is $s->size => 1;
    done_testing();

Its class and implementation:

    package Example::Roles::Stack;

    use Minions
        interface => [qw( push pop size )],

        implementation => 'Example::Roles::Acme::Stack_v1',
    ;

    1;

    package Example::Roles::Acme::Stack_v1;

    use Minions::Implementation
        has  => {
            items => { default => sub { [ ] } },
        }, 
    ;

    sub size {
        my ($self) = @_;
        scalar @{ $self->{$ITEMS} };
    }

    sub push {
        my ($self, $val) = @_;

        push @{ $self->{$ITEMS} }, $val;
    }

    sub pop {
        my ($self) = @_;

        pop @{ $self->{$ITEMS} };
    }

    1;

The two implementations are very similar, both containing an "items" attribute, the "size" and "push" methods. The "pop" methods are almost the same, the only difference being whether an item is removed from the front or the back of the array.

Suppose we wanted to factor out the commonality of the two implementations. We can use a role to do this:

    package Example::Roles::Role::Pushable;

    use Minions::Role
        has  => {
            items => { default => sub { [ ] } },
        }, 
    ;

    sub size {
        my ($self) = @_;
        scalar @{ $self->{$ITEMS} };
    }

    sub push {
        my ($self, $val) = @_;

        push @{ $self->{$ITEMS} }, $val;
    }

    1;

The role provides the "items" attribute, the "size" and "push" methods.

Now using this role, the Queue implementation can be simplified to this:

    package Example::Roles::Acme::Queue_v2;

    use Minions::Implementation
        roles => ['Example::Roles::Role::Pushable'],

        requires => {
            attributes => [qw/items/]
        };
    ;

    sub pop {
        my ($self) = @_;

        shift @{ $self->{$ITEMS} };
    }

    1;

And the Stack implementation can be simplified to this:

    package Example::Roles::Acme::Stack_v2;

    use Minions::Implementation
        roles => ['Example::Roles::Role::Pushable'],

        requires => {
            attributes => [qw/items/]
        };
    ;

    sub pop {
        my ($self) = @_;

        pop @{ $self->{$ITEMS} };
    }

    1;

To test these new implementations, we don't even need to update the main classes because we can re-bind them to new implementations quite easily:

    use Test::More;

    use Minions
        bind => {
            'Example::Roles::Queue' => 'Example::Roles::Acme::Queue_v2',
        };
    use Example::Roles::Queue;

    my $q = Example::Roles::Queue->new;

    is $q->size => 0;

    $q->push(1);
    is $q->size => 1;

    $q->push(2);
    is $q->size => 2;

    my $n = $q->pop;
    is $n => 1;
    is $q->size => 1;
    done_testing();

=head2 Using multiple roles

An implementation can get its functionality from more than one role. As an example consider adding logging of the size as was done in L<Minions::Implementation/PRIVATE ROUTINES>.

Such functionality does not logically belong in the Pushable role, but we could create a new role for it

    package Example::Roles::Role::LogSize;

    use Minions::Role
        semiprivate => ['log_info'],
        requires => {
            methods => [qw/ size /],
        },
    ;

    sub log_info {
        my (undef, $self) = @_;

        warn sprintf "[%s] I have %d element(s)\n", scalar(localtime), $self->size;
    }

    1;

Now we can use this role too

    package Example::Roles::Acme::Queue_v3;

    use Minions::Implementation
        roles => [qw/
            Example::Roles::Role::Pushable
            Example::Roles::Role::LogSize
        /],

        requires => {
            attributes => [qw/items/]
        };
    ;

    sub pop {
        my ($self) = @_;

        $self->{$__}->log_info($self);
        # or just
        # $self->log_info;

        shift @{ $self->{$ITEMS} };
    }

    1;

And use the queue like this

    % reply -I t/lib
    0> use Minions bind => { 'Example::Roles::Queue' => 'Example::Roles::Acme::Queue_v3' }
    1> use Example::Roles::Queue
    2> my $q = Example::Roles::Queue->new
    $res[0] = bless( {
        '83cb834b-' => 'Example::Roles::Queue::__Private',
        '83cb834b-items' => []
    }, 'Example::Roles::Queue::__Minions' )

    3> $q->push(1)
    $res[1] = 1

    4> $q->pop
    [Tue Mar  3 18:24:08 2015] I have 1 element(s)
    $res[2] = 1

    5> $q->can
    $res[3] = [
    'pop',
    'push',
    'size'
    ]

    6> $q->DOES
    $res[4] = [
        'Example::Roles::Queue',
        'Example::Roles::Role::LogSize',
        'Example::Roles::Role::Pushable'
    ]

    7>

The last two commands show L<Minions>' support for introspection.
