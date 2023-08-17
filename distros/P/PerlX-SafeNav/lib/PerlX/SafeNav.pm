package PerlX::SafeNav;
use strict;
use warnings;
our $VERSION = '0.004';

use Exporter 'import';

our @EXPORT = ('$safenav', '$unsafenav');
our @EXPORT_OK = ('&safenav');

our $safenav = sub {
    my $o = shift;
    bless \$o, 'PerlX::SafeNav::Object';
};

our $unsafenav = sub {
    ${ $_[0] }
};

sub safenav (&@) {
    my ($block, $o) = @_;
    local $_ = $o->$safenav;
    $block->()->$unsafenav;
}

package PerlX::SafeNav::Object;

use overload
    '@{}' => sub {
        my $self = shift;
        tie my @a, 'PerlX::SafeNav::ArrayRef', $$self;
        return \@a;
    },
    '%{}' => sub {
        my $self = shift;
        tie my %h, 'PerlX::SafeNav::HashRef', $$self;
        return \%h;
    };

sub AUTOLOAD {
    our $AUTOLOAD;
    my $method = substr $AUTOLOAD, 2 + rindex($AUTOLOAD, '::');

    my ($self, @args) = @_;

    (defined $$self) ?
        $$self -> $method(@args) -> $safenav :
        $self;
}

sub DESTROY {}

package PerlX::SafeNav::ArrayRef;
use Tie::Array;
our @ISA = ('Tie::Array');

sub TIEARRAY {
    my ($class, $o) = @_;
    return bless \$o, $class;
}

sub FETCH {
    my ($self, $i) = @_;
    @$$self[$i] -> $safenav;
}

sub FETCHSIZE {
    my ($self) = @_;
    (defined $$self) ? @$$self : 0
}

package PerlX::SafeNav::HashRef;
use Tie::Hash;
our @ISA = ('Tie::Hash');

sub TIEHASH {
    my ($class, $o) = @_;
    bless \$o, $class;
}

sub FETCH {
    my ($self, $k) = @_;
    $$self->{$k} -> $safenav;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

PerlX::SafeNav - Safe-navigation for Perl

=head1 SYNOPSIS

Wrap a chain of method calls to make it resilient on encountering C<undef> values in the middle:

    use PerlX::SafeNav ('$safenav', '$unsafenav', 'safenav');

    my $answer = safenav {
        $_->a()->{b}->c()->[42]->d()
    } $o;

    my $tire_age = $car -> $safenav
         -> wheels()
         -> [0]               # undef, if no wheels at all.
         -> tire()            # undef, if no tire on the wheel.
         -> {created_on}
         -> delta_days($now)
         -> $unsafenav;

    unless (defined $tire_age) {
        # The car either have no wheels, or the first wheel has no tire.
        ...
    }

=head1 DESCRIPTION

=head2 Background

In many other languages, there is an operator (often C<?.>) doing
"Safe navigation", or "Optional Chaining".  The operator does a
method-call when its left-hand side (first operant) is an object.  But
when the left-hand side is an undefined value (or null value), the
operator returns but evaluates to C<undef>.

For perl there is currently an PPC: L<Optional Chaining|https://github.com/Perl/PPCs/blob/main/ppcs/ppc0021-optional-chaining-operator.md>

This module provides a mean of making chains of method call safe
regarding undef values. When encountering an C<undef> in the middle of
a call chain like C<< $o->foo()->bar()->baz() >>, the program would die
with a message like this:

    Can't call method "bar" on an undefined value

With the help of this module, instead of making the program die, the
call chain is reduced to C<undef>.

=head2 Usages

=head3 C<$safenav> and C<$unsafenav>

With this module, instead of using a different operator, we wrap a
chain of calls to make it safe with the imported C<$safenav> and
C<$unsafenav>. C<$safenav> must be placed at the beginning, while
C<$unsafenav> must be place at the end. The should be invoked as
method calls, like this:

    $obj-> $safenav
        -> a()
        -> {b}
        -> [0]
        -> c()
        -> $unsafenav;

Notice that it is possible to mix all three kinds method calls, hash
fetches, and array fetches together in the same chain. If any of the 4
sub-expresions returns C<undef>, the entire chain upto C<$unsafenav>
would also be evaluated to C<undef>. (For this reason, you probably
don't want to concatenate more sub-expressions after C<$unsafenav>.)

This module provide 2 symbols are both C<$>-sigiled scalar variables,
this is on purpose, so that they could be called as methods on
arbitrary scalar values.

It is mandatory to have both C<$safenav> and C<$unsafenav> together in
the same chain. Without C<$unsafenav>, the original return value of
the chain would be forever wrapped inside the mechanism of
C<PerlX::SafeNav>.

While being unconventional in their look, one benifit is that the
chance of having naming conflicts with methods from C<$o> should be very
small. However, be aware that C<$safenav> and C<$unsafenav> would be
masked by locally-defined variables with the same name.

=head3 safenav block

A block syntax is also provided by importing the C<safenav> symbol explicitly:

    use PerlX::SafeNav ('safenav');

    my $answer = safenav {
        $_ ->a()->{b}->[0]->c()
    } $o;

Inside this C<safenav> block, C<$_> is the safenav-wrapped version of C<$o>, and the chain is automaticly un-wrapped at the end. C<$answer> contains the return value of method C<c()> if no C<undef> values are encountered or otherwise, an C<undef>.

=head2 Bugs

There are likely many unknown bugs, as the current test suite only
covers the minmum set of forms that are known to work.


=head1 AUTHOR

Kang-min Liu <gugod@gugod.org>

Toby Inkster <tobyink@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2023 Kang-min Liu C<< <gugod@gugod.org> >>.

This is free software, licensed under:

    The MIT License

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
