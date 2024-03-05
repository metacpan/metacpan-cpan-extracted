package Net::PaccoFacile {
    use Moo;
    use Mojo::UserAgent;
    use Carp qw/croak confess/;
    use List::Util qw/first/;
    use Mojo::Util qw/url_escape url_unescape/;
    use namespace::clean;
    use version;
    use v5.36;

    our $VERSION = qv("v0.1.0");

    has endpoint_uri => ( is => 'ro', lazy => 1, default => sub {
        $_[0]->mode eq 'sandbox' ? $_[0]->endpoint_uri_sandbox : $_[0]->endpoint_uri_live
    } );
    has endpoint_uri_sandbox => ( is => 'ro', default => sub { 'https://paccofacile.tecnosogima.cloud/sandbox/v1/service/' } );
    has endpoint_uri_live => ( is => 'ro', default => sub { 'https://paccofacile.tecnosogima.cloud/live/v1/service/' } );
    has mode => ( is => 'ro' );
    has token => ( is => 'ro' );
    has api_key => ( is => 'ro' );
    has account_number => ( is => 'ro' );
    has request_timeout => ( is => 'ro', default => sub { 10 } );
    has connect_timeout => ( is => 'ro', default => sub { 7 } );
    has ua => ( is => 'ro', lazy => 1, default => sub {
        Mojo::UserAgent->new()->connect_timeout($_[0]->connect_timeout)->inactivity_timeout($_[0]->request_timeout)
    } );

    sub BUILD {
        my ($self, $args) = @_;

        croak 'Please provide token' if !exists $args->{token};
        croak 'Please provide api_key' if !exists $args->{api_key};
        croak 'Please provide account_number' if !exists $args->{account_number};
        croak 'Please provide mode (sandbox or live)'
	        if $args->{mode} ne 'sandbox' && $args->{mode} ne 'live';
    }

    sub request($self, $path, $method, $args = {}) {
        croak 'Please provide path' if !defined $path;
        croak 'Invalid path' if $path !~ m/\w+/xs;
        $method = $self->_validate_method($method);

        my $reqargs = {
            %$args,
        };

        my $datatransport = $method eq 'get' ? 'form' : 'json';

        # die $self->endpoint_uri . "$path";
        # use Data::Dump qw/dump/; die dump($reqargs);
        my $res = $self->ua->$method( $self->endpoint_uri . "$path" =>
            {
                Authorization => 'Bearer ' . $self->token,
                'Account-Number' => $self->account_number,
                'api-key' => $self->api_key,
            },
            $datatransport => $reqargs
        )->result;
        croak $res->message .': ' . $res->body if !$res->is_success;

        return $res->json;
    }

    sub _validate_method($self, $method) {
        confess 'Invalid-method' if !defined first { $_ eq uc($method) } qw/GET POST PUT DELETE/;
        return lc $method;
    }
}

1;

=head1 NAME

Net::PaccoFacile - Perl library with MINIMAL interface to use PaccoFacile API.

=head1 SYNOPSIS

    use Net::PaccoFacile;
    use Data::Dump qw/dump/;

    my $pf = Net::PaccoFacile->new(
        mode            => 'live',
        token           => 'xxxx',
        api_key         => 'yyy',
        account_number  => '01234',
    );

    my $res;

    $res = $pf->request('carriers', 'get');
    say dump($res);

    $res = $pf->request('address-book', 'get');
    say dump($res);

    $res = $pf->request('shipment/quote', 'post', { 
        "shipment_service" => {
            "parcels" => [{
                "shipment_type" => 1,
                "dim1" => 10,
                "dim2" => 11,
                "dim3" => 12,
                "weight" => 2
            }],
            "accessories" => [],
            "package_content_type" => "GOODS"
        },
        "pickup" => {
            "iso_code" => "IT",
            "postal_code" => "04011",
            "city" => "Aprilia",
            "StateOrProvinceCode" => "LT"
        },
        "destination" => {
            "iso_code" => "IT",
            "postal_code" => "00135",
            "city" => "Roma",
            "StateOrProvinceCode" => "RM"
        },
    });

    say dump($res);

=head1 DESCRIPTION

This is HIGHLY EXPERIMENTAL and in the works, do not use for now.

=head1 AUTHOR

Michele Beltrame, C<mb@blendgroup.it>

=head1 LICENSE

This library is free software under the Artistic License 2.0.

=cut
