package Net::Silverpeak::Orchestrator;
$Net::Silverpeak::Orchestrator::VERSION = '0.001002';
# ABSTRACT: Silverpeak Orchestrator REST API client library

use 5.024;
use Moo;
use feature 'signatures';
use Types::Standard qw( Str );
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
    my $error_message = $res->data;

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

    return 1;
}


sub logout($self) {
    die "user and password required\n"
        unless $self->has_user && $self->has_passwd;

    my $res = $self->get('/gms/rest/authentication/logout');
    $self->_error_handler($res)
        unless $res->code == 200;

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


sub update_templategroup($self, $name, $data) {
    my $res = $self->post('/gms/rest/template/templateGroups/' . $name,
        $data);
    $self->_error_handler($res)
        unless $res->code == 200;
    return $res->data;
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

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Silverpeak::Orchestrator - Silverpeak Orchestrator REST API client library

=head1 VERSION

version 0.001002

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

=head2 update_templategroup

Takes a template group name and a hashref of template configs.

Returns true on success.

Throws an exception on error.

=head2 list_appliances

Returns an arrayref of appliances.

=head2 get_appliance

Returns an appliance by id.

=head2 list_template_applianceassociations

Returns a hashref of template to appliances associations.

=head2 list_applianceids_by_templategroupname

Returns an arrayref of appliance IDs a templategroup is assigned to.

=head1 KNOWN SILVERPEAK ORCHESTRATOR BUGS

=over

=item http 500 response on api key authentication

Orchestrator versions before version 9.0.4 respond with a http 500 error on
every request using an api key that has no expriation date set.
The only workaround is to set an expiration date for it.

=back

=for Pod::Coverage has_user has_passwd has_api_key

=head1 AUTHOR

Alexander Hartmaier <abraxxa@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Alexander Hartmaier.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
