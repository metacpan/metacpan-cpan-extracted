package Net::Fortinet::FortiManager;
$Net::Fortinet::FortiManager::VERSION = '0.001000';
# ABSTRACT: Fortinet FortiManager REST API client library

use 5.024;
use Moo;
use feature 'signatures';
use Types::Standard qw( ArrayRef HashRef InstanceOf Str );
use Types::Common::Numeric qw( PositiveInt );
use Carp qw( croak );
use List::Util qw( all any );

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

has '_sessionid' => (
    isa         => Str,
    is          => 'rw',
    predicate   => 1,
    clearer     => 1,
);

has '_last_transaction_id' => (
    isa         => PositiveInt,
    is          => 'rw',
    predicate   => 1,
    clearer     => 1,
);

sub _get_transaction_id ($self) {
    my $id;
    if ($self->_has_last_transaction_id) {
        $id = $self->_last_transaction_id;
        $id++;
    }
    else {
        $id = 1;
    }

    $self->_last_transaction_id($id);
    return $id;
}


has 'adoms' => (
    is  => 'rwp',
    isa => ArrayRef[Str],
);


has 'adom' => (
    is      => 'rw',
    isa     => Str,
    default => sub { 'root' },
);

with 'Role::REST::Client';

# around 'do_request' => sub($orig, $self, $method, $uri, $opts) {
#     warn 'request: ' . np($method, $uri, $opts);
#     my $response = $orig->($self, $method, $uri, $opts);
#     warn 'response: ' .  np($response);
#     return $response;
# };

sub _http_error_handler ($self, $res) {
    croak('http error (' . $res->code . '): ' . $res->response->decoded_content)
        unless $res->code == 200;
}

sub _rpc_error_handler ($self, $res, $number_of_expected_results) {
    if (ref $res->data eq 'HASH'
        && exists $res->data->{result}
        && ref $res->data->{result} eq 'ARRAY'
        && scalar $res->data->{result}->@* == $number_of_expected_results
        && all { ref $_ eq 'HASH' } $res->data->{result}->@* ) {
        if ($number_of_expected_results == 1) {
            my $code = $res->data->{result}->[0]->{status}->{code};
            my $message = $res->data->{result}->[0]->{status}->{message};
            if ($code != 0) {
                croak("jsonrpc error ($code): $message");
            }
        }
        else {
            my @failed_calls = grep {
                $_->{status}->{code} != 0
            } $res->data->{result}->@*;

            if (@failed_calls) {
                croak("jsonrpc errors: " . join(', ', map {
                    $_->{url} . ': (' . $_->{status}->{code} . ') ' .
                    $_->{status}->{message}
                } @failed_calls));
            }
        }
    }
    else {
        croak "jsonrpc error: response not in expected format: " .
            $res->response->decoded_content;
    }
}

sub _exec_method ($self, $method, $params = undef) {
    croak 'params needs to be an arrayref'
        if defined $params && ref $params ne 'ARRAY';

    my $body = {
        id      => $self->_get_transaction_id,
        method  => $method,
        params  => $params,
        verbose => 1,
    };
    $body->{session} = $self->_sessionid
        if $self->_has_sessionid;

    # p $body;
    my $res = $self->post('/jsonrpc', $body);
    # p $res;

    $self->_http_error_handler($res);

    $self->_rpc_error_handler($res, defined $params ? scalar $params->@* : 1);

    return $res;
}


sub exec_method ($self, $method, $url, $params = undef) {
    croak 'params needs to be a hashref'
        if defined $params && ref $params ne 'HASH';

    my %full_params = defined $params
        ? $params->%*
        : ();
    $full_params{url} = $url;
    my $rv = $self->_exec_method($method, [\%full_params])->data;

    # the existance of {result}[0] is already verified by _rpc_error_handler
    # called in _exec_method
    if (exists $rv->{result}[0]->{data}) {
        return $rv->{result}[0]->{data};
    }
    return 1;
}


sub exec_method_multi ($self, $method, $params) {
    croak 'params needs to be an arrayref'
        unless ref $params eq 'ARRAY';

    croak 'each parameter needs to be a hashref'
        unless any { ref $_ eq 'HASH' } $params->@*;

    my $rv = $self->_exec_method($method, $params)->data;

    if (exists $rv->{result}) {
        return $rv->{result};
    }
    return 1;
}


sub login ($self) {
    die "user and password required\n"
        unless $self->has_user && $self->has_passwd;

    my $res = $self->_exec_method('exec', [{
        url => "/sys/login/user",
        data => {
            user   => $self->user,
            passwd => $self->passwd,
        },
    }]);

    $self->_sessionid($res->data->{session});

    $self->_set_adoms($self->list_adoms);

    return 1;
}


sub logout ($self) {
    $self->exec_method('exec', '/sys/logout');
    $self->_clear_sessionid;
    $self->_clear_last_transaction_id;

    return 1;
}


sub get_sys_status ($self) {
    return $self->exec_method('get', '/sys/status');
}


sub list_adoms ($self) {
    my @adoms = map {
        $_->{name}
    } $self->exec_method('get', '/dvmdb/adom', {
        fields  => [qw( name )],
    })->@*;
    return \@adoms;
}


sub list_firewall_addresses ($self, $params = {}) {
    $self->exec_method('get', '/pm/config/adom/' . $self->adom .
        '/obj/firewall/address', $params);
}


sub get_firewall_address ($self, $name, $params = {}) {
    $self->exec_method('get', '/pm/config/adom/' . $self->adom .
        '/obj/firewall/address/'. $name, $params);
}


sub create_firewall_address ($self, $name, $data) {
    my $params = {
        data => [{
            $data->%*,
            name => $name,
        }],
    };
    $self->exec_method('set', '/pm/config/adom/' . $self->adom .
        '/obj/firewall/address', $params);
}


sub update_firewall_address ($self, $name, $data) {
    my $params = {
        data => {
            $data->%*,
        },
    };
    $self->exec_method('update', '/pm/config/adom/' . $self->adom .
        '/obj/firewall/address/' . $name, $params);
}


sub delete_firewall_address ($self, $name) {
    $self->exec_method('delete', '/pm/config/adom/' . $self->adom .
        '/obj/firewall/address/' . $name);
}


sub list_firewall_address_groups ($self, $params = {}) {
    $self->exec_method('get', '/pm/config/adom/' . $self->adom .
        '/obj/firewall/addrgrp', $params);
}


sub get_firewall_address_group ($self, $name, $params = {}) {
    $self->exec_method('get', '/pm/config/adom/' . $self->adom .
        '/obj/firewall/addrgrp/'. $name, $params);
}


sub create_firewall_address_group ($self, $name, $data) {
    my $params = {
        data => [{
            $data->%*,
            name => $name,
        }],
    };
    $self->exec_method('set', '/pm/config/adom/' . $self->adom .
        '/obj/firewall/addrgrp', $params);
}


sub update_firewall_address_group ($self, $name, $data) {
    my $params = {
        data => {
            $data->%*,
        },
    };
    $self->exec_method('update', '/pm/config/adom/' . $self->adom .
        '/obj/firewall/addrgrp/' . $name, $params);
}


sub delete_firewall_address_group ($self, $name) {
    $self->exec_method('delete', '/pm/config/adom/' . $self->adom .
        '/obj/firewall/addrgrp/' . $name);
}


sub list_firewall_ipv6_addresses ($self, $params = {}) {
    $self->exec_method('get', '/pm/config/adom/' . $self->adom .
        '/obj/firewall/address6', $params);
}


sub get_firewall_ipv6_address ($self, $name, $params = {}) {
    $self->exec_method('get', '/pm/config/adom/' . $self->adom .
        '/obj/firewall/address6/'. $name, $params);
}


sub create_firewall_ipv6_address ($self, $name, $data) {
    my $params = {
        data => [{
            $data->%*,
            name => $name,
        }],
    };
    $self->exec_method('set', '/pm/config/adom/' . $self->adom .
        '/obj/firewall/address6', $params);
}


sub update_firewall_ipv6_address ($self, $name, $data) {
    my $params = {
        data => {
            $data->%*,
        },
    };
    $self->exec_method('update', '/pm/config/adom/' . $self->adom .
        '/obj/firewall/address6/' . $name, $params);
}


sub delete_firewall_ipv6_address ($self, $name) {
    $self->exec_method('delete', '/pm/config/adom/' . $self->adom .
        '/obj/firewall/address6/' . $name);
}


sub list_firewall_ipv6_address_groups ($self, $params = {}) {
    $self->exec_method('get', '/pm/config/adom/' . $self->adom .
        '/obj/firewall/addrgrp6', $params);
}


sub get_firewall_ipv6_address_group ($self, $name, $params = {}) {
    $self->exec_method('get', '/pm/config/adom/' . $self->adom .
        '/obj/firewall/addrgrp6/'. $name, $params);
}


sub create_firewall_ipv6_address_group ($self, $name, $data) {
    my $params = {
        data => [{
            $data->%*,
            name => $name,
        }],
    };
    $self->exec_method('set', '/pm/config/adom/' . $self->adom .
        '/obj/firewall/addrgrp6', $params);
}


sub update_firewall_ipv6_address_group ($self, $name, $data) {
    my $params = {
        data => {
            $data->%*,
        },
    };
    $self->exec_method('update', '/pm/config/adom/' . $self->adom .
        '/obj/firewall/addrgrp6/' . $name, $params);
}


sub delete_firewall_ipv6_address_group ($self, $name) {
    $self->exec_method('delete', '/pm/config/adom/' . $self->adom .
        '/obj/firewall/addrgrp6/' . $name);
}


sub list_firewall_services ($self, $params = {}) {
    $self->exec_method('get', '/pm/config/adom/' . $self->adom .
        '/obj/firewall/service/custom', $params);
}


sub get_firewall_service ($self, $name, $params = {}) {
    $self->exec_method('get', '/pm/config/adom/' . $self->adom .
        '/obj/firewall/service/custom/'. $name, $params);
}


sub create_firewall_service ($self, $name, $data) {
    my $params = {
        data => [{
            $data->%*,
            name => $name,
        }],
    };
    $self->exec_method('set', '/pm/config/adom/' . $self->adom .
        '/obj/firewall/service/custom', $params);
}


sub update_firewall_service ($self, $name, $data) {
    my $params = {
        data => {
            $data->%*,
        },
    };
    $self->exec_method('update', '/pm/config/adom/' . $self->adom .
        '/obj/firewall/service/custom/' . $name, $params);
}


sub delete_firewall_service ($self, $name) {
    $self->exec_method('delete', '/pm/config/adom/' . $self->adom .
        '/obj/firewall/service/custom/' . $name);
}


sub list_firewall_service_groups ($self, $params = {}) {
    $self->exec_method('get', '/pm/config/adom/' . $self->adom .
        '/obj/firewall/service/group', $params);
}


sub get_firewall_service_group ($self, $name, $params = {}) {
    $self->exec_method('get', '/pm/config/adom/' . $self->adom .
        '/obj/firewall/service/group/'. $name, $params);
}


sub create_firewall_service_group ($self, $name, $data) {
    my $params = {
        data => [{
            $data->%*,
            name => $name,
        }],
    };
    $self->exec_method('set', '/pm/config/adom/' . $self->adom .
        '/obj/firewall/service/group', $params);
}


sub update_firewall_service_group ($self, $name, $data) {
    my $params = {
        data => {
            $data->%*,
        },
    };
    $self->exec_method('update', '/pm/config/adom/' . $self->adom .
        '/obj/firewall/service/group/' . $name, $params);
}


sub delete_firewall_service_group ($self, $name) {
    $self->exec_method('delete', '/pm/config/adom/' . $self->adom .
        '/obj/firewall/service/group/' . $name);
}


sub list_policy_packages ($self, $params = {}) {
    $self->exec_method('get', '/pm/pkg/adom/' . $self->adom, $params);
}


sub get_policy_package ($self, $name, $params = {}) {
    $self->exec_method('get', '/pm/pkg/adom/' . $self->adom . '/'. $name,
        $params);
}


sub create_policy_package ($self, $name, $data) {
    my $params = {
        data => [{
            $data->%*,
            name => $name,
        }],
    };
    $self->exec_method('add', '/pm/pkg/adom/' . $self->adom, $params);
}


sub update_policy_package ($self, $name, $data) {
    my $params = {
        data => {
            $data->%*,
        },
    };
    $self->exec_method('update', '/pm/pkg/adom/' . $self->adom . '/' . $name,
        $params);
}


sub delete_policy_package ($self, $name) {
    $self->exec_method('delete', '/pm/pkg/adom/' . $self->adom . '/' . $name);
}


sub install_policy_package ($self, $name, $data) {
    my $params = {
        data => {
            $data->%*,
            adom    => $self->adom,
            pkg     => $name,
        },
    };
    $self->exec_method('exec', '/securityconsole/install/package',
        $params);
}


sub list_tasks ($self, $params = {}) {
    $self->exec_method('get', '/task/task', $params);
}


sub get_task ($self, $id, $params = {}) {
    $self->exec_method('get', '/task/task/' . $id, $params);
}


sub list_firewall_policies ($self, $pkg, $params = {}) {
    $self->exec_method('get', '/pm/config/adom/' . $self->adom .
        '/pkg/' .  $pkg . '/firewall/policy', $params);
}


sub get_firewall_policy ($self, $pkg, $id, $params = {}) {
    $self->exec_method('get', '/pm/config/adom/' . $self->adom .
        '/pkg/' .  $pkg . '/firewall/policy/' . $id, $params);
}


sub create_firewall_policy ($self, $pkg, $data) {
    my $params = {
        data => [{
            $data->%*,
        }],
    };
    $self->exec_method('add', '/pm/config/adom/' . $self->adom .
        '/pkg/' .  $pkg . '/firewall/policy', $params);
}


sub update_firewall_policy ($self, $pkg, $id, $data) {
    my $params = {
        data => {
            $data->%*,
        },
    };
    $self->exec_method('update', '/pm/config/adom/' . $self->adom .
        '/pkg/' .  $pkg . '/firewall/policy/' . $id , $params);
}


sub delete_firewall_policy ($self, $pkg, $id) {
    $self->exec_method('delete', '/pm/config/adom/' . $self->adom .
        '/pkg/' .  $pkg . '/firewall/policy/' . $id);
}


sub list_firewall_security_policies ($self, $pkg, $params = {}) {
    $self->exec_method('get', '/pm/config/adom/' . $self->adom .
        '/pkg/' .  $pkg . '/firewall/security-policy', $params);
}


sub get_firewall_security_policy ($self, $pkg, $id, $params = {}) {
    $self->exec_method('get', '/pm/config/adom/' . $self->adom .
        '/pkg/' .  $pkg . '/firewall/security-policy/' . $id, $params);
}



sub create_firewall_security_policy ($self, $pkg, $data) {
    my $params = {
        data => [{
            $data->%*,
        }],
    };
    $self->exec_method('add', '/pm/config/adom/' . $self->adom .
        '/pkg/' .  $pkg . '/firewall/security-policy', $params);
}


sub update_firewall_security_policy ($self, $pkg, $id, $data) {
    my $params = {
        data => {
            $data->%*,
        },
    };
    $self->exec_method('update', '/pm/config/adom/' . $self->adom .
        '/pkg/' .  $pkg . '/firewall/security-policy/' . $id , $params);
}


sub delete_firewall_security_policy ($self, $pkg, $id) {
    $self->exec_method('delete', '/pm/config/adom/' . $self->adom .
        '/pkg/' .  $pkg . '/firewall/security-policy/' . $id);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Fortinet::FortiManager - Fortinet FortiManager REST API client library

=head1 VERSION

version 0.001000

=head1 SYNOPSIS

    use strict;
    use warnings;
    use Net::Fortinet::FortiManager;

    my $fortimanager = Net::Fortinet::FortiManager->new(
        server      => 'https://fortimanager.example.com',
        user        => 'username',
        passwd      => '$password',
        clientattrs => {
            timeout     => 10,
        },
    );

    $fortimanager->login;

    $fortimanager->adom('adomname');

=head1 DESCRIPTION

This module is a client library for the Fortigate FortiManager JSONRPC-like
API.
Currently it is developed and tested against version 6.4.6.
All requests have the verbose parameter set to 1 to ensure that enums return
their strings instead of undocumented ids.

=head1 ATTRIBUTES

=head2 adoms

Returns a list of hashrefs containing name and uuid of all ADOMs which gets
populated by L</login>.

=head2 adom

The name of the ADOM which is used by all methods.
Defaults to 'root'.

=head1 METHODS

=head2 exec_method

Executes a method with the specified parameters.

Returns its response.

This is the lowest level method which can be used to execute every API action
that's available.
It does the http and JSONRPC error handling and extraction of the result
from the JSONRPC response.

=head2 exec_method_multi

Executes a method with multiple specified parameters.

Returns its responses.

This is also a low level method which can be used to execute multiple API
actions in a single JSONRPC call.
The only restriction of the JSONRPC API is that all actions need to use the
same method.
It does the http and JSONRPC error handling and extraction of the results
from the JSONRPC response.

=head2 login

Logs into the Fortinet FortiManager.

=head2 logout

Logs out of the Fortinet FortiManager.

=head2 get_sys_status

Returns /sys/status.

=head2 list_adoms

Returns an arrayref of ADOMs by name.

=head2 list_firewall_addresses

Returns an arrayref of firewall addresses.

=head2 get_firewall_address

Takes a firewall address name and an optional parameter hashref.

Returns its data as a hashref.

=head2 create_firewall_address

Takes a firewall address name and a hashref of address config.

Returns true on success.

Throws an exception on error.

=head2 update_firewall_address

Takes a firewall address name and a hashref of address config.

Returns true on success.

Throws an exception on error.

=head2 delete_firewall_address

Takes a firewall address name.

Returns true on success.

Throws an exception on error.

=head2 list_firewall_address_groups

Returns an arrayref of firewall address groups.

=head2 get_firewall_address_group

Takes a firewall address group name and an optional parameter hashref.

Returns its data as a hashref.

=head2 create_firewall_address_group

Takes a firewall address group name and a hashref of address group config.

Returns true on success.

Throws an exception on error.

=head2 update_firewall_address_group

Takes a firewall address group name and a hashref of address group config.

Returns true on success.

Throws an exception on error.

=head2 delete_firewall_address_group

Takes a firewall address group name.

Returns true on success.

Throws an exception on error.

=head2 list_firewall_ipv6_addresses

Returns an arrayref of firewall IPv6 addresses.

=head2 get_firewall_ipv6_address

Takes a firewall IPv6 address name and an optional parameter hashref.

Returns its data as a hashref.

=head2 create_firewall_ipv6_address

Takes a firewall IPv6 address name and a hashref of address config.

Returns true on success.

Throws an exception on error.

=head2 update_firewall_ipv6_address

Takes a firewall IPv6 address name and a hashref of address config.

Returns true on success.

Throws an exception on error.

=head2 delete_firewall_ipv6_address

Takes a firewall IPv6 address name.

Returns true on success.

Throws an exception on error.

=head2 list_firewall_ipv6_address_groups

Returns an arrayref of firewall IPv6 address groups.

=head2 get_firewall_ipv6_address_group

Takes a firewall IPv6 address group name and an optional parameter hashref.

Returns its data as a hashref.

=head2 create_firewall_ipv6_address_group

Takes a firewall IPv6 address group name and a hashref of address group config.

Returns true on success.

Throws an exception on error.

=head2 update_firewall_ipv6_address_group

Takes a firewall IPv6 address group name and a hashref of address group config.

Returns true on success.

Throws an exception on error.

=head2 delete_firewall_ipv6_address_group

Takes a firewall IPv6 address group name.

Returns true on success.

Throws an exception on error.

=head2 list_firewall_services

Returns an arrayref of firewall services.

=head2 get_firewall_service

Takes a firewall service name and an optional parameter hashref.

Returns its data as a hashref.

=head2 create_firewall_service

Takes a firewall service name and a hashref of service config.

Returns true on success.

Throws an exception on error.

=head2 update_firewall_service

Takes a firewall service name and a hashref of service config.

Returns true on success.

Throws an exception on error.

=head2 delete_firewall_service

Takes a firewall service name.

Returns true on success.

Throws an exception on error.

=head2 list_firewall_service_groups

Returns an arrayref of firewall service groups.

=head2 get_firewall_service_group

Takes a firewall service group name and an optional parameter hashref.

Returns its data as a hashref.

=head2 create_firewall_service_group

Takes a firewall service group name and a hashref of service group config.

Returns true on success.

Throws an exception on error.

=head2 update_firewall_service_group

Takes a firewall service group name and a hashref of service group config.

Returns true on success.

Throws an exception on error.

=head2 delete_firewall_service_group

Takes a firewall service group name.

Returns true on success.

Throws an exception on error.

=head2 list_policy_packages

Takes optional parameters.

Returns an arrayref of firewall policies.

=head2 get_policy_package

Takes a policy package name and an optional parameter hashref.

Returns its data as a hashref.

=head2 create_policy_package

Takes a policy package name and a hashref of attributes.

Returns true on success.

Throws an exception on error.

The firewall policies are configured depending on the 'ngfw-mode'.
For profile-based policy packages you have to use the 'policy' methods,
for policy-based the 'security_policy' methods.

=head2 update_policy_package

Takes a policy package name and a hashref of attributes.

Returns true on success.

Throws an exception on error.

=head2 delete_policy_package

Takes a policy package name.

Returns true on success.

Throws an exception on error.

=head2 install_policy_package

Takes a policy package name and a hashref of parameters.

Returns true on success.

Throws an exception on error.

=head2 list_tasks

Takes optional parameters.

Returns an arrayref of tasks.

=head2 get_task

Takes a task id and an optional parameter hashref.

Returns its data as a hashref.

=head2 list_firewall_policies

Takes a package name and optional parameters.

Returns an arrayref of firewall policies.

=head2 get_firewall_policy

Takes a policy package name, a firewall policy id and an optional parameter
hashref.

Returns its data as a hashref.

=head2 create_firewall_policy

Takes a policy package name and a hashref of firewall policy attributes.

Returns the response data from the API on success which is a hashref
containing only the policyid.

Throws an exception on error.

=head2 update_firewall_policy

Takes a policy package name, a firewall policy id and a hashref of firewall
policy attributes.

Returns the response data from the API on success which is a hashref
containing only the policyid.

Throws an exception on error.

=head2 delete_firewall_policy

Takes a policy package name and a firewall policy id.

Returns true on success.

Throws an exception on error.

=head2 list_firewall_security_policies

Takes a package name and optional parameters.

Returns an arrayref of firewall security policies.

=head2 get_firewall_security_policy

Takes a policy package name, a firewall security policy id and an optional
parameter hashref.

Returns its data as a hashref.

=head2 create_firewall_security_policy

Takes a policy package name and a hashref of firewall security policy
attributes.

Returns the response data from the API on success which is a hashref
containing only the policyid.

Throws an exception on error.

=head2 update_firewall_security_policy

Takes a policy package name, a firewall security policy id and a hashref of
firewall security policy attributes.

Returns the response data from the API on success which is a hashref
containing only the policyid.

Throws an exception on error.

=head2 delete_firewall_security_policy

Takes a policy package name and a firewall security policy id.

Returns true on success.

Throws an exception on error.

=for Pod::Coverage has_user has_passwd has_api_key

=head1 AUTHOR

Alexander Hartmaier <abraxxa@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Alexander Hartmaier.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
