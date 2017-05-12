package SQL::Translator::Producer::Teng;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.03";

use Text::Xslate;
use Data::Section::Simple;
use DBI;
use SQL::Translator::Schema::Field;

my $_tx;
sub _tx {
    $_tx ||= Text::Xslate->new(
        type   => 'text',
        module => ['Text::Xslate::Bridge::Star'],
        path   => [Data::Section::Simple::get_data_section]
    );
}

sub produce {
    my $translator = shift;
    my $schema = $translator->schema;
    my $args = $translator->producer_args;

    my $package        = $args->{package};
    my $base_row_class = $args->{base_row_class};

    my @tables;
    for my $table ($schema->get_tables) {
        my @pks;
        my @columns;
        for my $field ($table->get_fields) {
            push @columns, {
                name      => $field->name,
                type_name => $field->data_type,
                type      => _get_dbi_const($field->sql_data_type),
            };
            push @pks, $field->name if $field->is_primary_key;
        }

        push @tables, {
            name    => $table->name,
            pks     => \@pks,
            columns => \@columns,
        };
    }

    _tx->render('schema.tx', {
        package        => $package,
        base_row_class => $base_row_class,
        tables         => \@tables,
    });
}

my %CONST_HASH;
sub _get_dbi_const {
    my $val = shift;

    unless (%CONST_HASH) {
        for my $const_key (@{ $DBI::EXPORT_TAGS{sql_types} }) {
            my $const_val = DBI->can($const_key)->();

            unless (exists $CONST_HASH{$const_val}) {
                $CONST_HASH{$const_val} = $const_key;
            }
        }
    }

    $CONST_HASH{$val};
}

1;
__DATA__
@@ schema.tx
: if $package {
package <: $package :>;
: }
use strict;
use warnings;
use DBI qw/:sql_types/;
use Teng::Schema::Declare;

: if $base_row_class {
base_row_class '<: $base_row_class :>';

: }
: for $tables -> $table {
table {
    name '<: $table.name :>';
    pk   qw/<: $table.pks.join(' ') :>/;
    columns
    : for $table.columns -> $column {
        { name => '<: $column.name :>', type => <: $column.type :> }, # <: $column.type_name | uc :>
    : }
    ;
};

: }
1;
__END__

=encoding utf-8

=head1 NAME

SQL::Translator::Producer::Teng - Teng-specific producer for SQL::Translator

=head1 SYNOPSIS

Use via SQL::Translator:

    use SQL::Translator;
    my $t = SQL::Translator->new( parser => '...' );
    $t->producer('Teng', package => 'MyApp::DB::Schema');
    $t->translate;

=head1 DESCRIPTION

This module will produce text output of the schema suitable for L<Teng>.
It will be a '.pm' file of L<Teng::Schema::Declare> format.

=head1 ARGUMENTS

This producer takes a single optional producer_arg C<package>, which
provides the package name of the target schema '.pm' file.

=head1 LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Songmu E<lt>y.songmu@gmail.comE<gt>

=cut
