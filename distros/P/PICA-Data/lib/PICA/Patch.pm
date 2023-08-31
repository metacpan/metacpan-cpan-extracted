package PICA::Patch;
use v5.14.1;

our $VERSION = '2.12';

use PICA::Schema qw(field_identifier);
use PICA::Data::Field;

use Exporter 'import';
our @EXPORT_OK   = qw(pica_diff pica_patch);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

# Compare full fields, ignoring annotation of the latter
# note this does not strip occurrence from level 2 records!
sub cmp_fields {
    my @a = @{$_[0]};
    my @b = @{$_[1]};
    pop @b if @b % 2;
    return join("\t", @a) cmp join("\t", @b);
}

sub sorted_fields {
    my $fields = PICA::Data::pica_fields(PICA::Data::pica_sort(shift));

    if (@$fields) {
        my $level = substr $fields->[0][0], 0, 1;
        for (@$fields) {
            die "diff/patch only allowed on atomic records\n"
                if $level ne substr $_->[0], 0, 1;
        }
    }

    $fields = [sort {cmp_fields($a, $b)} @$fields];

    return $fields;
}

*annotation = *PICA::Data::pica_annotation;

sub pica_diff {
    my $a       = sorted_fields(shift);
    my $b       = sorted_fields(shift);
    my %options = @_;

    my (@diff, $i, $j);

    my $changed = sub {
        my $field = PICA::Data::Field->new(@{$_[0]});
        $field->annotation($_[1]);
        push @diff, $field;
    };

    while ($i < @$a && $j < @$b) {
        my $cmp = cmp_fields($a->[$i], $b->[$j]);

        if ($cmp < 0) {
            $changed->($a->[$i++], '-');
        }
        elsif ($cmp > 0) {
            $changed->($b->[$j++], '+');
        }
        else {
            push @diff, $a->[$i] if $options{keep};
            $i++;
            $j++;
        }
    }
    while ($i < @$a) {
        $changed->($a->[$i++], '-');
    }
    while ($j < @$b) {
        $changed->($b->[$j++], '+');
    }

    # remove identical fields (could also be done in sort_fields)
    for (my $i = 0; $i < $#diff;) {
        if ($diff[$i]->equal($diff[$i + 1])) {
            splice @diff, $i + 1, 1;
        }
        else {
            $i++;
        }
    }

    bless {record => \@diff}, 'PICA::Data';
}

sub no_match {
    my $field = shift;
    annotation($field, undef);
    die "records don't match, expected: " . PICA::Data::pica_string([$field]);
}

sub pica_patch {
    my $fields = sorted_fields(shift);
    my $diff   = sorted_fields(shift);

    for (map {annotation($_)} @$diff) {
        die "invalid PICA Patch annotation: $_\n" if $_ !~ /^[ +-]$/;
    }

    my ($i, $j) = (0, 0);
PATCH: while ($i < @$fields && $j < @$diff) {
        my $cur;
        my $next = field_identifier($diff->[$j]);
        my $ann  = annotation($diff->[$j]);

        # while current field is behind or same
        while (($cur = field_identifier($fields->[$i])) le $next) {
            if ($cur eq $next && !cmp_fields($fields->[$i], $diff->[$j])) {
                if ($ann eq '-') {
                    splice @$fields, $i, 1;
                    last PATCH if $j++ == @$diff or $i == @$fields;

                }
                else {
                    $i++;
                    $j++;
                    last PATCH if $i >= @$fields or $j >= @$diff;
                }

                $next = field_identifier($diff->[$j]);
                $ann  = annotation($diff->[$j]);

            }
            else {

                # keep current field
                last PATCH if ++$i == @$fields;
            }
        }

        # current field is ahead
        if ($ann eq '+') {
            my $add = $diff->[$j++];
            annotation($add, undef);
            splice @$fields, $i++, 0, $add;
        }
        else {
            no_match($diff->[$j]);
        }
    }

    while ($j < @$diff) {
        if (annotation($diff->[$j]) eq '+') {
            $fields->[$i] = $diff->[$j++];
            annotation($fields->[$i++], undef);
        }
        else {
            no_match($diff->[$j]);
        }
    }

    bless {record => $fields}, 'PICA::Data';
}
1;
__END__

=head1 NAME

PICA::Patch - Implementation of PICA diff and patch

=head1 DESCRIPTION

This file contains the implementation of diff and patch algorithm for PICA+
records.  See functions C<pica_diff> and C<pica_patch> (or object methods
C<diff> and C<patch>) of L<PICA::Data> for usage.

=head1 FORMAT

The difference between two records or the change to be applied to a record is
referred to as B<diff>, B<delta> or B<patch>. In any case the format must
encode a set of modifications. PICA Patch format encodes modifications to PICA
records in form of annotated PICA records. PICA fields can be annotated with:

=over

=item B<+>

To denote a field that should be added.

=item B<->

To denote a field that should be removed.

=item B<blank>

To denote a field that should be kept as it is.

=back

Modification of a field can be encoded by removal of the old version followed by
addition of the new version.

=head1 EXAMPLE

Given a PICA record with two fields: 

  | 003@ $012345
  | 021A $aA book

A diff to modify the second field could be this:

  | - 021A $aA book
  | + 021A $aAn interesting book

The diff could be extended with the first field to make sure it can only
applied if the first field exists in the record:

  |   003@ $012345
  | - 021A $aA book
  | + 021A $aAn interesting book

=head1 APPLICATION

Records are always sorted before application of diff or patch. Records must be
limited to one level and contain no sub-records.

Fields are not added with a patch if the records already contains a fully
identical field.

=head1 FUNCTIONS

=head2 pica_diff( $before, $after )

Return the difference between two records as annotated record.

=head2 pica_patch( $record, $diff )

Apply a difference given as annotated PICA and return the result as new record.
This function may die with an error method if the diff cannot be applied.

=cut
