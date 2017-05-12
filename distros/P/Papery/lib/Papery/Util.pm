package Papery::Util;

use strict;
use warnings;

use Exporter;
our @ISA       = qw( Exporter );
our @EXPORT_OK = qw( merge_meta );

sub merge_meta {
    my ( $meta, $extra ) = @_;

    # __ keys are ignored
    my @__keys = grep {/^__/} keys %$extra;
    my @__values = delete @{$extra}{@__keys};

    # keys postfixed with + or - are updates
    my @keys = grep {/[-+]$/} keys %$extra;
    my @values = delete @{$extra}{@keys};

    # others are replacement
    # FIXME: deep keys with postfix
    @{$meta}{ keys %$extra } = values %$extra;

    # restore $extra
    @{$extra}{@__keys} = @__values;
    @{$extra}{@keys}   = @values;

    # process the updates
    while ( my $key = shift @keys ) {
        my $where = chop $key;
        my $value = shift @values;

        if ( ref $value eq 'ARRAY' ) {
            if ( $where eq '+' ) { push @{ $meta->{$key} }, @$value; }
            else                 { unshift @{ $meta->{$key} }, @$value; }
        }
        elsif ( ref $value eq 'HASH' ) {
            merge_meta( $meta->{$key}, $value );    # recursive update!
        }
        else {                                      # assume string
            if ( $where eq '+' ) { $meta->{$key} .= $value; }
            else {
                $meta->{$key}
                    = $value . ( defined $meta->{$key} ? $meta->{$key} : '' );
            }
        }
    }

    return $meta;
}

1;

__END__

=head1 NAME

Papery::Util - Various utilities functions for Papery

=head1 SYNOSPSIS

    use Papery::Util;

    # no exports by default

=head1 DESCRIPTION

C<Papery::Util> exists to provide a number of utility functions to other
classes in Papery.

=head1 FUNCTIONS

C<Papery::Util> provides the following functions:

=over 4

=item merge_meta( $meta, $extra )

Merge the keys and values from C<$extra> into C<$meta>, and return C<$meta>.

The merging scheme is relatively flexible: the keys in the C<$extra> hash
can have a suffix (either C<+> or C<->, which of course means that no
key in the Papery metadata can end with those characters).

A key without suffix is simply a replacement.

If the value is a string, and the suffix is C<+>, the string is appended
to the original. If the suffix is C<->, the string is prepended to the
original.

If the value is an array, and the suffix is C<+>, the array content is
pushed to the end of the original. If the suffix is C<->, the array content
is inserted at the beginning of the original.

=back

=head1 AUTHOR

Philippe Bruhat (BooK), C<< <book at cpan.org> >>

=head1 COPYRIGHT

Copyright 2010 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

