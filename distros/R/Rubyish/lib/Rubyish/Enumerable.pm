=head1 NAME

Rubyish::Enumerable - Enumerable (module)

=cut

package Rubyish::Enumerable;
use strict;

use base qw(Rubyish::Module);
use Rubyish::Syntax::def;

def all($cb) {
    my $all_true = 1;
    $cb = sub { $_[0] } unless $cb;
    $self->each(
        sub {
            my ($i) = @_;
            $all_true = 0 if !$cb->($i);
        }
    );
    return $all_true;
}

def any($cb) {
    my $any_true = 0;
    $cb = sub { $_[0] } unless $cb;

    $self->each(
        sub {
            my ($i) = @_;
            $any_true = 1 if $cb->($i);
        }
    );
    return $any_true;
}

use Rubyish::Array;
def to_a {
    my @arr;
    $self->each(sub { push @arr, $_[0] });
    return Rubyish::Array->new(\@arr);
}

1;

=head1 NAME

Rubyish::Enumerable - The Enumerable implementation

=head1 SYNOPSIS

    use MyEnumerableClass;
    use Rubyish::Enumerable;

    # you define "each"...
    def each {... }

    # and get these methods for free:
    # all, any, to_a

=head1 DESCRIPTION

This module exports several methods that can be defined in terms of
"each". When you define your classes and you want it behave as
enumerables, simply say C<use Rubyish::Enumerable>. And define C<each>
method. Then you will get the following intance methods for free.

=over 4

=item all([ $block ])

Return true if all items in the enumerable object makes $block returns
true. For example:

  $collection->all(sub {
    my ($i) = @_;
    $i > 3;
  });

Will test if all items in the C<$collection> are greater then 3. If
C<$block> is not given, then it simply test if all items in the
collection are considered to be true value.

See also L<List::MoreUtils> and L<Quantum::Superpositions> for the
concept and alternative implementation of the C<all> function.

=item any([ $block ])

Similar to C<all> function, but returns ture if any item in the
enumerable object is true, or let $block returns true.

See also L<List::MoreUtils> and L<Quantum::Superpositions> for the
concept and alternative implementation of the C<any> function.

=item to_a

Convert the enumerable object to an array.

=back

=head1 SEE ALSO

L<Rubyish::Arry>

=head1 AUTHOR

Kang-min Liu  C<< <gugod@gugod.org> >>, shelling C<shelling@cpan.org>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008,2009, Kang-min Liu C<< <gugod@gugod.org> >>.

This is free software, licensed under:

    The MIT (X11) License

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.



