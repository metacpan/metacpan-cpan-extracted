package Otogiri::Plugin::TableInfo::PgKeywords;
use 5.008005;
use strict;
use warnings;

# keywords are picked from postgresql-9.3.4/src/include/parser/kwlist.h

# COL_NAME_KEYWORD
my @col_name_keywords = (
    'between',
    'bigint',
    'bit',
    'boolean',
    'char',
    'character',
    'coalesce',
    'dec',
    'decimal',
    'exists',
    'extract',
    'float',
    'greatest',
    'inout',
    'int',
    'integer',
    'interval',
    'least',
    'national',
    'nchar',
    'none',
    'nullif',
    'numeric',
    'out',
    'overlay',
    'position',
    'precision',
    'real',
    'row',
    'setof',
    'smallint',
    'substring',
    'time',
    'timestamp',
    'treat',
    'trim',
    'values',
    'varchar',
    'xmlattributes',
    'xmlconcat',
    'xmlelement',
    'xmlexists',
    'xmlforest',
    'xmlparse',
    'xmlpi',
    'xmlroot',
    'xmlserialize',
);

# RESERVED_KEYWORD
my @reserved_keywords = (
    "all",
    "analyse",
    "analyze",
    "and",
    "any",
    "array",
    "as",
    "asc",
    "asymmetric",
    "both",
    "case",
    "cast",
    "check",
    "collate",
    "column",
    "constraint",
    "create",
    "current_catalog",
    "current_date",
    "current_role",
    "current_time",
    "current_timestamp",
    "current_user",
    "default",
    "deferrable",
    "desc",
    "distinct",
    "do",
    "else",
    "end",
    "except",
    "false",
    "fetch",
    "for",
    "foreign",
    "from",
    "grant",
    "group",
    "having",
    "in",
    "initially",
    "intersect",
    "into",
    "lateral",
    "leading",
    "limit",
    "localtime",
    "localtimestamp",
    "not",
    "null",
    "offset",
    "on",
    "only",
    "or",
    "order",
    "placing",
    "primary",
    "references",
    "returning",
    "select",
    "session_user",
    "some",
    "symmetric",
    "table",
    "then",
    "to",
    "trailing",
    "true",
    "union",
    "unique",
    "user",
    "using",
    "variadic",
    "when",
    "where",
    "window",
    "with",
);

sub new {
    my ($class) = @_;
    my @keywords = (@col_name_keywords, @reserved_keywords);
    my %keyword_hash    = map { ($_ => 1)     } @keywords;
    my %keyword_hash_uc = map { (uc($_) => 1) } @keywords;
    my $self = {
        keyword => { %keyword_hash, %keyword_hash_uc },
    };
    bless $self, $class;
}

sub quote {
    my ($self, $column_name) = @_;
    return '"' . $column_name . '"' if ( exists $self->{keyword}->{$column_name} );
    return $column_name;
}


1;
__END__

=encoding utf-8

=head1 NAME

Otogiri::Plugin::TableInfo::PgKeywords - PostgreSQL Keywords

=head1 SYNOPSIS

    use Otogiri::Plugin::TableInfo::PgKeywords;
    my $k = Otogiri::Plugin::TableInfo::PgKeywords->new();
    my $quoted = $k->quote('position'); # => '"position"'


=head1 DESCRIPTION

Provide PostgreSQL Keyword

=head1 METHODS

=head2 my $quoted_column = $self->quote_column($column_name);

quote column name if column uses reserved word

=cut
