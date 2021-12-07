package MySQL::Workbench::Parser;

# ABSTRACT: parse .mwb files created with MySQL Workbench

use strict;
use warnings;

use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Carp;
use List::MoreUtils qw(all);
use Moo;
use Scalar::Util qw(blessed);
use XML::LibXML;
use YAML::Tiny;

use MySQL::Workbench::Parser::Table;
use MySQL::Workbench::Parser::View;

our $VERSION = '1.11';

has lint => ( is => 'ro', default => sub { 1 } );

has file   => (
    is       => 'ro',
    required => 1,
    isa      => sub { -f $_[0] },
);

has tables => (
    is  => 'rwp',
    isa => sub {
        ref $_[0] && ref $_[0] eq 'ARRAY' &&
        all { blessed $_ && $_->isa( 'MySQL::Workbench::Parser::Table' ) }@{$_[0]} ;
    },
    lazy    => 1,
    builder => \&_parse_tables,
);

has views => (
    is  => 'rwp',
    isa => sub {
        ref $_[0] && ref $_[0] eq 'ARRAY' &&
        all { blessed $_ && $_->isa( 'MySQL::Workbench::Parser::View' ) }@{$_[0]} ;
    },
    lazy    => 1,
    builder => \&_parse_views,
);

has datatypes => (
    is  => 'rwp',
    isa => sub {
        ref $_[0] && ref $_[0] eq 'HASH' &&
        all { !ref $_[0]->{$_} }keys %{ $_[0] };
    },
    lazy    => 1,
    default => sub { +{} },
);

has dom => (
    is  => 'rwp',
    isa => sub {
        blessed $_[0] && $_[0]->isa('XML::LibXML');
    },
);

sub dump {
    my $self = shift;

    my $tables = $self->tables;
    my %info;
    for my $table ( @{$tables} ) {
        push @{$info{tables}}, $table->as_hash;
    }

    for my $view ( @{ $self->views } ) {
        push @{$info{views}}, $view->as_hash;
    }

    my $yaml = YAML::Tiny->new;
    $yaml->[0] = \%info;

    return $yaml->write_string;
}

sub get_datatype {
    my $self = shift;

    my $datatypes = $self->datatypes;
    return $datatypes->{$_[0]};
}

sub _parse_tables {
    my ($self) = shift;

    $self->_parse;
    $self->tables;
}

sub _parse_views {
    my ($self) = shift;

    $self->_parse;
    $self->views;
}

sub _parse {
    my $self = shift;

    my $zip = Archive::Zip->new;
    if ( $zip->read( $self->file ) != AZ_OK ) {
        croak "can't read file " . $self->file;
    }

    my $xml = $zip->contents( 'document.mwb.xml' );
    my $dom = XML::LibXML->load_xml( string => $xml );

    $self->_set_dom( $dom );

    my %datatypes;
    my @simple_type_nodes = $dom->documentElement->findnodes( './/value[@key="simpleDatatypes"]/link' );
    for my $type_node ( @simple_type_nodes ) {
         my $link     = $type_node->textContent;
         my $datatype = uc +(split /\./, $link)[-1];
         $datatype    =~ s/_F\z//;

         $datatypes{$link} = { name => $datatype, length => undef };
    }

    my @user_type_structs = $dom->documentElement->findnodes( './/value[@key="userDatatypes"]' );
    for my $type_structs ( @user_type_structs ) {
         my @user_types = $type_structs->findnodes( './value[@struct-name="db.UserDatatype"]' );
         for my $type ( @user_types ) {
             my $name        = $type->findvalue( '@id' );
             my $sql         = $type->findvalue( './value[@key="sqlDefinition"]' );
             my ($orig)      = $sql =~ m{^([A-Z]+)};
             my ($length)    = $sql =~ m{\( (\d+) \)}x;
             my ($precision) = $sql =~ m{\( (\d+,\d+) \)}x;
             my ($args)      = $sql =~ m{\( (.+?) \)}x;
             my $gui_name    = $type->findvalue( './value[@key="name"]' );

             $datatypes{$name} = { name => $orig, length => $length, precision => $precision, gui_name => $gui_name, args => $args };
         }
    }

    $self->_set_datatypes( \%datatypes );

    my @tables;

    my @table_nodes = $dom->documentElement->findnodes( './/value[@struct-name="db.mysql.Table"]' );
    for my $table_node ( @table_nodes ) {
        push @tables, MySQL::Workbench::Parser::Table->new(
            node   => $table_node,
            parser => $self,
        );
    }

    $self->_lint( \@tables ) if $self->lint;
    $self->_set_tables( \@tables );

    my @views;

    my @view_nodes = $dom->documentElement->findnodes( './/value[@struct-name="db.mysql.View"]' );

    my %column_mapping;
    if ( @view_nodes ) {

        TABLE:
        for my $table ( @tables ) {
            my $name = $table->name;

            for my $col ( @{ $table->columns } ) {
                my $col_name = $col->name;
                $column_mapping{$name}->{$col_name} = $col;
            }
        }
    }

    for my $view_node ( @view_nodes ) {
        push @views, MySQL::Workbench::Parser::View->new(
            node           => $view_node,
            column_mapping => \%column_mapping,
            parser         => $self,
        );
    }

    $self->_set_views( \@views );
}

sub _lint {
    my ($self, $tables) = @_;

    return if !ref $tables;
    return if 'ARRAY' ne ref $tables;

    my %tablenames;
    my %indexes;
    my %duplicate_columns;

    for my $table ( @{ $tables } ) {
        my $name = $table->name;

        $tablenames{$name}++;

        INDEX:
        for my $index ( @{ $table->indexes } ) {
            my $index_name = $index->name;

            next INDEX if $index_name eq 'PRIMARY';
            next INDEX if $index->type eq 'UNIQUE';

            $indexes{$index_name}++;
        }

        my %columns;

        COLUMN:
        for my $column ( @{ $table->columns } ) {
            my $column_name = $column->name;
            $duplicate_columns{$name}++ if $columns{$column_name};
            $columns{$column_name}++;
        }
    }

    # warn if table names occur more than once
    my @duplicate_tables = grep{ $tablenames{$_} > 1 }sort keys %tablenames;
    if ( @duplicate_tables ) {
        carp 'duplicate table names (' .
            ( join ', ', @duplicate_tables ).
            ')';
    }

    # warn if index name occurs more than once
    my @duplicate_indexes = grep{ $indexes{$_} > 1  }sort keys %indexes;
    if ( @duplicate_indexes ) {
        carp 'duplicate indexes (' .
            ( join ', ', @duplicate_indexes ) .
            ')';
    }

    # warn if there are duplicate column names
    if ( %duplicate_columns ) {
        carp 'duplicate column names in a table (' .
            ( join ', ', sort keys %duplicate_columns ).
            ')';
    }

    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MySQL::Workbench::Parser - parse .mwb files created with MySQL Workbench

=head1 VERSION

version 1.11

=head1 SYNOPSIS

    # create the parser
    my $parser = MySQL::Workbench::Parser->new(
        file => '/path/to/file.mwb',
    );

    # access tables of the workbench ER model
    my @tables = @{ $parser->tables };

    # access views of the workbench ER model
    my @views = @{ $parser->views };

=head1 DESCRIPTION

The MySQL Workbench is a tool to design database entity relationship models.
This parser parses .mwb files created with that tool and extracts all relevant
information.

=head1 METHODS

=head2 new

Create a new parser object

    my $parser = MySQL::Workbench::Parser->new(
        file => '/path/to/file.mwb',
    );

=head2 dump

dump the database structure as YAML

    my $yaml = $parser->dump;

=head2 get_datatype

get datatype for a workbench column datatype

    my $datatype = $table->get_datatype( 'com.mysql.rdbms.mysql.datatype.mediumtext' );

returns the MySQL name of the datatype

    MEDIUMTEXT

=head1 ATTRIBUTES

=over 4

=item * tables

An array of L<MySQL::Workbench::Parser::Table> objects

    my @tables = $parser->tables;

=item * views

An array of L<MySQL::Workbench::Parser::View> objects

    my @views = $parser->views;

=item * file

=item * datatypes

=item * dom

The L<DOM|https://metacpan.org/pod/XML::LibXML> created by L<XML::LibXML>.

=item * lint

If set to false, the linting isn't done (default: true)

=back

=head1 WARNINGS

The ER model designed with Workbench is checked for:

=over 4

=item * duplicate indices

=item * duplicate table names

=item * duplicate column names in a table

=back

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
