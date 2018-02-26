package PICA::Schema;
use strict;
use warnings;

our $VERSION = '0.36';

use Exporter 'import';
our @EXPORT_OK = qw(field_identifier);

use Scalar::Util qw(reftype);

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
            my %error = (
                tag => substr($id, 0, 4),
                required => 1,
                message => "missing field $id",
            );
            $error{occurrence} = substr($id, 5) if length $id gt 4;
            push @errors, \%error;
        }
    }

    return @errors;
}

sub field_identifier {
    my ($tag, $occ) = @{$_[0]};
    (($occ // '') ne '' and substr($tag,0,1) eq '0') ? "$tag/$occ" : $tag;
}

sub check_field {
    my ($self, $field, %options) = @_;

    my $id = field_identifier($field);
    my $spec = $self->{fields}{$id};

    if (!$spec) {
        if (!$options{ignore_unknown_fields}) {
            return _error($field,
                message => 'unknown field '.field_identifier($field)
            )
        } else {
            return ()
        }
    }

    if ($options{counter} && !$spec->{repeatable}) {
        my $tag_occ = join '/', grep { defined } @$field[0,1];
        if ($options{counter}{$tag_occ}++) {
            return _error($field,
                repeated => 1,
                message => 'field '.field_identifier($field).' is not repeatable',
            )
        }
    }


    my %errors;
    if ($spec->{subfields}) {
        my %sfcounter;
        my (undef, undef, @subfields) = @$field;

        while (@subfields) {
            my ($code, undef) = splice @subfields, 0, 2;
            my $sfspec = $spec->{subfields}{$code};

            if ($sfspec) {
                if (!$sfspec->{repeatable} && $sfcounter{$code}) {
                    $errors{$code} = {
                        code     => $code,
                        repeated => 1,
                        message  => "subfield $id\$$code is not repeatable",
                    };
                }
                $sfcounter{$code}++;
            } elsif (!$options{ignore_unknown_subfields}) {
                $errors{$code} = {
                    code    => $code,
                    message => "unknown subfield $id\$$code"
                };
            }
        }

        foreach my $code (keys %{$spec->{subfields}}) {
            if (!$sfcounter{$code} && $spec->{subfields}{$code}{required}) {
                $errors{$code} = {
                    code     => $code,
                    required => 1,
                    message  => "missing subfield $id\$$code"
                }
            }
        }
    }

    return %errors ? _error($field, subfields => \%errors) : ();
}

sub _error {
    my $field = shift;
    return {
        tag => $field->[0],
        (($field->[1] // '' ne '') ? (occurrence => $field->[1]) : ()),
        @_
    }
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
records.

=head1 METHODS

=head2 check( $record [, %options ] )

Check whether a given L<PICA::Data> record confirms to the schema and return a
list of detected violations. Possible options include:

=over

=item ignore_unknown_fields

Don't report fields not included in the schema.

=item ignore_unknown_subfields

Don't report subfields not included in the schema.

=back

Errors are given as list of hash reference with keys C<tag> and C<occurrence>
set to tag and (optional) ocurrence of the violated field. If key C<repeated>
is set, the field was repeated although not repeatable. Otherwise, if key
C<subfields> is set, the field was defined but contained invalid subfields.

Additional error field C<message> contains a human-readable error message which
can also be derived from the rest of the error object.

=head2 check_field( $field [, %options ] )

Check whether a PICA field confirms to the schema. Use same options as method
C<check>.

=head1 FUNCTION

=head2 field_identifier( $field )

Return the field identifier of a given PICA field. The identifier consists of
field tag and optional occurrence if the tag starts with C<0>.

=head1 LIMITATIONS

The current version does not properly validate required field on level 1 and 2.

Field types and subfield order have neither been implemented yet.

=head1 SEE ALSO

L<PICA::Path>

L<MARC::Schema>

L<MARC::Lint>

=cut
