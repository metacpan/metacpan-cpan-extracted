package Net::Cisco::FMC::v1::Role::FixAccessruleLiterals;
$Net::Cisco::FMC::v1::Role::FixAccessruleLiterals::VERSION = '0.005001';
# ABSTRACT: Role for Cisco Firepower Management Center (FMC) API version 1 method generation

use 5.024;
use feature 'signatures';
use NetAddr::IP::Lite ':nofqdn';
use Moo::Role;

no warnings "experimental::signatures";

requires qw( get_accessrule list_accessrules );


sub _fix_accessrule_literals ($accessrule) {
    for my $attr (qw( sourceNetworks destinationNetworks )) {
        my @literals;
        for my $obj ($accessrule->{$attr}->{literals}->@*) {
            if ($obj->{type} eq 'FQDN') {
                # NOTE: this never throws an exception but returns undef
                my $ip = NetAddr::IP::Lite->new($obj->{value});
                if (defined $ip) {
                    $obj->{type} =
                        (  ( $ip->version == 4 && $ip->masklen == 32 )
                        || ( $ip->version == 6 && $ip->masklen == 128 ) )
                        ? 'Host'
                        : 'Network';
                }
            }
            push @literals, $obj;
        }
        $accessrule->{$attr}->{literals} = \@literals;
    }

    return $accessrule;
}

around 'get_accessrule' => sub {
    my $orig = shift;
    my $self = shift;
    my $data = $orig->($self, @_);

    return _fix_accessrule_literals($data);
};

around 'list_accessrules' => sub {
    my $orig = shift;
    my $self = shift;
    my $data = $orig->($self, @_);

    my @rules = map { _fix_accessrule_literals($_) } $data->{items}->@*;
    $data->{items} = \@rules;

    return $data;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Cisco::FMC::v1::Role::FixAccessruleLiterals - Role for Cisco Firepower Management Center (FMC) API version 1 method generation

=head1 VERSION

version 0.005001

=head1 SYNOPSIS

    use strict;
    use warnings;
    use Net::Cisco::FMC::v1;
    use Moo::Role ();

    my $fmc = Net::Cisco::FMC::v1->new(
        server      => 'https://fmcrestapisandbox.cisco.com',
        user        => 'admin',
        passwd      => '$password',
        clientattrs => { timeout => 30 },
    );

    Moo::Role->apply_roles_to_object($fmc,
        'Net::Cisco::FMC::v1::Role::FixAccessruleLiterals');

=head1 DESCRIPTION

Cisco FMC 6.3.0 introduced support for FQDN objects which broke literal IPv4
host and network objects via the accessrules REST API.
Even worse not only are the types of the replies incorrect but updating an
existing rule or creating a new one based on a reply silently swallows literal
host and network objects which have their type set to FQDN.

This role works around this bug by modifying the reply of
L</Net::Cisco::FMC::v1/get_accessrule> and
L<Net::Cisco::FMC::v1/list_accessrules> and replacing 'FQDN' with 'Network'.

This is how an accessrule API response looks like in 6.2.3.7:

    {
      "links": {
        "self": "https://fmc6237.example.com/api/fmc_config/v1/domain/e276abec-e0f2-11e3-8169-6d9ed49b625f/policy/accesspolicies/005056A6-88ED-0ed3-0000-330712486749/accessrules?offset=0&limit=1&expanded=true"
      },
      "items": [
        {
          "metadata": {
            "ruleIndex": 1,
            "section": "Mandatory",
            "category": "--Undefined--",
            "accessPolicy": {
              "type": "AccessPolicy",
              "name": "test",
              "id": "005056A6-88ED-0ed3-0000-330712486749"
            },
            "timestamp": 1551185188796,
            "domain": {
              "name": "Global",
              "id": "e276abec-e0f2-11e3-8169-6d9ed49b625f",
              "type": "Domain"
            }
          },
          "links": {
            "self": "https://fmc6237.example.com/api/fmc_config/v1/domain/e276abec-e0f2-11e3-8169-6d9ed49b625f/policy/accesspolicies/005056A6-88ED-0ed3-0000-330712486749/accessrules/005056A6-88ED-0ed3-0000-000268435459"
          },
          "enabled": true,
          "name": "test",
          "type": "AccessRule",
          "action": "ALLOW",
          "id": "005056A6-88ED-0ed3-0000-000268435459",
          "sourceNetworks": {
            "literals": [
              {
                "type": "Network",
                "value": "10.0.0.0/24"
              }
            ]
          },
          "destinationNetworks": {
            "literals": [
              {
                "type": "Host",
                "value": "10.1.0.1"
              }
            ]
          },
          "logBegin": false,
          "logEnd": false,
          "variableSet": {
            "name": "Default-Set",
            "id": "76fa83ea-c972-11e2-8be8-8e45bb1343c0",
            "type": "VariableSet"
          },
          "logFiles": false,
          "vlanTags": {},
          "sendEventsToFMC": false
        }
      ],
      "paging": {
        "offset": 0,
        "limit": 1,
        "count": 1,
        "pages": 1
      }
    }

And on FMC 6.3.0.1:

    {
      "links": {
        "self": "https://fmc6301.example.com/api/fmc_config/v1/domain/e276abec-e0f2-11e3-8169-6d9ed49b625f/policy/accesspolicies/00505688-74E1-0ed3-0000-193273532969/accessrules?offset=0&limit=1&expanded=true"
      },
      "items": [
        {
          "metadata": {
            "ruleIndex": 1,
            "section": "Mandatory",
            "category": "--Undefined--",
            "accessPolicy": {
              "type": "AccessPolicy",
              "name": "test",
              "id": "00505688-74E1-0ed3-0000-193273532969"
            },
            "timestamp": 1551185492316,
            "domain": {
              "name": "Global",
              "id": "e276abec-e0f2-11e3-8169-6d9ed49b625f",
              "type": "Domain"
            }
          },
          "links": {
            "self": "https://fmc.6301.example.com/api/fmc_config/v1/domain/e276abec-e0f2-11e3-8169-6d9ed49b625f/policy/accesspolicies/00505688-74E1-0ed3-0000-193273532969/accessrules/00505688-74E1-0ed3-0000-000268447785"
          },
          "id": "00505688-74E1-0ed3-0000-000268447785",
          "sourceNetworks": {
            "literals": [
              {
                "type": "Network",
                "value": "10.0.0.0/24"
              }
            ]
          },
          "destinationNetworks": {
            "literals": [
              {
                "type": "FQDN",
                "value": "1.1.0.1"
              }
            ]
          },
          "logFiles": false,
          "logBegin": false,
          "logEnd": false,
          "variableSet": {
            "name": "Default-Set",
            "id": "76fa83ea-c972-11e2-8be8-8e45bb1343c0",
            "type": "VariableSet"
          },
          "enableSyslog": false,
          "vlanTags": {},
          "sendEventsToFMC": false,
          "type": "AccessRule",
          "action": "ALLOW",
          "name": "test",
          "enabled": true
        }
      ],
      "paging": {
        "offset": 0,
        "limit": 1,
        "count": 1,
        "pages": 1
      }
    }

=head1 AUTHOR

Alexander Hartmaier <abraxxa@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 - 2020 by Alexander Hartmaier.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
