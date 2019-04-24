package MooX::BuildArgsHooks;
our $VERSION = '0.08';

=encoding utf8

=head1 NAME

MooX::BuildArgsHooks - Structured BUILDARGS.

=head1 SYNOPSIS

    package Foo;
    use Moo;
    with 'MooX::BuildArgsHooks';
    
    has bar => (is=>'ro');
    
    around NORMALIZE_BUILDARGS => sub{
        my ($orig, $class, @args) = @_;
        @args = $class->$orig( @args );
        return( bar=>$args[0] ) if @args==1 and ref($args[0]) ne 'HASH';
        return @args;
    };
    
    around TRANSFORM_BUILDARGS => sub{
        my ($orig, $class, $args) = @_;
        $args = $class->$orig( $args );
        $args->{bar} = ($args->{bar}||0) + 10;
        return $args;
    };
    
    around FINALIZE_BUILDARGS => sub{
        my ($orig, $class, $args) = @_;
        $args = $class->$orig( $args );
        $args->{bar}++;
        return $args;
    };
    
    print Foo->new( 3 )->bar(); # 14

=head1 DESCRIPTION

This module installs some hooks directly into L<Moo> which allow
for more fine-grained access to the phases of C<BUILDARGS>.  The
reason this is important is because if you have various roles and
classes modifying BUILDARGS you will often end up with weird
behaviors depending on what order the various BUILDARGS wrappers
are applied in.  By breaking up argument processing into three
steps (normalize, transform, and finalize) these conflicts are
much less likely to arise.

To further avoid these kinds of issues, and this applies to any
system where you would C<around> methods from a consuming role or
super class not just BUILDARGS, it is recommended that you implement
your extensions via methods.  This way if something inherits from your
role or class they can treat your method as a hook.  For example:

    around TRANSFORM_BUILDARGS => sub{
        my ($class, $orig, $args) = @_;
        $args = $class->$orig( $args );
        return $class->TRANSFORM_FOO_BUILDARGS( $args );
    };
    
    sub TRANSFORM_FOO_BUILDARGS {
        my ($class, $args) = @_;
        $args->{bar} = ($args->{bar}||0) + 10;
        return $args;
    }

Then if some other code wishes to inject code before or after
the C<Foo> class transforming BUILDARGS they can do so at very
specific points.

=cut

use Class::Method::Modifiers qw( install_modifier );
use Moo::Object qw();

use Moo::Role;
use strictures 2;
use namespace::clean;

BEGIN {
    package # NO INDEX
        MooX::BuildArgsHooks::Test;
    use Moo;
    around BUILDARGS => sub{
        my $orig = shift;
        my $class = shift;
        return $class->$orig( @_ );
    };
    has normalize => ( is=>'rw' );
    has transform => ( is=>'rw' );
    has finalize  => ( is=>'rw' );
    sub NORMALIZE_BUILDARGS { $_[0]->normalize(1); shift; @_ }
    sub TRANSFORM_BUILDARGS { $_[0]->transform(1); $_[1] }
    sub FINALIZE_BUILDARGS  { $_[0]->finalize(1); $_[1] }
}

# When installing these modifiers we're going to be super defensive
# and not overwrite anything that may have already declared these
# methods or even provides this functionality already.  This should
# hopefully make this module relatively future proof.
BEGIN {
    my $moo = 'Moo::Object';

    install_modifier(
        $moo, 'fresh',
        'NORMALIZE_BUILDARGS' => sub{ shift; @_ },
    ) unless $moo->can('NORMALIZE_BUILDARGS');

    install_modifier(
        $moo, 'fresh',
        'TRANSFORM_BUILDARGS' => sub{ $_[1] },
    ) unless $moo->can('TRANSFORM_BUILDARGS');

    install_modifier(
        $moo, 'fresh',
        'FINALIZE_BUILDARGS' => sub{ $_[1] },
    ) unless $moo->can('FINALIZE_BUILDARGS');

    my $test = MooX::BuildArgsHooks::Test->new();
    my $does_normalize = $test->normalize();
    my $does_transform = $test->transform();
    my $does_finalize  = $test->finalize();
    $test = undef;

    unless ($does_normalize and $does_transform and $does_finalize) {
        install_modifier(
            $moo, 'around',
            'BUILDARGS' => sub{
                my ($orig, $class, @args) = @_;

                @args = $class->NORMALIZE_BUILDARGS( @args ) unless $does_normalize;

                my $args = $class->$orig( @args );

                $args = $class->TRANSFORM_BUILDARGS( { %$args } ) unless $does_transform;

                $args = $class->FINALIZE_BUILDARGS( { %$args } ) unless $does_finalize;

                return $args;
            },
        );
    }
}

# Must declare a custom no-op BUILDARGS otherwise
# Method::Generate::Constructor gets in the way.
# Alternatively we could modify its inlined BUILDARGS
# to include our logic, but that's making things even
# more brittle.
around BUILDARGS => sub{
    my $orig = shift;
    my $class = shift;
    return $class->$orig( @_ );
};

1;
__END__

=head1 HOOKS

A hook in the context of this module is just a method that has
been declared in the inheritance hierarchy and is made available
for consuming roles and classes to apply method modifiers to.

=head2 NORMALIZE_BUILDARGS

    around NORMALIZE_BUILDARGS => sub{
        my ($orig, $class, @args) = @_;

        # Make sure you let other normalizations happen.
        @args = $class->$orig( @args );

        # Do your normalization logic.
        ...

        return @args;
    };

Used to do some basic normalization of arguments from some
custom format to a format acceptable to Moo (a hash or a
hashref).

This is useful, for example, when you want to support single
arguments.  For example:

    around NORMALIZE_BUILDARGS => sub{
        my ($orig, $class, @args) = @_;

        # If only one argument is passed in assume that it is
        # the value for the foo attribute.
        if (@args==1 and ref($args[0]) ne 'HASH') {
            @args = { foo => $args[0] };
        }

        @args = $class->$orig( @args );

        return @args;
    };

Or you could just use L<MooX::SingleArg>.

=head2 TRANSFORM_BUILDARGS

    around TRANSFORM_BUILDARGS => sub{
        my ($orig, $class, $args) = @_;

        # Make sure you let any other transformations happen.
        $args = $class->$orig( $args );

        # Do your transformations.
        ...

        return $args;
    };

This hook is the workhorse where much of the C<BUILDARGS> work
typically happens.  By the time this hook is called the arguments
will always be in hashref form, not a list, and a hashref must be
returned.

=head2 FINALIZE_BUILDARGS

    around FINAL_BUILDARGS => sub{
        my ($orig, $class, $args) = @_;

        # Let any other hooks have a turn.
        $args = $class->$orig( $args );

        # Do your finalization logic.
        ...

        return $args;
    };

This hook works just like L</TRANSFORM_BUILDARGS> except that it happens
after it and is meant to be used by hooks that are the last step in the
argument building process and need access to the arguments after most
all other steps have completed.

=head1 SEE ALSO

=over

=item *

L<MooX::BuildArgs>

=item *

L<MooX::MethodProxyArgs>

=item *

L<MooX::Rebuild>

=item *

L<MooX::SingleArg>

=back

=head1 SUPPORT

See L<MooX::BuildArgs/SUPPORT>.

=head1 AUTHORS

See L<MooX::BuildArgs/AUTHORS>.

=head1 LICENSE

See L<MooX::BuildArgs/LICENSE>.

=cut

