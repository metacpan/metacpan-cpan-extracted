package Sort::Hash1;
{
  $Sort::Hash1::VERSION = '2.05';
}
use Exporter 'import';
use Try::Tiny 0.13;
use Scalar::Util 1.24;
use strict;
use warnings FATAL => 'all';

our @EXPORT = qw( sort_hash );    # symbols to export on request

=head1 NAME

Sort::Hash1 Version1 of SortHash

=head1 VERSION 

1.042

=head1 SYNOPSIS

Sort::Hash1 is included in the distribution for backwards compatibility. If you used Sort::Hash and don't want to fix the code right now, use Sort::Hash1. If you are writing or maintaining your code use Sort::Hash instead. 

=head2 sort_hash

The interface to sort_hash changed from version 1 to version 2. Instead of taking a hash of values it now takes a list in which the first item must be a reference to the hash to sort. Sort::Hash1 will be removed from the distribution in the future, updating your code is easy:

 sort_hash( desc => 1 , alpha => 1, %somehash );
 becomes
 sort_hash( \%somehash, 'desc', 'alpha' );

=cut

sub sort_hash {
    my %H      = @_;
    my @sorted = ();
    my $direction   = delete $H{direction}   || 'asc';
    my $alpha       = delete $H{alpha}       || 0;
    my $strictalpha = delete $H{strictalpha} || 0;
    my $numeric     = delete $H{numeric}     || 1;
    if ( defined $H{hashref} ) { %H = %{ $H{hashref} } }
    if ($strictalpha) { 
        $alpha = 1;
        for ( values %H ) {
            if (Scalar::Util::looks_like_number($_)) {
                warn 'Attempt to Sort Numeric Value in Strict Alpha Sort';
                return undef }
            }
        }
    if ($alpha) {
        @sorted = ( sort { lc $H{$a} cmp lc $H{$b} } keys %H ) ;
        }
    else {
        try { @sorted = ( sort { $H{$a} <=> $H{$b} } keys %H ) ;}
        catch { 
            warn 'Attempt to Sort non-Numeric values in a Numeric Sort';
            return undef ; }
        }
    if ( lc($direction) eq 'desc' ) {
        return reverse @sorted;
    }
    else { return @sorted; }
}

=head1 AUTHOR

John Karr, C<< <brainbuz at brainbuz.org> >>

=head1 BUGS

Please report any bugs or feature requests via the BitBucket issue tracker at
L<https://bitbucket.org/brainbuz/sort-hash/issues>.  I will be
notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

You can also look for information at: The documentation for the 
sort command in the Perl documentation.

=head1 LICENSE AND COPYRIGHT

Copyright 2014 John Karr.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 3 or at your option
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License is available in the source tree;
if not, write to the Free Software Foundation, Inc.,
59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=cut

1;
