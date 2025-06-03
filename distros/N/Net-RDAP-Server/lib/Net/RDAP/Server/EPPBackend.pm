package Net::RDAP::Server::EPPBackend;
# ABSTRACT: an RDAP server that retrieves registration data from an EPP server.
use base qw(Net::RDAP::Server);
use List::Util qw(any);
use JSON::PP;
use Net::EPP::Simple;
use Net::RDAP::EPPStatusMap;
use Net::EPP::ResponseCodes;
use vars qw($EVENTS $CONTACTS);
use common::sense;


#
# this maps EPP event element names to the corresponding RDAP event type, and if
# applicable, the entity that performed the event action.
#
$EVENTS = {
    crDate  => [q{registration}, q{crID}],
    exDate  => [q{expiration}           ],
    upDate  => [q{last changed}, q{upID}],
    trDate  => [q{transfer},     q{trID}],
};

#
# this maps EPP contact types to the equivalent RDAP role.
#
$CONTACTS = {
    admin   => q{administrative},
    tech    => q{technical},
    billing => q{billing},
};

sub set_backend {
    my ($self, %args) = @_;

    $self->{_epp} = Net::EPP::Simple->new(%args);

    $self->set_handlers;

    return $self;
}

sub epp { shift->{_epp} }

sub set_handlers {
    my $self = shift;

    $self->set_handler(HEAD => 'help',      sub { shift->ok                 });
    $self->set_handler(GET  => 'help',      sub { $self->get_help(@_)       });
    $self->set_handler(HEAD => q{domain},   sub { $self->head_domain(@_)    });
    $self->set_handler(GET  => q{domain},   sub { $self->get_domain(@_)     });
}

sub get_help {
    my ($self, $response) = @_;

    $response->ok;

    $response->content({
        rdapConformance => [q{rdap_level_0}],
        notices => [ {
            title => 'About this server',
            description => [ 'This server runs on '.__PACKAGE__.'.' ],
        } ]
    });
}

#
# Perform a <check> command and set the HTTP status depending on the object
# availability
#
sub head_domain {
    my ($self, $response) = @_;

    my $avail = $self->epp->check_domain($response->request->object);

    if (!defined($avail)) {
        $response->error(504, q{Unable to query EPP server.});

    } elsif (0 == $avail) {
        $response->ok;

    }
}

#
# Perform an <info> command, and if successful, construct an RDAP response from
# the information return.
#
sub get_domain {
    my ($self, $response) = @_;

    my $info = $self->epp->domain_info($response->request->object);

    if ($info) {
        $response->ok;
        $response->content($self->generate_domain_record($info));

    } elsif (OBJECT_DOES_NOT_EXIST == $Net::EPP::Simple::Code) {
        $response->error(404, $Net::EPP::Simple::Error);

    } elsif (AUTHORIZATION_ERROR == $Net::EPP::Simple::Code) {
        $response->error(403, $Net::EPP::Simple::Error);

    } else {
        $response->error(504, $Net::EPP::Simple::Error);

    }
}

#
# Convert an EPP <info> response to an RDAP response.
#
sub generate_domain_record {
    my ($self, $info) = @_;

    my $domain = {
        rdapConformance => [q{rdap_level_0}],
        objectClassName => q{domain},
        ldhName         => $info->{name},
        handle          => $info->{roid},
        status          => $self->generate_status($info),
        nameservers     => $self->generate_nameservers($info),
        secureDNS       => $self->generate_dnssec($info),
        events          => $self->generate_events($info),
        entities        => $self->generate_entities($info),
    };

    return $domain;
}

#
# Convert DNSSEC info from an <info> response.
#
sub generate_dnssec {
    my ($self, $info) = @_;

    if ($info->{DS}) {
        return {
            delegationSigned => $JSON::PP::true,
            dsData => $self->generate_dnssec_dsdata($info->{DS}),
        };

    } elsif ($info->{DNSKEY}) {
        return {
            delegationSigned => $JSON::PP::true,
            keyData => $self->generate_dnssec_keydata($info->{DNSKEY}),
        };

    } else {
        return {
            delegationSigned => $JSON::PP::false,
        };

    }
}

#
# Convert dsData info from an <info> response.
#
sub generate_dnssec_dsdata {
    my ($self, $ds) = @_;

    my @dsData;

    foreach my $ds (map { [ split(/ /, $_, 4)] } @{$ds}) {
        push(@dsData, {
            keyTag      => int($ds->[0]),
            algorithm   => int($ds->[1]),
            digestType  => int($ds->[2]),
            digest      => $ds->[3],
        });
    }

    return \@dsData;
}

#
# Convert keyData info from an <info> response.
#
sub generate_dnssec_keydata {
    my ($self, $keys) = @_;

    my @keyData;

    foreach my $key (map { [ split(/ /, $_, 4)] } @{$keys}) {
        push(@keyData, {
            flags       => int($key->[0]),
            protocol    => int($key->[1]),
            algorithm   => int($key->[2]),
            publicKey   => $key->[3],
        });
    }

    return \@keyData;
}

#
# Convert the EPP status codes in an EPP <info> response to an arrayref of RDAP
# status codes.
#
sub generate_status {
    my ($self, $info) = @_;
    return [ map { epp2rdap($_) } @{$info->{status}} ];
}

#
# Convert the nameservers in an EPP <info> response to an arrayref of RDAP
# nameserver objects.
#
sub generate_nameservers {
    my ($self, $info) = @_;
    return [ map { { objectClassName => q{nameserver}, ldhName => $_ } } @{$info->{ns}} ],
}

#
# Convert the events in an EPP <info> response to an arrayref of RDAP
# event objects.
#
sub generate_events {
    my ($self, $info) = @_;

    my @events;

    foreach my $key (grep { exists($info->{$_}) } keys(%{$EVENTS})) {
        my $event = {
            eventAction => $EVENTS->{$key}->[0],
            eventDate   => $info->{$key},
        };

        if (exists($EVENTS->{$key}->[1]) && exists($info->{$EVENTS->{$key}->[1]})) {
            $event->{eventActor} = $info->{$EVENTS->{$key}->[1]};
        }

        push(@events, $event);
    }

    return \@events;
}

#
# Convert the contact/client IDs in an EPP <info> response to an arrayref of
# RDAP entity objects.
#
sub generate_entities {
    my ($self, $info) = @_;

    #
    # this maps contact IDs to the appropriate RDAP role
    #
    my $roles => {};

    push(@{$roles->{$info->{registrant}}},  q{registrant})  if (exists($info->{registrant}));
    push(@{$roles->{$info->{clID}}},        q{registrar})   if (exists($info->{clID}));

    foreach my $role (keys(%{$info->{contacts}})) {
        push(@{$roles->{$info->{contacts}->{$role}}}, $CONTACTS->{$role});
    }

    return [ map { $self->generate_entity($_, $roles->{$_}) } sort(keys(%{$roles})) ];
}

#
# Given a contact/client ID, construct an RDAP entity.
#
sub generate_entity {
    my ($self, $handle, $roles) = @_;

    my $entity = {
        objectClassName => q{entity},
        handle          => $handle,
        roles           => $roles,
    };

    if (1 < scalar(@{$roles}) || q{registrar} ne $roles->[0]) {
        if (my $cinfo = $self->epp->contact_info($handle)) {
            $entity->{vcardArray} = $self->generate_vcardArray($cinfo);
        }
    }

    return $entity;
}

#
# Given a contact <info> respose, construct a JCard object.
#
sub generate_vcardArray {
    my ($self, $info) = @_;

    my @props;

    push(@props, [q{version}, {}, q{text}, q{4.0}]);

    foreach my $type (qw(int loc)) {
        if (exists($info->{postalInfo}->{$type})) {
            push(@props, $self->generate_postal_info($info->{postalInfo}->{$type}));
            last;
        }
    }

    push(@props, $self->generate_telephones($info));

    push(@props, [
        q{email},
        {},
        q{text},
        $info->{email},
    ]);

    return [q{vcard}, \@props];
}

#
# Given a contact <info> respose, generate a set of JCard properties for the
# postal address information.
#
sub generate_postal_info {
    my ($self, $info) = @_;

    my @props;

    #
    # the FN property is mandatory
    #
    push(@props, [
        q{fn},
        {},
        q{text},
        $info->{name} || "",
    ]);

    if (exists($info->{org}) && length($info->{org}) > 0) {
        push(@props, [
            q{kind},
            {},
            q{text},
            q{org},
        ]);
        push(@props, [
            q{org},
            {},
            q{text},
            $info->{org},
        ]);
    }

    push(@props, [
        q{adr},
        {
            cc => $info->{addr}->{cc},
        },
        q{text},
        [ map { $_ || "" } (
            undef,
            undef,
            $info->{addr}->{street},
            $info->{addr}->{city},
            $info->{addr}->{sp},
            $info->{addr}->{pc},
            undef,
        ) ]
    ]);

    return @props;
}

#
# Given a contact <info> respose, generate a set of JCard properties for the
# voice and fax numbers.
#
sub generate_telephones {
    my ($self, $info) = @_;

    my @props;

    foreach my $type (qw(voice fax)) {
        if (exists($info->{$type}) && length($info->{$type}) > 0) {
            push(@props, [
                q{tel},
                {type => $type},
                q{text},
                $info->{$type},
            ]);
        }
    }

    return @props;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::RDAP::Server::EPPBackend - an RDAP server that retrieves registration data from an EPP server.

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    #!/usr/bin/env perl
    use Net::RDAP::Server::EPPBackend;
    use common::sense;

    Net::RDAP::Server::EPPBackend->new
        ->set_backend(
            host => 'epp.nic.tld',
            user => 'my-clid',
            pass => 'my-pwd',
        )
        ->run;

=head1 DESCRIPTION

L<Net::RDAP::Server::EPPBackend> implements an RDAP server that answers RDAP
queries using data retrieved from an EPP server. It is based on
L<Net::RDAP::Server>, and uses L<Net::EPP::Simple> to talk to the EPP server.

=head2 EPP SERVER INTEGRATION

Use the C<set_backend()> method to specify the details of the EPP server to
use. The arguments to this method are the same as those of L<Net::EPP::Simple>'s
constructor.

The EPP client specified in the C<user> parameter needs to have appropriate
privileges to perform C<E<lt>infoE<gt>> commands on any domain in the EPP
repository, otherwise, any query for a domain not under its sponsorship will
result in an HTTP error.

=head2 IMPORTANT NOTE

This module is a proof-of-concept that may be useful to those interested in
deploying RDAP. It should be noted that the server has B<no> support for any of
the following:

=over

=item * Entity and nameserver queries;

=item * Concurrency;

=item * HTTPS;

=item * Caching;

=item * Redaction of personal information.

=back

=head1 AUTHOR

Gavin Brown <gavin.brown@fastmail.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Gavin Brown.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
