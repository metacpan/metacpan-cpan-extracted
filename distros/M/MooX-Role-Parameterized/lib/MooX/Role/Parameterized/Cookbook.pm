package MooX::Role::Parameterized::Cookbook;
use v5.12;
use strict;
use warnings;

our $VERSION = '0.701'; # VERSION

# ABSTRACT: recipes and worked examples for MooX::Role::Parameterized

1;

__END__

=head1 NAME

MooX::Role::Parameterized::Cookbook - recipes for parameterized roles with Moo

=encoding utf8

=head1 DESCRIPTION

This is a documentation-only module. It collects worked recipes for
L<MooX::Role::Parameterized>, the L<Moo> port of
L<MooseX::Role::Parameterized>.

Each recipe is backed by a runnable script in the distribution's F<examples/>
directory, named at the end of the recipe. The author test
F<xt/examples.t> runs every one of those scripts, so the code shown here
is kept honest against working programs.

If you have never used a parameterized role before, read the recipes in order.
If you are porting code from Moose, jump to
L</"RECIPE 4: PORTING FROM MooseX::Role::Parameterized">.

=head1 RECIPE 1: YOUR FIRST PARAMETERIZED ROLE

B<Problem:> you want a role that injects an attribute and a couple of methods,
but the names depend on how the role is consumed.

B<Solution:> declare a C<parameter>, then build the role body from it.

    package Counter;

    use Moo::Role;
    use MooX::Role::Parameterized;

    parameter name => (
        is       => 'ro',
        required => 1,
    );

    role {
        my ( $params, $mop ) = @_;

        my $name = $params->name;

        $mop->has( $name => ( is => 'rw', default => sub {0} ) );

        $mop->method(
            "increment_$name" => sub {
                my $self = shift;
                $self->$name( $self->$name + 1 );
            }
        );

        $mop->method(
            "reset_$name" => sub {
                my $self = shift;
                $self->$name(0);
            }
        );
    };

Consume it with L<MooX::Role::Parameterized::With>, passing the parameter:

    package Game::Wand;

    use Moo;
    use MooX::Role::Parameterized::With;

    with Counter => { name => 'zapped' };

C<Game::Wand> now has a C<zapped> attribute plus C<increment_zapped> and
C<reset_zapped> methods.

Two things to remember:

=over

=item *

C<parameter> takes the same options as C<Moo::has> — C<is> is mandatory.

=item *

Inside the C<role> block, always go through the C<$mop> proxy
(C<< $mop->has >>, C<< $mop->method >>). Calling C<has> directly would install
on the role instead of the consumer.

=back

B<Runnable example:> F<examples/basics.pl>.

=head1 RECIPE 2: REQUIRED, TYPED, AND OPTIONAL PARAMETERS

B<Problem:> you want some parameters mandatory, some optional, and some
validated.

B<Solution:> C<parameter> accepts the full C<Moo::has> specification, including
C<required>, C<isa>, C<default>, and C<predicate>.

    package Field;

    use Moo::Role;
    use MooX::Role::Parameterized;

    parameter mandatory_attribute => (
        is       => 'ro',
        required => 1,
    );

    parameter optional_attribute => (
        is        => 'ro',
        predicate => 1,
    );

    role {
        my ( $params, $mop ) = @_;

        $mop->has( $params->mandatory_attribute => ( is => 'rw' ) );

        if ( $params->has_optional_attribute ) {
            $mop->has( $params->optional_attribute => ( is => 'rw' ) );
        }
    };

When a role declares at least one C<parameter>, the C<$params> argument is
blessed into a generated L<Moo> class. That is what enforces C<required> and
C<isa>, and what gives you accessors such as C<< $params->mandatory_attribute >>
and the C<predicate> C<< $params->has_optional_attribute >>.

A role with no C<parameter> declarations still works — there C<$params> is a
plain hash reference.

B<Runnable example:> F<examples/parameters.pl>.

=head1 RECIPE 3: APPLYING A ROLE SEVERAL TIMES

B<Problem:> you want to apply the same parameterized role more than once to a
single consumer, each time with different parameters.

B<Solution:> pass an array reference of parameter sets. The C<with> installed
by L<MooX::Role::Parameterized::With> applies the role once per set.

    package KeyValue;

    use Moo::Role;
    use MooX::Role::Parameterized;

    parameter attr   => ( is => 'ro', required => 1 );
    parameter method => ( is => 'ro', required => 1 );

    role {
        my ( $params, $mop ) = @_;

        $mop->has( $params->attr => ( is => 'rw' ) );
        $mop->method( $params->method => sub {1024} );
    };

    package Widget;

    use Moo;
    use MooX::Role::Parameterized::With;

    with KeyValue => [
        { attr => 'width',  method => 'compute_width' },
        { attr => 'height', method => 'compute_height' },
      ],
      KeyValue => { attr => 'depth', method => 'compute_depth' };

C<Widget> ends up with C<width>, C<height>, and C<depth> attributes and the
three C<compute_*> methods. A single C<with> call can mix the arrayref and
hashref forms, and can name plain C<Moo>, C<Moo::Role>, and C<Role::Tiny> roles
alongside parameterized ones.

B<Runnable example:> F<examples/applying-roles.pl>.

=head1 RECIPE 4: PORTING FROM MooseX::Role::Parameterized

B<Problem:> you have a role written with L<MooseX::Role::Parameterized> and
want to move it to L<Moo>.

B<Solution:> the DSL is deliberately close. The differences that matter:

=over

=item *

Use C<use MooX::Role::Parameterized;> in the role and
C<use MooX::Role::Parameterized::With;> in the consumer.

=item *

C<parameter> options follow C<Moo::has>, so C<is> is mandatory — Moose lets you
omit it.

=item *

The C<role> block receives C<< ($params, $mop) >>. Build the role through the
C<$mop> proxy: C<< $mop->has >>, C<< $mop->method >>, C<< $mop->before >>,
C<< $mop->after >>, C<< $mop->around >>, C<< $mop->with >>, and
C<< $mop->requires >>.

=item *

There is no C<make_immutable> step to worry about.

=back

The runnable example shows the C<Counter> role — the canonical L<MooseX::Role::Parameterized> example — ported to C<Moo> and applied to two consumer classes.

B<Runnable example:> F<examples/moosex-role-parameterized.pl>.

=head1 RECIPE 5: A WORKED EXAMPLE — AN ARITHMETIC STREAM

B<Problem:> something larger than a snippet — a parameterized role used as a
building block in a small program.

B<Solution:> build a lazy arithmetic-sequence stream. A plain C<Stream> role
defines the C<next> protocol; a parameterized C<Stream::Sequence::Arithmetic>
role fills in C<first> and C<code> from its parameters.

    package Stream::Sequence::Arithmetic;

    use Moo::Role;
    use MooX::Role::Parameterized;
    with 'Stream';

    role {
        my ( $params, $mop ) = @_;

        $mop->has( state => ( is => 'rw', predicate => 1 ) );
        $mop->method( first => sub { $params->{first} } );
        $mop->method(
            code => sub {
                my ( $self, $previous ) = @_;
                return $previous + $params->{difference};
            }
        );
    };

    package Stream::TenPlusTen;

    use Moo;
    use MooX::Role::Parameterized::With;
    with 'Stream::Sequence::Arithmetic' => { first => 10, difference => 10 };

This role declares no C<parameter>, so C<$params> is a plain hash reference —
hence C<< $params->{first} >> rather than C<< $params->first >> (see Recipe 2).
C<Stream::TenPlusTen> yields 10, 20, 30, ...; the parameters C<first> and
C<difference> decide which arithmetic sequence you get. The full program
computes a running average over the first several terms.

This recipe is adapted from Perl Weekly Challenge 122.

B<Runnable example:> F<examples/task-1-weekly-challenge-122.pl>.

=head1 SEE ALSO

L<MooX::Role::Parameterized> - the DSL itself

L<MooX::Role::Parameterized::With> - the C<with> override used by consumers

L<MooseX::Role::Parameterized> - the Moose original

=head1 AUTHOR

Tiago Peczenyj <tiago.peczenyj+cpan@gmail.com>
