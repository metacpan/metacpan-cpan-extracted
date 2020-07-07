package MySQL::Workbench::Parser::Index;

# ABSTRACT: An index of the ER model

use strict;
use warnings;

use Moo;
use Scalar::Util qw(blessed);

our $VERSION = '1.10';


has node => (
    is       => 'ro',
    required => 1,
    isa      => sub {
        blessed $_[0] && $_[0]->isa( 'XML::LibXML::Element' );
    },
);

has table => (
    is       => 'ro',
    required => 1,
    isa      => sub {
        blessed $_[0] && $_[0]->isa( 'MySQL::Workbench::Parser::Table' );
    },
);


sub BUILD {
    my $self = shift;
    $self->_parse;
}

has id   => ( is => 'rwp' );
has name => ( is => 'rwp' );
has type => ( is => 'rwp' );

has columns => (
    is  => 'rwp',
    isa => sub {
        ref $_[0] && ref $_[0] eq 'ARRAY';
    },
    lazy    => 1,
    default => sub { [] },
);


sub as_hash {
    my $self = shift;

    my %info;

    for my $attr ( qw(name type columns) ) {
        $info{$attr} = $self->$attr();
    }

    return \%info;
}

sub _parse {
    my $self = shift;

    my $node = $self->node;

    for my $key ( qw(id) ) {
        my $value  = $node->findvalue( './value[@key="' . $key . '"]' );
        my $method = $self->can( '_set_' . $key );
        $self->$method( $value );
    }

    my $mapping    = $self->table->column_mapping;
    my @column_ids = map{ $_->textContent }$node->findnodes( './/link[@key="referencedColumn"]' );
    my @columns    = map{ $mapping->{$_} }@column_ids;
    $self->_set_columns( \@columns );

    my $name = $node->findvalue( './value[@key="name"]' );
    $self->_set_name( $name );

    my $type = $node->findvalue( './/value[@key="indexType"]' );
    $self->_set_type( $type );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MySQL::Workbench::Parser::Index - An index of the ER model

=head1 VERSION

version 1.10

=head1 METHODS

=for Pod::Coverage BUILD

=head2 as_hash

return info about a column as a hash

    my %info = $index->as_hash;

returns

    (
        name          => 'id',
        columns       => ['col1','col2'],
        type          => 'INDEX', # 'UNIQUE'
    )

=head1 ATTRIBUTES

=over 4

=item * id

=item * name

=item * node

=item * table

=item * type

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
