
package Sort::Half::Maker;

use strict;
use warnings;

our $VERSION = '0.04';

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(make_halfsorter make_halfsort);

sub make_halfsort {
    my %args = @_;
    my $sort_sub = $args{fallback} || sub ($$) { $_[0] cmp $_[1] };
    my %start_hash;
    if ( $args{start} ) {
        my @start = @{ $args{start} };

        #@start_hash{@start} = (1..@start);
        my $idx = 1;
        for (@start) {
            $start_hash{$_} = $idx unless exists $start_hash{$_};
            $idx++;
        }
    }
    my %end_hash;
    if ( $args{end} ) {
        my @end = @{ $args{end} };

        #@end_hash{@end} = (1..@end);
        my $idx = 1
          ; # the same as "@end_hash{@end} = (1..@end)" but keeps the first occurrence
        for (@end) { $end_hash{$_} = $idx unless exists $end_hash{$_}; $idx++ }
    }
    return sub ($$) {
        my ( $left, $right ) = @_;
        if ( $start_hash{$left} || $start_hash{$right} ) {
            my $ia = $start_hash{$left}  || keys(%start_hash) + 1;
            my $ib = $start_hash{$right} || keys(%start_hash) + 1;
            return $ia <=> $ib;
        }
        elsif ( $end_hash{$left} || $end_hash{$right} ) {
            my $ia = $end_hash{$left}  || 0;
            my $ib = $end_hash{$right} || 0;
            return $ia <=> $ib;
        }
        else {
            return $sort_sub->( $left, $right );
        }
      }

}

#sub make_halfsorter {
#    my %args = @_;
#    my $sort_sub = $args{any} || sub { $_[0] cmp $_[1] };
#    my %pre_hash;
#    if ($args{pre}) {
#        my @pre = @{$args{pre}};
#        @pre_hash{@pre} = (1..@pre);
#    }
#    my %post_hash;
#    if ($args{post}) {
#        my @post = @{$args{post}};
#        @post_hash{@post} = (1..@post);
#    }
#    return sub {
#        sort {
#               my ($left, $right) = map { $_ } $a, $b;
#               #my ($left, $right) = map { $_ } @_;
#               if ($pre_hash{$left} || $pre_hash{$right}) {
#                   my $ia = $pre_hash{$left} || keys(%pre_hash)+1;
#                   my $ib = $pre_hash{$right} || keys(%pre_hash)+1;
#                   return $ia <=> $ib;
#               } elsif ($post_hash{$left} || $post_hash{$right}) {
#                   my $ia = $post_hash{$left} || 0;
#                   my $ib = $post_hash{$right} || 0;
#                   return $ia <=> $ib;
#               } else {
#                   return $sort_sub->($left, $right);
#               }
#        } @_
#    }
#
#}

1;

__END__

=head1 NAME

Sort::Half::Maker - Create half-sort subs easily

=head1 SYNOPSIS

    use Sort::Half::Maker qw(make_halfsort);

    $sub = make_halfsort(
                  start => [ qw(x y z) ],
                  end => [ qw(a b c) ],
                  fallback => sub { $_[0] cmp $_[1] },
    );
    @list = sort $sub qw(a y f h w z b t x);
    # qw(x y z f h t w a b)

=head1 DESCRIPTION

Before anything, what it a half-sort?

A half-sort is a sort subroutine defined by a starting
list, an ending list and an ordinary sort subroutine.
Elements in the starting list always go first in
comparison to others and keep the original order.
Elements in the ending list always go last in
comparison to others and keep their original
order. The remaining elements are sorted via
the given ordinary sort subroutine.

An example, please?

Imagine we want to sort the list of key/value pairs
of a hash, such that C<qw(name version abstract license
author)> come first and C<qw(meta-spec)> comes last,
using case-insensitive comparison in-between. With this
module, this is done so:

    $sub = make_halfsort(
               start => [ qw(name version abstract license author) ],
               end => [ qw(meta-spec) ],
               fallback => sub { lc $_[0] cmp lc $_[1] }
           );
    my @pairs = map { ($_, $h{$_}) } sort $sub keys(%h);

Why is it good for?

I don't see many uses for it. I played with the concept
while writing a patch to improve META.yml generation
by ExtUtils::MakeMaker. There we wanted to dump some
keys (like name, version, abstract, license, author) before
and then the ones the module author provided as
extra information.

=head2 FUNCTIONS

=over 4

=item B<make_halfsort>

    $sub = make_halfsort(start => \@start_list,
                         end => \@end_list,
                         fallback => &\sort_sub
           );
    @sorted = sort $sub @unsorted;

Builds a sort subroutine which can be used with C<sort>.
It splits the sorted list into (possibly) three partitions:
the elements contained in C<@start_list>, the elements
contained in C<@end_list> and the remaining ones.
For the elements in C<@start_list> and C<@end_list>,
the list order is preserved. For the remaining ones,
the given sort sub (or the default) is used.

If C<fallback> is ommited, it defaults to use the sort sub
C<sub ($$) { $_[0] cmp $_[1] }>.

The arguments C<start> or C<end> may be ommited as well.
But if you omit both, you could have done it without
a half-sort ;)

=begin comment

=item B<make_halfsorter>

    $sorter = make_halfsorter(pre => \@start, post => \@end, any => $sub);
    @sorted = $sorter->(@unsorted);

Arguments: pre, post, any, name

(like Sort::Maker)

=end comment

=back

=head1 SEE ALSO

Sort::Maker

=head1 BUGS

Please report bugs via CPAN RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Sort-Half-Maker>.

=head1 AUTHOR

Adriano R. Ferreira, E<lt>ferreira@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Adriano R. Ferreira

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

