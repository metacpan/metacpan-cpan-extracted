package Paymill::REST::Base;

use Moose::Role;
use MooseX::Types::URI qw(Uri);

with 'Paymill::REST::Operations::Find';
with 'Paymill::REST::Operations::List';
with 'Paymill::REST::Operations::Create';

use LWP::UserAgent;
use HTTP::Request;
use JSON::XS;

has type    => (is => 'ro', required => 1, isa => 'Str');
has debug   => (is => 'rw', required => 0, isa => 'Bool', default => 0);
has proxy   => (is => 'rw', required => 0, isa => Uri, coerce => 1);
has api_key => (is => 'ro', required => 1, isa => 'Str', default => sub {$Paymill::REST::PRIVATE_KEY});
has auth_netloc     => (is => 'rw', required => 0, isa => 'Str',  default => 'api.paymill.com:443');
has auth_realm      => (is => 'rw', required => 0, isa => 'Str',  default => 'Api Access');
has verify_hostname => (is => 'rw', required => 0, isa => 'Bool', default => 1);

has useragent => (
    is       => 'ro',
    required => 0,
    isa      => 'LWP::UserAgent',
    lazy     => 1,
    builder  => '_build_useragent',
    clearer  => '_reset_useragent',
);

has agent_name =>
    (is => 'rw', required => 0, isa => 'Str', default => sub { "Paymill::REST/" . $Paymill::REST::VERSION });
has base_url =>
    (is => 'rw', required => 0, isa => Uri, coerce => 1, default => sub { to_Uri('https://api.paymill.com/v2/') });

sub _build_item {
    my $self       = shift;
    my $item_attrs = shift;

    # Find type.  Coercing will not have ->type but _type as item attribute.
    my $item_type;
    $item_type = $self->type if $self->can('type');
    $item_type = delete $item_attrs->{_type} if exists $item_attrs->{_type};

    # Remove "data" root if it exists
    if (ref $item_attrs eq 'HASH' && exists $item_attrs->{data}) {
        $item_attrs = $item_attrs->{data};
    }

    # Deleting objects may result in no returned data (eg. deleting offers)
    return if ref $item_attrs eq 'ARRAY' && scalar @$item_attrs < 1;

    # Passing the factory to the item so it can call the API directly (eg. for delete)
    # For coercing, $self is not a blessed object so we need to create one.  This is
    # ugly because it's losing all custom settings.
    if (ref $self) {
        $item_attrs->{_factory} = $self;
    } else {
        my $factory = 'Paymill::REST::' . ucfirst($item_type) . 's';
        $item_attrs->{_factory} = $factory->new;
    }

    # Remove empty attributes because of validation
    foreach (keys %$item_attrs) {
        delete $item_attrs->{$_} unless defined $item_attrs->{$_};
    }

    # Create new instance
    my $module        = 'Paymill::REST::Item::' . ucfirst($item_type);
    my $item_instance = $module->new($item_attrs);

    return $item_instance;
}

sub _build_items {
    my $self         = shift;
    my $hashed_items = shift;
    my $type         = shift;    # optional, for coercing

    $type = $self->type if $self->can('type');

    # Remove "data" root if it exists
    if (ref $hashed_items eq 'HASH' && exists $hashed_items->{data}) {
        $hashed_items = $hashed_items->{data};
    }

    my @items;
    foreach my $item_attrs (@$hashed_items) {

        # Some objects are empty and only return the identifier for the object
        unless (ref $item_attrs) {
            $item_attrs = { id => $item_attrs };
        }

        # Build single item
        push @items, $self->_build_item({ %$item_attrs, _type => $type });
    }

    # Return how the caller want it
    return wantarray ? @items : \@items;
}

sub _build_useragent {
    my $self = shift;
    my $ua   = LWP::UserAgent->new;

    $self->_debug("New user agent " . $self->agent_name);
    $ua->agent($self->agent_name);

    if ($self->proxy) {
        $self->_debug("Using https proxy " . $self->proxy);
        $ua->proxy('https', $self->proxy);
    }

    $self->_debug("Authenticate with " . $self->api_key);
    $ua->credentials($self->auth_netloc, $self->auth_realm, $self->api_key, '');

    $ua->ssl_opts(verify_hostname => $self->verify_hostname);

    return $ua;
}

sub _get_response {
    my $self   = shift;
    my $params = shift;

    my $uri    = $params->{uri} || die "No URI given!";
    my $method = $params->{method};
    my $query  = $params->{query} ? $params->{query} : undef;

    $self->useragent->requests_redirectable([]) if $params->{noredirect};

    my $res;

    $self->_debug("New request, URI is $uri");
    my $req = HTTP::Request->new;
    $req->header(Accept => 'application/json');
    $req->content_type('application/json');
    $req->uri($uri);

    if ($query) {
        $self->_debug("Adding params: " . encode_json($query));
        $req->uri->query_form($query);
    }

    if (defined $method && $method) {
        $self->_debug("Explicit method $method");
        $req->method($method);
    } else {
        $req->method('GET');
    }

    $res = $self->useragent->request($req);
    $self->_reset_useragent;

    unless ($res->is_success) {
        $self->_debug("Request unsuccessful: " . $res->code);
        $self->_debug("Content: '" . $res->content . "'");
        die "Request error: " . $res->status_line . "\n";
    } else {
        $self->_debug("Request successful: " . $res->code);
        $self->_debug("Content: '" . $res->content . "'");
        if ($res->content !~ /^\s*$/) {
            return decode_json($res->content);
        } else {
            return undef;
        }
    }
}

=head2 _debug

Parameters:

=over

=item C<@msgs>

=back

Small debug message handler that C<warn>s C<@msgs> joined with a line break.  Only prints if C<debug> set to C<true>.

=cut

sub _debug {
    my $self = shift;
    warn "[" . localtime . "] " . join("\n", @_) . "\n" if $self->debug;
}

no Moose::Role;
1;
__END__

=encoding utf-8

=head1 NAME

Paymill::REST - Base class for item factories

=head1 SEE ALSO

L<Paymill::REST> for documentation.

=head1 AUTHOR

Matthias Dietrich E<lt>perl@rainboxx.deE<gt>

=head1 COPYRIGHT

Copyright 2013 - Matthias Dietrich

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.