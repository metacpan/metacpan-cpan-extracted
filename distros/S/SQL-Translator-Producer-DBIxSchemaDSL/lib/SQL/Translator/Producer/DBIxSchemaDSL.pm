package SQL::Translator::Producer::DBIxSchemaDSL;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.04";

use DBI qw/:sql_types/;
use File::Spec;
use Text::MicroTemplate;
use Scalar::Util qw/looks_like_number/;
use SQL::Translator::Schema::Constants;
use Data::Dumper ();

my $_RENDER = Text::MicroTemplate->new(
    template     => do { local $/; <DATA> },
    package_name => __PACKAGE__,
    escape_func  => undef,
)->build;
my %_NAMEMAP = map { $_ => *{$DBI::{$_}}{CODE}->() } @{ $DBI::EXPORT_TAGS{sql_types} };

our %TYPEMAP = (
    SQL_GUID()                         => 'varchar',
    SQL_WLONGVARCHAR()                 => 'text',
    SQL_WVARCHAR()                     => 'varchar',
    SQL_WCHAR()                        => 'char',
    SQL_BIGINT()                       => 'bigint',
    SQL_BIT()                          => 'bit',
    SQL_TINYINT()                      => 'tinyint',
    SQL_LONGVARBINARY()                => 'blob',
    SQL_VARBINARY()                    => 'varbinary',
    SQL_BINARY()                       => 'binary',
    SQL_LONGVARCHAR()                  => 'text',
    SQL_UNKNOWN_TYPE()                 => 'blob',
    SQL_ALL_TYPES()                    => 'blob',
    SQL_CHAR()                         => 'char',
    SQL_NUMERIC()                      => 'numeric',
    SQL_DECIMAL()                      => 'decimal',
    SQL_INTEGER()                      => 'integer',
    SQL_SMALLINT()                     => 'smallint',
    SQL_FLOAT()                        => 'float',
    SQL_REAL()                         => 'real',
    SQL_DOUBLE()                       => 'double',
    SQL_DATETIME()                     => 'datetime',
    SQL_DATE()                         => 'date',
    SQL_INTERVAL()                     => 'integer',
    SQL_TIME()                         => 'time',
    SQL_TIMESTAMP()                    => 'timestamp',
    SQL_VARCHAR()                      => 'varchar',
    SQL_BOOLEAN()                      => 'tinyint',
    SQL_UDT()                          => 'string',
    SQL_UDT_LOCATOR()                  => 'string',
    SQL_ROW()                          => 'string',
    SQL_REF()                          => 'string',
    SQL_BLOB()                         => 'blob',
    SQL_BLOB_LOCATOR()                 => 'blob',
    SQL_CLOB()                         => 'blob',
    SQL_CLOB_LOCATOR()                 => 'blob',
    SQL_ARRAY()                        => 'blob',
    SQL_ARRAY_LOCATOR()                => 'blob',
    SQL_MULTISET()                     => 'blob',
    SQL_MULTISET_LOCATOR()             => 'blob',
    SQL_TYPE_DATE()                    => 'date',
    SQL_TYPE_TIME()                    => 'time',
    SQL_TYPE_TIMESTAMP()               => 'timestamp',
    SQL_TYPE_TIME_WITH_TIMEZONE()      => 'timestamp',
    SQL_TYPE_TIMESTAMP_WITH_TIMEZONE() => 'timestamp',
    SQL_INTERVAL_YEAR()                => 'tinyint',
    SQL_INTERVAL_MONTH()               => 'tinyint',
    SQL_INTERVAL_DAY()                 => 'tinyint',
    SQL_INTERVAL_HOUR()                => 'tinyint',
    SQL_INTERVAL_MINUTE()              => 'tinyint',
    SQL_INTERVAL_SECOND()              => 'tinyint',
    SQL_INTERVAL_YEAR_TO_MONTH()       => 'tinyint',
    SQL_INTERVAL_DAY_TO_HOUR()         => 'tinyint',
    SQL_INTERVAL_DAY_TO_MINUTE()       => 'tinyint',
    SQL_INTERVAL_DAY_TO_SECOND()       => 'tinyint',
    SQL_INTERVAL_HOUR_TO_MINUTE()      => 'tinyint',
    SQL_INTERVAL_HOUR_TO_SECOND()      => 'tinyint',
    SQL_INTERVAL_MINUTE_TO_SECOND()    => 'tinyint',
);

my %NUMERIC_TYPEMAP = (
    SQL_INTEGER()  => 1,
    SQL_TINYINT()  => 1,
    SQL_SMALLINT() => 1,
    SQL_BIGINT()   => 1,
    SQL_DOUBLE()   => 1,
    SQL_NUMERIC()  => 1,
    SQL_DECIMAL()  => 1,
    SQL_FLOAT()    => 1,
    SQL_REAL()     => 1,
);

our $DEFAULT_UNISIGNED;
our $DEFAULT_NOT_NULL;

sub produce {
    my $translator = shift;
    my $schema = $translator->schema;
    my $args = $translator->producer_args;

    my $typemap = $args->{typemap} || {};
    local %TYPEMAP = (%TYPEMAP, %$typemap);
    local $DEFAULT_NOT_NULL  = $args->{default_not_null} || 0;
    local $DEFAULT_UNISIGNED = $args->{default_unsigned} || 0;
    my $src = $_RENDER->($schema, $args);
    $src =~ s/'(\w+)'(?=\s+=>)/$1/msg;
    return $src;
}

sub _field_type {
    my $field = shift;

    if ($field->sql_data_type == SQL_UNKNOWN_TYPE) {
        my $list = exists $field->extra->{list} && $field->extra->{list};
        if ($list) {
            return 'enum' if $field->data_type eq 'enum';
            return 'set' if $field->data_type eq 'set';
        }
        return $field->data_type;
    }

    my $type = $TYPEMAP{$field->sql_data_type};
    unless (defined $type) {
        my $name = $_NAMEMAP{$field->sql_data_type} || "(unknown)"; # uncoverable condition left
        die "Unknown type: $name (sql_data_type: @{[ $field->sql_data_type ]})";
    }

    return $type;
}

sub _is_numeric_data_type {
    my $field = shift;
    return $NUMERIC_TYPEMAP{$field->sql_data_type};
}

sub _field_options {
    my $field = shift;
    my $unsigned = exists $field->extra->{unsigned} && $field->extra->{unsigned};
    my $on_update = exists $field->extra->{'on update'} && $field->extra->{'on update'};
    my $list = exists $field->extra->{list} && $field->extra->{list};
    my $numeric = _is_numeric_data_type($field);

    my $type = _field_type($field);
    my $is_char = $type =~ /char$/;
    my $is_decimal = $type eq 'decimal';

    my @options;
    push @options => _list($field)      if $list;
    push @options => 'signed'           if $numeric && !$unsigned && $DEFAULT_UNISIGNED;
    push @options => 'unsigned'         if $numeric && $unsigned && !$DEFAULT_UNISIGNED;
    push @options => _size($field)      if ($is_char || $is_decimal) && $field->size;
    push @options => 'null'             if $field->is_nullable && $DEFAULT_NOT_NULL;
    push @options => 'not_null'         if !$field->is_nullable && !$DEFAULT_NOT_NULL;
    push @options => _default($field)   if defined $field->default_value;
    push @options => _on_update($field) if $on_update;
    push @options => 'primary_key'      if _field_is_single_primary_key($field);
    push @options => 'unique'           if _field_is_single_unique_key($field);
    push @options => 'auto_increment'   if $field->is_auto_increment;
    push @options => _extra($field);

    return ', ' . join ', ', @options if @options;
    return '';
}

sub _field_is_single_primary_key {
    my $field = shift;
    my @primary_key = $field->table->primary_key->fields;
    return $field->is_primary_key && @primary_key == 1;
}

sub _field_is_single_unique_key {
    my $field = shift;
    for my $unique (grep { $_->type eq UNIQUE } $field->table->get_constraints) {
        my %field = map { $_ => 1 } $unique->field_names;
        return 1 if $field{$field->name} && keys %field == 1 && $unique->name eq "@{[$field->name]}_uniq";
    }
    return 0;
}

sub _list {
    my $field = shift;
    my $values = join ' ', @{ $field->extra->{list} };
    return "[qw/$values/]";
}

sub _size {
    my $field = shift;

    my @size = $field->size;
    return sprintf 'size => %d', $size[0] if @size == 1;
    return sprintf 'size => [%s]', join ', ', @size;
}

sub _default {
    my $field = shift;
    return sprintf q{default => \q{%s}}, ${$field->default_value} if ref $field->default_value eq 'SCALAR';
    return sprintf 'default => %s', $field->default_value if looks_like_number($field->default_value);
    return 'default => \q{NULL}' if  $field->default_value eq 'NULL';
    return sprintf q{default => '%s'}, $field->default_value;
}

sub _on_update {
    my $field = shift;
    my $on_update = $field->extra->{'on update'};
    return sprintf q{on_update => \q{%s}}, $$on_update if ref $on_update eq 'SCALAR';
    return sprintf q{on_update => '%s'}, $on_update;
}

sub _extra {
    my $field = shift;
    my %extra = $field->extra;
    delete $extra{list};
    delete $extra{'on update'};
    delete $extra{unsigned};
    return unless %extra;

    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Sortkeys = 1;
    return sprintf q{extra => %s}, Data::Dumper::Dumper(\%extra);
}

sub _index_fields {
    my $index = shift;
    return join ' ', $index->fields;
}

sub _index_type {
    my $index = shift;
    return 'unique_index' if $index->type eq 'UNIQUE';
    return 'index';
}

sub _index_options {
    my $index = shift;
    return '' if not $index->type;
    return '' if $index->type eq 'UNIQUE';
    return '' if $index->type eq 'NORMAL';
    return sprintf q{, '%s'}, $index->type;
}

sub _filter_constraint(;$) {# no critic
    $_ = shift if @_;
    return if $_->type eq NOT_NULL;
    return if $_->type eq PRIMARY_KEY && @{ $_->fields } == 1;
    return if $_->type eq UNIQUE && @{ $_->fields } == 1 && $_->name eq "@{[ $_->fields->[0] ]}_uniq";
    return 1;
}

sub _constraint_type {
    my $constraint = shift;

    return 'set_primary_key' if $constraint->type eq PRIMARY_KEY;
    return 'add_unique_index' if $constraint->type eq UNIQUE;
    return _fk_type($constraint) if $constraint->type eq FOREIGN_KEY;
    die "Unknown type: ", $constraint->type;
}

sub _fk_type {
    my $constraint = shift;
    my $table_name  = $constraint->table->name;
    my @fields = $constraint->field_names;
    my $reference_table  = $constraint->reference_table;
    my @reference_fields = $constraint->reference_fields;

    if (@fields == 1 && $fields[0] eq 'id') {
        my $expected_field = sprintf '%s_id', $table_name;
        if (@reference_fields == 1 && $reference_fields[0] eq $expected_field) {
            my $unique = $constraint->table->schema->get_table($reference_table)->get_field($expected_field)->is_unique;
            return $unique ? 'has_one' : 'has_many';
        }
    }
    elsif (@reference_fields == 1 && $reference_fields[0] eq 'id') {
        my $expected_field = sprintf '%s_id', $reference_table;
        if (@fields == 1 && $fields[0] eq $expected_field) {
            return 'belongs_to';
        }
    }

    return 'fk';
}

sub _constraint_options {
    my $constraint = shift;
    return _primary_key_options($constraint) if $constraint->type eq PRIMARY_KEY;
    return _unique_key_options($constraint) if $constraint->type eq UNIQUE;
    return _fk_options($constraint) if $constraint->type eq FOREIGN_KEY;
    die "Unknown type: ", $constraint->type;
}

sub _primary_key_options {
    my $constraint = shift;
    my $fields = join ' ', $constraint->field_names;
    return sprintf 'qw/%s/', $fields;
}

sub _unique_key_options {
    my $constraint = shift;
    my $fields = join ' ', $constraint->field_names;
    return sprintf q{'%s' => [qw/%s/]}, $constraint->name, $fields;
}

sub _fk_options {
    my $constraint = shift;

    my $type = _fk_type($constraint);
    if ($type eq 'fk') {
        my @fields = $constraint->field_names;
        my $fields = @fields > 1 ? sprintf '[qw/%s/]', join ' ', @fields : "'$fields[0]'";
        my @reference_fields = $constraint->reference_fields;
        my $reference_fields = @reference_fields > 1 ? sprintf '[qw/%s/]', join ' ', @reference_fields : "'$reference_fields[0]'";
        return sprintf q{%s, '%s' => %s},
            $fields, $constraint->reference_table, $reference_fields;
    }

    return sprintf q{'%s'}, $constraint->reference_table;
}

1;

=encoding utf-8

=head1 NAME

SQL::Translator::Producer::DBIxSchemaDSL - DBIX::Schema::DSL specific producer for SQL::Translator

=head1 SYNOPSIS

    use SQL::Translator;
    use SQL::Translator::Producer::DBIxSchemaDSL;

    my $t = SQL::Translator->new( parser => '...' );
    $t->producer('DBIxSchemaDSL');
    $t->translate;

=head1 DESCRIPTION

This module will produce text output of the schema suitable for DBIx::Schema::DSL.

=head1 ARGUMENTS

=over 4

=item C<default_not_null>

Enables C<default_not_null> in DSL.

=item C<default_unsigned>

Enables C<default_unsigned> in DSL.

=item C<typemap>

Override type mapping from DBI type to DBIx::Schema::DSL type.

Example:

    use DBI qw/:sql_types/;
    use SQL::Translator;
    use SQL::Translator::Producer::DBIx::Schema::DSL;

    my $t = SQL::Translator->new( parser => '...' );
    $t->producer('GoogleBigQuery', { typemap => { SQL_TINYINT() => 'integer' } });
    $t->translate;

=back

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut

__DATA__
? my ($schema, $args) = @_;
use strict;
use warnings;

use DBIx::Schema::DSL;

? if ($args->{default_unsigned}) {
default_unsigned;
? }
? if ($args->{default_not_null}) {
default_not_null;
? }

? for my $table ($schema->get_tables) {
create_table '<?= $table->name ?>' => columns {
?   for my $field ($table->get_fields) {
?       if ($field->sql_data_type == SQL_UNKNOWN_TYPE && _field_type($field) !~ /^(?:set|enum)$/) {
    column '<?= $field->name ?>', '<?= _field_type($field) ?>'<?= _field_options($field) ?>;
?       } else {
    <?= _field_type($field) ?> '<?= $field->name ?>'<?= _field_options($field) ?>;
?       }
?   }
?   if ($table->get_indices) {

?   }
?   for my $index ($table->get_indices) {
    add_<?= _index_type($index) ?> '<?= $index->name ?>' => [qw/<?= _index_fields($index) ?>/]<?= _index_options($index) ?>;
?   }
?   if (grep _filter_constraint, $table->get_constraints) {

?   }
?   for my $constraint (grep _filter_constraint, $table->get_constraints) {
    <?= _constraint_type($constraint) ?> <?= _constraint_options($constraint) ?>;
?   }
};

? }
1;
