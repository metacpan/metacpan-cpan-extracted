package PICA::Schema::Builder;
use v5.14.1;

our $VERSION = '1.08';

use PICA::Schema qw(field_identifier);
use Scalar::Util qw(reftype);

sub new {
    my $class = shift;
    bless {fields => {}, counter => 0}, $class;
}

sub add {
    my ($self, $record) = @_;

    $record = $record->{record} if reftype $record eq 'HASH';
    my $fields = $self->{fields};

    my %field_identifiers;
    foreach (@$record) {
        my ($tag, $occ, @content) = @$_;

        my $id = field_identifier($_);

        # check whether field is repeated within thin record
        if ($field_identifiers{$id}) {
            $fields->{$id}{repeatable} = 1;
        }
        else {
            $field_identifiers{$id} = 1;
        }

        # field has not been inspected yet
        if (!$fields->{$id}) {
            $fields->{$id} = {counter => 0, tag => $tag, subfields => {},};
            $fields->{$id}{occurrence} = $occ if length $id gt 4;
            $fields->{$id}{required}   = 1 unless $self->{counter};
        }
        else {
            $fields->{$id}{counter}++;
        }

        my $subfields = $fields->{$id}{subfields};
        my %subfield_codes;
        while (@content) {
            my ($code, $value) = splice(@content, 0, 2);

            # check whether subfield is repeated within this field
            if ($subfield_codes{$code}) {
                $subfields->{$code}{repeatable} = 1;
            }
            else {
                $subfield_codes{$code} = 1;
            }

            if (!$subfields->{$code}) {
                $subfields->{$code} = {code => $code};
                $subfields->{$code}{required} = 1
                    unless $fields->{$id}{counter};
            }
        }

        # subfields not given in this field are not required
        for (grep {!$subfield_codes{$_}} keys %$subfields) {
            delete $subfields->{$_}{required};
        }
    }

    # fields not given in this record are not required
    for (grep {!$field_identifiers{$_}} keys %$fields) {
        delete $fields->{$_}{required};
    }

    $self->{counter}++;
}

sub schema {
    my ($self) = @_;
    PICA::Schema->new(
        {
            fields => {
                map {
                    my %field = %{$self->{fields}{$_}};
                    delete $field{counter};
                    $_ => \%field;
                } keys %{$self->{fields}}
            }
        }
    );
}

1;
__END__

=head1 NAME

PICA::Schema::Builder - Create Avram Schema from examples

=head1 SYNOPSIS

  my $builder = PICA::Schema::Builder->new;

  while (my $record = get_some_pica_record()) {
      $builder->add($record);
  }

  $schema = $builder->schema;

=head1 DESCRIPTION

An L<Avram Schema|https://format.gbv.de/schema/avram/specification> can be
created automatically from L<PICA::Data> records. The result contains a list of
field that have been used in any of the inspected records. The schema can tell
which fields occurr in all records (C<required>), whether a field has been
repeated in a record (C<repeatable>), and the same information for subfields
(C<subfields>). Subfield order is not taken into account.

=head1 METHODS

=head2 add( $record )

Analyse an additional PICA record.

=head2 schema

Return a L<PICA::Schema> that all analyzed records conform to.

=head1 SEE ALSO

L<Catmandu::Breaker> can analyze PICA data and create additional statistics.

=cut
