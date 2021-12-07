package MySQL::Workbench::Parser::Table;

# ABSTRACT: A table of the ER model

use strict;
use warnings;

use List::MoreUtils qw(all);
use Moo;
use Scalar::Util qw(blessed);
use YAML::Tiny;

use MySQL::Workbench::Parser::Column;
use MySQL::Workbench::Parser::Index;

our $VERSION = '1.10';

has node => (
    is       => 'ro',
    required => 1,
    isa      => sub {
        blessed $_[0] && $_[0]->isa( 'XML::LibXML::Node' );
    },
);

has parser => (
    is       => 'ro',
    required => 1,
    isa      => sub {
        blessed $_[0] && $_[0]->isa( 'MySQL::Workbench::Parser' );
    },
);

has columns => (
    is  => 'rwp',
    isa => sub {
        ref $_[0] && ref $_[0] eq 'ARRAY' &&
        all{ blessed $_ && $_->isa( 'MySQL::Workbench::Parser::Column' ) }@{$_[0]}
    },
    lazy    => 1,
    default => sub { [] },
);

has indexes => (
    is  => 'rwp',
    isa => sub {
        ref $_[0] && ref $_[0] eq 'ARRAY' &&
        all{ blessed $_ && $_->isa( 'MySQL::Workbench::Parser::Index' ) }@{$_[0]}
    },
    lazy    => 1,
    default => sub { [] },
);

has foreign_keys => (
    is  => 'rwp',
    isa => sub {
        ref $_[0] && ref $_[0] eq 'HASH'
    },
    default => sub { {} },
);

has primary_key => (
    is => 'rwp',
    isa => sub {
        ref $_[0] && ref $_[0] eq 'ARRAY'
    },
    default => sub { [] },
);

has comment => (is => 'rwp');

has name => ( is => 'rwp' );

has column_mapping => (
    is   => 'rwp',
    lazy => 1,
    isa  => sub {
        ref $_[0] && ref $_[0] eq 'HASH'
    },
    default => sub {
        my $self = shift;

        my %map  = map{
            $_->id => $_->name
        }@{ $self->columns || [] };

        \%map;
    },
);


sub BUILD {
    my $self = shift;
    $self->_parse;
}


sub as_hash {
    my $self = shift;

    my @columns;
    for my $column ( @{$self->columns} ) {
        push @columns, $column->as_hash;
    }

    my @indexes;
    for my $index ( @{ $self->indexes } ) {
        push @indexes, $index->as_hash;
    }

    my %info = (
        name         => $self->name,
        columns      => \@columns,
        indexes      => \@indexes,
        foreign_keys => $self->foreign_keys,
        primary_key  => $self->primary_key,
    );

    $info{comment} = $self->comment if $self->comment;

    return \%info;
}

sub _parse {
    my $self = shift;

    my $node = $self->node;

    my @columns;
    my @column_nodes = $node->findnodes( './/value[@struct-name="db.mysql.Column"]' );
    for my $column_node ( @column_nodes ) {
        my $column_obj = MySQL::Workbench::Parser::Column->new(
            node  => $column_node,
            table => $self,
        );
        push @columns, $column_obj;
    }
    $self->_set_columns( \@columns );

    my $comment = $node->findvalue( './value[@key="comment"]' );
    $self->_set_comment( $comment ) if $comment;

    my $name = $node->findvalue( './value[@key="name"]' );
    $self->_set_name( $name );

    my %foreign_keys;
    my @foreign_key_nodes = $node->findnodes( './value[@key="foreignKeys"]/value[@struct-name="db.mysql.ForeignKey"]' );
    for my $foreign_key_node ( @foreign_key_nodes ) {
        my $foreign_table_id  = $foreign_key_node->findvalue( 'link[@key="referencedTable"]' );
        my $foreign_column_id = $foreign_key_node->findvalue( 'value[@key="referencedColumns"]/link' );

        my $foreign_data      = $self->_foreign_data(
            table_id  => $foreign_table_id,
            column_id => $foreign_column_id,
        );

        my $table  = $foreign_data->{table};
        my $column = $foreign_data->{column};

        my $me_column_id = $foreign_key_node->findvalue( './/value[@key="columns"]/link' );
        my $me_column    = $node->findvalue( './/value[@id="' . $me_column_id . '"]/value[@key="name"]' );

        my %actions;
        my $delete_action = $foreign_key_node->findvalue( './/value[@key="deleteRule"]' );
        $actions{on_delete} = lc $delete_action;

        my $update_action = $foreign_key_node->findvalue( './/value[@key="updateRule"]' );
        $actions{on_update} = lc $update_action;

        push @{ $foreign_keys{$table} }, { %actions, me => $me_column, foreign => $column };
    }

    my @indexes;
    my @index_column_nodes = $node->findnodes( './/value[@struct-name="db.mysql.Index"]' );
    for my $index_column_node ( @index_column_nodes ) {
        my $type = $index_column_node->findvalue( './/value[@key="indexType"]' );

        my $index_obj = MySQL::Workbench::Parser::Index->new(
            node  => $index_column_node,
            table => $self,
        );
        push @indexes, $index_obj;

        next if $type ne 'PRIMARY';

        my @column_nodes   = $index_column_node->findnodes( './/link[@key="referencedColumn"]' );
        my @column_names = map{
            my $id = $_->textContent;
            $node->findvalue( './/value[@id="' . $id . '"]/value[@key="name"]' );
        }@column_nodes;

        $self->_set_primary_key( \@column_names );
    }

    $self->_set_foreign_keys( \%foreign_keys );
    $self->_set_indexes( \@indexes );
}


sub get_datatype {
    my $self = shift;

    return $self->parser->get_datatype( @_ );
}

sub _foreign_data {
    my $self = shift;
    my %ids  = @_;

    my ($foreign_table_node) = $self->node->parentNode->findnodes(
        'value[@struct-name="db.mysql.Table" and @id="' . $ids{table_id} . '"]'
    );

    my $foreign_table_name   = $foreign_table_node->findvalue( 'value[@key="name"]' );
    my $foreign_column_name  = $foreign_table_node->findvalue(
        './/value[@id="' . $ids{column_id} . '"]/value[@key="name"]'
    );

    return { table => $foreign_table_name, column => $foreign_column_name };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MySQL::Workbench::Parser::Table - A table of the ER model

=head1 VERSION

version 1.11

=for Pod::Coverage BUILD

=head1 METHODS

=head2 as_hash

return info about a table as a hash

    my %info = $table->as_hash;

returns

    (
        name         => 'table_name',
        primary_key  => [ 'id' ],
        foreign_keys => {
            second_table => [
                {
                    foreign => 'id',
                    me      => 'second_id',
                },
            ],
        },
        columns      => [
            {
                name          => 'id',
                datatype      => 'INT',
                length        => '',
                precision     => '0',
                not_null      => '1',
                autoincrement => '1',
                default_value => '',
            }
        ],
    )

=head2 get_datatype

get datatype for a workbench column datatype

    my $datatype = $table->get_datatype( 'com.mysql.rdbms.mysql.datatype.mediumtext' );

returns the MySQL name of the datatype

    MEDIUMTEXT

=head1 ATTRIBUTES

=over 4

=item * comment

=item * columns

An array reference of L<MySQL::Workbench::Parser::Column> objects

=item * foreign_keys

An array reference of all relationships to other tables

=item * name

The name of the table

=item * node

=item * parser

=item * primary_key

=item * indexes

=item * column_mapping

=back

=head1 MISC

=head2 BUILD

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
