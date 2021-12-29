# Paranoid::Data -- Misc. Data Manipulation Functions
#
# $Id: lib/Paranoid/Data.pm, 2.09 2021/12/28 15:46:49 acorliss Exp $
#
# This software is free software.  Similar to Perl, you can redistribute it
# and/or modify it under the terms of either:
#
#   a)     the GNU General Public License
#          <https://www.gnu.org/licenses/gpl-1.0.html> as published by the 
#          Free Software Foundation <http://www.fsf.org/>; either version 1
#          <https://www.gnu.org/licenses/gpl-1.0.html>, or any later version
#          <https://www.gnu.org/licenses/license-list.html#GNUGPL>, or
#   b)     the Artistic License 2.0
#          <https://opensource.org/licenses/Artistic-2.0>,
#
# subject to the following additional term:  No trademark rights to
# "Paranoid" have been or are conveyed under any of the above licenses.
# However, "Paranoid" may be used fairly to describe this unmodified
# software, in good faith, but not as a trademark.
#
# (c) 2005 - 2020, Arthur Corliss (corliss@digitalmages.com)
# (tm) 2008 - 2020, Paranoid Inc. (www.paranoid.com)
#
#####################################################################

#####################################################################
#
# Environment definitions
#
#####################################################################

package Paranoid::Data;

use 5.008;

use strict;
use warnings;
use vars qw($VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS);
use base qw(Exporter);
use Paranoid;
use Paranoid::Debug qw(:all);
use Carp;

($VERSION) = ( q$Revision: 2.09 $ =~ /(\d+(?:\.\d+)+)/sm );

@EXPORT      = qw(deepCopy deepCmp);
@EXPORT_OK   = @EXPORT;
%EXPORT_TAGS = ( all => [@EXPORT_OK], );

#####################################################################
#
# Module code follows
#
#####################################################################

sub deepCopy (\[$@%]\[$@%]) {

    # Purpose:  Attempts to safely copy an arbitrarily deep data
    #           structure from the source to the target
    # Returns:  True or False
    # Usage:    $rv = deepCopy($source, $target);
    # Usage:    $rv = deepCopy(@source, @target);
    # Usage:    $rv = deepCopy(%source, %target);

    my $source  = shift;
    my $target  = shift;
    my $rv      = 1;
    my $counter = 0;
    my $sref    = defined $source ? ref $source : 'undef';
    my $tref    = defined $target ? ref $target : 'undef';
    my ( @refs, $recurseSub );

    croak 'source and target must be identical data types'
        unless ref $sref eq ref $tref;

    pdebug( 'entering w/(%s)(%s)', PDLEVEL1, $source, $target );
    pIn();

    $recurseSub = sub {
        my $s    = shift;
        my $t    = shift;
        my $type = ref $s;
        my $irv  = 1;
        my ( $key, $value );

        # We'll grep the @refs list to make sure there's no
        # circular references going on
        if ( grep { $_ eq $s } @refs ) {
            Paranoid::ERROR = pdebug(
                'Found a circular reference in data structure: ' . '(%s) %s',
                PDLEVEL1, $s, @refs
                );
            return 0;
        }

        # Push the reference onto the list
        push @refs, $s;

        # Copy data over
        if ( $type eq 'ARRAY' ) {

            # Copy over array elements
            foreach my $element (@$s) {

                $type = ref $element;
                $counter++;
                if ( $type eq 'ARRAY' or $type eq 'HASH' ) {

                    # Copy over sub arrays or hashes
                    push @$t, $type eq 'ARRAY' ? [] : {};
                    return 0 unless &$recurseSub( $element, $$t[-1] );

                } else {

                    # Copy over everything else as-is
                    push @$t, $element;
                }
            }

        } elsif ( $type eq 'HASH' ) {
            while ( ( $key, $value ) = each %$s ) {
                $type = ref $value;
                $counter++;
                if ( $type eq 'ARRAY' or $type eq 'HASH' ) {

                    # Copy over sub arrays or hashes
                    $$t{$key} = $type eq 'ARRAY' ? [] : {};
                    return 0 unless &$recurseSub( $value, $$t{$key} );

                } else {

                    # Copy over everything else as-is
                    $$t{$key} = $value;
                }
            }
        }

        # We're done, so let's remove the reference we were working on
        pop @refs;

        return 1;
    };

    # Start the copy
    if ( $sref eq 'ARRAY' or $sref eq 'HASH' ) {

        # Copy over arrays & hashes
        if ( $sref eq 'ARRAY' ) {
            @$target = ();
        } else {
            %$target = ();
        }
        $rv = &$recurseSub( $source, $target );

    } else {

        # Copy over everything else directly
        $$target = $$source;
        $counter++;
    }

    $rv = $counter if $rv;

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

    return $rv;
}

sub _cmpArray (\@\@) {

    # Purpose:  Compares arrays, returns true if identical
    # Returns:  Boolean
    # Usage:    $rv = _cmpArray(@array1, @array2);

    my $ref1 = shift;
    my $ref2 = shift;
    my $rv   = 1;
    my $i    = 0;
    my ( $n, $d1, $d2, $t1, $t2 );

    pdebug( 'entering w/%s %s', PDLEVEL2, $ref1, $ref2 );
    pIn();

    $rv = scalar @$ref1 == scalar @$ref2;
    $n  = scalar @$ref1;

    # Compare contents if there is any
    if ( $rv and $n ) {
        while ( $i <= $n ) {

            # Collect some meta data
            $d1 = defined $$ref1[$i];
            $d2 = defined $$ref2[$i];
            $t1 = $d1 ? ref $$ref1[$i] : 'undef';
            $t2 = $d2 ? ref $$ref2[$i] : 'undef';

            if ( $d1 == $d2 ) {

                # Both are undefined, so move to the next item
                unless ($d1) {
                    $i++;
                    next;
                }

                # Both are defined, so check for type
                $rv = $t1 eq $t2;

                if ($rv) {

                    # The types are the same, so do some comparisons
                    if ( $t1 eq 'ARRAY' ) {
                        $rv = deepCmp( $$ref1[$i], $$ref2[$i] );
                    } elsif ( $t1 eq 'HASH' ) {
                        $rv = deepCmp( $$ref1[$i], $$ref2[$i] );
                    } else {

                        # Compare scalar value of all other types
                        $rv = $$ref1[$i] eq $$ref2[$i];
                    }
                }

            } else {

                # One of the two are undefined, so quick exit
                $rv = 0;
            }

            # Early exit if we've found a difference already
            last unless $rv;

            # Otherwise, on to the next element
            $i++;
        }
    }

    # A little explicit sanitizing of input for false returns
    $rv = 0 unless $rv;

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL2, $rv );

    return $rv;
}

sub _cmpHash (\%\%) {

    # Purpose:  Compares hashes, returns true if identical
    # Returns:  Boolean
    # Usage:    $rv = _cmpHash(%hash1, %hash2);

    my $ref1 = shift;
    my $ref2 = shift;
    my $rv   = 1;
    my ( @k1, @k2, @v1, @v2 );

    pdebug( 'entering w/%s %s', PDLEVEL2, $ref1, $ref2 );
    pIn();

    @k1 = sort keys %$ref1;
    @k2 = sort keys %$ref2;

    # Compare first by key list
    $rv = _cmpArray( @k1, @k2 );

    if ($rv) {

        # Compare by value list
        foreach (@k1) {
            push @v1, $$ref1{$_};
            push @v2, $$ref2{$_};
        }
        $rv = _cmpArray( @v1, @v2 );
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL2, $rv );

    return $rv;
}

sub deepCmp (\[$@%]\[$@%]) {

    # Purpose:  Compares data structures, returns true if identical
    # Returns:  Boolean
    # Usage:    $rv = deepCmp(%hash1, %hash2);
    # Usage:    $rv = deepCmp(@array1, @arrays2);

    my $ref1 = shift;
    my $ref2 = shift;
    my $rv   = 1;

    pdebug( 'entering w/%s %s', PDLEVEL1, $ref1, $ref2 );
    pIn();

    unless ( ref $ref1 eq ref $ref1 ) {
        $rv = 0;
        Paranoid::ERROR =
            pdebug( 'data structures are not the same type', PDLEVEL1 );
    }

    if ( $rv and ref $ref1 eq 'SCALAR' ) {
        $rv = $ref1 eq $ref2;
    } elsif ( $rv and ref $ref1 eq 'ARRAY' ) {
        $rv = _cmpArray( @$ref1, @$ref2 );
    } elsif ( $rv and ref $ref1 eq 'HASH' ) {
        $rv = _cmpHash( %$ref1, %$ref2 );
    } else {
        $rv = 0;
        Paranoid::ERROR =
            pdebug( 'called with non-simple data types', PDLEVEL1 );
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

    return $rv;
}

1;

__END__

=head1 NAME

Paranoid::Data - Misc. Data Manipulation Functions

=head1 VERSION

$Id: lib/Paranoid/Data.pm, 2.09 2021/12/28 15:46:49 acorliss Exp $

=head1 SYNOPSIS

    $rv = deepCopy($source, $target);
    $rv = deepCopy(@source, @target);
    $rv = deepCopy(%source, %target);

    $rv = deepCmp($source, $target);
    $rv = deepCmp(@source, @target);
    $rv = deepCmp(%source, %target);

=head1 DESCRIPTION

This module provides data manipulation functions, which at this time only
consists of B<deepCopy> and B<deepCmp>.

=head1 IMPORT LISTS

This module exports the following symbols by default:

    deepCopy deepCmp

The following specialized import lists also exist:

    List        Members
    --------------------------------------------------------
    all         @defaults

=head1 SUBROUTINES/METHODS

=head2 deepCopy

    $rv = deepCopy($source, $target);
    $rv = deepCopy(@source, @target);
    $rv = deepCopy(%source, %target);

This function performs a deep and safe copy of arbitrary data structures,
checking for circular references along the way.  Hashes and lists are safely
duplicated while all other data types are just copied.  This means that any
embedded object references, etc., are identical in both the source and the
target, which is probably not what you want.

In short, this should only be used on pure hash/list/scalar value data
structures.  Both the source and the target data types must be of an identical
type.

This function returns the number of elements copied unless it runs into a
problem (such as a circular reference), in which case it returns a zero.

=head2 deepCmp

    $rv = deepCmp($source, $target);
    $rv = deepCmp(@source, @target);
    $rv = deepCmp(%source, %target);

This function performs a deep comparison of arbitrarily complex data
structures (i.e., hashes of lists of lists of scalars, etc.).  It returns true
if the values of the structures are identical, false otherwise.  Like the
B<deepCopy> function there are no provisions for evaluating objects beyond
what their values are when coerced as scalar types.

End sum, the same caveats that applied to B<deepCopy> apply here.

=head1 DEPENDENCIES

=over

=item o

L<Carp>

=item o

L<Paranoid>

=item o

L<Paranoid::Debug>

=back

=head1 BUGS AND LIMITATIONS 

=head1 AUTHOR 

Arthur Corliss (corliss@digitalmages.com)

=head1 LICENSE AND COPYRIGHT

This software is free software.  Similar to Perl, you can redistribute it
and/or modify it under the terms of either:

  a)     the GNU General Public License
         <https://www.gnu.org/licenses/gpl-1.0.html> as published by the 
         Free Software Foundation <http://www.fsf.org/>; either version 1
         <https://www.gnu.org/licenses/gpl-1.0.html>, or any later version
         <https://www.gnu.org/licenses/license-list.html#GNUGPL>, or
  b)     the Artistic License 2.0
         <https://opensource.org/licenses/Artistic-2.0>,

subject to the following additional term:  No trademark rights to
"Paranoid" have been or are conveyed under any of the above licenses.
However, "Paranoid" may be used fairly to describe this unmodified
software, in good faith, but not as a trademark.

(c) 2005 - 2020, Arthur Corliss (corliss@digitalmages.com)
(tm) 2008 - 2020, Paranoid Inc. (www.paranoid.com)

