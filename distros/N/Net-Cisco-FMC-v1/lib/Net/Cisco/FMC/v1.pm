package Net::Cisco::FMC::v1;
$Net::Cisco::FMC::v1::VERSION = '0.005001';
# ABSTRACT: Cisco Firepower Management Center (FMC) API version 1 client library

use 5.024;
use Moo;
use feature 'signatures';
use Types::Standard qw( ArrayRef Dict Str );
use Carp qw( croak );
use Clone qw( clone );
use Syntax::Keyword::Try;
use Net::Cisco::FMC::v1::Role::ObjectMethods;
use JSON qw( decode_json );
# use Data::Dumper::Concise;

no warnings "experimental::signatures";



has 'domains' => (
    is => 'rwp',
    isa => ArrayRef[Dict[name => Str, uuid => Str]],
);


has 'domain_uuid' => (
    is => 'rw',
);

has '_refresh_token' => (
    is => 'rw',
);

with 'Net::Cisco::FMC::v1::Role::REST::Client';

sub _create ($self, $url, $object_data, $query_params = {}, $expected_code = 201) {
    my $params = $self->user_agent->www_form_urlencode( $query_params );
    my $res = $self->post("$url?$params", $object_data);
    my $code = $res->code;
    my $data = $res->data;
    croak($data->{error}->{messages}[0]->{description})
        unless $code == $expected_code;
    return $data;
}

sub _list ($self, $url, $query_params = {}) {
    # the API only allows 1000 objects at a time
    # work around that by making multiple API calls
    my $offset = 0;
    my $limit = 1000;
    my $more_data_available = 1;
    my @items;
    while ($more_data_available) {
        my $res = $self->get($url, {
            offset => $offset,
            limit => $limit,
            %$query_params,
        });
        my $code = $res->code;
        my $data = $res->data;

        croak($data->{error}->{messages}[0]->{description})
            unless $code == 200;

        push @items, $data->{items}->@*
            if exists $data->{items} && ref $data->{items} eq 'ARRAY';

        # check if more data is available
        if ($offset + $limit < $data->{paging}->{count}) {
            $more_data_available = 1;
            $offset += $limit;
        }
        else {
            $more_data_available = 0;
        }
    }

    # return response similar to FMC API
    return { items => \@items };
}

sub _get ($self, $url, $query_params = {}) {
    my $res = $self->get($url, $query_params);
    my $code = $res->code;
    my $data = $res->data;

    croak($data->{error}->{messages}[0]->{description})
        unless $code == 200;

    return $data;
}

sub _update ($self, $url, $object, $object_data) {
    my $updated_data = clone($object);
    delete $updated_data->{links};
    delete $updated_data->{metadata};
    delete $updated_data->{error};
    $updated_data = { %$updated_data, %$object_data };

    my $res = $self->put($url, $updated_data);
    my $code = $res->code;
    my $data = $res->data;
    my $errmsg = ref $data eq 'HASH'
        ? $data->{error}->{messages}[0]->{description}
        : $data;
    croak($errmsg)
        unless $code == 200;

    return $data;
}

sub _delete ($self, $url) {
    my $res = $self->delete($url);
    croak($res->data->{error}->{messages}[0]->{description})
        unless $res->code == 200;
    return 1;
}

Net::Cisco::FMC::v1::Role::ObjectMethods->apply([
    {
        path     => 'object',
        object   => 'portobjectgroups',
        singular => 'portobjectgroup',
    },
    {
        path     => 'object',
        object   => 'protocolportobjects',
        singular => 'protocolportobject',
    },
    {
        path     => 'object',
        object   => 'icmpv4objects',
        singular => 'icmpv4object',
    },
    {
        path     => 'object',
        object   => 'icmpv6objects',
        singular => 'icmpv6object',
    },
    {
        path     => 'object',
        object   => 'interfacegroups',
        singular => 'interfacegroup',
    },
    {
        path     => 'object',
        object   => 'networkgroups',
        singular => 'networkgroup',
    },
    {
        path     => 'object',
        object   => 'networks',
        singular => 'network',
    },
    {
        path     => 'object',
        object   => 'hosts',
        singular => 'host',
    },
    {
        path     => 'object',
        object   => 'ranges',
        singular => 'range',
    },
    {
        path     => 'object',
        object   => 'securityzones',
        singular => 'securityzone',
    },
    {
        path     => 'object',
        object   => 'slamonitors',
        singular => 'slamonitor',
    },
    {
        path     => 'object',
        object   => 'urlgroups',
        singular => 'urlgroup',
    },
    {
        path     => 'object',
        object   => 'urls',
        singular => 'url',
    },
    {
        path     => 'object',
        object   => 'vlangrouptags',
        singular => 'vlangrouptag',
    },
    {
        path     => 'object',
        object   => 'vlantags',
        singular => 'vlantag',
    },
    {
        path     => 'policy',
        object   => 'accesspolicies',
        singular => 'accesspolicy',
    },
    {
        path     => 'object',
        object   => 'networkaddresses',
        singular => 'networkaddress',
    },
    {
        path     => 'object',
        object   => 'ports',
        singular => 'port',
    },
    {
        path     => 'devices',
        object   => 'devicerecords',
        singular => 'devicerecord',
    },
    {
        path     => 'assignment',
        object   => 'policyassignments',
        singular => 'policyassignment',
    },
]);


sub login($self) {
    my $res = $self->post('/api/fmc_platform/v1/auth/generatetoken', undef,
        { authentication => 'basic' });
    if ($res->code == 204) {
        # the allowed domains are returned in the domains header JSON
        # encoded
        my $domains = decode_json($res->response->header('domains'));
        #say Dumper($domains);
        $self->_set_domains($domains);
        # set the current domain to the first available
        $self->domain_uuid($domains->[0]->{uuid});

        # store refresh token
        $self->_refresh_token($res->response->header('x-auth-refresh-token'));
        $self->set_persistent_header('X-auth-access-token',
            $res->response->header('x-auth-access-token'));
    }
    else {
        croak($res->data->{error}->{messages}[0]->{description});
    }
}


sub relogin($self) {
    my $domain_uuid = $self->domain_uuid;
    $self->login;
    $self->domain_uuid($domain_uuid)
        if defined $domain_uuid && $domain_uuid ne '';
}


sub create_accessrule ($self, $accesspolicy_id, $object_data, $query_params = {}) {
    return $self->_create(join('/',
            '/api/fmc_config/v1/domain',
            $self->domain_uuid,
            'policy',
            'accesspolicies',
            $accesspolicy_id,
            'accessrules'
        ), $object_data, $query_params);
}


sub list_accessrules ($self, $accesspolicy_id, $query_params = {}) {
    return $self->_list(join('/',
        '/api/fmc_config/v1/domain',
        $self->domain_uuid,
        'policy',
        'accesspolicies',
        $accesspolicy_id,
        'accessrules'
    ), $query_params);
}


sub get_accessrule ($self, $accesspolicy_id, $id, $query_params = {}) {
    return $self->_get(join('/',
        '/api/fmc_config/v1/domain',
        $self->domain_uuid,
        'policy',
        'accesspolicies',
        $accesspolicy_id,
        'accessrules',
        $id
    ), $query_params);
}


sub update_accessrule ($self, $accesspolicy_id, $object, $object_data) {
    my $id = $object->{id};
    my $fmc_rule = clone($object);
    for my $user ($fmc_rule->{users}->{objects}->@*) {
        delete $user->{realm};
    }
    return $self->_update(join('/',
        '/api/fmc_config/v1/domain',
        $self->domain_uuid,
        'policy',
        'accesspolicies',
        $accesspolicy_id,
        'accessrules',
        $id
    ), $fmc_rule, $object_data);
}



sub delete_accessrule ($self, $accesspolicy_id, $id) {
    return $self->_delete(join('/',
        '/api/fmc_config/v1/domain',
        $self->domain_uuid,
        'policy',
        'accesspolicies',
        $accesspolicy_id,
        'accessrules',
        $id
    ));
}


sub list_deployabledevices ($self, $query_params = {}) {
    return $self->_list(join('/',
        '/api/fmc_config/v1/domain',
        $self->domain_uuid,
        'deployment',
        'deployabledevices'
    ), $query_params);
}


sub create_deploymentrequest ($self, $object_data) {
    my $data = $self->_create(join('/',
        '/api/fmc_config/v1/domain',
        $self->domain_uuid,
        'deployment',
        'deploymentrequests'
    ), $object_data, {}, 202);
    return $data;
}


sub get_task ($self, $id) {
    return $self->_get(join('/',
        '/api/fmc_config/v1/domain',
        $self->domain_uuid,
        'job',
        'taskstatuses',
        $id
    ));
}


sub wait_for_task ($self, $id, $callback) {
    croak "id missing"
        unless defined $id;
    croak "callback must be a coderef"
        if defined $callback && ref $callback ne 'CODE';

    my %in_progress_status_for_type = (
        DEVICE_DEPLOYMENT => 'Deploying',
    );

    my $task = $self->get_task($id);
    die "support for task type '$task->{taskType}' not implemented\n"
        unless exists $in_progress_status_for_type{$task->{taskType}};
    do {
        &$callback($task)
            if defined $callback;
        sleep 1;
        $task = $self->get_task($id);
    } until (
        $task->{status} ne $in_progress_status_for_type{$task->{taskType}});
    return $task;
}


sub cleanup_protocolport ($self, $portobj) {
    #say Dumper($rule);
    #say "protocolport: " . Dumper($portobj);
    my $protocolportobject = $self->get_protocolportobject($portobj->{id});
    #say Dumper($protocolportobject);
    my $new_name = lc($protocolportobject->{protocol});
    if ( exists $protocolportobject->{port} ) {
        $new_name .= '_' . $protocolportobject->{port};
    }
    # avoid 'predefined name' errors
    else {
        $new_name .= '_any';
    }

    say "\t", $protocolportobject->{name}, ' ⮕ ', $new_name;
    try {
        my $portobject = $self->update_protocolportobject($protocolportobject, { name => $new_name });
        say "\tname updated";
        return { %$portobject{qw( id type )} };
    }
    catch {
        # replace with existing object
        if ( $@ =~ /The object name \S+ already exists/ ) {
            # find existing object
            my $existing_portobject = $self->find_protocolportobject({ name => $new_name });
            say "\texisting object used";
            return { %$existing_portobject{qw( id type )} };
        }
        else {
            croak "name update failed: $@";
        }
    }
}


sub cleanup_icmpv4object ($self, $icmpv4obj) {
    #say "icmpv4object: " . Dumper($icmpv4obj);
    my $icmpv4object = $self->get_icmpv4object($icmpv4obj->{id});
    #say Dumper($icmpv4object);
    my $new_name = 'icmp_' . lc($icmpv4object->{icmpType});
    $new_name .= '_' . $icmpv4object->{code}
        if exists $icmpv4object->{code};

    say "\t", $icmpv4object->{name}, ' ⮕ ', $new_name;
    try {
        my $obj = $self->update_icmpv4object($icmpv4object, { name => $new_name });
        say "\tname updated";
        return { %$obj{qw( id type )} };
    }
    catch {
        #say "name update failed: $@";
        # replace with existing object
        if ( $@ =~ /The object name \S+ already exists/ ) {
            # find existing object
            my $existing_object = $self->find_icmpv4object({ name => $new_name });
            say "\texisting object used";
            return { %$existing_object{qw( id type )} };
        }
        elsif ( $@ =~ /conflicts with predefined name on device/ ) {
            say "\t$@";
        }
        else {
            croak "name update failed: $@";
        }
    }
}


sub cleanup_hosts($self) {
    for my $object ($self->list_hosts({ expanded => 'true' })->{items}->@*) {
        try {
            #say $object->{name};
            #say Dumper($object);
            if ($object->{name} =~ /^(.*)_Mask32$/) {
                my $new_name = $1;
                say 'renaming host ', $object->{name}, ' ⮕ ', $new_name;
                $self->update_host($object, { name => $new_name });
            }
            # clear description
            if ($object->{description} eq 'Created during ASA Migration') {
                $self->update_host($object, { description => '' });
            }
        }
        catch {
            warn $@;
        }
    }
}


sub create_cleaned_accesspolicy (    $self,    $source_accesspolicy_name,    $optional = {}) {
    my $destination_accesspolicy_name = exists $optional->{target_access_policy_name}
        ? $optional->{target_access_policy_name}
        : $source_accesspolicy_name . '-cleaned';

    my @accesspolicies = $self->list_accesspolicies({ expanded => 'true'
        })->{items}->@*;
    for my $accesspolicy (@accesspolicies) {
        next
            unless $accesspolicy->{name} eq $source_accesspolicy_name;
        say "cleaning " . $accesspolicy->{id}, ': ', $accesspolicy->{name};
        #say Dumper($accesspolicy);
        #say "creating new accesspolicy: " . Dumper($accesspolicy);

        # check if the cleaned accesspolicy already exists, in that case
        # resume
        my $new_accesspolicy;
        for my $accesspolicy (@accesspolicies) {
            if ($accesspolicy->{name} eq $destination_accesspolicy_name) {
                $new_accesspolicy = $accesspolicy;
                last;
            }
        }

        my $resume_rulenumber;
        if (defined $new_accesspolicy) {
            # find first rule to resume cleanup
            my @rules = $self->list_accessrules($new_accesspolicy->{id})
                ->{items}->@*;
            $resume_rulenumber = scalar @rules + 1;
            say "resuming cleanup of $destination_accesspolicy_name ",
                "at rule #$resume_rulenumber\n";
        }
        else {
            $new_accesspolicy = $self->create_accesspolicy({
                name => $destination_accesspolicy_name,
                defaultAction => {
                    action => 'BLOCK',
                    logBegin => 1,
                    sendEventsToFMC => 1,
                },
            });
        }
        #say Dumper($new_accesspolicy);

        my $rulenumber = 1;
        RULE: for my $rule ($self->list_accessrules($accesspolicy->{id},
                { expanded => 'true' })->{items}->@*) {
            if ( defined $resume_rulenumber
                 && $rulenumber < $resume_rulenumber ) {
                $rulenumber++;
                next RULE;
            }

            #next RULE
            #    unless $rule->{name} eq 'outside_access_in#15-1';
            say $rule->{name};
            # copy all attributes of the existing rule to the new one
            my $updated_data = clone($rule);
            # remove attributes that are not needed/allowed in the create
            # call
            delete $updated_data->{id};
            delete $updated_data->{links};
            delete $updated_data->{metadata};
            delete $updated_data->{commentHistoryList};
            #my $rule_for_diff = clone($updated_data);

            if (exists $optional->{rule_name_coderef}) {
                $updated_data->{name} = $optional->{rule_name_coderef}->($rulenumber, $rule);
            }

            $rulenumber++;

            for my $networktype (qw( sourceNetworks destinationNetworks )) {
                my $src_networks = $rule->{$networktype};
                for my $key (keys $src_networks->%*) {
                    if ($key eq 'objects') {
                        $updated_data->{$networktype}->{objects} = [];
                        #say "old: " . Dumper($src_networks->{objects});
                        for my $network ($src_networks->{objects}->@*) {
                            #say Dumper($network);
                            my $name = $network->{name};
                            my $type = $network->{type};
                            if ( $name =~ /^DM_INLINE_/ ) {
                                # eliminate autogenerated NetworkGroups
                                if ( $type eq 'NetworkGroup' ) {
                                    my $networkgroup = $self->get_networkgroup($network->{id});
                                    my $object_count =
                                        (exists $networkgroup->{objects}
                                        ? scalar $networkgroup->{objects}->@*
                                        : 0)
                                        + (exists $networkgroup->{literals}
                                        ? scalar $networkgroup->{literals}->@*
                                        : 0);
                                    if ( $object_count > 50 ) {
                                        warn "\tnumber of objects (",
                                        $object_count, ") would exceed ",
                                        "current FMC limit of 50, ",
                                        "keeping current contents\n";
                                    }
                                    else {
                                        say "\tmoving contents of group $name directly into rule";
                                        for my $objecttype (qw( objects literals )) {
                                            for my $networkobject ($networkgroup->{$objecttype}->@*) {
                                                #say Dumper($networkobject);
                                                push $updated_data->{$networktype}->{$objecttype}->@*, $networkobject;
                                            }
                                        }
                                    }
                                }
                                else {
                                    warn "object type $type not supported, keeping original object!";
                                    push $updated_data->{$networktype}->{objects}->@*, $network;
                                }
                            }
                            # keep non-autogenerated objects
                            else {
                                push $updated_data->{$networktype}->{objects}->@*, $network;
                            }
                        }
                    }
                    # copy all other contents
                    else {
                        $updated_data->{$networktype}->{$key} = $src_networks->{$key};
                    }
                }
            }

            my $ports = $rule->{destinationPorts};
            if (exists $ports->{objects} ) {
                $updated_data->{destinationPorts} = {
                    objects => []
                };
                #say "old: " . Dumper($ports->{objects});
                for my $portobj ($ports->{objects}->@*) {
                    #say Dumper($portobj);
                    my $name = $portobj->{name};
                    my $type = $portobj->{type};

                    if ( $name =~ /^DM_INLINE_/ ) {
                        # eliminate autogenerated PortObjectGroups
                        if ( $type eq 'ProtocolPortObject' ) {
                            push
                                $updated_data->{destinationPorts}->{objects}->@*,
                                $self->cleanup_protocolport({
                                    %$portobj{qw( id type )} });
                        }
                        elsif ( $type eq 'ICMPV4Object' ) {
                            push
                                $updated_data->{destinationPorts}->{objects}->@*,
                                $self->cleanup_icmpv4object({
                                    %$portobj{qw( id type )} });
                        }
                        elsif ( $type eq 'PortObjectGroup' ) {
                            say "\tmoving contents of group $name directly into rule";
                            #say Dumper($rule);
                            my $portobjectgroup = $self->get_portobjectgroup($portobj->{id});
                            for my $portobject ($portobjectgroup->{objects}->@*) {
                                #say Dumper($portobject);
                                my $object = $portobject->{type} eq
                                    'ProtocolPortObject'
                                    ? $self->cleanup_protocolport(
                                            {%$portobject{qw( id type )}}
                                        )
                                    : {%$portobject{qw( id type )}};
                                push $updated_data->{destinationPorts}->{objects}->@*,
                                    $object;
                            }
                        }
                        else {
                            warn "unhandled object type $type, keeping unmodified\n";
                            push $updated_data->{destinationPorts}->{objects}->@*, $portobj;
                        }

                        #my $protocolportobject = $self->get_protocolportobject($portobj->{id});
                        #say Dumper($protocolportobject);
                    }
                    # keep non-autogenerated objects
                    else {
                        push $updated_data->{destinationPorts}->{objects}->@*, $portobj;
                    }
                }
            }
            #say "new: " . Dumper($updated_data);
            # always replace existing destinationPorts because one of
            # them might have been replaced with an existing one
            # FIXME: check if literals get lost
            #$self->update_accessrule($accesspolicy->{id}, $rule, $updated_data)
            #    if $updated_data->%*;
            #say Dumper($updated_data);
            #use Test::Differences;
            #eq_or_diff($updated_data, $rule_for_diff, 'rule');
            $self->create_accessrule($new_accesspolicy->{id}, $updated_data);
            #last RULE;
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Cisco::FMC::v1 - Cisco Firepower Management Center (FMC) API version 1 client library

=head1 VERSION

version 0.005001

=head1 SYNOPSIS

    use strict;
    use warnings;
    use Net::Cisco::FMC::v1;
    use Data::Dumper::Concise;

    my $fmc = Net::Cisco::FMC::v1->new(
        server      => 'https://fmcrestapisandbox.cisco.com',
        user        => 'admin',
        passwd      => '$password',
        clientattrs => { timeout => 30 },
    );

    # login to populate domains
    $fmc->login;

    # list all domain uuids and names
    print Dumper($fmc->domains);
    # switch domain
    $fmc->domain_uuid("e276abec-e0f2-11e3-8169-6d9ed49b625f");

=head1 DESCRIPTION

This module is a client library for the Cisco Firepower Management
Center (FMC) REST API version 1.
Currently it is developed and tested against FMC version 6.2.3.6.

=head1 ATTRIBUTES

=head2 domains

Returns a list of hashrefs containing name and uuid of all domains which gets
populated by L</login>.

=head2 domain_uuid

The UUID of the domain which is used by all methods.

=head1 METHODS

=head2 login

Logs into the FMC by fetching an authentication token via http basic
authentication.

=head2 relogin

Refreshes the session by loging in again (not using the refresh token) and
restores the currently set domain_uuid.

=head2 create_accessrule

Takes an access policy id, a hashref of the rule which should be created and
optional query parameters.

=head2 list_accessrules

Takes an access policy id and query parameters and returns a hashref with a
single key 'items' that has a list of access rules similar to the FMC API.

=head2 get_accessrule

Takes an access policy id, rule id and query parameters and returns the access
rule.

=head2 update_accessrule

Takes an access policy id, rule object and a hashref of the rule and returns
a hashref of the updated access rule.

=head2 delete_accessrule

Takes an access policy id and a rule object id.

Returns true on success.

=head2 list_deployabledevices

Takes optional query parameters and returns a hashref with a
single key 'items' that has a list of deployable devices similar to the FMC
API.

=head2 create_deploymentrequest

Takes a hashref of deployment parameters.

Returns the created task in the ->{metadata}->{task} hashref.

=head2 get_task

Takes a task id and returns its status.

=head2 wait_for_task

Takes a task id and an optional callback and checks its status every second
until it isn't in-progress any more.
The in-progress status is different for each task type, currently only
'DEVICE_DEPLOYMENT' is supported.
The callback coderef which is called for every check with the task as argument.

Returns the task.

=head2 cleanup_protocolport

Takes a ProtocolPortObject and renames it to protocol_port, e.g. tcp_443.
If it has no port 'any' is used instead of the port number no avoid
'predefined name' errors.
Returns the ProtocolPortObject with the updated attributes.

=head2 cleanup_icmpv4object

Takes a ICMPv4Object and renames it to protocol_type[_code], e.g. icmp_8_0.
If it has no code only protocol and type is used.

=head2 cleanup_hosts

=over

=item removes '_Mask32' from the name

=item removes the description if it is 'Created during ASA Migration'

=back

=head2 create_cleaned_accesspolicy

Takes an access policy name and a hashref of optional arguments.

=head3 Optional arguments

=over

=item target_access_policy_name

Defaults to access policy name with the postfix '-cleaned'.

=item rule_name_coderef

Gets passed the rule number and rule object and must return the new rule name.

=back

Creates a new access policy with the target name containing all rules of the
input access policy but cleaned by the following rules:

=over

=item the commentHistoryList is omitted

=item replace autogenerated DM_INLINE_ NetworkGroups by their content

Only if they don't contain more than 50 items because of the current limit in
FMC.

=item replace autogenerated DM_INLINE_ PortObjectGroups by their content

=item optional: the rule name is generated

By passing a coderef named 'rule_name_coderef' in the optional arguments
hashref.

=back

The new access policy is created with a defaultAction of:

    action          => 'BLOCK'
    logBegin        => true
    sendEventsToFMC => true

This is mainly for access policies migrated by the Cisco Firepower Migration
Tool from a Cisco ASA.

Supports resuming.

=head1 KNOWN BUGS

Older FMC versions have bugs like:

=over

=item truncated JSON responses

No workaround on client side possible, only a FMC update helps.

=item no response to the 11th call (version 6.2.2.1)

No workaround on client side because newer FMC versions (at least 6.2.3.6)
throttle the login call too.

=item accessrule is created but error 'You do not have the required
authorization to do this operation' is thrown (version 6.2.2)

No workaround on client side possible, only a FMC update helps.

=back

=head1 AUTHOR

Alexander Hartmaier <abraxxa@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 - 2020 by Alexander Hartmaier.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
