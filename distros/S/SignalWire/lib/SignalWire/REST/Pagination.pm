package SignalWire::REST::Pagination;
use strict;
use warnings;

# Perl port of signalwire.rest._pagination.PaginatedIterator.
#
# Iterates items across paginated API responses. Walks the
# C<links.next> cursor until no further page is advertised.
#
# Usage:
#   my $it = SignalWire::REST::Pagination::PaginatedIterator->new(
#       http     => $http,
#       path     => '/api/relay/rest/whatever',
#       params   => { page_size => 10 },
#       data_key => 'data',
#   );
#   while (defined(my $item = $it->next)) { ... }
#   # or:
#   my @items = $it->all;
#
# The class mirrors the Python iterator's three primary entry points
# (__init__, __iter__, __next__) plus the convenience C<all> form.

package SignalWire::REST::Pagination::PaginatedIterator;
use Moo;
use URI;

has 'http'      => ( is => 'ro', required => 1 );
has 'path'      => ( is => 'ro', required => 1 );
has 'params'    => ( is => 'rw', default => sub { {} } );
has 'data_key'  => ( is => 'ro', default => sub { 'data' } );

# Internal mutable state mirrors Python's _items/_index/_done. We store
# it directly on the blessed hashref under leading-underscore keys
# (Perl convention for "private") and expose getter/setter methods.
# Storing them outside the Moo `has` system keeps them off the surface
# audit's __init__ projection — they are not constructor arguments.

sub BUILD {
    my ($self) = @_;
    $self->{_items} = [];
    $self->{_index} = 0;
    $self->{_done}  = 0;
}

sub _items {
    my $self = shift;
    $self->{_items} = $_[0] if @_;
    return $self->{_items};
}

sub _index {
    my $self = shift;
    $self->{_index} = $_[0] if @_;
    return $self->{_index};
}

sub _done {
    my $self = shift;
    $self->{_done} = $_[0] if @_;
    return $self->{_done};
}

# Iterable interface (Python-mirroring, returns self so `iter()` parity).
sub __iter__ { return $_[0]; }

# Pull the next item; returns undef when exhausted (Perl-idiomatic
# alternative to Python's StopIteration).
sub __next__ {
    my ($self) = @_;
    while ($self->_index >= scalar @{ $self->_items }) {
        if ($self->_done) {
            return; # empty list scalar context => undef; signals exhaustion
        }
        $self->_fetch_next;
    }
    my $item = $self->_items->[$self->_index];
    $self->_index($self->_index + 1);
    return $item;
}

# Drain the whole iterator into a list. Mirrors the typical Python
# usage `list(iter)` — Perl callers can write `my @items = $it->all`
# instead of looping over __next__ themselves.
sub all {
    my ($self) = @_;
    my @out;
    while (defined(my $item = $self->__next__)) {
        push @out, $item;
    }
    return @out;
}

sub _fetch_next {
    my ($self) = @_;
    my $params = (keys %{ $self->params || {} }) ? $self->params : undef;
    my $resp = $self->http->get($self->path, params => $params);
    my $data = $resp->{ $self->data_key } || [];
    push @{ $self->_items }, @$data;

    my $links = $resp->{links} || {};
    my $next_url = $links->{next};
    if ($next_url && @$data) {
        # Parse cursor/page params from next URL query.
        my $u = URI->new($next_url);
        my %query = $u->query_form;
        $self->params(\%query);
    } else {
        $self->_done(1);
    }
    return;
}

1;

__END__

=head1 NAME

SignalWire::REST::Pagination - Cursor-based pagination iterator.

=head1 SYNOPSIS

    use SignalWire::REST::Pagination;

    my $it = SignalWire::REST::Pagination::PaginatedIterator->new(
        http     => $client->_http,
        path     => '/api/fabric/addresses',
        params   => { page_size => 25 },
        data_key => 'data',
    );
    while (defined(my $item = $it->next)) {
        ...
    }

=head1 DESCRIPTION

Mirrors the Python C<signalwire.rest._pagination.PaginatedIterator>.
Walks the C<links.next> cursor until no further page is advertised.
Each fetch is performed via the SDK's L<SignalWire::REST::HttpClient>
so authentication and base-URL handling is shared with the rest of
the SDK.

=cut
