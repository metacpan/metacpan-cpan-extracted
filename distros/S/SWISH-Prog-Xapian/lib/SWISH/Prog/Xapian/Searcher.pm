package SWISH::Prog::Xapian::Searcher;
use strict;
use warnings;
use base qw( SWISH::Prog::Searcher );
use Carp;
use Sort::SQL;
use SWISH::Prog::Xapian::Results;
use Search::Xapian::MultiValueSorter;
use SWISH::3 ':constants';
use Search::Query;

__PACKAGE__->mk_ro_accessors(qw( prop_id_map ));

our $VERSION = '0.09';

=head1 NAME

SWISH::Prog::Xapian::Searcher - Swish3 Xapian backend Searcher

=head1 SYNOPSIS

 # see SWISH::Prog::Searcher
 
=cut

=head1 DESCRIPTION

SWISH::Prog::Xapian::Searcher is not made to replace the more fully-featured
Search::Xapian. Instead, SWISH::Prog::Xapian::Searcher
provides a simple API similar to other SWISH::Prog::Searcher-based backends
so that you can experiment with alternate
storage engines without needing to change much code.
When your search application requirements become more complex, the author
recommends the switch to using Search::Xapian directly.

=head1 METHODS

Only new and overridden methods are documented here. See
the L<SWISH::Prog::Searcher> documentation.

=cut

=head2 init( I<params> )

Overrides superclass to build map of PropertyNames to ids, since
Xapian stores values by id not name.

=cut

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    $self->{prop_id_map} = $self->_build_prop_id_map();
    return $self;
}

sub _build_prop_id_map {
    my $self = shift;

    # load meta from the first invindex
    my $invindex = $self->invindex->[0];
    my $config   = $invindex->meta;
    my $props    = $config->PropertyNames;

    # initialize with built-ins
    my %map    = ();
    my %fields = %{ SWISH_DOC_FIELDS_MAP() };
    my %props  = %{ SWISH_DOC_PROP_MAP() };
    for my $p ( keys %props ) {
        my $field = $props{$p};
        my $id    = $fields{$field};
        $map{$p} = $id;
    }

    # add custom defined
    for my $name ( keys %$props ) {
        $map{$name} = $props->{$name}->{id};
    }
    return \%map;
}

=head2 prop_id_map 

Get the read-only internal map for PropertyNames to id values.

=head2 search( I<query> [, I<opts> ] )

Returns a SWISH::Prog::Xapian::Results object.

I<opts> is an optional hashref with the following supported
key/values:

=over

=item start

The starting position. Default is 0.

=item max

The ending position. Default is max_hits().

=item order

The sort order. Default is by score.
B<This feature is not yet supported.>

=item get_facets

If set to an array ref of field names, then the Results object
will contain a hash ref of facet counts for those fields.

=item facet_sample

How many results to examine when counting facets. Default is all
of them.

=back

=cut

sub search {
    my $self  = shift;
    my $query = shift;
    croak "query required" unless defined $query;
    my $opts = shift || {};

    my $start        = $opts->{start}        || 0;
    my $max          = $opts->{max}          || $self->max_hits;
    my $order        = $opts->{order}        || 'score';
    my $get_facets   = $opts->{get_facets}   || 0;
    my $facet_sample = $opts->{facet_sample} || 0;

    #warn Data::Dump::dump $self;

    # we enquire on one db but can span multiple.
    my $db1 = $self->{invindex}->[0]->{xdb};
    for my $xdb ( map { $_->{xdb} } ( @{ $self->{invindex} } )[ 1 .. -1 ] ) {
        $db1->add_database($xdb);
    }
    my $parsed_query = Search::Query->parser->parse($query);
    my $enq          = $db1->enquire($query);

    # sorting
    if ($order) {
        if ( ref $order ) {

            # assume it is a MultiValueSorter object
            $enq->set_sort_by_key( $order, 1 );
        }
        else {

            my $sorter     = Search::Xapian::MultiValueSorter->new();
            my $pmap       = $self->{prop_id_map};
            my $sort_array = Sort::SQL->parse($order);
            my @rules;
            for my $pair (@$sort_array) {
                my ( $field, $dir ) = @$pair;
                next if $field eq 'score';
                my $prop_id = $pmap->{$field};
                if ( !defined $prop_id ) {
                    croak "Invalid PropertyName in sort: $field";
                }
                $sorter->add( $prop_id, ( uc($dir) eq 'ASC' ? 0 : 1 ) );
            }
            $enq->set_sort_by_key( $sorter, 1 );
        }
    }

    my $mset;
    my %facets;
    if ($get_facets) {
        my $pmap = $self->{prop_id_map};
        my $i    = 0;
        $mset = $enq->get_mset(
            $start, $max,
            sub {

                my ($doc) = @_;
                return $doc if $facet_sample and $facet_sample > ++$i;

                for my $facet (@$get_facets) {
                    for my $value (
                        split( /\003/, $doc->get_value( $pmap->{$facet} ) ) )
                    {
                        $facets{$facet}->{$value}++;
                    }
                }
                return $doc;
            }
        );
    }
    else {
        $mset = $enq->get_mset( $start, $max );
    }
    my $results = SWISH::Prog::Xapian::Results->new(
        hits        => $mset->size(),
        mset        => $mset,
        query       => $parsed_query,
        prop_id_map => $self->{prop_id_map},
        facets      => \%facets,
    );
    $results->{_i} = 0;
    return $results;
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan dot org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-swish-prog-xapian at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SWISH-Prog-Xapian>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SWISH::Prog::Xapian

You can also look for information at:

=over 4

=item * Mailing list

L<http://lists.swish-e.org/listinfo/users>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SWISH-Prog-Xapian>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SWISH-Prog-Xapian>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SWISH-Prog-Xapian>

=item * Search CPAN

L<http://search.cpan.org/dist/SWISH-Prog-Xapian>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Peter Karman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
