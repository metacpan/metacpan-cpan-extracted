package Search::OpenSearch::Response;
use Moose;
use Types::Standard
    qw( Int Str Num ArrayRef HashRef InstanceOf Maybe Object Bool );
use Carp;
use Data::Pageset;
use overload
    '""'     => sub { $_[0]->stringify; },
    'bool'   => sub {1},
    fallback => 1;

use namespace::autoclean;

has 'engine' => ( is => 'rw', isa => Maybe [Str] );
has 'results' => ( is => 'rw', isa => ArrayRef );
has 'total'   => ( is => 'rw', isa => Int );
has 'offset'  => ( is => 'rw', isa => Maybe [Int], builder => 'init_offset' );
has 'page_size' =>
    ( is => 'rw', isa => Maybe [Int], builder => 'init_page_size' );
has 'fields' => ( is => 'rw', isa => Maybe [ArrayRef] );
has 'facets' => ( is => 'rw', isa => Maybe [HashRef] );
has 'query'  => (
    is  => 'rw',
    isa => Maybe [ Str | InstanceOf ['Search::Query::Dialect'] ]
);
has 'parsed_query' => (
    is  => 'rw',
    isa => Maybe [ Str | InstanceOf ['Search::Query::Dialect'] ]
);
has 'json_query' => ( is => 'rw', isa => Str );
has 'title' => ( is => 'rw', isa => Maybe [Str], builder => 'init_title', );
has 'link'   => ( is => 'rw', isa => Maybe [Str], builder => 'init_link' );
has 'author' => ( is => 'rw', isa => Maybe [Str], builder => 'init_author' );
has 'search_time' => ( is => 'rw', isa => Num );
has 'build_time'  => ( is => 'rw', isa => Num );
has 'sort_info'   => ( is => 'rw', isa => Str );
has 'version'     => ( is => 'rw', isa => Str, builder => 'get_version' );
has 'suggestions' => ( is => 'rw', isa => ArrayRef );
has 'debug' =>
    ( is => 'rw', isa => Bool, default => sub { $ENV{SOS_DEBUG} || 0 } );
has 'pps' => ( is => 'rw', isa => Maybe [Int], default => sub {10} );
has 'error' => ( is => 'rw', isa => Maybe [Str] );
has 'attr_blacklist' =>
    ( is => 'rw', isa => HashRef, builder => 'init_attr_blacklist' );
has 'mtime_field' =>
    ( is => 'rw', isa => Str, builder => 'init_mtime_field' );

our $VERSION = '0.409';

sub init_attr_blacklist {
    return {
        error          => 1,
        debug          => 1,
        attr_blacklist => 1,
        pps            => 1,
        mtime_field    => 1,
    };
}

sub init_mtime_field { return 'mtime' }

sub default_fields {
    return [qw( uri title summary mtime score )];
}

sub get_version {
    my $self = shift;
    my $class = ref $self ? ref($self) : $self;
    no strict 'refs';
    return ${"${class}::VERSION"};
}

sub init_author {
    my $self = shift;
    return ref($self);
}

sub init_title     {'OpenSearch Results'}
sub init_link      {''}
sub init_offset    {0}
sub init_page_size {10}

sub stringify { croak "$_[0] does not implement stringify()" }

sub as_hash {
    my $self = shift;
    my %hash;
    my %class_attrs = map { $_->name => $_ } $self->meta->get_all_attributes;
    for my $attr ( keys %class_attrs ) {
        next if exists $self->attr_blacklist->{$attr};
        $hash{$attr} = $self->$attr;
    }
    $hash{updated} = $self->get_mtime();
    return \%hash;
}

sub get_mtime {
    my $self   = shift;
    my $field  = $self->mtime_field;
    my $recent = 0;
    for my $r ( @{ $self->results || [] } ) {
        next unless ref $r eq 'HASH';
        my $mtime = $r->{$field};
        if ( $mtime > $recent ) {
            $recent = $mtime;
        }
    }
    return $recent;
}

sub build_pager {
    my $self      = shift;
    my $offset    = $self->offset;
    my $page_size = $self->page_size;
    my $this_page = ( $offset / $page_size ) + 1;
    my $pager     = Data::Pageset->new(
        {   total_entries    => $self->total,
            entries_per_page => $page_size,
            current_page     => $this_page,
            pages_per_set    => $self->pps,
            mode             => 'slide',
        }
    );
    return $pager;
}

sub add_attribute {
    my $self = shift;
    my $class = ref $self ? ref $self : $self;
    for my $attr (@_) {
        has $attr => ( is => 'rw', );
    }
}

1;

__END__

=head1 NAME

Search::OpenSearch::Response - provide search results in OpenSearch format

=head1 SYNOPSIS

 use Search::OpenSearch;
 my $engine = Search::OpenSearch->engine(
    type    => 'Lucy',
    index   => [qw( path/to/index1 path/to/index2 )],
    facets  => {
        names       => [qw( color size flavor )],
        sample_size => 10_000,
    },
    fields  => [qw( color size flavor )],
 );
 my $response = $engine->search(
    q           => 'quick brown fox',   # query
    s           => 'score desc',        # sort order
    o           => 0,                   # offset
    p           => 25,                  # page size
    h           => 1,                   # highlight query terms in results
    c           => 0,                   # return count stats only (no results)
    L           => 'field|low|high',    # limit results to inclusive range
    f           => 1,                   # include facets
    r           => 1,                   # include results
    format      => 'XML',               # or JSON
    b           => 'AND',               # or OR
 );
 print $response;

=head1 DESCRIPTION

Search::OpenSearch::Response is an abstract base class with some
common methods for all Response subclasses.

=head1 METHODS

This class is a subclass of Moose. Only new or overridden
methods are documented here.

=head2 get_version

Returns the package var $VERSION string by default.

=head2 new( I<params> )

The following standard get/set attribute methods are available:

=over

=item debug

=item results

An interator object behaving like SWISH::Prog::Results.

=item total

=item offset

=item page_size

=item fields

=item facets

=item query

=item parsed_query

As returned by Search::Query.

=item json_query

Same as parsed_query, but the object tree is JSON encoded instead
of stringified.

=item author

=item pps

Pages-per-section. Used by Data::Pageset. Default is "10".

=item title

=item link

=item search_time

=item build_time

=item engine

=item sort_info

=item version

=item suggestions

=item mtime_field

The results field to use for the last-modified logic in get_mtime().
The default is C<mtime>. The field value should be an integer.

=back

=head2 build_pager

Returns Data::Pageset object based on offset() and page_size().

=head2 as_hash

Returns the Response object as a hash ref of key/value pairs.

=head2 get_mtime

Returns an integer representing the most recent mtime of the
current set of results.

=head2 stringify

Returns the Response in the chosen serialization format.

Response objects are overloaded to call stringify().

=head2 add_attribute( I<attribute_name> )

Adds get/set method I<attribute_name> to the class and will include
that attribute in as_hash(). This method is intended to make it easier
to extend the basic structure without needing to subclass.

=head2 default_fields 

Returns array ref of default result field names. These are implemented
by the default Engine class.

=head2 error

Get/set error value for the Response. This value is not included
in the stringify() output, but can be used to set or check for
errors in processing.

=head2 init_author

Builder method for the B<author>.

=head2 init_title

Builder method for B<title>.

=head2 init_link

Builder method for B<link>.

=head2 init_offset

Builder method for B<offset>.

=head2 init_page_size

Builder method for B<page_size>.

=head2 init_attr_blacklist

Builder method for B<attr_blacklist>. This hashref of attribute names
registers which attributes are excluded by stringify().

=head2 init_mtime_field

Builder method for B<mtime_field>.

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-search-opensearch at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Search-OpenSearch>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::OpenSearch::Response


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-OpenSearch>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Search-OpenSearch>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Search-OpenSearch>

=item * Search CPAN

L<http://search.cpan.org/dist/Search-OpenSearch/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2010 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
