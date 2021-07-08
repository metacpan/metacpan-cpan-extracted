package PICA::Schema;
use v5.14.1;

our $VERSION = '1.28';

use Scalar::Util qw(reftype);
use Storable qw(dclone);
use PICA::Data;
use PICA::Error;

use Exporter 'import';
our @EXPORT_OK = qw(field_identifier check_value clean_pica);

sub new {
    my ($class, $schema) = @_;
    bless $schema, $class;
}

sub check {
    my ($self, $record, %options) = @_;

    my @errors;
    $record
        = clean_pica($record, error => sub {push @errors, shift}, %options)
        or return @errors;

    my @errors = map {$self->check_record($_->{record}, %options)}
        PICA::Data::pica_split($record);

    my %seen;
    return grep {not $seen{"$_"}++} @errors;
}

sub check_record {
    my ($self, $record, %options) = @_;

    my @errors;
    $options{counter} = {};

    my %field_identifiers;
    for my $field (@$record) {
        my $id = $self->field_identifier($field);
        $field_identifiers{$id} = 1;
        my $error = $self->check_field($field, %options, _field_id => $id);
        if ($error) {
            push @errors, $error unless grep {$_ eq $error} @errors;
        }
        if ($options{annotate}) {
            my $annotation = ' ';
            if ($error) {
                $annotation = $error->{message} =~ /^unknown/ ? '?' : '!';
            }
            PICA::Data::pica_annotation($field, $annotation);
        }
    }

    # check whether required fields exist for this record level
    my $level = substr $record->[0][0], 0, 1;
    for my $id (keys %{$self->{fields}}) {
        next if $level ne substr $id, 0, 1;
        my $field = $self->{fields}{$id};
        if ($field->{required} && !$field_identifiers{$id}) {
            push @errors,
                PICA::Error->new(
                [substr($id, 0, 4), length $id > 4 ? substr($id, 5) : undef],
                required => 1
                );
        }
    }

    return @errors;
}

sub check_field {
    my ($self, $field, %opts) = @_;

    my $id = $opts{_field_id} || $self->field_identifier($field);
    my $spec = $self->{fields}{$id};

    if ($opts{allow_deprecated}) {
        $opts{allow_deprecated_fields}    = 1;
        $opts{allow_deprecated_subfields} = 1;
    }

    if ($opts{ignore_unknown}) {
        $opts{ignore_unknown_fields}    = 1;
        $opts{ignore_unknown_subfields} = 1;
    }

    if (!$spec) {    # field is not defined
        $spec = $self->{'deprecated-fields'}{$id};
        my $simple = [split('/', $id)];

        if ($spec) {    # field is deprectaed
            unless ($opts{allow_deprecated_fields}) {
                return PICA::Error->new($simple, deprecated => 1);
            }
        }
        elsif ($opts{ignore_unknown_fields}) {
            return ();
        }
        else {
            return PICA::Error->new($simple);
        }
    }

    if ($opts{counter} && !$spec->{repeatable}) {
        if ($opts{counter}{$id}++) {
            return PICA::Error->new($field, repeated => 1);
        }
    }

    my $failed = check_annotation($field, %opts);
    return PICA::Error->new($failed) if $failed;

    if ($opts{ignore_subfields}) {
        return ();
    }

    my %errors;
    if ($spec->{subfields}) {
        my $order;
        my %sfcounter;
        my (undef, undef, @subfields) = @$field;
        pop @subfields if @subfields % 2;

        while (@subfields) {
            my ($code, $value) = splice @subfields, 0, 2;
            my $sfspec = $spec->{subfields}{$code};

            if (!$sfspec) {    # subfield is not defined
                $sfspec = $spec->{'deprecated-subfields'}{$code};
                if ($sfspec) {    # subfield is deprecated
                    unless ($opts{allow_deprecated_subfields}) {
                        $errors{$code} = {deprecated => 1};
                    }
                }
                elsif (!$opts{ignore_unknown_subfields}) {
                    $errors{$code} = {};
                }
            }

            if ($sfspec) {
                if (!$sfspec->{repeatable} && $sfcounter{$code}) {
                    $errors{$code} = {repeated => 1};
                }
                elsif (!$opts{ignore_subfield_order}
                    && defined $sfspec->{order})
                {
                    if (defined $order && $order > $sfspec->{order}) {
                        $errors{$code} = {order => $sfspec->{order}};
                    }
                    else {
                        $order = 1 * $sfspec->{order};
                    }
                }
                $sfcounter{$code}++;

                $errors{$code} = $_ for check_value($value, $sfspec, %opts);
            }

        }

        foreach my $code (keys %{$spec->{subfields}}) {
            if (!$sfcounter{$code} && $spec->{subfields}{$code}{required}) {
                $errors{$code} = {required => 1};
            }
        }
    }

    return %errors ? PICA::Error->new($field, subfields => \%errors) : ();
}

sub check_annotation {
    my ($field, %options) = @_;

    my (undef, undef, @subfields) = @$field;

    if (@subfields % 2) {
        return "Field annotation not allowed"
            if defined $options{check_annotation}
            && !$options{check_annotation};

        return "Annotation must not be non-alphanumeric character"
            if pop(@subfields) !~ /^[^A-Za-z0-9]\z/;
    }
    elsif ($options{check_annotation}) {
        return "Missing field annotation";
    }
}

sub check_value {
    my ($value, $schedule, %opts) = @_;

    # TODO: check compatible with ECMA 262 (2015) regular expression grammar
    if ($schedule->{pattern} and $value !~ /$schedule->{pattern}/) {
        return {value => $value, pattern => $schedule->{pattern},};
    }

    # check positions and codes
    my $positions = $schedule->{positions} // {};
    foreach my $pos (keys %$positions) {
        my @p = split '-', $pos;

        if (length $value < int $p[-1]) {
            return {value => $value, position => $pos,};
        }

        my $def = $positions->{$pos};
        if ($def->{codes}) {
            my $codes      = $def->{codes};
            my $deprecated = $def->{'deprecated-codes'} // {};
            my $c          = substr $value, $p[0] - 1,
                (@p > 1 ? $p[1] - $p[0] : 0) + 1;
            if (!defined $codes->{$c}) {
                if (!$deprecated->{$c}) {
                    return {value => $value, position => $pos};
                }
                elsif (!$opts{allow_deprecated}
                    && !$opts{allow_deprecated_codes})
                {
            # TODO: there is no way to see that an invalid value is deprecated
                    return {value => $value, position => $pos};
                }
            }
        }
    }

    return;
}

sub field_identifier {
    my $fields = ref $_[0] eq 'PICA::Schema' ? shift->{fields} : undef;
    my ($tag, $occ) = @{$_[0]};

    $occ
        = (substr($tag, 0, 1) ne '2' && $occ > 0)
        ? sprintf("%02d", $occ)
        : '';

    if ($fields && !exists $fields->{"$tag/$occ"}) {

        # TODO: we could create an index to speed up this slow lookup
        for my $id (keys %$fields) {
            return $id
                if $id =~ /^$tag\/(..)-(..)$/ && $occ >= $1 && $occ <= $2;
        }

        # TODO: support x fields with field counter
    }

    return $occ ne '' ? "$tag/$occ" : $tag;
}

sub TO_JSON {
    my ($self) = @_;
    return {map {$_ => $self->{$_}} keys %$self};
}

sub abbreviated {
    my ($self) = @_;
    my $abbr = dclone($self->TO_JSON);
    delete $abbr->{total};
    for my $field (values %{$abbr->{fields} // {}}) {
        delete $field->{tag};
        delete $field->{occurrence};
        delete $field->{total};
        for my $sf (values %{$field->{subfields} // {}}) {
            delete $_->{code};
        }
    }
    return $abbr;
}

sub clean_pica {
    my ($record, %options) = @_;

    my $ok      = 1;
    my $handler = $options{error};
    my $error   = exists $options{error}
        ? sub {
        if ($handler) {
            $handler->(PICA::Error->new($_[1] || [], message => $_[0]));
        }
        $ok = 0;
        }
        : sub {say STDERR shift; $ok = 0};

    $record = $record->{record} if reftype $record eq 'HASH';

    if (reftype $record ne 'ARRAY') {
        $error->('PICA record must be array reference');
    }
    elsif (!@$record && !$options{ignore_empty_records}) {
        $error->('PICA record should not be empty');
    }

    return unless $ok;

    my @filtered;

    for my $field (@$record) {
        if (reftype $field ne 'ARRAY') {
            $error->('PICA field must be array reference');
            return
        }

        my ($tag, $occ, @sf) = @$field;

        if ($tag !~ /^[012.][0-9.][0-9.][A-Z@.]$/) {
            $error->("Malformed PICA tag: $tag", $field);
        }

        if ($occ) {
            if ($occ !~ /^[0-9]{1,3}$/) {
                $error->("Malformed occurrence: $occ", $field);
            }
            elsif (substr($tag, 0, 1) ne '2' && length $occ eq 3) {
                $error->(
                    "Three digit occurrences only allowed on PICA level 2",
                    $field
                );
            }
        }

        my $msg = check_annotation($field, %options);
        $error->($msg, $field) if $msg;

        next if $options{ignore_subfields};

        pop @sf if @sf % 2;
        while (@sf) {
            my ($code, $value) = splice @sf, 0, 2;

            $error->("Malformed PICA subfield: $code", $field)
                if $code !~ /^[_A-Za-z0-9]$/;
            $error->("PICA subfield \$$code must be non-empty string", $field)
                if $value !~ /^./ && !$options{allow_empty_subfields};
        }
    }

    return $record if $ok;
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

Schema information can also be used for documentation of records with
L<PICA::Writer::XML>.

=head1 METHODS

=head2 check( $record [, %options ] )

Check whether a given L<PICA::Data> record confirms to the schema and return a
list of L<PICA::Error>. Possible options include:

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

=item allow_empty_subfields

Don't report subfields with empty string values.

=item ignore_subfield_order

Don't report errors resulting on wrong subfield order.

=item ignore_subfields

Don't check subfields at all.

=item check_annotation

Require or forbid annotated fields if set to true or false.
Otherwise just check whether given annotation is a valid character.

=back

=head2 check_field( $field [, %options ] )

Check whether a PICA field confirms to the schema. Use same options as method
C<check>. Returns a L<PICA::Error> on schema violation.

=head2 abbreviated

Return an abbreviated data structure of the schema without inferable and
calculated fields such as C<tag>, C<occurrence>, C<code>, and C<total>.

=head1 FUNCTIONS

=head2 clean_pica( $record[, %options] )

Syntactically check a PICA record and return it as array of arrays on success.
Syntactic check is performed on schema validation before checking the record
against a schema and before writing a record.

Options include:

=over

=item error

Error handler, prints instances of L<PICA::Error> to STDERR by default. Use
C<undef> to ignore all errors.

=item ignore_empty_records

Don't emit an error if the record has no fields.

=item ignore_subfields

Don't check subfields.

=back

=head2 field_identifier( [$schema, ] $field )

Return the field identifier of a given PICA field. The identifier consists of
field tag and optional occurrence. If this function is used as method of a
schema, the field_identifier may contain an occurrence ranges instead of the
plain occurrence.

=head2 check_value( $value, $schedule [, %options ] )

Check a subfield value against a subfield schedule. On malformed values returns
a L<subfield error|PICA::Error/SUBFIELD ERRORS> without C<message> key.

=head1 LIMITATIONS

Fields types and deprecated (sub)fields in Avram Schemas are not fully supported yet.

=head1 SEE ALSO

L<PICA::Path>

L<MARC::Schema>

L<MARC::Lint>

=cut
