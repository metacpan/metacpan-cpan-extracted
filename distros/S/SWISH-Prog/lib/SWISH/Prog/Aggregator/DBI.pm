package SWISH::Prog::Aggregator::DBI;

use strict;
use warnings;
use base qw( SWISH::Prog::Aggregator );
use Carp;
use Data::Dump qw( dump );
use DBI;
use SWISH::Prog::Utils;

__PACKAGE__->mk_accessors(
    qw( db alias_columns schema use_quotes quote_char ));

our $VERSION = '0.75';

my $XMLer = Search::Tools::XML->new();    # included in Utils

=pod

=head1 NAME

SWISH::Prog::Aggregator::DBI - index DB records with Swish-e

=head1 SYNOPSIS
    
    use SWISH::Prog::Aggregator::DBI;
    use Carp;
    
    my $aggregator = SWISH::Prog::Aggregator::DBI->new(
        db => [
            "DBI:mysql:database=movies;host=localhost;port=3306",
            'some_user', 'some_secret_pass',
            {
                RaiseError  => 1,
                HandleError => sub { confess(shift) },
            }
        ],
        schema => {
          'moviesIlike' => {
               title       => {type => 'char', bias => 1},
               synopsis    => {type => 'char', bias => 1},
               year        => {type => 'int',  bias => 1},
               director    => {type => 'char', bias => 1},
               producer    => {type => 'char', bias => 1},
               awards      => {type => 'char', bias => 1},
               date        => {type => 'date', bias => 1},
               swishdescription => { synopsis => 1, producer => 1 },
               swishtitle       => 'title',
          }
        }
        use_quotes      => 1,
        quote_char      => '`', # backtick
        alias_columns   => 1,
        indexer         => SWISH::Prog::Indexer::Native->new,
    );
    
    $aggregator->crawl();


=head1 DESCRIPTION

SWISH::Prog::Aggregator::DBI is a SWISH::Prog::Aggregator subclass 
designed for providing full-text search for databases.

=head1 METHODS

Since SWISH::Prog::Aggregator::DBI inherits from SWISH::Prog::Aggregator, 
read that documentation first. Any overridden methods are documented here.

=head2 new( I<opts> )

Create new aggregator object. 

The following I<opts> are required:

=over

=item db => I<connect_info>

I<connect_info> is passed
directly to DBI's connect() method, so see the DBI docs for syntax.
If I<connect_info> is a DBI handle object, it is accepted as is.
If I<connect_info> is an array ref, it will be dereferenced and
passed to connect(). Otherwise it will be passed to connect as is.

=item schema => I<db_schema>

I<db_schema> is a hashref of table names and column descriptions.
Each key should be a table name. Each value should be a hashref of 
column descriptions, where the key is the column name and the value
is a hashref of type and bias. See the SYNOPSIS.

There are two special column names: swishtitle and swishdescription.
These are reserved for mapping real column names to Swish-e property names
for returning in search results. C<swishtitle> should be the name of a column,
and C<swishdescription> should be a hashref of column names to include
in the StoreDescription value.

=item indexer => I<indexer_obj>

A SWISH::Prog::Indexer-derived object.

=back

The following I<opts> are optional:

=over

=item alias_columns => 0|1

The C<alias_columns> flag indicates whether all columns should be searchable
under the default MetaName of C<swishdefault>. The default is 1 (true). This
is B<not> the default behaviour of swish-e; this is a feature of SWISH::Prog.

=item use_quotes

Boolean indicating whether column and table names should be quoted.
This is typically DBD-specific (e.g., MySQL requires this be true).
Default is true.

=item quote_char

The character to use when C<use_quotes> is true. Default is B<`> (backtick).

=back

B<NOTE:> The new() method simply inherits from SWISH::Prog::Aggregator, 
so any params valid for that method are allowed here.

=head2 init

See SWISH::Prog::Class. This method does all the setup.

=cut

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    $self->{use_quotes} = 1   unless defined $self->{use_quotes};
    $self->{quote_char} = '`' unless defined $self->{quote_char};

    # verify DBI connection
    if ( defined( $self->db ) ) {

        if ( ref( $self->db ) eq 'ARRAY' ) {
            $self->db( DBI->connect( @{ $self->{db} } ) );
        }
        elsif ( ref( $self->db ) && $self->db->isa('DBI::db') ) {

            # do nothing
        }
        else {
            $self->db( DBI->connect( $self->db ) );
        }
    }
    else {
        croak "db required";
    }

    # verify schema
    if ( defined $self->schema ) {

        my $schema = $self->schema;
        unless ( ref($schema) eq 'HASH' ) {
            croak "schema must be a hashref";
        }
        for my $table ( keys %$schema ) {
            my $cols = $schema->{$table};
            unless ( ref($cols) eq 'HASH' ) {
                croak "column descriptions must be a hashref";
            }
            for my $colname ( keys %$cols ) {
                my $desc = $cols->{$colname};
                if ( $colname eq 'swishtitle' ) {
                    if ( ref $desc ) {
                        croak "swishtitle must be a column name string";
                    }
                    next;
                }
                unless ( ref($desc) eq 'HASH' ) {
                    croak "$colname description must be a hashref";
                }
                $desc->{type}
                    ||= 'char'; # TODO auto-make property types based on this.
                $desc->{bias} ||= 1;
            }
        }
    }
    else {
        croak "schema required";
    }

    $self->{alias_columns} = 1 unless exists $self->{alias_columns};

    # unless metanames are defined, use all the column names from schema
    my $m = $self->config->MetaNames;
    unless (@$m) {
        for my $table ( keys %{ $self->{schema} } ) {
            my $columns = $self->{schema}->{$table};
            my %ranks;
            for my $col ( sort keys %$columns ) {
                next if $col eq 'swishtitle';
                next if $col eq 'swishdescription';
                push( @{ $ranks{ $columns->{$col}->{bias} } }, $col );
            }

            for my $rank ( keys %ranks ) {
                $self->config->MetaNamesRank(
                    "$rank " . join( ' ', @{ $ranks{$rank} } ), 1 );
            }
        }
    }

    # alias the top level tags to that default search
    # will match any metaname in any table
    if ( $self->alias_columns ) {
        $self->config->MetaNameAlias(
            'swishdefault '
                . join( ' ',
                map { '_' . $_ . '_row' }
                    sort
                    grep { $_ ne 'swishtitle' and $_ ne 'swishdescription' }
                    keys %{ $self->{schema} } ),
            1    # always append
        );
    }

    # add 'table' metaname
    $self->config->MetaNames('table');

    # save all row text in the swishdescription property for excerpts
    $self->config->StoreDescription('XML* <_desc>');

}

=head2 crawl

Create index.

Returns number of rows indexed.

=cut

sub crawl {
    my $self = shift;

    my @tables = sort keys %{ $self->{schema} };

T: for my $table (@tables) {

        my $table_info = $self->{schema}->{$table};

        # which columns to index
        my @cols
            = sort grep { $_ ne 'swishtitle' and $_ ne 'swishdescription' }
            keys %$table_info;

        # special col names
        my $desc  = delete( $table_info->{swishdescription} ) || {};
        my $title = delete( $table_info->{swishtitle} )       || '';

        my $quote_char = $self->use_quotes ? $self->quote_char : '';

        my $c = $self->_do_table(
            name => $table . ".index",
            sql  => "SELECT "
                . join( ",", map {qq/$quote_char$_$quote_char/} @cols )
                . " FROM $table",
            table => $table,
            desc  => $desc,
            title => $title,
        );
        $self->_increment_count($c);
    }

    return $self->{count};
}

sub _do_table {
    my $self = shift;
    my %opts = @_;

    if ( !$opts{sql} ) {
        croak "need SQL statement to index with";
    }

    $opts{table} ||= '';
    $opts{title} ||= '';

    my $counter = 0;
    my $indexer = $self->indexer;

    my $sth = $self->db->prepare( $opts{sql} )
        or croak "DBI prepare() failed: " . $self->db->errstr;
    $sth->execute or croak "SELECT failed " . $sth->errstr;

    while ( my $row = $sth->fetchrow_hashref ) {

        my $title = $row->{ $opts{title} } || '[ no title ]';

        my $xml = $self->_row2xml( $XMLer->tag_safe( $opts{table} ),
            $row, $title, \%opts );

        my $doc = $self->doc_class->new(
            content => $xml,
            url     => ++$counter,
            modtime => time(),
            parser  => 'XML*',
            type    => 'application/xml',
            data    => $row
        );

        $indexer->process($doc);
    }

    $sth->finish;

    return $counter;

}

sub _row2xml {
    my ( $self, $table, $row, $title, $opts ) = @_;

    my $xml
        = "<_${table}_row>"
        . "<table>"
        . $table
        . "</table>"
        . "<swishtitle>"
        . $XMLer->utf8_safe($title)
        . "</swishtitle>"
        . "<_body>";

    for my $col ( sort keys %$row ) {
        my @x = (
            $XMLer->start_tag($col),
            $XMLer->utf8_safe( $row->{$col} ),
            $XMLer->end_tag($col)
        );

        if ( $opts->{desc}->{$col} ) {
            unshift( @x, '<_desc>' );
            push( @x, '</_desc>' );
        }

        $xml .= join( '', @x );
    }
    $xml .= "</_body></_${table}_row>";

    #$self->debug and warn $xml . "\n";

    return $xml;
}

1;

__END__

=head1 AUTHOR

Peter Karman, E<lt>perl@peknet.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-swish-prog at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SWISH-Prog>.  
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SWISH::Prog


You can also look for information at:

=over 4

=item * Mailing list

L<http://lists.swish-e.org/listinfo/users>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SWISH-Prog>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SWISH-Prog>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SWISH-Prog>

=item * Search CPAN

L<http://search.cpan.org/dist/SWISH-Prog/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

L<http://swish-e.org/>
