package Otogiri::Plugin::TableInfo::Pg;
use 5.008005;
use strict;
use warnings;
use DBI;
use DBIx::Inspector;
use List::MoreUtils qw(any);
use Otogiri::Plugin::TableInfo::PgKeywords;

sub new {
    my ($class, $table_info) = @_;
    my $keywords = Otogiri::Plugin::TableInfo::PgKeywords->new();
    my $self = {
        table_info => $table_info,
        keywords   => $keywords,
    };
    bless $self, $class;
}


sub show_create_view {
    my ($self, $view_name) = @_;
    my ($row) = $self->{table_info}->search_by_sql('SELECT definition FROM pg_views WHERE viewname = ?', [$view_name]);
    my $definition = $row->{definition};
    if ( defined $definition ) {
        $definition =~ s/\A\s//;
        $definition =~ s/\n//g;
        $definition =~ s/\s{2,}/ /g;
    }
    return $definition;
}

sub show_create_table {
    my ($self, $table_name) = @_;
    my $inspector = DBIx::Inspector->new(dbh => $self->{table_info}->dbh);
    my $table = $inspector->table($table_name);

    return if ( !defined $table );

    my @indexes = $self->{table_info}->select('pg_indexes', { tablename => $table->name }, { order_by => 'indexname' });
    my $result = "CREATE TABLE " . $table->name . " (\n";
    $result .= $self->_build_column_defs($table);
    $result .= ");\n";
    $result .= $self->_build_sequence_defs($table);
    $result .= $self->_build_pk_defs($table);
    $result .= $self->_build_uk_defs($table, @indexes);
    $result .= $self->_build_index_defs($table, @indexes);
    $result .= $self->_build_fk_defs($table);
    return $result;
}

sub _build_column_defs {
    my ($self, $table) = @_;
    my $result = "";
    for my $column ( $table->columns() ) {
        my $column_name = $self->{keywords}->quote($column->name); #quote column name if it is need.
        $result .= "    " . $column_name . " " . $column->{PG_TYPE};
        $result .= " DEFAULT " . $column->column_def if ( defined $column->column_def && !$self->_is_sequence_column($column) );
        $result .= " NOT NULL" if ( !$column->nullable );
        $result .= ",\n";
    }
    $result =~ s/,\n\z/\n/;
    return $result;
}

sub _build_sequence_defs {
    my ($self, $table) = @_;
    my $result = "";
    my @sequence_columns = grep { $self->_is_sequence_column($_) } $table->columns();
    for my $column ( @sequence_columns ) {
        my $sequence_name = $self->_parse_sequence_name($column);
        $result .= $self->_build_create_sequence_defs($sequence_name);
        $result .= "ALTER SEQUENCE " . $sequence_name . " OWNED BY " . $table->name . "." . $column->name . ";\n";
        $result .= "ALTER TABLE ONLY " . $table->name . " ALTER COLUMN " . $column->name . " SET DEFAULT " . $column->column_def . ";\n";
    }
    return $result;
}

sub _parse_sequence_name {
    my ($self, $column) = @_;
    if ( $column->column_def =~ qr/^nextval\('([^']+)'::regclass\)/ ) {
        return $1;
    }
    return;
}

sub _build_create_sequence_defs {
    my ($self, $sequence_name) = @_;
    my ($row) = $self->{table_info}->select($sequence_name);
    my $result = "CREATE SEQUENCE $sequence_name\n";
    $result .= "    START WITH " . $row->{start_value} . "\n";
    $result .= "    INCREMENT BY " . $row->{increment_by} . "\n";
    if ( $row->{min_value} eq '1' ) {
        $result .= "    NO MINVALUE\n";
    }
    else {
        $result .= "    MINVALUE " . $row->{min_value} . "\n";
    }

    if ( $row->{max_value} eq '9223372036854775807' ) {
        $result .= "    NO MAXVALUE\n";
    }
    else {
        $result .= "    MAXVALUE " . $row->{max_value} . "\n";
    }

    $result .= "    CACHE " . $row->{cache_value} . ";\n";
    return $result;
}

sub _is_sequence_column {
    my ($self, $column) = @_;
    my $default_value = $column->column_def;
    return if ( !defined $default_value );
    return $default_value =~ qr/^nextval\(/;
}

sub _build_pk_defs {
    my ($self, $table) = @_;
    my $result = "";
    for my $column ( $table->primary_key() ) {
        $result .= "ALTER TABLE ONLY " . $table->name . "\n";
        $result .= "    ADD CONSTRAINT " . $column->{PG_COLUMN} . " PRIMARY KEY (" . $column->name . ");\n";
    }
    return $result;
}

sub _build_index_defs {
    my ($self, $table, @indexes) = @_;

    my @rows = grep { $_->{indexdef} !~ qr/\ACREATE UNIQUE INDEX/ } @indexes;

    my $result = '';
    for my $row ( @rows ) {
        next if ( $self->_is_pk($table, $row->{indexname}) );
        $result .= $row->{indexdef} . ";\n";
    }
    return $result;
}

sub _is_pk {
    my ($self, $table, $column_name) = @_;
    return any { $_->{PK_NAME} eq $column_name } $table->primary_key();
}

sub _build_uk_defs {
    my ($self, $table, @indexes) = @_;
    my @unique_indexes = grep {
        $_->{indexdef} =~ qr/\ACREATE UNIQUE INDEX/ && !$self->_is_pk($table, $_->{indexname})
    } @indexes;
    my $result = '';
    for my $indexdef ( map{ $_->{indexdef} } @unique_indexes ) {
        $result .= $indexdef . ";\n";
    }
    return $result;
}

sub _build_fk_defs {
    my ($self, $table) = @_;
    my $result = '';
    # UPDATE_RULE and DELETE_RULE are described in http://search.cpan.org/dist/DBI/DBI.pm#foreign_key_info
    my %rule = (
        0 => 'CASCADE',
        1 => 'RESTRICT',
        2 => 'SET NULL',
        #3 => 'NO ACTION', # If NO ACTION, ON UPDATE/DELETE statament is not exist.
        4 => 'SET DEFAULT',
    );

    for my $fk_info ( $table->fk_foreign_keys() ) {
        $result .= "ALTER TABLE ONLY " . $table->name . "\n";
        $result .= "    ADD CONSTRAINT " . $fk_info->fk_name . " FOREIGN KEY (" . $fk_info->fkcolumn_name . ")";
        $result .= " REFERENCES " . $fk_info->pktable_name . "(" . $fk_info->pkcolumn_name . ")";
        $result .= " ON UPDATE " . $rule{$fk_info->{UPDATE_RULE}} if ( exists $rule{$fk_info->{UPDATE_RULE}} );
        $result .= " ON DELETE " . $rule{$fk_info->{DELETE_RULE}} if ( exists $rule{$fk_info->{DELETE_RULE}} );
        $result .= " DEFERRABLE" if ( $fk_info->deferability ne '7' );
        $result .= ";\n";
    }
    return $result;
}



1;
__END__

=encoding utf-8

=for stopwords PostgreSQL

=head1 NAME

Otogiri::Plugin::TableInfo::Pg - build CREATE TABLE statement for PostgreSQL

=head1 SYNOPSIS

    use Otogiri::Plugin::TableInfo;
    my $db = Otogiri->new( connect_info => [ ... ] );
    $db->load_plugin('TableInfo');
    my @table_names = $db->show_tables();


=head1 DESCRIPTION

Otogiri::Plugin::TableInfo is Otogiri plugin to fetch table information from database.
=cut

