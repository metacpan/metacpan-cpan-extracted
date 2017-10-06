package QBit::Application::Model::DB::clickhouse::Field;
$QBit::Application::Model::DB::clickhouse::Field::VERSION = '0.005';
use qbit;

use base qw(QBit::Application::Model::DB::Field);

our %DATA_TYPES = (
    Date        => {field_type => 'EMPTY',  quote_type => 'STRING',},
    UInt8       => {field_type => 'EMPTY',  quote_type => 'NUMBER',},
    UInt32      => {field_type => 'EMPTY',  quote_type => 'NUMBER',},
    UInt64      => {field_type => 'EMPTY',  quote_type => 'NUMBER',},
    Enum8       => {field_type => 'ENUM',   quote_type => 'STRING',},
    Enum16      => {field_type => 'ENUM',   quote_type => 'STRING',},
    FixedString => {field_type => 'STRING', quote_type => 'STRING',},
);

our %FIELD2STR = (
    EMPTY => sub {
        return $_->quote_identifier($_->name) . ' ' . $_->type;
    },
    ENUM => sub {
        my $self = $_;

        my $value = 0;

        return
            $self->quote_identifier($self->name) . ' '
          . $self->type . '('
          . join(', ', map {$self->quote($_) . ' = ' . ++$value} @{$self->{'values'}}) . ')';
    },
    STRING => sub {
        return $_->quote_identifier($_->name) . ' ' . $_->type . '(' . $_->{'length'} . ')';
    },
);

sub create_sql {
    my ($self) = @_;

    return $FIELD2STR{$DATA_TYPES{$self->type}->{'field_type'}}($self);
}

sub init_check {
    my ($self) = @_;

    $self->SUPER::init_check();

    throw gettext('Unknown type: %s', $self->{'type'})
      unless exists($DATA_TYPES{$self->{'type'}});
}

sub quote {
    my ($self, $value) = @_;
    #TODO: rewrite(C++)

    return 'NULL' unless defined($value);

    if ($DATA_TYPES{$self->type}->{'quote_type'} eq 'STRING') {
        $value =~ s/\\/\\\\/g;
        $value =~ s/'/\\'/g;

        return "'$value'";
    }

    return $value;
}

TRUE;

__END__

=encoding utf8

=head1 Name

QBit::Application::Model::DB::clickhouse::Field - Class for ClickHouse fields.

=head1 Description

Implements work with ClickHouse fields.

=head1 Field types

=head2 Supported types

=over

=item

Date

=item

UInt8

=item

UInt32

=item

UInt64

=item

Enum8

=item

Enum16

=item

FixedString

=back

=head1 Package methods

=head2 create_sql

Generate and returns a sql for field.

B<No arguments.>

B<Return values:>

=over

=item

B<$sql> - string

=back

=head2 quote

B<Arguments:>

=over

=item

B<$value> - scalar

=back

B<Return values:>

=over

=item

B<$value> - scalar

=back

B<Example:>

  my $value = $field->quote("it's ok"); # "'it\'s ok'"
  $value = $field->quote(12); # 12
  $value = $field->quote(undef); # 'NULL'

=head2 init_check

Check options for field.

B<No arguments.>

=cut
