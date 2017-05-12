package SQL::Translator::Producer::GoogleBigQuery;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use JSON::PP;
use DBI qw/:sql_types/;
use File::Spec;

my $_JSON = JSON::PP->new;
my %_NAMEMAP = map { $_ => *{$DBI::{$_}}{CODE}->() } @{ $DBI::EXPORT_TAGS{sql_types} };
my %_TYPEMAP = (
    SQL_GUID()                         => 'string',
    SQL_WLONGVARCHAR()                 => 'string',
    SQL_WVARCHAR()                     => 'string',
    SQL_WCHAR()                        => 'string',
    SQL_BIGINT()                       => 'integer',
    SQL_BIT()                          => 'integer',
    SQL_TINYINT()                      => 'integer',
    SQL_LONGVARBINARY()                => 'string',
    SQL_VARBINARY()                    => 'string',
    SQL_BINARY()                       => 'string',
    SQL_LONGVARCHAR()                  => 'string',
    SQL_UNKNOWN_TYPE()                 => 'string',
    SQL_ALL_TYPES()                    => 'string',
    SQL_CHAR()                         => 'string',
    SQL_NUMERIC()                      => 'float',
    SQL_DECIMAL()                      => 'float',
    SQL_INTEGER()                      => 'integer',
    SQL_SMALLINT()                     => 'integer',
    SQL_FLOAT()                        => 'float',
    SQL_REAL()                         => 'float',
    SQL_DOUBLE()                       => 'float',
    SQL_DATETIME()                     => 'timestamp',
    SQL_DATE()                         => 'timestamp',
    SQL_INTERVAL()                     => 'integer',
    SQL_TIME()                         => 'string',
    SQL_TIMESTAMP()                    => 'timestamp',
    SQL_VARCHAR()                      => 'string',
    SQL_BOOLEAN()                      => 'boolean',
    SQL_UDT()                          => 'string',
    SQL_UDT_LOCATOR()                  => 'string',
    SQL_ROW()                          => 'string',
    SQL_REF()                          => 'string',
    SQL_BLOB()                         => 'string',
    SQL_BLOB_LOCATOR()                 => 'string',
    SQL_CLOB()                         => 'string',
    SQL_CLOB_LOCATOR()                 => 'string',
    SQL_ARRAY()                        => 'string',
    SQL_ARRAY_LOCATOR()                => 'string',
    SQL_MULTISET()                     => 'string',
    SQL_MULTISET_LOCATOR()             => 'string',
    SQL_TYPE_DATE()                    => 'timestamp',
    SQL_TYPE_TIME()                    => 'string',
    SQL_TYPE_TIMESTAMP()               => 'timestamp',
    SQL_TYPE_TIME_WITH_TIMEZONE()      => 'string',
    SQL_TYPE_TIMESTAMP_WITH_TIMEZONE() => 'timestamp',
    SQL_INTERVAL_YEAR()                => 'integer',
    SQL_INTERVAL_MONTH()               => 'integer',
    SQL_INTERVAL_DAY()                 => 'integer',
    SQL_INTERVAL_HOUR()                => 'integer',
    SQL_INTERVAL_MINUTE()              => 'integer',
    SQL_INTERVAL_SECOND()              => 'integer',
    SQL_INTERVAL_YEAR_TO_MONTH()       => 'integer',
    SQL_INTERVAL_DAY_TO_HOUR()         => 'integer',
    SQL_INTERVAL_DAY_TO_MINUTE()       => 'integer',
    SQL_INTERVAL_DAY_TO_SECOND()       => 'integer',
    SQL_INTERVAL_HOUR_TO_MINUTE()      => 'integer',
    SQL_INTERVAL_HOUR_TO_SECOND()      => 'integer',
    SQL_INTERVAL_MINUTE_TO_SECOND()    => 'integer',
);

sub produce {
    my $translator = shift;
    my $schema = $translator->schema;
    my $args = $translator->producer_args;

    my $outdir  = $args->{outdir};
    my $typemap = $args->{typemap} || {};

    my @tables;
    for my $table ($schema->get_tables) {
        push @tables => {
            name   => $table->name,
            schema => [
                map {
                    +{
                        name => $_->name,
                        type => _type($_->sql_data_type, $typemap),
                    }
                } $table->get_fields
            ],
        };
    }

    return \@tables unless defined $outdir;

    die "No such directory: $outdir" unless -d $outdir;
    for my $table (@tables) {
        my $file = File::Spec->catfile($outdir, "$table->{name}.json");
        open my $fh, '>', $file or die "$file: $!"; # uncoverable branch
        print {$fh} $_JSON->encode($table->{schema});
        close $fh;
    }

    return \@tables;
}

sub _type {
    my ($sql_data_type, $typemap) = @_;
    return $typemap->{$sql_data_type} if exists $typemap->{$sql_data_type};

    my $type = $_TYPEMAP{$sql_data_type};
    unless (defined $type) {
        my $name = $_NAMEMAP{$sql_data_type} || "(unknown)"; # uncoverable condition left
        die "Unknown type: $name (sql_data_type: $sql_data_type)";
    }
    return $type;
}

1;
__END__

=encoding utf-8

=head1 NAME

SQL::Translator::Producer::GoogleBigQuery - Google BigQuery specific producer for SQL::Translator

=head1 SYNOPSIS

    use SQL::Translator;
    use SQL::Translator::Producer::GoogleBigQuery;

    my $t = SQL::Translator->new( parser => '...' );
    $t->producer('GoogleBigQuery', outdir => './'); ## dump to ...
    $t->translate;

=head1 DESCRIPTION

This module will produce text output of the schema suitable for Google BigQuery.
It will be a '.json' file of BigQuery schema format.

=head1 ARGUMENTS

=over 4

=item C<outdir>

Base directory of output schema files.

=item C<typemap>

Override type mapping from DBI type to Goolge BigQuery type.

Example:

    use DBI qw/:sql_types/;
    use SQL::Translator;
    use SQL::Translator::Producer::GoogleBigQuery;

    my $t = SQL::Translator->new( parser => '...' );
    $t->producer('GoogleBigQuery', outdir => './', typemap => { SQL_TINYINT() => 'boolean' });
    $t->translate;

=back

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut

