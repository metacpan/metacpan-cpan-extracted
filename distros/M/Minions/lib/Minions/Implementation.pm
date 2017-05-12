package Minions::Implementation;

use strict;
use Minions::_Guts;
use Package::Stash;
use Readonly;

sub import {
    my ($class, %arg) = @_;

    strict->import();

    $arg{-caller} = (caller)[0];
    $class->define(%arg);
}

sub define {
    my ($class, %arg) = @_;

    my $caller_pkg = delete $arg{-caller} || (caller)[0];
    my $stash = Package::Stash->new($caller_pkg);

    $class->update_args(\%arg);
    $class->add_attribute_syms(\%arg, $stash);

    $stash->add_symbol('%__meta__', \%arg);
}

sub add_attribute_syms {
    my ($class, $arg, $stash) = @_;

    my @slots = (
        keys %{ $arg->{has} },
        @{ $arg->{requires}{attributes} || [] },
        '', # semiprivate pkg
    );
    foreach my $slot ( @slots ) {
        $class->add_obfu_name($arg, $stash, $slot);
    }
}

sub add_obfu_name {
    my ($class, $arg, $stash, $slot) = @_;

    my $data_version = $stash->get_symbol('$DATA_VERSION');
    Readonly my $sym_val => sprintf(
        "%s-$slot",
       Minions::_Guts::attribute_sym($data_version),
    );
    $Minions::_Guts::obfu_name{$slot} = $sym_val;

    my $prefix = '';
    if($slot eq '' || $arg->{attr_style} eq '_2') {
        $prefix = '__';
    }
    elsif($arg->{attr_style} eq 'uc' || ! $arg->{attr_style}) {
        $slot = uc $slot;
    }
    $stash->add_symbol(
        sprintf('$%s%s', $prefix, $slot),
        \ $sym_val
    );
}

sub update_args {}

1;

__END__

=head1 NAME

Minions::Implementation

=head1 SYNOPSIS

    package Example::Construction::Acme::Set_v1;

    use Minions::Implementation
        has => {
            set => {
                default => sub { {} },
                init_arg => 'items',
                map_init_arg => sub { return { map { $_ => 1 } @{ $_[0] } } },
            }
        },
    ;

    sub has {
        my ($self, $e) = @_;
        exists $self->{$SET}{$e};
    }

    sub add {
        my ($self, $e) = @_;
        ++$self->{$SET}{$e};
    }

    1;

=head1 DESCRIPTION

An implementation is a package containing attribute definitions as well as subroutines implementing the
behaviours described by the class interface.

=head1 CONFIGURATION

An implementation package can be configured either using Minions::Implementation or with a package variable C<%__meta__>. Both methods make use of the following keys:

=head2 has => HASHREF

This declares attributes of the implementation, mapping the name of an attribute to a hash with keys described in
the following sub sections.

An attribute called "foo" can be accessed via it's object in one of two ways:

    # implementation defined using Minions::Implementation
    $self->{$FOO}

    # implementation defined using %__meta__
    $self->{-foo}

The advantage of the first form is that the symbol C<$FOO> is not (easily) available to users of the object, so
there is greater incentive for using the provided interface when using the object.

=head3 default => SCALAR | CODEREF

The default value assigned to the attribute when the object is created. This can be an anonymous sub,
which will be excecuted to build the the default value (this would be needed if the default value is a reference,
to prevent all objects from sharing the same reference).

=head3 assert => HASHREF

This is like the C<assert> declared in a class package, except that these assertions are not run at
construction time. Rather they are invoked by calling the semiprivate ASSERT routine.

=head3 handles => ARRAYREF | HASHREF

This declares that methods can be forwarded from the object to this attribute in one of two ways
described below. These forwarding methods are generated as public methods if they are declared in
the interface, and as semiprivate routines otherwise.

=head3 handles => ARRAYREF

All methods in the given array will be forwarded.

=head3 handles => HASHREF

Method forwarding will be set up such that a method whose name is a key in the given hash will be
forwarded to a method whose name is the corresponding value in the hash.

=for comment
=head3 handles => SCALAR
The scalar is assumed to be a role, and methods provided directly (i.e. not including methods in sub-roles) by the role will be forwarded.

=head3 init_arg => SCALAR

This causes the attribute to be populated with the value of a similarly named constructor parameter.

=head3 map_init_arg => CODEREF

If the attribute has an C<init_arg>, it will be populated with the result of applying the given code ref to the value of a similarly named constructor parameter.

=head3 reader => SCALAR

This can be a string which if present will be the name of a generated reader method.

Readers should only be created if they are needed by end users of the class.

=head3 writer => SCALAR

This can be a string which if present will be the name of a generated writer method.

Writers should only be created if they are needed by end users of the class.

=head2 roles => ARRAYREF

A reference to an array containing the names of one or more Role packages. 

Any attributes and/or routines defined in the specified roles will be added to the implementation subject to the following rules 

=over 

=item Implementation trumps Roles

An attribute/routine defined in a role won't get added to the implementation if the implementation already has an attribute/routine with the same name.

=item Conflicts not allowed

An exception will be raised if the same attribute/routine would be provided by two roles.

=back

L<Minions::Role> describes how roles are configured.

=head2 semiprivate => ARRAYREF

These are perhaps only useful when used in conjunction with Roles. They work the same way as in L<Minions::Role>.

=head2 attr_style => SCALAR

If this is set to the string C<'_2'>, then an attribute named 'foo' can be accessed via its object using the symbol C<$__foo> e.g.

    # implementation defined using Minions::Implementation
    $self->{$__foo}

This was the default behaviour in Minions 0.000008 and earlier.

=head1 PRIVATE ROUTINES

An implementation package will typically contain subroutines that are for internal use in the package and therefore ought not to be declared in the interface.
These won't be callable using the C<$minion-E<gt>command(...)> syntax.

As an example, suppose we want to print an informational message whenever the Set's C<has> or C<add> methods are called. A first cut may look like:

    sub has {
        my ($self, $e) = @_;

        warn sprintf "[%s] I have %d element(s)\n", scalar(localtime), scalar(keys %{ $self->{$SET} });
        exists $self->{$SET}{$e};
    }

    sub add {
        my ($self, $e) = @_;

        warn sprintf "[%s] I have %d element(s)\n", scalar(localtime), scalar(keys %{ $self->{$SET} });
        ++$self->{$SET}{$e};
    }

But this duplication of code is not good, so we factor it out:

    sub has {
        my ($self, $e) = @_;

        log_info($self);
        exists $self->{$SET}{$e};
    }

    sub add {
        my ($self, $e) = @_;

        log_info($self);
        ++$self->{$SET}{$e};
    }

    sub size {
        my ($self) = @_;
        scalar(keys %{ $self->{$SET} });
    }

    sub log_info {
        my ($self) = @_;

        warn sprintf "[%s] I have %d element(s)\n", scalar(localtime), $self->size;
    }

Notice how the C<log_info> routine is called as a regular sub rather than as a method.

Here is a transcript of using this object via L<reply|https://metacpan.org/pod/distribution/Reply/bin/reply>

    5:51% reply -I t/lib
    0> use Example::Construction::Set_v1
    1> my $set = Example::Construction::Set_v1->new
    $res[0] = bless( {
            '1f5f6ad9-' => 'Example::Construction::Set_v1::__Private',
            '1f5f6ad9-set' => {}
        }, 'Example::Construction::Set_v1::__Minions' )

    2> $set->can
    $res[1] = [
    'add',
    'has',
    'size'
    ]

    3> $set->add(1)
    [Sat Jan 10 17:52:35 2015] I have 0 element(s)
    $res[2] = 1

    4> $set->add(1)
    [Sat Jan 10 17:57:03 2015] I have 1 element(s)
    $res[3] = 2

    5> $set->log_info()
    Can't locate object method "log_info" via package "Example::Construction::Set_v1::__Minions" at reply input line 1.
    6> 

=head1 OBJECT COMPOSITION

Composition allows us to create new objects incorporating the functionality of existing ones.

As an example, consider a queue which we would use like this:

    use strict;
    use Test::More;
    use Example::Delegates::Queue;

    my $q = Example::Delegates::Queue->new;

    is $q->size => 0;

    $q->push(1);
    is $q->size => 1;

    $q->push(2);
    is $q->size => 2;

    $q->pop;
    is $q->size => 1;
    done_testing();

Now suppose we need a queue which maintains a fixed size by evicting the oldest items:

    use strict;
    use Test::More;
    use Example::Delegates::FixedSizeQueue;

    my $q = Example::Delegates::FixedSizeQueue->new(max_size => 3);

    $q->push($_) for 1 .. 3;
    is $q->size => 3;

    $q->push($_) for 4 .. 6;
    is $q->size => 3;
    is $q->pop => 4;
    done_testing();

Here is the interface for this fixed size queue

    package Example::Delegates::FixedSizeQueue;

    use Minions
        interface => [qw( push pop size )],

        construct_with  => {
            max_size => { 
                assert => { positive_int => sub { $_[0] =~ /^\d+$/ && $_[0] > 0 } }, 
            },
        }, 

        implementation => 'Example::Delegates::Acme::FixedSizeQueue_v1',
    ;

    1;

And it is implemented like this

    package Example::Delegates::Acme::FixedSizeQueue_v1;

    use Example::Delegates::Queue;

    use Minions::Implementation
        has  => {
            q => {
                default => sub { Example::Delegates::Queue->new },

                handles => [qw( size pop )],
            },

            max_size => {
                init_arg => 'max_size',
            },
        },
    ;

    sub push {
        my ($self, $val) = @_;

        $self->{$Q}->push($val);

        if ($self->size > $self->{$MAX_SIZE}) {
            $self->pop;
        }
    }

    1;

The fixed size queue is composed out of the regular queue, which handles the C<size> and C<pop> methods.
