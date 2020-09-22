package Net::Checkpoint::Management::v1;
$Net::Checkpoint::Management::v1::VERSION = '0.001008';
# ABSTRACT: Checkpoint Management API version 1.x client library

use 5.024;
use Moo;
use feature 'signatures';
use Types::Standard qw( ArrayRef Str );
use Carp::Clan qw(^Net::Checkpoint::Management::v1);
use Clone qw( clone );
use Net::Checkpoint::Management::v1::Role::ObjectMethods;

no warnings "experimental::signatures";


has 'user' => (
    isa => Str,
    is  => 'rw',
);
has 'passwd' => (
    isa => Str,
    is  => 'rw',
);


has 'api_versions' => (
    is => 'lazy',
    isa => ArrayRef[Str],
);

sub _build_api_versions ($self) {
    my $res_versions = $self->post('/web_api/v1.1/show-api-versions', {});
    return $res_versions->data->{'supported-versions'};
}


has 'api_version' => (
    is  => 'rw',
    isa => Str,
);

with 'Net::Checkpoint::Management::v1::Role::REST::Client';

sub _error_handler ($self, $data) {
    my $error_message;

    if (exists $data->{'blocking-errors'}
        && ref $data->{'blocking-errors'} eq 'ARRAY'
        && exists $data->{'blocking-errors'}->[0]
        && exists $data->{'blocking-errors'}->[0]->{message}) {
        $error_message = $data->{'blocking-errors'}->[0]->{message};
    }
    elsif (exists $data->{errors}
        && ref $data->{errors} eq 'ARRAY'
        && exists $data->{errors}->[0]
        && exists $data->{errors}->[0]->{message}) {
        $error_message = $data->{errors}->[0]->{message};
    }
    # when ignore-warnings isn't passed to the API call, a response with only
    # warnings is also considered an error because its changes aren't saved
    # when passing ignore-warnings the error handler isn't called because the
    # http response code is 200
    elsif (exists $data->{warnings}
        && ref $data->{warnings} eq 'ARRAY'
        && exists $data->{warnings}->[0]
        && exists $data->{warnings}->[0]->{message}) {
        $error_message = $data->{warnings}->[0]->{message};
    }
    else {
        $error_message = $data->{message};
    }
    croak($error_message);
}

sub _create ($self, $url, $object_data, $query_params = {}) {
    my $params = $self->user_agent->www_form_urlencode( $query_params );
    my $res = $self->post("$url?$params", $object_data);
    my $code = $res->code;
    my $data = $res->data;

    $self->_error_handler($data)
        unless $code == 200;
    return $data;
}

sub _list ($self, $url, $list_key, $query_params = {}) {
    # the API only allows 500 objects at a time
    # work around that by making multiple API calls
    my $offset = 0;
    my $limit = exists $query_params->{limit}
        ? $query_params->{limit}
        : 500;
    my $more_data_available = 1;
    my $response;
    while ($more_data_available) {
        my $res = $self->post($url, {
            offset => $offset,
            limit => $limit,
            %$query_params,
        });
        my $code = $res->code;
        my $data = $res->data;
        $self->_error_handler($data)
            unless $code == 200;

        # use first response for base structure of response
        if ($offset == 0) {
            $response = clone($data);
            delete $response->{from};
            delete $response->{to};
        }
        else {
            push $response->{$list_key}->@*, $data->{$list_key}->@*
                if exists $data->{$list_key} && ref $data->{$list_key} eq 'ARRAY';
        }

        # check if more data is available
        if ($offset + $limit < $data->{total}) {
            $more_data_available = 1;
            $offset += $limit;
        }
        else {
            $more_data_available = 0;
        }
    }

    # return response similar to Checkpoint API
    return $response;
}

sub _get ($self, $url, $query_params = {}) {
    my $res = $self->post($url, $query_params);
    my $code = $res->code;
    my $data = $res->data;

    $self->_error_handler($data)
        unless $code == 200;

    return $data;
}

sub _update ($self, $url, $object_data) {
    my $res = $self->post($url, $object_data);
    my $code = $res->code;
    my $data = $res->data;
    $self->_error_handler($data)
        unless $code == 200;

    return $data;
}

sub _delete ($self, $url, $object) {
    my $res = $self->post($url, $object);
    my $code = $res->code;
    my $data = $res->data;
    $self->_error_handler($data)
        unless $code == 200;

    return 1;
}

Net::Checkpoint::Management::v1::Role::ObjectMethods->apply([
    {
        object   => 'packages',
        singular => 'package',
        create   => 'add-package',
        list     => 'show-packages',
        get      => 'show-package',
        update   => 'set-package',
        delete   => 'delete-package',
        list_key => 'packages',
        id_keys  => [qw( uid name )],
    },
    {
        object   => 'accessrules',
        singular => 'accessrule',
        create   => 'add-access-rule',
        list     => 'show-access-rulebase',
        get      => 'show-access-rule',
        update   => 'set-access-rule',
        delete   => 'delete-access-rule',
        list_key => 'rulebase',
        id_keys  => ['uid', 'name', 'rule-number'],
    },
    {
        object   => 'networks',
        singular => 'network',
        create   => 'add-network',
        list     => 'show-networks',
        get      => 'show-network',
        update   => 'set-network',
        delete   => 'delete-network',
        list_key => 'objects',
        id_keys  => [qw( uid name )],
    },
    {
        object   => 'hosts',
        singular => 'host',
        create   => 'add-host',
        list     => 'show-hosts',
        get      => 'show-host',
        update   => 'set-host',
        delete   => 'delete-host',
        list_key => 'objects',
        id_keys  => [qw( uid name )],
    },
    {
        object   => 'groups',
        singular => 'group',
        create   => 'add-group',
        list     => 'show-groups',
        get      => 'show-group',
        update   => 'set-group',
        delete   => 'delete-group',
        list_key => 'objects',
        id_keys  => [qw( uid name )],
    },
    {
        object   => 'access_roles',
        singular => 'access_role',
        create   => 'add-access-role',
        list     => 'show-access-roles',
        get      => 'show-access-role',
        update   => 'set-access-role',
        delete   => 'delete-access-role',
        list_key => 'objects',
        id_keys  => [qw( uid name )],
    },
    {
        object   => 'services_tcp',
        singular => 'service_tcp',
        create   => 'add-service-tcp',
        list     => 'show-services-tcp',
        get      => 'show-service-tcp',
        update   => 'set-service-tcp',
        delete   => 'delete-service-tcp',
        list_key => 'objects',
        id_keys  => [qw( uid name )],
    },
    {
        object   => 'services_udp',
        singular => 'service_udp',
        create   => 'add-service-udp',
        list     => 'show-services-udp',
        get      => 'show-service-udp',
        update   => 'set-service-udp',
        delete   => 'delete-service-udp',
        list_key => 'objects',
        id_keys  => [qw( uid name )],
    },
    {
        object   => 'services_icmp',
        singular => 'service_icmp',
        create   => 'add-service-icmp',
        list     => 'show-services-icmp',
        get      => 'show-service-icmp',
        update   => 'set-service-icmp',
        delete   => 'delete-service-icmp',
        list_key => 'objects',
        id_keys  => [qw( uid name )],
    },
    {
        object   => 'services_icmpv6',
        singular => 'service_icmpv6',
        create   => 'add-service-icmp6',
        list     => 'show-services-icmp6',
        get      => 'show-service-icmp6',
        update   => 'set-service-icmp6',
        delete   => 'delete-service-icmp6',
        list_key => 'objects',
        id_keys  => [qw( uid name )],
    },
    {
        object   => 'services_other',
        singular => 'service_other',
        create   => 'add-service-other',
        list     => 'show-services-other',
        get      => 'show-service-other',
        update   => 'set-service-other',
        delete   => 'delete-service-other',
        list_key => 'objects',
        id_keys  => [qw( uid name )],
    },
    {
        object   => 'service_groups',
        singular => 'service_group',
        create   => 'add-service-group',
        list     => 'show-service-groups',
        get      => 'show-service-group',
        update   => 'set-service-group',
        delete   => 'delete-service-group',
        list_key => 'objects',
        id_keys  => [qw( uid name )],
    },
    {
        object   => 'sessions',
        singular => 'session',
        list     => 'show-sessions',
        get      => 'show-session',
        update   => 'set-session',
        list_key => 'objects',
    },
    {
        object   => 'tasks',
        singular => 'task',
        list     => 'show-tasks',
        get      => 'show-task',
        list_key => 'tasks',
    },
]);


sub login($self) {
    my $res = $self->post('/web_api/v1/login', {
        user     => $self->user,
        password => $self->passwd,
    });
    if ($res->code == 200) {
        my $api_version = $res->data->{'api-server-version'};
        $self->api_version($api_version);
        $self->set_persistent_header('X-chkp-sid',
            $res->data->{sid});
    }
    else {
        $self->_error_handler($res->data);
    }
}


sub logout($self) {
    my $res = $self->post('/web_api/v1/logout', {});
    my $code = $res->code;
    my $data = $res->data;
    $self->_error_handler($data)
        unless $code == 200;
}


sub publish($self) {
    my $res = $self->post('/web_api/v' . $self->api_version . '/publish', {});
    my $code = $res->code;
    my $data = $res->data;
    $self->_error_handler($data)
        unless $code == 200;

    return $data->{'task-id'};
}


sub discard($self) {
    my $res = $self->post('/web_api/v' . $self->api_version . '/discard', {});
    my $code = $res->code;
    my $data = $res->data;
    $self->_error_handler($data)
        unless $code == 200;

    return $data;
}


sub verify_policy($self, $policyname) {
    croak "policy name missing"
        unless defined $policyname;

    my $res = $self->post('/web_api/v' . $self->api_version .
        '/verify-policy', {
            'policy-package' => $policyname,
        });
    my $code = $res->code;
    my $data = $res->data;
    $self->_error_handler($data)
        unless $code == 200;

    return $data->{'task-id'};
}


sub install_policy($self, $policyname, $targets, $params={}) {
    croak "policy name missing"
        unless defined $policyname;
    croak "target(s) missing"
        unless defined $targets;
    croak "target(s) must be a single name or uid or a list of names or uids"
        unless ref $targets eq ''
            || ref $targets eq 'ARRAY';
    croak "parameters needs to be a hashref"
        if defined $params && ref $params ne 'HASH';

    my $res = $self->post('/web_api/v' . $self->api_version .
        '/install-policy', {
            $params->%*,
            'policy-package' => $policyname,
            targets          => $targets,
        });
    my $code = $res->code;
    my $data = $res->data;
    $self->_error_handler($data)
        unless $code == 200;

    return $data->{'task-id'};
}


sub wait_for_task($self, $taskid, $callback) {
    croak "task-id missing"
        unless defined $taskid;
    croak "callback must be a coderef"
        if defined $callback && ref $callback ne 'CODE';

    my $task;
    while (($task = $self->get_task({'task-id' => $taskid})->{tasks}[0])
        && $task->{status} eq 'in progress') {
        &$callback($task)
            if defined $callback;
        sleep 1;
    }
    return $task;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Checkpoint::Management::v1 - Checkpoint Management API version 1.x client library

=head1 VERSION

version 0.001008

=head1 SYNOPSIS

    use strict;
    use warnings;
    use Net::Checkpoint::Management::v1;

    my $cpmgmt = Net::Checkpoint::Management::v1->new(
        server      => 'https://cpmgmt.example.com',
        user        => 'username',
        passwd      => '$password',
        clientattrs => { timeout => 30 },
    );

    $cpmgmt->login;

=head1 DESCRIPTION

This module is a client library for the Checkpoint Management API version 1.x.
Currently it is developed and tested against version R80.40.

=head1 ATTRIBUTES

=head2 api_versions

Returns a list of all available API versions which gets populated on the first
call.
Only works on API version 1.1 and higher.

=head2 api_version

The API version used by all methods. Is automatically set to the highest
version available by the L</login> method.

=head1 METHODS

=head2 login

Logs into the Checkpoint Manager API using version 1.

=head2 logout

Logs out of the Checkpoint Manager API using version 1.

=head2 publish

Publishes all previously submitted changes.
Returns the task id on success.

=head2 discard

Discards all previously submitted changes.
Returns a hashref containing the operation status message and the number of
discarded changes.

=head2 verify_policy

Verifies the policy of the given package.

Takes a policy name.

Returns the task id on success.

=head2 install_policy

Installs the policy of the given package onto the given target(s).

Takes a policy name, target(s) and an optional hashref of additional
parameters.
The target(s) can be a single name or uid or a list of names or uids.

Returns the task id on success.

=head2 wait_for_task

Takes a task id and checks its status every second until it isn't
'in progress' any more and return the status.
Takes an optional callback coderef which is called for every check with the
task as argument.

=head1 AUTHOR

Alexander Hartmaier <abraxxa@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Alexander Hartmaier.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
