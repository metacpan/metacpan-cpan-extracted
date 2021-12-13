package PICA::Schema::Builder;
use v5.14.1;

our $VERSION = '2.01';

use Scalar::Util qw(reftype);
use Storable qw(dclone);

use parent 'PICA::Schema';

sub new {
    my $class = shift;
    bless {fields => {}, records => 0, @_}, $class;
}

sub add {
    my ($self, $record) = @_;

    $record = $record->{record} if reftype $record eq 'HASH';
    my $fields = $self->{fields};

    my %field_identifiers;
    foreach (@$record) {
        my ($tag, $occ, @content) = @$_;

        my $id = $self->field_identifier($_);

        # check whether field is repeated within this record
        if ($field_identifiers{$id}) {
            $fields->{$id}{repeatable} = \1;
        }
        else {
            $field_identifiers{$id} = 1;
        }

        # field has not been seen in any record
        if (!$fields->{$id}) {
            next if $self->{ignore_unknown};
            $fields->{$id}
                = {total => 0, records => 0, tag => $tag, subfields => {},};
            $fields->{$id}{occurrence} = $occ if $occ > 0 && length $id gt 4;
            $fields->{$id}{required} = \1 unless $self->{records};
        }

        my $subfields = $fields->{$id}{subfields};
        my %subfield_codes;
        pop @content if @content % 2;    # remove annotation
        while (@content) {
            my ($code, $value) = splice(@content, 0, 2);

            # check whether subfield is repeated within this field
            if ($subfield_codes{$code}) {
                $subfields->{$code}{repeatable} = \1;
            }
            else {
                $subfield_codes{$code} = 1;
            }

            if (!$subfields->{$code}) {
                $subfields->{$code} = {code => $code};
                $subfields->{$code}{required} = \1
                    unless $fields->{$id}{total};
            }
        }

        # subfields not given in this field are not required
        for (grep {!$subfield_codes{$_}} keys %$subfields) {
            delete $subfields->{$_}{required};
        }

        # count total number of this field
        $fields->{$id}{total}++;
    }

    for (grep {exists $fields->{$_}} keys %field_identifiers) {
        $fields->{$_}{records}++;
    }

    # fields not given in this record are not required
    for (grep {!$field_identifiers{$_}} keys %$fields) {
        delete $fields->{$_}{required};
    }

    $self->{records}++;
}

sub schema {
    my $schema = dclone($_[0]->TO_JSON);
    my $fields = $schema->{fields};

    delete $fields->{$_} for grep {!$fields->{$_}{total}} keys %$fields;

    return PICA::Schema->new($schema);
}

1;
__END__

=head1 NAME

PICA::Schema::Builder - Create Avram Schema from examples

=head1 SYNOPSIS

  my $builder = PICA::Schema::Builder->new( title => 'My Schema' );

  while (my $record = get_some_pica_record()) {
      $builder->add($record);
  }

  $schema = $builder->schema;

=head1 DESCRIPTION

An L<Avram Schema|https://format.gbv.de/schema/avram/specification> can be
created automatically from L<PICA::Data> records. The result contains a list of
field that have been used in any of the inspected records. The schema can tell:

=over

=item

the number of inspected C<records>

=item

which C<fields> and their C<subfields> have been found in records

=item

the C<total> number each field has been found and the number of C<records>
with each field.

=item

which of the fields occurr in all records (C<required>)

=item

whether a field has been repeated in a record (C<repeatable>)

=back

And information about requiredness and repeatability for subfields.
Subfield order is not taken into account.

This class is a subclass of L<PICA::Schema>.

=head1 CONSTRUCTOR

The builder can be initialized with information of an existing builder or
schema, in particular C<fields>, C<total>, and C<records>. Option
C<ignore_unknown> will ignore fields not already specified in C<fields>.

=head1 METHODS

=head2 add( $record )

Analyse an additional PICA record.

=head2 schema

Return a L<PICA::Schema> that all analyzed records conform to. This methods
creates a deep copy and removes all fields with C<total> zero.

=head1 SEE ALSO

L<Catmandu::Breaker> can analyze PICA data and create additional statistics.

=cut
