BEGIN {
    # A hack to suppress redefined warning caused by circulation dependency
    $INC{'Test/AutoMock/Manager.pm'} //= do {
        require File::Spec;
        File::Spec->rel2abs(__FILE__);
    };
}

package Test::AutoMock::Manager;
use strict;
use warnings;
use Scalar::Util qw(blessed refaddr weaken);
use Test::AutoMock::Mock::Functions qw(new_mock get_manager);
use Test::AutoMock::Mock::TieArray;
use Test::AutoMock::Mock::TieHash;
use Test::More import => [qw(ok eq_array)];

sub new {
    my $class = shift;
    my %params = @_;

    # considering overloaded dereference operators, use ref of hash-ref
    my $self = bless {
        methods => {},  # method name => code-ref
        isa => {},  # class name => 1
        name => $params{name},
        parent => $params{parent},
        children => {},  # name => instance
        calls => [],
        mock_class => $params{mock_class},
        mock => $params{mock},
        tie_hash => undef,  # See: Test::AutoMock::Mock::TieHash
        tie_array => undef,  # See: Test::AutoMock::Mock::TieArray
    } => $class;

    # avoid cyclic reference
    weaken($self->{parent});
    weaken($self->{mock});

    # parse all method definitions
    while (my ($k, $v) = each %{$params{methods} // {}}) {
        $self->add_method($k => $v);
    }

    if (my $isa = $params{isa}) {
        my @args = ref $isa eq 'ARRAY' ? @$isa : ($isa, );
        $self->set_isa(@args);
    }

    $self;
}

sub mock { $_[0]->{mock} }

sub add_method {
    my ($self, $name, $code_or_value) = @_;

    my ($method, $child_method) = split /->/, $name, 2;

    # check duplicates with pre-defined methods
    die "`$method` has already been defined as a method"
        if exists $self->{methods}{$method};

    # handle nested method definitions
    if (defined $child_method) {
        my $child = $self->child($method);
        $child->add_method($child_method, $code_or_value);
        return;
    }

    # check duplicates with fields
    die "`$method` has already been defined as a field"
        if exists $self->{children}{$method};

    my $code;
    if (ref $code_or_value // '' eq 'CODE') {
        $code = $code_or_value;
    } else {
        $code = sub { $code_or_value };
    }

    $self->{methods}{$name} = $code;
}

sub set_isa {
    my $self = shift;

    my %isa;
    @isa{@_} = map { 1 } @_;

    $self->{isa} = \%isa;
}

sub calls {
    my $self = shift;

    @{$self->{calls}}
}

sub _get_child_mock {
    my ($self, $name) = @_;

    return if exists $self->{methods}{$name};

    $self->{children}{$name} //=
        # create new child
        new_mock(
            $self->{mock_class},
            name => $name,
            parent => $self->mock,
        );
}

sub child {
    my ($self, $name) = @_;
    my $child_mock = $self->_get_child_mock($name);

    defined $child_mock ? get_manager $child_mock
                        : undef;
}

sub reset {
    my $self = shift;

    $self->{calls} = [];
    (get_manager $_)->reset for values %{$self->{children}};
}

sub _find_call {
    my ($self, $method) = @_;
    my @calls = $self->calls;
    grep { $_->[0] eq $method } @calls;
}

sub called_with_ok {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my ($self, $method, $args) = @_;
    my @calls = $self->_find_call($method);
    my @calls_with_args = grep { eq_array $args, $_->[1] } @calls;
    ok scalar @calls_with_args,
       "$method has been called with correct arguments";
}

sub called_ok {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my ($self, $method) = @_;
    ok !! $self->_find_call($method), "$method has been called";
}

sub not_called_ok {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my ($self, $method) = @_;
    ok ! $self->_find_call($method), "$method has not been called";
}

sub _record_call {
    my ($self, $meth, $ref_params) = @_;

    # follow up the chain of mocks and record calls
    my %seen;
    my $cur_call = [$meth, $ref_params];
    my $cur_mgr = $self;
    while (defined $cur_mgr && ! $seen{refaddr($cur_mgr)}++) {
        push @{$cur_mgr->{calls}}, $cur_call;

        my $method_name = $cur_call->[0];
        my $parent_name = $cur_mgr->{name};
        $method_name = "$parent_name->$method_name" if defined $parent_name;

        $cur_call = [$method_name, $cur_call->[1]];
        $cur_mgr =
            defined $cur_mgr->{parent} ? get_manager($cur_mgr->{parent})
                                       : undef;
    }
}

sub _call_method {
    my ($self, $meth, $ref_params, $default_handler) = @_;

    $default_handler //= sub { $self->_get_child_mock($meth) };

    $self->_record_call($meth, $ref_params);

    # return value
    if (my $code = $self->{methods}{$meth}) {
        $code->(@$ref_params);
    } else {
        $self->mock->$default_handler(@$ref_params);
    }
}

my %default_overload_handlers = (
    '+' => undef,
    '-' => undef,
    '*' => undef,
    '/' => undef,
    '%' => undef,
    '**' => undef,
    '<<' => undef,
    '>>' => undef,
    'x' => undef,
    '.' => undef,

    '+=' => sub { $_[0] },
    '-=' => sub { $_[0] },
    '*=' => sub { $_[0] },
    '/=' => sub { $_[0] },
    '%=' => sub { $_[0] },
    '**=' => sub { $_[0] },
    '<<=' => sub { $_[0] },
    '>>=' => sub { $_[0] },
    'x=' => sub { $_[0] },
    '.=' => sub { $_[0] },

    '<' => undef,
    '<=' => undef,
    '>' => undef,
    '>=' => undef,
    '==' => undef,
    '!=' => undef,

    '<=>' => undef,
    'cmp' => undef,

    'lt' => undef,
    'le' => undef,
    'gt' => undef,
    'ge' => undef,
    'eq' => undef,
    'ne' => undef,

    '&' => undef,
    '&=' => sub { $_[0] },
    '|' => undef,
    '|=' => sub { $_[0] },
    '^' => undef,
    '^=' => sub { $_[0] },
    # '&.' => undef,
    # '&.=' => sub { $_[0] },
    # '|.' => undef,
    # '|.=' => sub { $_[0] },
    # '^.' => undef,
    # '^.=' => sub { $_[0] },

    'neg' => undef,
    '!' => undef,
    '~' => undef,
    # '~.' => sub { $_[0] },

    '++' => sub { $_[0] },
    '--' => sub { $_[0] },

    'atan2' => undef,
    'cos' => undef,
    'sin' => undef,
    'exp' => undef,
    'abs' => undef,
    'log' => undef,
    'sqrt' => undef,
    'int' => undef,

    'bool' => sub { !! 1 },
    '""' => sub {
        my $mock = shift;
        sprintf "%s(0x%x)", blessed $mock, refaddr $mock;
    },
    '0+' => sub { 1 },
    'qr' => sub { qr// },

    '<>' => sub { undef },

    '-X' => undef,

    # '~~' => sub { !! 1 },

    '${}' => sub { \ my $x },
    '*{}' => sub { \*DUMMY },
);

sub _overload_nomethod {
    my ($self, $other, $is_swapped, $operator, $is_numeric) = @_;

    # don't record the call of copy constructor (and don't copy mocks)
    return $self->mock if $operator eq '=';

    my $operator_name = "`$operator`";
    my $default_handler;
    if (exists $default_overload_handlers{$operator}) {
        $default_handler = $default_overload_handlers{$operator};
    } else {
        warn "unknown operator: $operator";
    }

    $self->_call_method(
        $operator_name => [$other, $is_swapped],
        $default_handler,
    );
}

sub _deref_hash {
    my ($self, $mock) = @_;

    # don't record `%{}` calls

    tie my %hash, 'Test::AutoMock::Mock::TieHash', $self;
    \%hash;
}

sub tie_array { $_[0]->{tie_array} //= [] }

sub _deref_array {
    my ($self) = @_;

    # don't record `@{}` calls

    tie my @array, 'Test::AutoMock::Mock::TieArray', $self;
    \@array;
}

sub tie_hash { $_[0]->{tie_hash} //= {} }

sub _deref_code {
    my ($self) = @_;

    # don't record `&{}` calls

    sub {
        my @args = @_;
        $self->_call_method('()', [@_], undef);
    };
}

1;
__END__

=encoding utf-8

=head1 NAME

Test::AutoMock::Manager - Manage Test::AutoMock::Mock::Basic

=head1 DESCRIPTION

This module provides an interface for manipulating
L<Test::AutoMock::Mock::Basic> and L<Test::AutoMock::Mock::Overloaded>.

=head1 METHODS

=head2 C<add_method>

    manager($mock)->add_method(add_one => sub { $_[0] + 1 });
    manager($mock)->add_method('path->to->some_obj->name' => 'some_obj');

Define the behavior of AutoMock when calling a method.

The first argument is the method name. You can also specify nested names with
C<< -> >>. A call in the middle of a method chain is regarded as a field and
can not be defined as a method at the same time. For example, if you try to
specify C<< 'get_object->name' >> and C<'get_object'> as the same mock,
you'll get an error.

The second argument specifies the return value when the method is called.
If you specify a code reference, that code will be called on method invocation.
Be aware that neither C<$mock> nor C<manager($mock)> are not included
in arguments.

=head2 C<set_isa>

    manager($mock)->set_isa('Foo', 'Hoge');

Specify the superclass of the mock. This specification only affects the C<isa>
method. It is convenient when argument is checked like L<Moose> field.

=head2 C<child>

    # return the manager($mock->some_field)
    manager($mock)->child('some_field');

Return the Manager of the mock's child. Since this call is not recorded, it is
convenient when you want to avoid recording unnecessary calls when writing
assertions.

TODO: Support C<< -> >> notations.

=head2 C<mock>

It returns the mock that this manager manages.
See also L<Test::AutoMock::manager>.

=head2 C<calls>

    my @calls = manager($mock)->calls;

Returns all recorded method calls. The element of "calls" is a two-element
array-ref. The first element is a method name, and the second element is an
array-ref representing arguments.

Method calls to children are also recorded in C<$mock>. For example, calling
C<< $mock->child->do_it >> will record two calls C<'child'> and
C<< 'child->do_it' >>.

=head2 C<reset>

Erase all recorded method calls. Delete all method call history from descendant
mocks as well. It is used when you want to reuse mock.

=head2 C<called_ok>

    manager($mock)->called_ok('hoge->bar');

Checks if the method was called. It is supposed to be used with L<Test::More> .

=head2 C<called_with_ok>

    manager($mock)->called_with_ok(
        'hoge->bar', [10, 20],
    );

Checks if the method was called with specified arguments.

=head2 C<not_called_ok>

    manager($mock)->not_called_ok('hoge->bar');

Checks if the method was not called.

=head1 LICENSE

Copyright (C) Masahiro Honma.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item L<Test::AutoMock>

=back

=head1 AUTHOR

Masahiro Honma E<lt>hiratara@cpan.orgE<gt>

=cut

