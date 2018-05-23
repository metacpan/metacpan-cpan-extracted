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

our $VERSION = 1.00;

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
    builder => \&_parse,
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

sub dump {
    my $self = shift;

    my $tables = $self->tables;
    my %info;
    for my $table ( @{$tables} ) {
        push @{$info{tables}}, $table->as_hash;
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

sub _parse {
    my $self = shift;

    my $zip = Archive::Zip->new;
    unless ( $zip->read( $self->file ) == AZ_OK ) {
        croak "can't read file " . $self->file;
    }

    my $xml = $zip->contents( 'document.mwb.xml' );
    my $dom = XML::LibXML->load_xml( string => $xml );

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

             $datatypes{$name} = { name => $orig, length => $length, precision => $precision };
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

    $self->_set_tables( \@tables );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MySQL::Workbench::Parser - parse .mwb files created with MySQL Workbench

=head1 VERSION

version 1

=head1 SYNOPSIS

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

=head2 tables

returns an array of L<MySQL::Workbench::Parser::Table> objects

    my @tables = $parser->tables;

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

=item * file

=back

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
