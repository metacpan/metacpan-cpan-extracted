# This is for PAUSE
package Net::Topsy::Result;

use MooseX::Declare;

=head1 NAME

Net::Topsy::Result - Topsy Result Objects

=head1 SYNOPSIS

    use Net::Topsy;

    my $topsy  = Net::Topsy->new( key => $ENV{TOPSY_API_KEY} );
    my $result = $topsy->search({
                                    q => $search_term,
                                    page   =>  1,  # default
                                    perpage => 30, # 30 per page
                                    window => 'd', # today
                                });
    my $iter   = $result->iter;
    while ($iter->has_next) {
        my $item = $iter->next;
        printf "%-60s : %d : %s\n", $item->{title} ,$item->{hits}, $item->{url};
    }


Each API call to a Net::Topsy object returns an object that abstracts away some
of the intricacies of the raw data structure that is returned. The result of
an API call has some metadata associated with it, as well as an iterator that
allows you to access the list of data.

=head1 METHODS

=over

=item iter

    my $iter   = $result->iter;
    while ($iter->has_next) {
        my $item = $iter->next;
        ...
    }

Returns an iterator that is a subclass of MooseX::Iterator, which allows access
to the list of data that is the result of a Topsy API call.

=item page

    my $page = $result->page();

Returns the current page number of the results.

=item window

    my $window = $result->window();

Returns the single letter designation of the time window.

=item total

    my $total = $result->total();

Returns the total number of results.

=item perpage

    my $perpage = $result->perpage();

Returns the number of results "per page", i.e. the number of results in the list.

=item perl

    my $perl = $result->perl();

Returns the perl (hash reference) representation of the JSON that is returned by
the Topsy API.

=item json

    my $json = $result->json();

Returns the raw string of JSON that is returned by the Topsy API.

=item response

    my $r = $result->response();

Returns the HTTP::Response object that is returned by the Topsy API.

=item list

    my $list = $result->list();

Returns an array reference of hash references that is the raw representation of
what is returned by the Topsy API. You probably shouldn't mess with this, but
maybe you know what you are doing.

The structure of this list can change at any time, don't depend on it.

=back

=cut

class Net::Topsy::Result {
    use MooseX::Iterator;
    use Data::Dumper;
    use namespace::autoclean;

    # Result attributes
    has perl     => ( isa => 'HashRef',        is => 'rw', default => sub { [ ] } );
    has json     => ( isa => 'Str',            is => 'rw', default => '' );
    has response => ( isa => 'HTTP::Response', is => 'rw' );

    # properties of result that Topsy sends us
    has page     => ( isa => 'Int',      is => 'rw', default => 0 );
    has window   => ( isa => 'Str',      is => 'rw', default => '' );
    has total    => ( isa => 'Int',      is => 'rw', default => 0 );
    has perpage  => ( isa => 'Int',      is => 'rw', default => 10);
    has list     => ( isa => 'ArrayRef', is => 'rw', default => sub { [ ] } );

    has iter     => (
        metaclass    => 'Iterable',
        iterate_over => 'list',
    );

    method BUILD {
        for my $attr (qw/page window total list perpage/) {
            $self->$attr( $self->perl->{response}{$attr} ) if exists $self->perl->{response}{$attr};
        }
        return $self;
    }
}

=head1 AUTHOR

Jonathan Leto, C<< <jonathan at leto.net> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Jonathan Leto <jonathan@leto.net>, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
