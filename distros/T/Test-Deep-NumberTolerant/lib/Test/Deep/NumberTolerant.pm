use strict;
use warnings;
package Test::Deep::NumberTolerant; # git description: v0.001-25-gfd85626
# vim: set ts=8 sts=4 sw=4 tw=115 et :
# ABSTRACT: A Test::Deep plugin for testing numbers within a tolerance range
# KEYWORDS: testing tests plugin numbers tolerance range epsilon uncertainty

our $VERSION = '0.002';

use Exporter 5.57 'import';
our @EXPORT = qw(within_tolerance);

sub within_tolerance
{
    my ($number, @tolerance_args) = @_;
    return Test::Deep::NumberTolerant::Object->new($number, @tolerance_args);
}

package # hide from PAUSE
    Test::Deep::NumberTolerant::Object;

our $VERSION = '0.002';

use parent 'Test::Deep::Cmp';
use Number::Tolerant ();

sub init
{
    my $self = shift;
    $self->{tolerance} = Number::Tolerant->new(@_);
}

sub descend
{
    my ($self, $got) = @_;
    return $got == $self->{tolerance};
}

sub diag_message
{
    my ($self, $where) = @_;

    return 'Checking ' . $where . ' against ' . $self->{tolerance};
}

# we do not define a diagnostics sub, so we get the one produced by deep_diag
# showing exactly what part of the data structure failed. This calls renderGot
# and renderVal:

sub renderGot
{
    my ($self, $got) = @_;
    return defined $self->{error_message}
        ? $self->{error_message}
        : 'failed';  # TODO?  $got . ' is not ' . $self->{tolerance};
}

sub renderExp
{
    my $self = shift;
    return 'no error';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Deep::NumberTolerant - A Test::Deep plugin for testing numbers within a tolerance range

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use Test::More;
    use Test::Deep;
    use Test::Deep::NumberTolerant;

    cmp_deeply(
        {
            counter => 123,
        },
        {
            counter => within_tolerance(100, plus_or_minus => 50),
        },
        'counter field is 100 plus or minus 50',
    );

=head1 DESCRIPTION

This is a L<Test::Deep> plugin that
provides the sub C<within_tolerance> to indicate
that the data being tested matches the equivalent C<tolerance(...)> value
from L<Number::Tolerant>.

I wrote this because I found myself doing this a lot:

    cmp_deeply(
        $thing,
        methods(
            delete_time => methods(epoch => code( sub { $_[0] == tolerance(time(), offset => (-2,0)) || (0, "got $_[0], expected ", time()) } )),
        ),
        'object has been deleted',
    );

With this module, this can be simplified to the much more readable:

    cmp_deeply(
        $thing,
        methods(
            delete_time => methods(epoch => within_tolerance(time(), offset => (-2,0))),
        ),
        'object has been deleted',
    );

(Note that for the simple C<plus_or_minus> case, you can also use L<Test::Deep/num>.)

=head1 FUNCTIONS

=head2 C<within_tolerance>

Exported by default; to be used within a L<Test::Deep> comparison function
such as L<cmp_deeply|Test::Deep/COMPARISON FUNCTIONS>.  Accepted arguments are
the same as for C<L<Number::Tolerant/tolerance>>.

=for Pod::Coverage descend
diag_message
init
renderExp
renderGot

=head1 SEE ALSO

=over 4

=item *

L<Test::Deep>

=item *

L<Number::Tolerant>

=item *

L<Test::Deep::Between>

=item *

L<Test::Deep::Fuzzy>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Test-Deep-NumberTolerant>
(or L<bug-Test-Deep-NumberTolerant@rt.cpan.org|mailto:bug-Test-Deep-NumberTolerant@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/perl-qa.html>.

There is also an irc channel available for users of this distribution, at
L<C<#perl> on C<irc.perl.org>|irc://irc.perl.org/#perl-qa>.

I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
