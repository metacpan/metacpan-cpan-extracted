package Net::OpenStack::Swift::InnerKeystone::Base;
use Carp;
use Mouse;
use JSON;
use Furl;
use Data::Validator;
use namespace::clean -except => 'meta';

has auth_token      => ( is => 'rw' );
has service_catalog => ( is => 'rw' );
has auth_url        => ( is => 'rw', required => 1 );
has user            => ( is => 'rw', required => 1 );
has password        => ( is => 'rw', required => 1 );
has tenant_name     => ( is => 'rw' );

#has verify_ssl      => (is => 'ro', default => sub {! $ENV{OSCOMPUTE_INSECURE}});

has agent => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self  = shift;
        my $agent = Furl->new;
        return $agent;
    },
);

sub get_auth_params { die; }

sub service_catalog_url_for {
    my $self = shift;
    my $rule = Data::Validator->new(
        endpoint_type => {
            isa     => 'Str',
            default => sub { 'object-store' }
        },
        service_type => {
            isa     => 'Str',
            default => sub { 'publicURL' }
        },
        region => { isa => 'Str', default => undef },
    );
    my $args = $rule->validate(@_);

    my $found_endpoint;
    LOOP: foreach my $service_catelog ( @{ $self->service_catalog } ) {
        if ( $args->{service_type} eq $service_catelog->{type} ) {
            foreach my $endpoint ( @{ $service_catelog->{endpoints} } ) {
                if ( exists $endpoint->{ $args->{endpoint_type} } ) {
                    # check if the region matches or if there is no prefered region
                    if ( !$args->{region} or $args->{region} eq $endpoint->{region} ) {
                        $found_endpoint = $endpoint;
                        # we found it, stop searching
                        last LOOP;
                    }
                }
            }
        }
    }
    unless ($found_endpoint) {
        croak sprintf( "%s endpoint for %s service not found", $args->{endpoint_type}, $args->{service_type} );
    }
    return $found_endpoint->{ $args->{endpoint_type} };
}

package Net::OpenStack::Swift::InnerKeystone::V1_0;
use Carp;
use JSON;
use Mouse;
use namespace::clean -except => 'meta';

extends 'Net::OpenStack::Swift::InnerKeystone::Base';

sub get_auth_params {
    my $self = shift;
    return {
        auth => {
            tenantName          => 'no-needed',
            passwordCredentials => {
                username => $self->user,
                password => $self->password,
            }
        }
    };
}

sub auth {
    my $self = shift;
    my $res  = $self->agent->get(
        $self->auth_url,
        [
            'X-Auth-Key'  => $self->password,
            'X-Auth-User' => $self->user
        ]
    );
    croak "authorization failed: " . $res->status_line unless $res->is_success;
    my $url = $res->header('X-Storage-Url');
    $self->auth_token( $res->header('X-Auth-Token') );
    $self->service_catalog(
        [
            {
                type      => 'object-store',
                endpoints => [ { endpoint_type => 'publicURL', publicURL => $url } ]
            }
        ]
    );
    return $self->auth_token();
}

package Net::OpenStack::Swift::InnerKeystone::V2_0;
use Carp;
use JSON;
use Mouse;
use namespace::clean -except => 'meta';

extends 'Net::OpenStack::Swift::InnerKeystone::Base';

sub get_auth_params {
    my $self = shift;
    return {
        auth => {
            tenantName          => $self->tenant_name,
            passwordCredentials => {
                username => $self->user,
                password => $self->password,
            }
        }
    };
}

sub auth {
    my $self = shift;
    my $res  = $self->agent->post(
        $self->auth_url . "/tokens",
        [ 'Content-Type' => 'application/json' ],
        to_json( $self->get_auth_params ),
    );
    croak "authorization failed: " . $res->status_line unless $res->is_success;
    my $body_params = from_json( $res->content );
    $self->auth_token( $body_params->{access}->{token}->{id} );
    $self->service_catalog( $body_params->{access}->{serviceCatalog} );
    return $self->auth_token();
}

package Net::OpenStack::Swift::InnerKeystone::V3_0;
use Carp;
use JSON;
use Mouse;
use namespace::clean -except => 'meta';

extends 'Net::OpenStack::Swift::InnerKeystone::Base';

sub get_auth_params {

    #return {
    #    auth => {
    #        identity => {
    #            methods => ['password'],
    #            password => {
    #                user => {
    #                    name => $self->user,
    #                    domain => {id => "default"},
    #                    password => $self->password,
    #                }
    #            }
    #        }
    #    }
    #};
}

sub auth {
    my $self = shift;
    croak "not implemented yet......";
}

1;
