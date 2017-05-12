package Perl6::Take;

use warnings;
use strict;

use Carp;

our $VERSION = '0.04';

our @GATHER;

sub gather (&) {
    # We used to push and pop ourselves, but local's easier for cleanup
    # purposes, and since the gather stack only contains references to the
    # takelists, copying it isn't expensive. Unless you have like a couple
    # thousand nested gathers, in which case you're beyond my help.
    local @GATHER = (@GATHER, []);

    # Here needs to come some trick to see the code didn't explicitly say
    # "return". But that's presumed impossible in pure Perl 5.
    shift->();

    return @{ $GATHER[-1] };
}

sub take (@) {
    Carp::croak("take with no gather") unless @GATHER;
    Carp::confess("internal error: gather cell not a listref") unless
            ref $GATHER[-1] eq 'ARRAY';
    Carp::croak('take with no args, did you mean "take $_"?') unless @_;

    push @{ $GATHER[-1] }, @_;
    return @_; # for possible en passant assignment
}

sub import {
    my $caller = caller;
    no strict;
    *{"$caller\::gather"} = \&gather;
    *{"$caller\::take"}   = \&take;
}

1;

__END__

=head1 NAME

Perl6::Take - gather/take in Perl 5

=cut

=head1 SYNOPSIS

    use Perl6::Take;

    my @foo = gather {
        take 5;
    };

=head1 EXPORT

=over 4

=item gather

Accepts a block. C<take> statements inside the dynamic scope of the
block are used to accumulate a list, which is gathered as the return value
of the block.

=item take

Accumulates its argument (or list of arguments) on to the nearest
C<gather> in the dynamic scope. Arguments are evaluated in list
context. The arguments may be passed on to a variable, but note that
this assignment should usually be done in list context, as per usual
context rules:

    $answer   = take 42; #  1
    ($answer) = take 42; # 42

=back

=cut

=head1 AUTHOR

Gaal Yahas, C<< <gaal at forum2.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-perl6-gather at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl6-Take>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Perl6::Take

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Perl6-Take>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Perl6-Take>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Perl6-Take>

=item * Search CPAN

L<http://search.cpan.org/dist/Perl6-Take>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT (The "MIT" License)

Copyright 2006-2007 Gaal Yahas.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

