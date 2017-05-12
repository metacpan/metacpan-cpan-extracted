package Net::OpenStack::Compute::AuthRole;
use Moose::Role;

use JSON qw(from_json to_json);

requires qw(
    auth_url
    user
    password
    project_id
    region
    service_name
    is_rax_auth
    verify_ssl
    _agent
);

sub get_auth_info {
    my ($self) = @_;
    my $auth_url = $self->auth_url;
    my ($version) = $auth_url =~ /(v\d+\.\d+)$/;
    die "Could not determine version from url [$auth_url]" unless $version;
    return $self->auth_rax() if $self->is_rax_auth;
    return $self->auth_basic() if $version lt 'v2';
    return $self->auth_keystone();
}

sub auth_basic {
    my ($self) = @_;
    my $res = $self->_agent->get($self->auth_url,
        x_auth_user       => $self->user,
        x_auth_key        => $self->password,
        x_auth_project_id => $self->project_id,
    );
    die $res->status_line . "\n" . $res->content unless $res->is_success;

    return {
        base_url   => $res->header('x-server-management-url'),
        token => $res->header('x-auth-token'),
    };
}

sub auth_keystone {
    my ($self) = @_;
    return $self->_parse_catalog({
        auth =>  {
            tenantName => $self->project_id,
            passwordCredentials => {
                username => $self->user,
                password => $self->password,
            }
        }
    });
}

sub auth_rax {
    my ($self) = @_;
    return $self->_parse_catalog({
        auth =>  {
            'RAX-KSKEY:apiKeyCredentials' => {
                apiKey   => $self->password,
                username => $self->user,
            }
        }
    });
}

sub _parse_catalog {
    my ($self, $auth_data) = @_;
    my $res = $self->_agent->post($self->auth_url . "/tokens",
        content_type => 'application/json', content => to_json($auth_data));
    die $res->status_line . "\n" . $res->content unless $res->is_success;
    my $data = from_json($res->content);
    my $token = $data->{access}{token}{id};

    my @catalog = @{ $data->{access}{serviceCatalog} };
    @catalog = grep { $_->{type} eq 'compute' } @catalog;
    die "No compute catalog found" unless @catalog;
    if ($self->service_name) {
        @catalog = grep { $_->{name} eq $self->service_name } @catalog;
        die "No catalog found named " . $self->service_name unless @catalog;
    }
    my $catalog = $catalog[0];
    my $base_url = $catalog->{endpoints}[0]{publicURL};
    if ($self->region) {
        for my $endpoint (@{ $catalog->{endpoints} }) {
            my $region = $endpoint->{region} or next;
            if ($region eq $self->region) {
                $base_url = $endpoint->{publicURL};
                last;
            }
        }
    }

    return { base_url => $base_url, token => $token };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::OpenStack::Compute::AuthRole

=head1 VERSION

version 1.1200

=head1 DESCRIPTION

This role is used by L<Net::OpenStack::Compute> for OpenStack authentication.
It supports the old 1.0 style auth,
L<Keystone|https://github.com/openstack/keystone> auth,
and Rackspace's RAX auth.

=head1 AUTHOR

Naveed Massjouni <naveedm9@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Naveed Massjouni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
