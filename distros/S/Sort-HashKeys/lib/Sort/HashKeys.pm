use strict;
use warnings;
package Sort::HashKeys;

# ABSTRACT: Get a sorted-by-key list from a hash
our $VERSION = '0.007'; # VERSION

require XSLoader;
XSLoader::load('Sort::HashKeys', $VERSION);

=pod

=encoding utf8

=head1 NAME

Sort::HashKeys - Get a sorted-by-key list from a hash


=head1 SYNOPSIS

    use Sort::HashKeys;

    my %hash;

    @sorted_1 = map { ($_, $hash{$_}) } sort keys %hash;
    @sorted_2 = Sort::HashKeys::sort(%hash);
    # Same outcome, but the second is faster

=head1 DESCRIPTION

    [13:37:51]  <a3f>    Is there a better way to get a sorted list out of a hash
                         than map { ($_, $versions{$_}) } reverse sort keys @versions
                         or iterating manually?
    [13:39:06]  <a3f>    oh I could provide a compare function to sort and chunk the
                         list two by two..
    [13:40:15]  <haarg>  i'd probably go with the map{} reverse sort keys
    [13:41:04]  <a3f>    I don't like it that it repeats the lookup for all keys.
                         Of course wouldn't matter in practice but still…
    [13:43:40]  <haarg>  whatever other solution you find will be slower
    [13:49:05]  <a3f>    put it into a list, pass it to XS, run qsort(3) over it
                         with double the element size. and compare taking only the
                         first part into account. return it back?

=head1 BENCHMARK

See L<benchmark.pl|https://github.com/athreef/Sort-HashKeys/blob/master/benchmark.pl> in this distribution. Test was run on a Haswell 2.6 GHz i5 CPU (4278U) for a minute each on a copy of a randomly generated hash of 1000 keys. Keys were alphanumeric with length between 1 and 6 and values of integers between 1 and 1000.

    # perl-5.24.0 w/ BSD libc
                                             Rate
    map {($_,$h{$_})} sort keys %h           1589/s       --       0%    -28%    -28%    -32%    -33%
    map +($_,$h{$_}), sort keys %h           1592/s        0%     --     -28%    -28%    -32%    -33%
    %h{sort keys %h}                         2204/s       39%     38%     --       0%     -6%     -7%
    S::HK::sort(%h) w/ qsort (threaded)      2199/s       38%     38%      0%     --      -6%     -7%
    S::HK::sort(%h) w/ qsort_r (threaded)    2338/s       47%     47%      6%      6%     --	  -2%
    S::HK::sort(%h) w/ qsort (non-threaded)  2375/s       49%     49%      8%      8%      2%     --


49% faster on non-threaded Perl and up to 47% faster on threaded Perl. Aristotle Pagaltzis L<suggested|https://github.com/athreef/Sort-HashKeys/pull/1> adding hash slices available since Perl v5.20.0 to the benchmark. This doesn't solve the unncessary hash lookup, but skipping the C<map> appears to have a much bigger impact on performance. The XS solution is only 8% faster than the pure Perl sort using hash slices.

The Slowdown with C<qsort> on threaded build is because the interpreter state is fetched from thread local storage on every comparison. On GNU and FreeBSD libcs, this is avoided by using non-standard C<qsort_r>, which allows passing an extra parameter to the comparison function.


=head1 METHODS AND ARGUMENTS

=over 4

=item sort(@)

Sorts a hash-like list C<< (key1 => val1, key2 => val2>) >> by means of your libc's 
L<qsort|http://en.cppreference.com/w/c/algorithm/qsort> in ascending order according to Perl's internal C<sv_cmp> function. 

Unlike Perl's built-in L<sort>. C<qsort(3)> is not required to be a stable sort and providing a custom comparison function is not yet supported.

Lists with odd number of elements are padded by an C<undef>.

=item reverse_sort(@)

Sorts in descending order.

=cut

1;
__END__

=back

=head1 GIT REPOSITORY

L<http://github.com/athreef/Sort-HashKeys>

=head1 AUTHOR

Ahmad Fatoum C<< <athreef@cpan.org> >>, L<http://a3f.at>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 Ahmad Fatoum

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
