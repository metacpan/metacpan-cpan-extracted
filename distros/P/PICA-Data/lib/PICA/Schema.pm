package PICA::Schema;
use strict;
use warnings;

our $VERSION = '0.35';

use Scalar::Util qw(reftype);

sub new {
    my ($class, $schema) = @_;
    bless $schema, $class;
}

sub check {
    my ($self, $record, %options) = @_;
    
    $record = $record->{record} if reftype $record eq 'HASH';
    
    $options{counter} = {};
    return map { $self->check_field($_, %options) } @$record;
}

sub _error {
    my $field = shift;
    return {
        tag => $field->[0],
        ($field->[1] ? (occurrence => $field->[1]) : ()),
        @_
    }
}

sub check_field {
    my ($self, $field, %options) = @_;

    my $spec = $self->{fields}{$field->[0]};

    if (!$spec) {
        if (!$options{ignore_unknown_fields}) {
            return _error($field, message => 'unknown field')
        } else {
            return ()
        }
    } 

    if ($options{counter} && $spec->{unique}) {
        my $tag_occ = join '/', grep { defined } @$field[0,1];
        if ($options{counter}{$tag_occ}++) {        
            return _error($field, unique => 1, message => 'field is not repeatable')
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
                if ($sfspec->{unique} && $sfcounter{$code}++) {
                    $errors{$code} = { 
                        message => 'subfield is not repeatable',
                        unique => 1 
                    };
                }
            } elsif (!$options{ignore_unknown_subfields}) {
                $errors{$code} = { message => 'unknown subfield' };
            }
        }
    }

    return %errors ? _error($field, subfields => \%errors) : ();
}

1;
__END__

=head1 NAME

PICA::Schema - Specification of a PICA based format

=head1 DESCRIPTION

A PICA Schema defines a set of PICA+ fields and subfields to validate
L<PICA::Data> records. A schema is given as hash reference such as:

    {
      fields => {
        '021A' => { },      # field without additional information
        '003@' => {         # field with additional constraints
          unique => 1,
          label => 'Pica-Produktionsnummer',
          subfields => {
            0 => { unique => 1 }
          }
        }
      }
    }

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
set to tag and (optional) ocurrence of the violated field. If key C<unique> is
set, the field was repeated although not repeatable. Otherwise, if key
C<subfields> is set, the field was defined but contained invalid subfields.

Additional error field C<message> contains a human-readable error message which
can also be derived from the rest of the error object.

=head2 check_field( $field [, %options ] )

Check whether a PICA field confirms to the schema. Use same options as method C<check>.

=head1 LIMITATIONS

The current version can only validate records with tags on level 0.

=head1 SEE ALSO

L<PICA::Path> (support may be added in a future version)

L<MARC::Lint>

=cut
