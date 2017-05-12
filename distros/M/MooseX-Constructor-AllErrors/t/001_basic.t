use strict;
use warnings;
use Test::More tests => 54;
use Test::Moose;

{
    package Foo;

    use Moose;
    use MooseX::Constructor::AllErrors;

    has bar => (
        is => 'ro',
        required => 1,
    );

    has baz => (
        is => 'ro',
        isa => 'Int',
    );

    has quux => (
        is => 'ro',
        trigger => sub { my ($x, $y) = (1, 0); $x / $y; },
    );

    has bletch => (
        is => 'ro', isa => 'Int'
    );

    has $_ => (
        is => 'ro', isa => 'Str',
    ) foreach qw(name id);

    sub BUILD
    {
        my ($self, $args) = @_;

        $self->bletch($self->baz) if $self->baz;

        my @errors;

        # either baz *or* bletch is required
        push @errors, MooseX::Constructor::AllErrors::Error::Misc->new(
            message => 'Either \'name\' or \'id\' must be provided',
        ) if not defined $args->{name} and not defined $args->{id};

        if (@errors)
        {
            # TODO: we really should be getting the existing Error object, and
            # adding on to that - given that we run BUILD even after we already
            # have some Required and/or TypeConstraint errors
            my $error = MooseX::Constructor::AllErrors::Error::Constructor->new(
                caller => [ caller( Class::MOP::class_of($self)->is_immutable ? 2 : 4) ],
            );

            $error->add_error($_) foreach @errors;
            die $error;
        }
    }

    no Moose;
    no MooseX::Constructor::AllErrors;
}

with_immutable
{
    my $file = __FILE__;

    my $foo = eval { Foo->new(bar => 1, name => 'me') };
    is($@, '');
    isa_ok($foo, 'Foo');

    eval { Foo->new(baz => "hello", name => 'me') }; my $line = __LINE__;
    my $e = $@;
    my $t;
    isa_ok($e, 'MooseX::Constructor::AllErrors::Error::Constructor');
    isa_ok($t = ($e->errors)[0], 'MooseX::Constructor::AllErrors::Error::Required');
    is($e->has_errors, 2, 'there are two errors');
    like(
        $e,
        qr/^\QAttribute (bar) is required at $file line $line\E/,
        'stringified error',
    );

    is($t->attribute, Foo->meta->get_attribute('bar'));
    is($t->message, 'Attribute (bar) is required');
    isa_ok($t = ($e->errors)[1], 'MooseX::Constructor::AllErrors::Error::TypeConstraint');
    is($t->attribute, Foo->meta->get_attribute('baz'));
    is($t->data, 'hello');
    like($t->message,
        qr/^\QAttribute (baz) does not pass the type constraint because: Validation failed for 'Int' with value \E.*hello.*/
    );

    TODO: {
        local $TODO = 'BUILD errors are not yet caught if there were required/tc errors already found';
        isa_ok($t = ($e->errors)[2], 'MooseX::Constructor::AllErrors::Error::TypeConstraint') or todo_skip 'doh', 5;
        is($t->attribute, Foo->meta->get_attribute('bletch'));
        is($t->data, 'hello');
        like($t->message,
            qr/\QAttribute (bletch) does not pass the type constraint because: Validation failed for 'Int' with value \E.*hello.*/
        );

        isa_ok($t = ($e->errors)[3], 'MooseX::Constructor::AllErrors::Error::Misc');
        is($t->message,
            q{Either 'name' or 'id' must be provided},
        );
    }

    is(
        $e->message,
        ($e->errors)[0]->message,
        "message is first error's message",
    );

    is_deeply(
        [ map { $_->attribute->name } $e->missing ],
        [ 'bar' ],
        'correct missing',
    );

    is_deeply(
        [ map { $_->attribute->name } $e->invalid ],
        [ 'baz' ],
        'correct invalid',
    );

    my $pattern = "\QAttribute (bar) is required at \E$file line $line";
    like("$e", qr/$pattern/);

    eval { Foo->new(bar => 1, quux => 1) };
    like $@, qr/Illegal division by zero/, "unrecognized error rethrown";

    eval { Foo->new(bar => 1) }; $line = __LINE__;
    $e = $@;
    isa_ok($e, 'MooseX::Constructor::AllErrors::Error::Constructor');
    like(
        $e,
        qr/^\QEither 'name' or 'id' must be provided at $file line $line\E/,
        'stringified error',
    );
    isa_ok($t = ($e->errors)[0], 'MooseX::Constructor::AllErrors::Error::Misc');
    is($t->message,
        q{Either 'name' or 'id' must be provided},
    );
}
qw(Foo);

