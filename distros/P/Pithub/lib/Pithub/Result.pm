package Pithub::Result;
our $AUTHORITY = 'cpan:PLU';

# ABSTRACT: Github v3 result object

use Moo;

our $VERSION = '0.01043';

use Pithub::ResultSet ();
use JSON::MaybeXS     qw( JSON );
use URI               ();
use Carp              qw( confess croak );

sub _isa_isa_maker {
    my $class = shift;
    return sub {
        confess "must be an instance of $class but isn't a reference"
            if !ref $_[0];
        confess "must be an instance of $class, but is a " . ref $_[0]
            unless eval { $_[0]->isa($class) };
    };
}


has 'auto_pagination' => (
    default => sub { 0 },
    is      => 'rw',
);


has 'content' => (
    builder => '_build_content',
    clearer => 'clear_content',
    is      => 'ro',
    lazy    => 1,
);


has 'first_page_uri' => (
    builder => '_build_first_page_uri',
    clearer => 'clear_first_page_uri',
    is      => 'ro',
    lazy    => 1,
);


has 'last_page_uri' => (
    builder => '_build_last_page_uri',
    clearer => 'clear_last_page_uri',
    is      => 'ro',
    lazy    => 1,
);


has 'next_page_uri' => (
    builder => '_build_next_page_uri',
    clearer => 'clear_next_page_uri',
    is      => 'ro',
    lazy    => 1,
);


has 'prev_page_uri' => (
    builder => '_build_prev_page_uri',
    clearer => 'clear_prev_page_uri',
    is      => 'ro',
    lazy    => 1,
);


has 'response' => (
    handles => {
        code        => 'code',
        raw_content => 'content',
        request     => 'request',
        success     => 'is_success',
    },
    is       => 'ro',
    isa      => _isa_isa_maker('HTTP::Response'),
    required => 1,
);


# required for next_page etc
has '_request' => (
    is  => 'ro',
    isa => sub {
        croak 'must be a coderef, but is ' . ref $_[0]
            unless ref $_[0] eq 'CODE';
    },
    required => 1,
);

# required for next
has '_iterator' => (
    builder => '_build__iterator',
    clearer => '_clear_iterator',
    is      => 'ro',
    isa     => _isa_isa_maker(Pithub::ResultSet::),
    lazy    => 1,
);


has 'utf8' => (
    is      => 'ro',
    default => 1,
);

has '_json' => (
    builder => '_build__json',
    is      => 'ro',
    isa     => sub {
        confess "$_[0] is not a suitable JSON object"
            unless eval { $_[0]->can('decode') };
    },
    lazy => 1,
);


sub count {
    my ($self) = @_;
    return 0 unless $self->success;
    my $content = $self->content;
    if ( ref $content eq 'HASH' && scalar keys %$content == 0 ) {
        return 0;
    }
    return $self->_iterator->getLength;
}


sub first {
    my ($self) = @_;
    my $content = $self->content;
    if ( ref $content eq 'ARRAY' ) {
        return $content->[0];
    }
    return $content;
}


sub first_page {
    my ($self) = @_;
    return unless $self->first_page_uri;
    return $self->_paginate( $self->first_page_uri );
}


sub get_page {
    my ( $self, $page ) = @_;

    # First we need to get an URI we can work with and replace
    # the page GET parameter properly with the given value. If
    # we cannot get the first or last page URI, then there is
    # only one page.
    my $uri_str = $self->first_page_uri || $self->last_page_uri;
    return unless $uri_str;

    my $uri   = URI->new($uri_str);
    my %query = $uri->query_form;

    $query{page} = $page;

    my $options = {
        prepare_request => sub {
            my ($request) = @_;
            %query = ( $request->uri->query_form, %query );
            $request->uri->query_form(%query);
        },
    };

    return $self->_request->(
        method  => 'GET',
        path    => $uri->path,
        options => $options,
    );
}


sub last_page {
    my ($self) = @_;
    return unless $self->last_page_uri;
    return $self->_paginate( $self->last_page_uri );
}


## no critic (Subroutines::ProhibitBuiltinHomonyms)
sub next {
    my ($self) = @_;
    my $row = $self->_iterator->getNext;
    return $row if $row;
    if ( $self->auto_pagination ) {
        my $result = $self->next_page;
        return unless $result;
        $self->_reset;
        $self->{response} = $result->response;
        return $self->_iterator->getNext;
    }
    return;
}
## use critic


sub next_page {
    my ($self) = @_;
    return unless $self->next_page_uri;
    return $self->_paginate( $self->next_page_uri );
}


sub prev_page {
    my ($self) = @_;
    return unless $self->prev_page_uri;
    return $self->_paginate( $self->prev_page_uri );
}


sub etag {
    my ($self) = @_;
    return $self->response->header('ETag');
}


sub ratelimit {
    my ($self) = @_;
    return $self->response->header('X-RateLimit-Limit');
}


sub ratelimit_remaining {
    my ($self) = @_;
    return $self->response->header('X-RateLimit-Remaining');
}

sub _build_content {
    my ($self) = @_;
    if ( $self->raw_content ) {
        return $self->_json->decode( $self->raw_content );
    }
    return {};
}

sub _build_first_page_uri {
    return shift->_get_link_header('first');
}

sub _build__iterator {
    my ($self) = @_;
    my $content = $self->content;
    $content = [$content] unless ref $content eq 'ARRAY';
    return Pithub::ResultSet->new($content);
}

sub _build_last_page_uri {
    return shift->_get_link_header('last');
}

sub _build_next_page_uri {
    return shift->_get_link_header('next');
}

sub _build_prev_page_uri {
    return shift->_get_link_header('prev');
}

sub _build__json {
    my ($self) = @_;
    return JSON->new->utf8( $self->utf8 );
}

sub _get_link_header {
    my ( $self, $type ) = @_;
    return $self->{_get_link_header}{$type}
        if $self->{_get_link_header}{$type};
    my $link = $self->response->header('Link');
    return unless $link;
    return unless $link =~ /(next|first|last|prev)/;
    foreach my $item ( split /,/, $link ) {
        my @result = $item =~ /<([^>]+)>; rel="([^"]+)"/g;
        next if !$result[1] || !$result[0];
        $self->{_get_link_header}{ $result[1] } = $result[0];
    }
    return $self->{_get_link_header}{$type};
}

sub _paginate {
    my ( $self, $uri_str ) = @_;
    my $uri     = URI->new($uri_str);
    my $options = {
        prepare_request => sub {
            my ($request) = @_;
            my %query = ( $request->uri->query_form, $uri->query_form );
            $request->uri->query_form(%query);
        },
    };
    return $self->_request->(
        method  => 'GET',
        path    => $uri->path,
        options => $options,
    );
}

sub _reset {
    my ($self) = @_;
    $self->clear_content;
    $self->clear_first_page_uri;
    $self->clear_last_page_uri;
    $self->clear_next_page_uri;
    $self->clear_prev_page_uri;
    $self->_clear_iterator;
    delete $self->{_get_link_header};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pithub::Result - Github v3 result object

=head1 VERSION

version 0.01043

=head1 DESCRIPTION

Every method call which maps directly to a Github API call returns a
L<Pithub::Result> object. Once you got the result object, you can
set L<attributes|/ATTRIBUTES> on them or call L<methods|/METHODS>.

=head1 ATTRIBUTES

=head2 auto_pagination

If you set this to true and use the L</next> method to iterate
over the result rows, it will call automatically L</next_page>
for you until you got all the results. Be careful using this
feature, if there are 100 pages, this will make 100 API calls.
By default it's off. Instead of setting it per L<Pithub::Result>
you can also set it directly on any of the L<Pithub> API objects.

Examples:

    my $r = Pithub::Repos->new;
    my $result = $r->list( user => 'rjbs' );

    # This would just show the first 30 by default
    while ( my $row = $result->next ) {
        printf "%s: %s\n", $row->{name}, $row->{description};
    }

    # Let's do the same thing using auto_pagination to fetch all
    $result = $r->list( user => 'rjbs' );
    $result->auto_pagination(1);
    while ( my $row = $result->next ) {
        printf "%s: %s\n", $row->{name}, $row->{description};
    }

    # Turn auto_pagination on for all L<Pithub::Result> objects
    my $p = Pithub::Repos->new( auto_pagination => 1 );
    my $result = $p->list( user => 'rjbs' );
    while ( my $row = $result->next ) {
        printf "%s: %s\n", $row->{name}, $row->{description};
    }

=head2 content

The decoded JSON response. May be an arrayref or hashref, depending
on the API call. For some calls there is no content at all.

=head2 first_page_uri

The extracted value from the C<< Link >> header for the first page.
This can return undef.

=head2 last_page_uri

The extracted value from the C<< Link >> header for the last page.
This can return undef.

=head2 next_page_uri

The extracted value from the C<< Link >> header for the next page.
This can return undef.

=head2 prev_page_uri

The extracted value from the C<< Link >> header for the previous
page. This can return undef.

=head2 response

The L<HTTP::Response> object.

=head2 utf8

This can set utf8 flag.

=head1 METHODS

=head2 raw_content

Returns the content of the API response as a string, it will probably
be JSON.

=head2 request

Returns the L<HTTP::Request> object used to make the API call.

=head2 code

Returns the HTTP code from the API call.

=head2 success

Returns whether the API call was successful.

=head2 count

Returns the count of the elements in L</content>. If the result is
not an arrayref but a hashref, it will still return C<< 1 >>. Some
calls return an empty hashref, for those calls it returns C<< 0 >>.

=head2 first

Return the first element from L</content> if L</content> is an
arrayref. If it's a hashref, it returns just that.

=head2 first_page

Get the L<Pithub::Result> of the first page. Returns undef if there
is no first page (if you're on the first page already or if there
is no pages at all).

=head2 get_page

Get the L<Pithub::Result> for a specific page. The parameter is not
validated, if you hit a page that does not exist, the Github API will
tell you so. If there is only one page, this method will return
undef, no matter which page you ask for, even for page 1.

=head2 last_page

Get the L<Pithub::Result> of the last page. Returns undef if there
is no last page (if you're on the last page already or if there
is only one page or no pages at all).

=head2 next

Most of the results returned by the Github API calls are arrayrefs
of hashrefs. The data structures can be retrieved directly by
calling L</content>. Besides that it's possible to iterate over
the results using this method.

Examples:

    my $r = Pithub::Repos->new;
    my $result = $r->list( user => 'rjbs' );

    while ( my $row = $result->next ) {
        printf "%s: %s\n", $row->{name}, $row->{description};
    }

=head2 next_page

Get the L<Pithub::Result> of the next page. Returns undef if there
is no next page (there's only one page at all).

Examples:

=over

=item *

List all followers in order, from the first one on the first
page to the last one on the last page. See also
L</auto_pagination>.

    my $followers = Pithub->new->users->followers;
    my $result = $followers->list( user => 'rjbs' );
    do {
        if ( $result->success ) {
            while ( my $row = $result->next ) {
                printf "%s\n", $row->{login};
            }
        }
    } while $result = $result->next_page;

The nature of the implementation requires you here to do a
C<< do { ... } while ... >> loop. If you're going to fetch
all results of all pages, I suggest to use the
L</auto_pagination> feature, it's much more convenient.

=back

=head2 prev_page

Get the L<Pithub::Result> of the previous page. Returns undef if there
is no previous page (you're on the first page).

Examples:

=over

=item *

List all followers in reverse order, from the last one on the last
page to the first one on the first page. See also
L</auto_pagination>.

    my $followers = Pithub->new->users->followers;
    my $result = $followers->list( user => 'rjbs' )->last_page;    # this makes two requests!
    do {
        if ( $result->success ) {
            while ( my $row = $result->next ) {
                printf "%s\n", $row->{login};
            }
        }
    } while $result = $result->prev_page;

=back

=head2 etag

Returns the value of the C<< ETag >> http header.

=head2 ratelimit

Returns the value of the C<< X-Ratelimit-Limit >> http header.

=head2 ratelimit_remaining

Returns the value of the C<< X-Ratelimit-Remaining >> http header.

=head1 AUTHOR

Johannes Plunien <plu@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Johannes Plunien.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
