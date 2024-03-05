package Net::Silverpeak::Orchestrator;
$Net::Silverpeak::Orchestrator::VERSION = '0.010000';
# ABSTRACT: Silverpeak Orchestrator REST API client library

use 5.024;
use Moo;
use feature 'signatures';
use Types::Standard qw( Bool Str );
use Carp qw( croak );
use HTTP::CookieJar;
use List::Util qw( any );
# use Data::Dumper::Concise;

no warnings "experimental::signatures";


has 'user' => (
    isa => Str,
    is  => 'rw',
    predicate => 1,
);
has 'passwd' => (
    isa => Str,
    is  => 'rw',
    predicate => 1,
);
has 'api_key' => (
    isa => Str,
    is  => 'rw',
    predicate => 1,
);


has 'is_logged_in' => (
    isa     => Bool,
    is      => 'rwp',
    default => sub { 0 },
);

with 'Role::REST::Client';

has '+persistent_headers' => (
    default => sub {
        my $self = shift;
        my %headers;
        $headers{'X-Auth-Token'} = $self->api_key
            if $self->has_api_key;
        return \%headers;
    },
);

around 'do_request' => sub($orig, $self, $method, $uri, $opts) {
    # $uri .= '?apiKey='  . $self->api_key
    #     if $self->has_api_key;
    # warn 'request: ' . Dumper([$method, $uri, $opts]);
    my $response = $orig->($self, $method, $uri, $opts);
    # warn 'response: ' .  Dumper($response);
    return $response;
};

sub _build_user_agent ($self) {
    require HTTP::Thin;

    my %params = $self->clientattrs->%*;
    if ($self->has_user && $self->has_passwd) {
        $params{cookie_jar} = HTTP::CookieJar->new;
    }

    return HTTP::Thin->new(%params);
}

sub _error_handler ($self, $res) {
    my $error_message = ref $res->data eq 'HASH' && exists $res->data->{error}
        ? $res->data->{error}
        : $res->response->decoded_content;

    croak('error (' . $res->code . '): ' . $error_message);
}


sub login($self) {
    die "user and password required\n"
        unless $self->has_user && $self->has_passwd;

    my $res = $self->post('/gms/rest/authentication/login', {
        user     => $self->user,
        password => $self->passwd,
    });

    $self->_error_handler($res)
        unless $res->code == 200;

    my @cookies = $self->user_agent->cookie_jar->cookies_for($self->server);
    if (my ($csrf_cookie) = grep { $_->{name} eq 'orchCsrfToken' } @cookies ) {
        $self->set_persistent_header('X-XSRF-TOKEN' => $csrf_cookie->{value});
    }

    $self->_set_is_logged_in(1);

    return 1;
}


sub logout($self) {
    die "user and password required\n"
        unless $self->has_user && $self->has_passwd;

    my $res = $self->get('/gms/rest/authentication/logout');
    $self->_error_handler($res)
        unless $res->code == 200;

    delete $self->persistent_headers->{'X-XSRF-TOKEN'};

    $self->_set_is_logged_in(0);

    return 1;
}


sub get_version($self) {
    my $res = $self->get('/gms/rest/gms/versions');
    $self->_error_handler($res)
        unless $res->code == 200;

    return $res->data->{current};
}


sub list_templategroups($self) {
    my $res = $self->get('/gms/rest/template/templateGroups');
    $self->_error_handler($res)
        unless $res->code == 200;
    return $res->data;
}


sub get_templategroup($self, $name) {
    my $res = $self->get('/gms/rest/template/templateGroups/' . $name);
    $self->_error_handler($res)
        unless $res->code == 200;
    return $res->data;
}


sub create_templategroup($self, $name, $data = {}) {
    $data->{name} = $name;
    my $res = $self->post('/gms/rest/template/templateCreate',
        $data);
    $self->_error_handler($res)
        unless $res->code == 204;
    return 1;
}


sub update_templates_of_templategroup($self, $name, $templatenames) {
    croak('templates names must be passed as an arrayref')
        unless ref $templatenames eq 'ARRAY';

    my $res = $self->post('/gms/rest/template/templateSelection/' . $name,
        $templatenames);
    $self->_error_handler($res)
        unless $res->code == 200;
    return $res->data;
}


sub update_templategroup($self, $name, $data) {
    my $res = $self->post('/gms/rest/template/templateGroups/' . $name,
        $data);
    $self->_error_handler($res)
        unless $res->code == 200;
    return $res->data;
}


sub delete_templategroup($self, $name) {
    my $res = $self->delete('/gms/rest/template/templateGroups/' . $name);
    $self->_error_handler($res)
        unless $res->code == 204;
    return 1;
}


sub has_segmentation_enabled ($self) {
    my $res = $self->get('/gms/rest/vrf/config/enable');
    $self->_error_handler($res)
        unless $res->code == 200;
    return $res->data->{enable};
}


sub get_vrf_zones_map ($self) {
    my $res = $self->get("/gms/rest/zones/vrfZonesMap");
    $self->_error_handler($res)
        unless $res->code == 200;
    return $res->data;
}


sub get_vrf_by_id ($self) {
    my $res = $self->get("/gms/rest/vrf/config/segments");
    $self->_error_handler($res)
        unless $res->code == 200;
    return $res->data;
}


sub get_vrf_security_policies_by_ids ($self, $source_vrf_id, $destination_vrf_id) {
    my $res = $self->get('/gms/rest/vrf/config/securityPolicies/' . $source_vrf_id . '_' . $destination_vrf_id);
    $self->_error_handler($res)
        unless $res->code == 200;
    return $res->data;
}


sub update_vrf_security_policies_by_ids ($self, $source_vrf_id, $destination_vrf_id, $data) {
    my $res = $self->post('/gms/rest/vrf/config/securityPolicies/' . $source_vrf_id . '_' . $destination_vrf_id, $data);
    $self->_error_handler($res)
        unless $res->code == 204;
    return 1;
}


sub list_appliances($self) {
    my $res = $self->get('/gms/rest/appliance');
    $self->_error_handler($res)
        unless $res->code == 200;
    return $res->data;
}


sub get_appliance($self, $id) {
    my $res = $self->get('/gms/rest/appliance/' . $id);
    $self->_error_handler($res)
        unless $res->code == 200;
    return $res->data;
}


sub get_appliance_extrainfo ($self, $id) {
    my $res = $self->get("/gms/rest/appliance/extraInfo/$id");
    $self->_error_handler($res)
        unless $res->code == 200;
    return $res->data;
}


sub get_ha_groups_by_id ($self) {
    my $res = $self->get("/gms/rest/haGroups");
    $self->_error_handler($res)
        unless $res->code == 200;
    return $res->data;
}


sub get_deployment ($self, $id) {
    my $res = $self->get("/gms/rest/deployment/$id");
    $self->_error_handler($res)
        unless $res->code == 200;
    return $res->data;
}


sub get_interface_state ($self, $id) {
    my $res = $self->get("/gms/rest/interfaceState/$id");
    $self->_error_handler($res)
        unless $res->code == 200;
    return $res->data;
}


sub get_interface_labels_by_type ($self) {
    my $res = $self->get("/gms/rest/gms/interfaceLabels");
    $self->_error_handler($res)
        unless $res->code == 200;
    return $res->data;
}


sub list_template_applianceassociations($self) {
    my $res = $self->get('/gms/rest/template/applianceAssociation');
    $self->_error_handler($res)
        unless $res->code == 200;
    return $res->data;
}


sub list_applianceids_by_templategroupname($self, $name) {
    my $associations = $self->list_template_applianceassociations;
    my @appliance_ids;
    for my $appliance_id (keys %$associations) {
        push @appliance_ids, $appliance_id
            if any { $_ eq $name } $associations->{$appliance_id}->@*;
    }
    return \@appliance_ids;
}


sub list_addressgroups($self) {
    my $res = $self->get('/gms/rest/ipObjects/addressGroup');
    $self->_error_handler($res)
        unless $res->code == 200;
    return $res->data;
}


sub list_addressgroup_names($self) {
    my $res = $self->get('/gms/rest/ipObjects/addressGroupNames');
    $self->_error_handler($res)
        unless $res->code == 200;
    return $res->data;
}


sub get_addressgroup($self, $name) {
    my $res = $self->get('/gms/rest/ipObjects/addressGroup/' . $name);
    $self->_error_handler($res)
        unless $res->code == 200;
    return $res->data;
}


sub create_or_update_addressgroup($self, $name, $data) {
    $data->{name} = $name;
    $data->{type} = 'AG';
    my $res = $self->post('/gms/rest/ipObjects/addressGroup', $data);
    $self->_error_handler($res)
        unless $res->code == 204;
    return 1;
}


sub update_addressgroup($self, $name, $data) {
    $data->{name} = $name;
    $data->{type} = 'AG';
    my $res = $self->put('/gms/rest/ipObjects/addressGroup', $data);
    $self->_error_handler($res)
        unless $res->code == 204;
    return 1;
}


sub delete_addressgroup($self, $name) {
    my $res = $self->delete('/gms/rest/ipObjects/addressGroup/' . $name);
    $self->_error_handler($res)
        unless $res->code == 204;
    return 1;
}


sub list_servicegroups($self) {
    my $res = $self->get('/gms/rest/ipObjects/serviceGroup');
    $self->_error_handler($res)
        unless $res->code == 200;
    return $res->data;
}


sub list_servicegroup_names($self) {
    my $res = $self->get('/gms/rest/ipObjects/serviceGroupNames');
    $self->_error_handler($res)
        unless $res->code == 200;
    return $res->data;
}


sub get_servicegroup($self, $name) {
    my $res = $self->get('/gms/rest/ipObjects/serviceGroup/' . $name);
    $self->_error_handler($res)
        unless $res->code == 200;
    return $res->data;
}


sub create_or_update_servicegroup($self, $name, $data) {
    $data->{name} = $name;
    $data->{type} = 'SG';
    my $res = $self->post('/gms/rest/ipObjects/serviceGroup', $data);
    $self->_error_handler($res)
        unless $res->code == 204;
    return 1;
}


sub update_servicegroup($self, $name, $data) {
    $data->{name} = $name;
    $data->{type} = 'SG';
    my $res = $self->put('/gms/rest/ipObjects/serviceGroup', $data);
    $self->_error_handler($res)
        unless $res->code == 204;
    return 1;
}


sub delete_servicegroup($self, $name) {
    my $res = $self->delete('/gms/rest/ipObjects/serviceGroup/' . $name);
    $self->_error_handler($res)
        unless $res->code == 204;
    return 1;
}


sub list_domain_applications($self, $resource_key='userDefined') {
    my $res = $self->get('/gms/rest/applicationDefinition/dnsClassification',
        { resourceKey => $resource_key });
    $self->_error_handler($res)
        unless $res->code == 200;
    return $res->data;
}


sub create_or_update_domain_application($self, $domain, $data) {
    $data->{domain} = $domain;
    my $res = $self->post('/gms/rest/applicationDefinition/dnsClassification2/domain', $data);
    $self->_error_handler($res)
        unless $res->code == 200;
    return 1;
}


sub delete_domain_application($self, $domain) {
    my $res = $self->delete('/gms/rest/applicationDefinition/dnsClassification/' . $domain);
    $self->_error_handler($res)
        unless $res->code == 200;
    return 1;
}


sub list_application_groups($self, $resource_key='userDefined') {
    my $res = $self->get('/gms/rest/applicationDefinition/applicationTags',
        { resourceKey => $resource_key });
    $self->_error_handler($res)
        unless $res->code == 200;
    return $res->data;
}


sub create_or_update_application_group($self, $name, $data) {
    my $application_groups = $self->list_application_groups;
    # set or overwrite existing application group
    $application_groups->{$name} = $data;
    my $res = $self->post('/gms/rest/applicationDefinition/applicationTags',
        $application_groups);
    $self->_error_handler($res)
        unless $res->code == 200;
    return 1;
}


sub delete_application_group($self, $name) {
    my $application_groups = $self->list_application_groups;
    # set or overwrite existing application group
    croak("application '$name' doesn't exist")
        unless exists $application_groups->{$name};
    delete $application_groups->{$name};
    my $res = $self->post('/gms/rest/applicationDefinition/applicationTags',
        $application_groups);
    $self->_error_handler($res)
        unless $res->code == 200;
    return 1;
}


sub DEMOLISH {
    my $self = shift;

    $self->logout
        if $self->has_user
        && $self->has_passwd
        && $self->is_logged_in;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Silverpeak::Orchestrator - Silverpeak Orchestrator REST API client library

=head1 VERSION

version 0.010000

=head1 SYNOPSIS

    use strict;
    use warnings;
    use Net::Silverpeak::Orchestrator;

    my $orchestrator = Net::Silverpeak::Orchestrator->new(
        server      => 'https://orchestrator.example.com',
        user        => 'username',
        passwd      => '$password',
        clientattrs => { timeout => 30 },
    );

    $orchestrator->login;

    # OR

    $orchestrator = Net::Silverpeak::Orchestrator->new(
        server      => 'https://orchestrator.example.com',
        api_key     => '$api-key',
        clientattrs => { timeout => 30 },
    );

=head1 DESCRIPTION

This module is a client library for the Silverpeak Orchestrator REST API.
Currently it is developed and tested against version 9.0.2.

=head1 ATTRIBUTES

=head2 is_logged_in

Returns true if successfully logged in.

=head1 METHODS

=head2 login

Logs into the Silverpeak Orchestrator.
Only required when using username and password, not for api key.

=head2 logout

Logs out of the Silverpeak Orchestrator.
Only possible when using username and password, not for api key.

=head2 get_version

Returns the Silverpeak Orchestrator version.

=head2 list_templategroups

Returns an arrayref of template groups.

=head2 get_templategroup

Returns a template group by name.

=head2 create_templategroup

Takes a template group name and a hashref with its config.

Returns true on success.

Throws an exception on error.

=head2 update_templates_of_templategroup

Takes a template group name and an arrayref of template names.

Returns true on success.

Throws an exception on error.

=head2 update_templategroup

Takes a template group name and a hashref of template configs.

Returns true on success.

Throws an exception on error.

=head2 delete_templategroup

Takes a template group name.

Returns true on success.

Throws an exception on error.

=head2 has_segmentation_enabled

Returns true if segmentation is enabled, else false.

=head2 get_vrf_zones_map

Returns a hashref of firewall zones indexed by VRF id and firewall zone id.

=head2 get_vrf_by_id

Returns a hashref of VRFs indexed by their id.

=head2 get_vrf_security_policies_by_ids

Takes the source and destination vrf ids.

Returns a hashref containing all settings and security policies of a vrf.

=head2 update_vrf_security_policies_by_ids

Takes the source and destination vrf ids.

Returns true on success.

Throws an exception on error.

=head2 list_appliances

Returns an arrayref of appliances.

=head2 get_appliance

Returns an appliance by id.

=head2 get_appliance_extrainfo

Takes an appliance id.

Returns a hashref with additional infos about the appliance like its location.

=head2 get_ha_groups_by_id

Returns a hashref of HA groups indexed by their id.

=head2 get_deployment

Takes an appliance id.

Returns a hashref containing the deployment data.

=head2 get_interface_state

Takes an interface id.

Returns a hashref containing the interface state.

=head2 get_interface_labels_by_type

Returns a hashref containing the interface labels indexed by LAN/WAN and their id.

=head2 list_template_applianceassociations

Returns a hashref of template to appliances associations.

=head2 list_applianceids_by_templategroupname

Returns an arrayref of appliance IDs a templategroup is assigned to.

=head2 list_addressgroups

Returns an arrayref of address groups.

=head2 list_addressgroup_names

Returns an arrayref of address group names.

=head2 get_addressgroup

Returns an address group by name.

=head2 create_or_update_addressgroup

Takes an address group name and a hashref of address group config.

Returns true on success.

Throws an exception on error.

=head2 update_addressgroup

Takes an address group name and a hashref of address group config.

Returns true on success.

Throws an exception on error.

=head2 delete_addressgroup

Takes an address group name.

Returns true on success.

Throws an exception on error.

=head2 list_servicegroups

Returns an arrayref of service groups.

=head2 list_servicegroup_names

Returns an arrayref of service group names.

=head2 get_servicegroup

Returns a service group by name.

=head2 create_or_update_servicegroup

Takes a service group name and a hashref of service group config.

Returns true on success.

Throws an exception on error.

=head2 update_servicegroup

Takes a service group name and a hashref of service group config.

Returns true on success.

Throws an exception on error.

=head2 delete_servicegroup

Takes a service group name.

Returns true on success.

Throws an exception on error.

=head2 list_domain_applications

Returns an arrayref of domain name applications for a resource key which
defaults to 'userDefined'.

=head2 create_or_update_domain_application

Takes a domain name application domain, not name, and a hashref of its config.

Returns true on success.

Throws an exception on error.

=head2 delete_domain_application

Takes a domain name, not application name.

Returns true on success.

Throws an exception on error.

=head2 list_application_groups

Returns a hashref of application groups indexed by their name for a resource
key which defaults to 'userDefined'.

=head2 create_or_update_application_group

Takes a application group name, and a hashref of its config.

Returns true on success.

Throws an exception on error.

Because there is no API endpoint for creating or editing a single application
group, this method has to load all application groups using
L<list_application_groups>, modify and then save them.

=head2 delete_application_group

Takes an application group name.

Returns true on success.

Throws an exception on error.

Because there is no API endpoint for deleting a single application group,
this method has to load all application groups using
L<list_application_groups>, remove the requested application group and then
save them.

=head1 KNOWN SILVERPEAK ORCHESTRATOR BUGS

=over

=item http 500 response on api key authentication

Orchestrator versions before version 9.0.4 respond with a http 500 error on
every request using an api key that has no expiration date set.
The only workaround is to set an expiration date for it.

=back

=for Pod::Coverage has_user has_passwd has_api_key

=for Pod::Coverage DEMOLISH

=head1 AUTHOR

Alexander Hartmaier <abraxxa@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Alexander Hartmaier.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
