package PICA::Schema;
use strict;
use warnings;

our $VERSION = '1.02';

use Exporter 'import';
our @EXPORT_OK = qw(field_identifier check_value);

use Scalar::Util qw(reftype);
use PICA::Schema::Error;

sub new {
    my ($class, $schema) = @_;
    bless $schema, $class;
}

sub check {
    my ($self, $record, %options) = @_;

    $record = $record->{record} if reftype $record eq 'HASH';

    $options{counter} = {};
    my @errors;

    my %field_identifiers;
    for my $field (@$record) {
        $field_identifiers{ field_identifier($field) } = 1;
        push @errors, $self->check_field($field, %options);
    }

    for my $id (keys %{$self->{fields}}) {
        my $field = $self->{fields}{$id};
        if ($field->{required} && !$field_identifiers{$id}) {
            push @errors, PICA::Schema::Error->new(
                [ substr($id,0,4), length $id gt 4 ? substr($id, 5) : undef ],
                required => 1
            );
        }
    }

    return @errors;
}

sub check_field {
    my ($self, $field, %opts) = @_;

    my $id = field_identifier($field);
    my $spec = $self->{fields}{$id};

    if ($opts{allow_deprecated}) {
        $opts{allow_deprecated_fields} = 1;
        $opts{allow_deprecated_subfields} = 1;
    }

    if ($opts{ignore_unknown}) {
        $opts{ignore_unknown_fields} = 1;
        $opts{ignore_unknown_subfields} = 1;
    }

    if (!$spec) { # field is not defined
        $spec = $self->{'deprecated-fields'}{$id};

        if ($spec) { # field is deprectaed
            unless ($opts{allow_deprecated_fields}) {
                return PICA::Schema::Error->new($field, deprecated => 1)
            }
        } elsif ($opts{ignore_unknown_fields}) {
            return ()
        } else {
            return PICA::Schema::Error->new($field)
        }
    }

    if ($opts{counter} && !$spec->{repeatable}) {
        my $tag_occ = join '/', grep { defined } @$field[0,1];
        if ($opts{counter}{$tag_occ}++) {
            return PICA::Schema::Error->new($field, repeated => 1)
        }
    }

    if ($opts{ignore_subfields}) {
        return ();
    }

    my %errors;
    if ($spec->{subfields}) {
        my $order;
        my %sfcounter;
        my (undef, undef, @subfields) = @$field;

        while (@subfields) {
            my ($code, $value) = splice @subfields, 0, 2;
            my $sfspec = $spec->{subfields}{$code};

            if (!$sfspec) { # subfield is not defined
                $sfspec = $spec->{'deprecated-subfields'}{$code};
                if ($sfspec) { # subfield is deprecated
                    unless ($opts{allow_deprecated_subfields}) {
                        $errors{$code} = { deprecated => 1 }
                    }
                } elsif (!$opts{ignore_unknown_subfields}) {
                    $errors{$code} = { }
                }
            }

            if ($sfspec) {
                if (!$sfspec->{repeatable} && $sfcounter{$code}) {
                    $errors{$code} = { repeated => 1 }
                } elsif (!$opts{ignore_subfield_order} && defined $sfspec->{order}) {
                    if (defined $order && $order > $sfspec->{order}) {
                        $errors{$code} = { order => $sfspec->{order} }
                    } else {
                        $order = 1*$sfspec->{order};
                    }
                }
                $sfcounter{$code}++;

                $errors{$code} = $_ for check_value($value, $sfspec, %opts);
            }

        }

        foreach my $code (keys %{$spec->{subfields}}) {
            if (!$sfcounter{$code} && $spec->{subfields}{$code}{required}) {
                $errors{$code} = { required => 1 }
            }
        }
    }

    return %errors ? PICA::Schema::Error->new($field, subfields => \%errors) : ();
}

sub check_value {
    my ($value, $schedule, %opts) = @_;

    # TODO: check compatible with ECMA 262 (2015) regular expression grammar
    if ($schedule->{pattern} and $value !~ /$schedule->{pattern}/) {
        return {
            value => $value,
            pattern => $schedule->{pattern},
        }
    }

    # check positions and codes
    my $positions = $schedule->{positions} // {};
    foreach my $pos (keys %$positions) {
        my @p = split '-', $pos;

        if (length $value < int $p[-1]) {
            return {
                value => $value,
                position => $pos,
            }
        }

        my $def = $positions->{$pos};
        if ($def->{codes}) {
            my $codes = $def->{codes};
            my $deprecated = $def->{'deprecated-codes'} // {};
            my $c = substr $value, $p[0]-1, (@p > 1 ? $p[1]-$p[0] : 0) + 1;
            if (!defined $codes->{$c}) {
                if (!$deprecated->{$c}) {
                    return {
                        value => $value,
                        position => $pos
                    }
                } elsif (!$opts{allow_deprecated} && !$opts{allow_deprecated_codes}) {
                    # TODO: there is no way to see that an invalid value is deprecated
                    return {
                        value => $value,
                        position => $pos
                    }
                }
            }
        }
    }

    return;
}

sub field_identifier {
    my ($tag, $occ) = @{$_[0]};
    (($occ // '') ne '' and substr($tag,0,1) eq '0') ? "$tag/$occ" : $tag;
}

sub TO_JSON {
    my ($self) = @_;
    return { map { $_ => $self->{$_} } keys %$self };
}

1;
__END__

=head1 NAME

PICA::Schema - Validate PICA based formats with Avram Schemas

=head1 SYNOPSIS

  $schema = PICA::Schema->new({ ... });

  @errors = $schema->check($record);

=head1 DESCRIPTION

A PICA Schema defines a set of PICA+ fields and subfields to validate
L<PICA::Data> records. Schemas are given as hash reference in L<Avram Schema
language|https://format.gbv.de/schema/avram/specification>, for instance:

    {
      fields => {
        '021A' => { },      # field without additional information
        '003@' => {         # field with additional constraints
          label => 'Pica-Produktionsnummer',
          repeatable => 0,
          required => 1,
          subfields => {
            '0' => { repeatable => 0, required => 1 }
          }
        }
      }
    }

See L<PICA::Schema::Builder> to automatically construct schemas from PICA
sample records.

Schema information can be included in PICA XML with L<PICA::Writer::XML>.

=head1 METHODS

=head2 check( $record [, %options ] )

Check whether a given L<PICA::Data> record confirms to the schema and return a
list of L<PICA::Schema::Error>. Possible options include:

=over

=item ignore_unknown_fields

Don't report fields not included in the schema.

=item ignore_unknown_subfields

Don't report subfields not included in the schema.

=item ignore_unknown

Don't report fields and subfields not included in the schema.

=item allow_deprecated_fields

Don't report deprecated fields.

=item allow_deprecated_subfields

Don't report deprecated subfields.

=item allow_deprecated_codes

Don't report deprecated codes.

=item allow_deprecated

Don't report deprecated fields, subfields, and codes.

=item ignore_subfield_order

Don't report errors resulting on wrong subfield order.

=item ignore_subfields

Don't check subfields at all.

=back

=head2 check_field( $field [, %options ] )

Check whether a PICA field confirms to the schema. Use same options as method
C<check>. Returns a L<PICA::Schema::Error> on schema violation.

=head1 FUNCTIONS

=head2 field_identifier( $field )

Return the field identifier of a given PICA field. The identifier consists of
field tag and optional occurrence if the tag starts with C<0>.

=head2 check_value( $value, $schedule [, %options ] )

Check a subfield value against a subfield schedule. On malformed values returns
a L<subfield error|PICA::Schema::Error/SUBFIELD ERRORS> without C<message> key.

=head1 LIMITATIONS

The current version does not properly validate required field on level 1 and 2.

Field types have neither been implemented yet.

=head1 SEE ALSO

L<PICA::Path>

L<MARC::Schema>

L<MARC::Lint>

=cut
