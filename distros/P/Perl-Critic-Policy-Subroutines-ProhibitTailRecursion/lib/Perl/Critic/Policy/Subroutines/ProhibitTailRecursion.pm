package Perl::Critic::Policy::Subroutines::ProhibitTailRecursion 0.001;

# ABSTRACT: Do not call a sub from itself: Perl gives every call a stack frame.

use strict;
use warnings FATAL => 'all';

use 5.014;

use re '/aa';

use Readonly;

use Perl::Critic::Utils qw{ :severities is_function_call is_method_call };
use parent              qw{Perl::Critic::Policy};



Readonly::Scalar my $DESC => 'A sub calls itself';
Readonly::Scalar my $EXPL => 'perl gives every call a stack frame, a tail call too, so recursion uses a frame for each level of its input.  Walk it with an array and a c-style for loop, or use goto &name for a tail call';

# The invocants a method recurses through.
Readonly::Hash my %SELF => map { $_ => 1 } qw{$self $class __PACKAGE__};

sub supported_parameters { return () }


sub default_severity { return $SEVERITY_MEDIUM }


sub default_themes { return qw{performance} }


sub applies_to { return qw{PPI::Statement::Sub PPI::Token::Word} }


sub violates {
    my ( $self, $elem ) = @_;

    if ( $elem->isa('PPI::Token::Word') ) {
        return () unless $elem->content eq '__SUB__' && _calls_current_sub($elem);
        return $self->violation( $DESC, $EXPL, $elem );
    }

    my $block = $elem->block;
    my $name  = $elem->name;
    return () if !$block || !defined $name || $name eq q{};

    my ($short) = $name =~ m/(\w+)\z/xs;
    my %names = map { $_ => 1 } ( $short, $name, _package_of($elem) . "::$short" );

    my $found = $block->find( sub { $_[1]->isa('PPI::Token::Word') || $_[1]->isa('PPI::Token::Symbol') } ) || [];
    return map { $self->violation( $DESC, $EXPL, $_ ) } grep { !_in_nested_sub( $_, $elem ) && _calls( $_, \%names ) } @$found;
}

# Whether $e, a word or a symbol in the body of the sub, calls it.
sub _calls {
    my ( $e, $names ) = @_;

    if ( $e->isa('PPI::Token::Symbol') ) {
        my ( $sigil, $called ) = $e->content =~ m/\A(&)(.+)\z/xs;
        return 0 unless $sigil && $names->{$called};
        my $before = $e->sprevious_sibling;
        return 0 if $before && $before->isa('PPI::Token::Word') && $before->content eq 'goto';
        return 0 if $before && $before->isa('PPI::Token::Cast') && $before->content eq '\\';
        return 1;
    }

    return 0                            unless $names->{ $e->content };
    return is_function_call($e) ? 1 : 0 unless is_method_call($e);

    # A method call: the element before the arrow is the invocant.
    my $arrow    = $e->sprevious_sibling;
    my $invocant = $arrow ? $arrow->sprevious_sibling : undef;
    return $invocant && $SELF{ $invocant->content } ? 1 : 0;
}

# Whether this __SUB__ is called, rather than taken as a value.
sub _calls_current_sub {
    my ($elem) = @_;

    my $after = $elem->snext_sibling;
    return 1 if $after && $after->isa('PPI::Token::Operator') && $after->content eq '->';

    # &{ __SUB__ }(...): the word alone in a block after a cast.
    my $statement = $elem->parent;
    my $block     = $statement ? $statement->parent : undef;
    return 0 unless $block && $block->isa('PPI::Structure::Block');
    my $cast = $block->sprevious_sibling;
    return $cast && $cast->isa('PPI::Token::Cast') && $cast->content eq q{&} ? 1 : 0;
}

# Whether $e sits in a named sub declared inside $sub, which is checked alone.
sub _in_nested_sub {
    my ( $e, $sub ) = @_;
    for ( my $up = $e->parent; $up && $up != $sub; $up = $up->parent ) {
        return 1 if $up->isa('PPI::Statement::Sub');
    }
    return 0;
}

# The package that $elem is declared in: the last package statement before it.
sub _package_of {
    my ($elem) = @_;

    my $packages = $elem->top->find('PPI::Statement::Package') || [];
    my $package  = 'main';
    foreach my $statement (@$packages) {
        last unless _before( $statement, $elem );
        $package = $statement->namespace;
    }
    return $package;
}

sub _before {
    my ( $one, $two ) = @_;
    my ( $l1, $c1 ) = @{ $one->location // [ 0, 0 ] };
    my ( $l2, $c2 ) = @{ $two->location // [ 0, 0 ] };
    return $l1 < $l2 || ( $l1 == $l2 && $c1 < $c2 );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::Subroutines::ProhibitTailRecursion - Do not call a sub from itself: Perl gives every call a stack frame.

=head1 VERSION

version 0.001

=head1 Perl::Critic::Policy::Subroutines::ProhibitTailRecursion

Perl does not optimize a tail call.  Every call makes a new stack frame, the
last call of a sub too, so a sub that calls itself uses one frame for each
level of its input, and a deep enough input fills the stack:

    sub walk {
        my ( $node, @seen ) = @_;
        walk( $_, @seen, $node ) for children($node);    # violates
        return;
    }

    my $walk = sub {
        __SUB__->($_) for children( $_[0] );             # violates
    };

Walk the input with a loop instead.  Push what is still to be visited onto an
array, and visit it in a c-style C<for> loop, which sees what the loop pushes
while it runs.  A C<foreach> over the array does not:

    my @todo = ($root);
    for ( my $i = 0; $i < scalar(@todo); $i++ ) {
        push( @todo, children( $todo[$i] ) );
    }

=head2 What it reports

Inside a named sub, a call to that sub by its name: C<walk(...)>,
C<walk @args>, C<&walk(...)>, C<&walk>, and C<Pkg::walk(...)> in its own
package.  It also reports a call of the same name as a method on the invocant
of the sub, C<< $self->walk >>, C<< $class->walk >>,
C<< __PACKAGE__->walk >> or C<< $self->Pkg::walk >>, which is how a method
recurses.  A call anywhere in the body counts, in a loop, in the block of a
C<map> or a C<sort>, or in an anonymous sub, because each one adds a frame
when it runs.

Anywhere, a call through C<__SUB__>: C<< __SUB__->(...) >> and
C<&{ __SUB__ }(...)>.

=head2 What it leaves alone

=over 4

=item * C<goto &walk> and C<goto __SUB__>.  C<goto> replaces the frame of the
sub rather than adding one, so it is the one tail call that Perl makes cheap.

=item * C<\&walk>, a reference and not a call.

=item * A call to the same name on any other object, and C<< $self->SUPER::walk >>,
which can reach a different sub.

=item * A named sub declared inside another.  It is a sub of its own, and it
is checked on its own.

=item * Calls from one sub to another that calls the first.  This policy looks at
one sub at a time.

=back

=head1 CONFIGURATION

There is nothing to configure.

=head2 METHODS

What L<Perl::Critic::Policy> asks of a policy, answered here rather than called
from anywhere.

=head3 supported_parameters

None.

=head3 default_severity

Medium: the code works until an input is deep enough, and then it fails.

=head3 default_themes

C<performance>.

=head3 applies_to

A named sub, for a call to it by name, and a word, for C<__SUB__>.

=head3 violates

One violation for each call of the sub to itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/perl-critic-policy-prohibittailrecursion/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
