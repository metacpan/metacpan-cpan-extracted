package Perl6::GatherTake;
our $VERSION = '0.0.3';

=head1 NAME

Perl6::GatherTake - Perl 6 like C<gather { take() }> for Perl 5

=head1 SYNOPSIS

    use Perl6::GatherTake; 

    my $powers_of_two = gather {
        my $i = 1;
        for (;;) {
            take $i;
            $i *= 2;
        }
    };

    print $powers_of_two->[3], "\n";
    # output: 8

=head1 DESCRIPTION

Perl6::GatherTake implements an API for producing partial computation results
on the fly, storing them in a lazy list.

A word of warning: This module tries to explore some language concepts. It is
B<not suitable for any productive work>.

A C<gather { ... };> block returns a reference to a (tied) array. Each call
to C<take> inside the block pushes its arguments to that array. The block
is only run as needed to produce results (but see "BUGS AND LIMITATIONS"
below), which means that you can put infinite loops inside the C<gather>
block as long as it calls C<take> on a regular basis.

Instead of this common construct:

    my @results;
    for (@data){
        # computations here
        if ($result =~ m/super regex/){
            push @results, $result;
        }
    }

You can now write

    my $results = gather {
        for (@data){
            # computations here
            if ($result =~ m/super regex/){
                take $result;
            }
        }
    };

It has the nice side effect that the computations are only executed as the
array elements are accessed, so if the end of the array is never used you
can save much time here.

Nested C<gather { take };> blocks are supported, a C<take> always supplies
data to the innermost C<gather> block.

Note that if a C<gather> block is an infinite loop, you're responsible for
not accessing all elements. If you do something stupid like iterating over
all items, joining them or copying the array (C<my @other = @$array_ref>)
you have an infinite loop (until you run out of memory).

Assigning to an array element triggers evaluation until the index of the
changed item is reached.

=head1 BUGS AND LIMITATIONS

This is a prototype module and is neither stable nor well-tested at the
moment.

=over 2

=item * 

Due to the L<Coro> based implementation (and the author's missing
understanding of L<Coro>'s concepts) the lazyness is limited: 
C<gather>-blocks might be run up to the first occurance of C<take> before
a element is fetched from the associated array.

=item * 

C<scalar @$array_ref> doesn't return "the right" value for an array
reference that is returend by a gather-take block. More precisely it returns
the number of already computed values plus one (unless the gather block is 
exhausted). This means that iterating over C<for (@$list)> will result in an 
undefined element at the end if the block returns only a finite number of
elements.

=item * 

This module consumes much more resources than desirable: for each
gather-take-block it (currently) maintains a tied array (which is implemented
as a blessed hash) which holds all the computed values so far, a C<Coro> and
a C<Coro::Channel> object.

=item * 

C<take> doesn't default to C<$_>.

=item * 

More advanced array operations (like slices, C<splice> etc.) aren't tested yet.

=back

=head1 LICENSE

This package is free software, you can use it under the same terms as Perl
itself.

All example and test code in this distribution is "Public Domain" (*), i.e.
you may use it in any way you want.

(*) German copyright laws always grant the original author some rights, so
I can't really place things in the "Public Domain". But don't let that bother
you.

=head1 AUTHOR

Moritz Lenz, L<http://perlgeek.de/>, L<http://perl-6.de/>.
E-Mail E<lt>moritz@faui2k3.orgE<gt>.

=head1 DEVELOPMENT

You can obtain the latest development version via subversion:

    svn co https://faui2k3.org/svn/moritz/cpan/Perl6-GatherTake

Patches and comments are welcome.

=cut

use strict;
use warnings;

use Data::Dumper;
use base 'Exporter';
use Perl6::GatherTake::LazyList;
use Coro;
use Coro::Channel;
use Carp qw(confess);
use Scalar::Util qw(refaddr);
our @EXPORT = qw(gather take);

our %_coro_to_queue;

sub gather(&@) {
    my $code = shift;
    # cheat prototype by prepending '&' to method call:
    my $coro = &async($code, @_);
    my @result = ();
    my $queue = Coro::Channel->new(1);
#    print "Initialized coro $coro\n";
    $_coro_to_queue{refaddr($coro)} = $queue;
    tie @result, 'Perl6::GatherTake::LazyList', $coro, $queue;
    return \@result;
}

sub take {
    my $c = Coro::current;
#    print "Take: $c\n";
    for (@_){
        $_coro_to_queue{refaddr($c)}->put($_);
    }
}

1;
