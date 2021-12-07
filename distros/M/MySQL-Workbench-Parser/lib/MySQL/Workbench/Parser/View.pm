package MySQL::Workbench::Parser::View;

# ABSTRACT: A view of the ER model

use strict;
use warnings;

use Carp qw(croak);
use List::MoreUtils qw(all);
use Moo;
use SQL::Translator;
use Scalar::Util qw(blessed);
use YAML::Tiny;

use MySQL::Workbench::Parser::Column;
use MySQL::Workbench::Parser::Index;
use MySQL::Workbench::Parser::MySQLParser;

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

has tables => (
    is  => 'rwp',
    isa => sub {
        ref $_[0] && ref $_[0] eq 'ARRAY'
    },
    lazy    => 1,
    default => sub { [] },
);

has comment    => (is => 'rwp');
has name       => (is => 'rwp');
has definition => (is => 'rwp');

has column_mapping => (
    is   => 'rwp',
    lazy => 1,
    isa  => sub {
        ref $_[0] && ref $_[0] eq 'HASH'
    },
    default => sub {
        my $self = shift;

        my %map;

        TABLE:
        for my $table ( @{ $self->parser->tables } ) {
            my $name = $table->name;

            for my $col ( @{ $table->columns } ) {
                my $col_name = $col->name;
                $map{$name}->{$col_name} = $col;
            }
        }

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

    my %info = (
        name       => $self->name,
        columns    => \@columns,
        definition => $self->definition,
    );

    $info{comment} = $self->comment if $self->comment;

    return \%info;
}

sub _parse {
    my $self = shift;

    my $node = $self->node;

    my @columns;

    my $definition = $node->findvalue( './value[@key="sqlDefinition"]' );

    $definition .= ';' if ';' ne substr $definition, -1;
    $self->_set_definition( $definition );

    my $translator = SQL::Translator->new;
    my $sub        = $translator->parser( 'MySQL::Workbench::Parser::MySQLParser' );

    $sub->( $translator, $definition );
    my ($view) = $translator->schema->get_views;

    croak 'Error in parsing the VIEW' if !$view;

    my %map = %{ $self->column_mapping || {} };
    for my $field ( $view->fields ) {
        my $column_obj;

        my ($table, $column) = split /\./, $field;
        if ( $column ) {
            $column_obj = $map{$table}->{$column};
        }
        else {
            $column = $table;

            VIEWTABLE:
            for my $view_table ( $view->tables ) {
                $column_obj = $map{$view_table}->{$column};
                last VIEWTABLE if $column_obj;
            }
        }

        push @columns, $column_obj if $column_obj;
    }

    $self->_set_columns( \@columns );
    $self->_set_tables( [ $view->tables ] );

    my $comment = $node->findvalue( './value[@key="comment"]' );
    $self->_set_comment( $comment ) if $comment;

    my $name = $node->findvalue( './value[@key="name"]' );
    $self->_set_name( $name );
}


sub get_datatype {
    my $self = shift;

    return $self->parser->get_datatype( @_ );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MySQL::Workbench::Parser::View - A view of the ER model

=head1 VERSION

version 1.11

=for Pod::Coverage BUILD

=head1 METHODS

=head2 as_hash

return info about a view as a hash

    my %info = $view->as_hash;

returns

    (
        name       => 'view_name',
        definition => 'CREATE VIEW `view_name` AS SELECT ...',
        columns    => [
            name          => 'id',
            datatype      => 'INT',
            length        => '',
            precision     => '0',
            not_null      => '1',
            autoincrement => '1',
            default_value => '',
        ],
    )

=head2 get_datatype

get datatype for a workbench column datatype

    my $datatype = $view->get_datatype( 'com.mysql.rdbms.mysql.datatype.mediumtext' );

returns the MySQL name of the datatype

    MEDIUMTEXT

=head1 ATTRIBUTES

=over 4

=item * comment

=item * name

=item * definition

=item * node

=item * parser

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
