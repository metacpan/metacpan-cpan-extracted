#!/usr/bin/perl
#
# NoZone::Zone - record information for a bind zone
#
# Copyright (C) 2013-2021  Daniel P. Berrange <dan@berrange.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

package NoZone::Zone;

use strict;
use warnings;

use POSIX qw(strftime);

=head1 NAME

Nozone::Zone - record information for a bind zone

=head1 SYNOPSIS

  use Nozone::Zone;

  my $nozone = Nozone::Zone->new(
    domains => [
      "nozone.org",
      "nozone.com",
    ],
    hostmaster => "hostmaster",
    lifetimes => {
      refresh => "1H",
      retry => "15M",
      expire => "1W"
      negative => "1H",
      ttl => "1H",
    },
    machines => {
      platinum => {
        ipv4 => "12.32.56.1"
        ipv6 => "2001:1234:6789::1"
      },
      gold => {
        ipv4 => "12.32.56.2"
        ipv6 => "2001:1234:6789::2"
      },
      silver => {
        ipv4 => "12.32.56.3"
        ipv6 => "2001:1234:6789::3"
      },
    },
    default => "platinum",
    spf => {
      policy => "reject",
      machines => [
         "gold",
         "silver"
      ]
    },
    dkim => {
      "default" => {
        version => "DKIM1",
        keytype => "rsa",
        pubkey => "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC1TaNgLlSyQMNWVLNLvyY/neDgaL2oqQE8T5illKqCgDtFHc8eHVAU+nlcaGmrKmDMw9dbgiGk1ocgZ56NR4ycfUHwQhvQPMUZw0cveel/8EAGoi/UyPmqfcPibytH81NFtTMAxUeM4Op8A6iHkvAMj5qLf4YRNsTkKAV"
      },
    },
    dmarc => {
      version => "DMARC1",
      policy => "none",
      subdomain_policy => "none",
      percent => "20",
      forensic_report => "mailto:dmarcfail@example.com",
      aggregate_report => "mailto:dmarcagg@example.com",
    },
    mail => {
      mx0 => {
        priority => 10,
        machine => "gold"
      },
      mx1 => {
        priority => 30,
        machine => "silver"
      },
    },
    dns => {
      ns0 => "gold",
      ns1 => "silver",
    },
    names => {
      www => "platinum",
    },
    aliases => {
      db => "gold",
      backup => "silver",
    },
    txt => {
      challenge1 => "9e428dae-b677-49b6-9eb9-a5754cbbfc2c",
    },
    wildcard => "platinum",
    inherits => $parentzone,
  );

  foreach my $domain ($zone->get_domains()) {
    my $conffile = "/etc/named/$domain.conf";
    my $datafile = "/var/named/data/$domain.data";

    my $conffh = IO::File->new($conffile, ">");
    $zone->generate_conffile($conffh, $domain, $datafile);
    $conffh->close();

    my $datafh = IO::File->new($datafile, ">");
    $zone->generate_datafile($datafh, $domain);
    $datafh->close();
  }

=head1 DESCRIPTION

The C<NoZone::Zone> class records the information for a single
DNS zone. A DNS zone can be associated with zero or more domain
names. A zone without any associated domain names can serve as
an abstract base from which other zones inherit data. Inheritance
of zones allows admins to minimize the duplication of data across
zones.

A zone contains a number of parameters, which are usually provided
when the object is initialized.

=over 4

=item domains

The C<domains> parameter is an array reference providing the list
of domain names associated with the DNS zone.

    domains => [
      "nozone.org",
      "nozone.com",
    ]

=item hostmaster

The C<hostmaster> parameter is the local part of the email address
of the person who manages the domain. This will be combined with
the domain name to form the complete email address

    hostmaster => "hostmaster"

=item lifetimes

The C<lifetimes> parameter specifies various times for DNS zone
records. These are use to populate the SOA records in the zone.

    lifetimes => {
      refresh => "1H",
      retry => "15M",
      expire => "1W"
      negative => "1H",
      ttl => "1H",
    }

=item machines

The C<machines> parameter is a hash reference whose keys are the
names of physical machines. The values are further hash references
specifying the IPv4 and IPv6 addresses for the names.

    machines => {
      platinum => {
        ipv4 => "12.32.56.1"
        ipv6 => "2001:1234:6789::1"
      },
      gold => {
        ipv4 => "12.32.56.2"
        ipv6 => "2001:1234:6789::2"
      },
      silver => {
        ipv4 => "12.32.56.3"
        ipv6 => "2001:1234:6789::3"
      },
    }

=item default

The C<default> parameter is used to specify the name of the
machine which will be use as the default when resolving the
base domain name

    default => "platinum"

=item mail

The C<mail> parameter is a hash reference whose keys are the
names to setup as mail servers. The values are an further has
reference whose elements specify the priority of the mail
server and the name of the machine defined in the C<machines>
parameter.

    mail => {
      mx0 => {
        priority => 10,
        machine => "gold"
      },
      mx1 => {
        priority => 30,
        machine => "silver"
      },
    }

=item dns

The C<dns> parameter is a hash reference whose keys are the
names to setup as DNS servers. The values are the names of
machines defined in the C<machines> parameter which are to
used to define the corresponding IP addresses

    dns => [
      ns0 => "gold",
      ns1 => "silver",
    ]

=item names

The C<names> parameter is a hash reference whose keys reflect
additional names to be defined as A/AAAA records for the zone.
The values refer to keys in the C<machines> parameter and are
used to define the corresponding IP addresses

    names => {
      www => "platinum",
    }

=item aliases

The C<aliases> parameter is a hash reference whose keys reflect
additional names to be defiend as CNAME records for the zone.
The values refer to keys in the C<machines> or C<names>
parameter and are used to the define the CNAME target.

    aliases => {
      db => "gold",
      backup => "silver",
    }

=item wildcard

The C<wildcard> parameter is a string refering to a name
defined in the C<machines> parameter. If set this parameter
is used to defined a wildcard DNS entry in the zone.

    wildcard => "platinum"

=item spf

The C<spf> parameter is a hash reference setting up the
SPF records. The C<policy> key takes one of the values
B<reject>, B<accept>, or B<mark>, to specify what happens
when an IP doesn't match the SPF. The C<machines> key
is an array reference that specifies the list of machine
names that are permitted to send email.

=item dkim

The C<dkim> parameter is a hash of hash references setting
up the DKIM records. The key for the first level hash is
the DKIM selector. The second level hashes contain the
following keys.

The C<version> key must always be C<DKIM1>. The C<keytype>
key must be a public key algorithm name, typically 'rsa'.
The C<service> key is a string restricting the usage.
The C<pubkey> key is the public key.

=item dmarc

The C<dkim> parameter is a hash reference setting up the
DMARC records.

The C<version> key must always be C<DMARC1>. The C<policy>
key is one of C<none>, C<quarantine> or C<reject>. The
C<subdomain_policy> key takes the same values. The
C<percent> key indicates how often to filter messages.
The C<forensic_report> and C<aggregate_report> keys
give a URI for sending reports.

=item txt

The C<txt> parameter is a has of arbitrary key and value
strings, which will be added as TXT records.

=back

=head1 METHODS

=over 4

=item my $zone = NoZone::Zone->new(%params);

Creates a new L<NoZone::Zone> object to hold information
about a DNS zone. The C<%params> has keys are allowed to
be any of the parameters documented earlier in this
document. In addition the C<inherits> parameter is valid
and can refer to another instance of the L<NoZone::Zone>
class.

=cut


sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    my %params = @_;

    $self->{domains} = $params{domains} ? $params{domains} : [];
    $self->{hostmaster} = $params{hostmaster} ? $params{hostmaster} : "hostmaster";
    $self->{lifetimes} = $params{lifetimes} ? $params{lifetimes} : undef;
    $self->{machines} = $params{machines} ? $params{machines} : {};
    $self->{default} = $params{default} ? $params{default} : undef;
    $self->{mail} = $params{mail} ? $params{mail} : {};
    $self->{dns} = $params{dns} ? $params{dns} : [];
    $self->{names} = $params{names} ? $params{names} : {};
    $self->{aliases} = $params{aliases} ? $params{aliases} : {};
    $self->{txt} = $params{txt} ? $params{txt} : {};
    $self->{wildcard} = $params{wildcard} ? $params{wildcard} : undef;
    $self->{spf} = $params{spf} ? $params{spf} : undef;
    $self->{dkim} = $params{dkim} ? $params{dkim} : {};
    $self->{dmarc} = $params{dmarc} ? $params{dmarc} : undef;
    $self->{inherits} = $params{inherits} ? $params{inherits} : undef;

    bless $self, $class;

    return $self;
}


=item $zone->set_inherits($parentzone);

Sets the zone from which this zone will inherit data
parameters. The C<$parentzone> method should be an
instance of the C<NoZone::Zone> class.

=cut


sub set_inherits {
    my $self = shift;
    my $zone = shift;

    $self->{inherits} = $zone;
}


=item my @domains = $zone->get_domains();

Returns the array of domain names associated directly
with this zone.

=cut

sub get_domains {
    my $self = shift;

    return @{$self->{domains}};
}


=item my $name = $zone->get_hostmaster();

Returns the hostmaster setting associated with this
zone, if any. If no hostmaster is set against this zone,
then the hostmaster from any parent zone will be returned.
If no parent zone is present, an undefined value will
be returned.

=cut

sub get_hostmaster {
    my $self = shift;

    if (defined $self->{hostmaster}) {
	return $self->{hostmaster};
    }

    if (defined $self->{inherits}) {
	return $self->{inherits}->get_hostmaster();
    }

    return "hostmaster";
}


=item my %lifetimes = $zone->get_lifetimes();

Return a hash containing the lifetimes defined against
this zone. If no data is defined for this zone, then
the data from any parent zone is returned. If not
parent zone is set, then some sensible default times
are returned.

=cut

sub get_lifetimes {
    my $self = shift;

    if (defined $self->{lifetimes}) {
	return %{$self->{lifetimes}};
    }

    if ($self->{inherits}) {
	return $self->{inherits}->get_lifetimes();
    }

    return (
	refresh => "1H",
	retry => "15M",
	expire => "1W",
	negative => "1H",
	ttl => "1H",
    );
}


=item my %machines = $zone->get_machines();

Return hash containing the union of all the machines
defined in this zone and its parent(s) recursively.

=cut

sub get_machines {
    my $self = shift;

    my %machines;

    if ($self->{inherits}) {
	%machines = $self->{inherits}->get_machines();
    }

    foreach my $name (keys %{$self->{machines}}) {
	$machines{$name} = $self->{machines}->{$name};
    }

    return %machines;
}


=item $machine = $zone->get_machine($name);

Return a hash reference containing the IP addresses
associated with the machine named C<$name>.

=cut

sub get_machine {
    my $self = shift;
    my $name = shift;

    my %machines = $self->get_machines();

    return exists $machines{$name} ? $machines{$name} : undef;
}


=item my $name = $zone->get_default();

Returns the name of the machine to be used as the
default for the zone. If no default is defined
for this zone, then the default from any parent
zone is defined. If no parent zone is defined,
then return an undefined value

=cut

sub get_default {
    my $self = shift;

    if (defined $self->{default}) {
	return $self->{default};
    }

    if (defined $self->{inherits}) {
	return $self->{inherits}->get_default();
    }

    return undef;
}


=item my %dns = $zone->get_dns();

Return a hash containing the union of all the machines
defined as dns servers in this zone and its parent(s)
recursively.

=cut

sub get_dns {
    my $self = shift;

    my %dns;

    if ($self->{inherits}) {
	%dns = $self->{inherits}->get_dns();
    }

    foreach my $name (keys %{$self->{dns}}) {
	$dns{$name} = $self->{dns}->{$name};
    }

    return %dns;
}


=item my %mail = $zone->get_mail();

Return a hash containing the union of all the machines
defined as mail servers in this zone and its parent(s)
recursively.

=cut

sub get_mail {
    my $self = shift;

    my %mail;

    if ($self->{inherits}) {
	%mail = $self->{inherits}->get_mail();
    }

    foreach my $name (keys %{$self->{mail}}) {
	$mail{$name} = $self->{mail}->{$name};
    }

    return %mail;
}


=item %names = $zone->get_names();

Return a hash containing the union of all the machine
hostnames defined in this zone and its parent(s)
recursively.

=cut

sub get_names {
    my $self = shift;

    my %names;

    if ($self->{inherits}) {
	%names = $self->{inherits}->get_names();
    }

    foreach my $name (keys %{$self->{names}}) {
	$names{$name} = $self->{names}->{$name};
    }

    return %names;
}


=item %names = $zone->get_aliases();

Return a hash containing the union of all the machine
aliases defined in this zone and its parent(s)
recursively.

=cut

sub get_aliases {
    my $self = shift;

    my %aliases;

    if ($self->{inherits}) {
	%aliases = $self->{inherits}->get_aliases();
    }

    foreach my $name (keys %{$self->{aliases}}) {
	$aliases{$name} = $self->{aliases}->{$name};
    }

    return %aliases;
}


=item %names = $zone->get_txt();

Return a hash containing the union of all the TXT
records defined in this zone and its parent(s)
recursively.

=cut

sub get_txt {
    my $self = shift;

    my %txt;

    if ($self->{inherits}) {
	%txt = $self->{inherits}->get_txt();
    }

    foreach my $name (keys %{$self->{txt}}) {
	$txt{$name} = $self->{txt}->{$name};
    }

    return %txt;
}


=item %selectors = $zone->get_dkim_selectors();

Return a hash containing the union of all the dkim
records defined in this zone and its parent(s)
recursively.

=cut

sub get_dkim_selectors {
    my $self = shift;

    my %selectors;

    if ($self->{inherits}) {
	%selectors = $self->{inherits}->get_dkim_selectors()
    }

    foreach my $selector (keys %{$self->{dkim}}) {
	$selectors{$selector} = $self->{dkim}->{$selector};
    }

    return %selectors;
}


=item my $name = $zone->get_wildcard();

Return the name of the machine which will handle
wildcard name lookups. If no wildcard is defined
against the zone, returns the wildcard of the
parent zone. If there is no parent zone, an
undefined value is returned, indicating that no
wildcard DNS entry will be created.

=cut

sub get_wildcard {
    my $self = shift;

    if (defined $self->{wildcard}) {
	return $self->{wildcard};
    }

    if ($self->{inherits}) {
	return $self->{inherits}->get_wildcard();
    }

    return undef;
}

=item my $policy = $zone->get_spf_policy();

Returns the policy for SPF records for the domain.
The policy is one of the string B<accept>, B<reject>
or B<mark>. If no SPF policy is defined gainst the
zone, returns the SPF policy of the parent zone.
if there is no parent zone an undefined value is
returned indicating that no SPF entry will be
created.

=cut

sub get_spf_policy {
    my $self = shift;

    if (defined $self->{spf}) {
	return $self->{spf}->{policy};
    }

    if ($self->{inherits}) {
	return $self->{inherits}->get_spf_policy();
    }

    return undef;
}


=item my @machines = $zone->get_spf_machines();

Returns the list of machines that are permitted to
send mail to record as SPF records. If no machines
are defined against the zone, returns the machines
of teh parent zone. If there is no parent zone an
empty list if returned

=cut

sub get_spf_machines {
    my $self = shift;

    if (defined $self->{spf}) {
	return @{$self->{spf}->{machines}};
    }

    if ($self->{inherits}) {
	return $self->{inherits}->get_spf_machines();
    }

    return ();
}


=item my $config = $zone->get_dmarc_config();

Returns the config for the DMARC records for the domain.
If no DMARC config is defined gainst the
zone, returns the DMAWRC config of the parent zone.
if there is no parent zone undefined values are
returned indicating that no DMARC entry will be
created.

=cut

sub get_dmarc_config {
    my $self = shift;

    if (defined $self->{dmarc}) {
	return $self->{dmarc};
    }

    if ($self->{inherits}) {
	return $self->{inherits}->get_dmarc_config();
    }

    return undef;
}



=item $zone->generate_conffile($fh, $domain, $datafile, \@masters, $verbose=0);

Generate a Bind zone conf file for the domain C<$domain>
writing the data to the file handle C<$fh>. C<$fh>
should be an instance of L<IO::File>. The optional C<$verbose>
parameter can be set to a true value to print progress on
stdout. If C<@masters> is a non-empty list, then a slave
config will be created, otherwise a master config will be
created. The C<$datafile> parameter should specify the
path to the corresponding zone data file, usually kept
in C</var/named/data>.

=cut

sub generate_conffile {
    my $self = shift;
    my $fh = shift;
    my $domain = shift;
    my $datafile = shift;
    my $masters = shift;
    my $verbose = shift || 0;

    if (int(@{$masters})) {
	my $masterlist = join (" ; ", @{$masters});

	print $fh <<EOF;
zone "$domain" in {
    type slave;
    file "$datafile";
    masters { $masterlist ; };
};
EOF
    } else {
	print $fh <<EOF;
zone "$domain" in {
    type master;
    file "$datafile";
};
EOF
    }
}


=item $zone->generate_datafile($fh, $domain, $verbose=0);

Generate a Bind zone data file for the domain C<$domain>
writing the data to the file handle C<$fh>. C<$fh>
should be an instance of L<IO::File>. The optional C<$verbose>
parameter can be set to a true value to print progress on
stdout.

=cut

sub generate_datafile {
    my $self = shift;
    my $fh = shift;
    my $domain = shift;
    my $verbose = shift || 0;

    $self->_generate_soa($fh, $domain, $verbose);
    $self->_generate_default($fh, $verbose);
    $self->_generate_dns($fh, $verbose);
    $self->_generate_mail($fh, $verbose);
    $self->_generate_machines($fh, $verbose);
    $self->_generate_names($fh, $verbose);
    $self->_generate_aliases($fh, $verbose);
    $self->_generate_dkim($fh, $verbose);
    $self->_generate_dmarc($fh, $verbose);
    $self->_generate_txt($fh, $verbose);
    $self->_generate_wildcard($fh, $verbose);
}


sub _generate_soa {
    my $self = shift;
    my $fh = shift;
    my $domain = shift;
    my $verbose = shift;

    print "    - Generate soa $domain\n" if $verbose;

    my $hostmaster = $self->get_hostmaster();

    my $now = time;
    my $time = strftime("%Y/%m/%d %H:%M:%S", gmtime(time));

    my %lifetimes = $self->get_lifetimes();
    my $refresh = $lifetimes{refresh};
    my $retry = $lifetimes{retry};
    my $expire = $lifetimes{expire};
    my $negative = $lifetimes{negative};
    my $ttl = $lifetimes{ttl};

    print $fh <<EOF;
\$ORIGIN $domain.
\$TTL     $ttl ; queries are cached for this long
@        IN    SOA    ns1    $hostmaster (
                           $now ; Date $time
                           $refresh  ; slave queries for refresh this often
                           $retry ; slave retries refresh this often after failure
                           $expire ; slave expires after this long if not refreshed
                           $negative ; errors are cached for this long
         )

EOF

}


sub _generate_record {
    my $self = shift;
    my $fh = shift;
    my $name = shift;
    my $type = shift;
    my $detail = shift;
    my $value = shift;
    my $comment = shift;

    my $suffix = "";
    if (defined $comment) {
	$suffix = " ; " . $comment;
    }

    printf $fh "%-20s IN    %-8s %-6s %s%s\n", $name, $type, $detail, $value, $suffix;
}


sub _generate_spf {
    my $self = shift;
    my $fh = shift;
    my $name = shift;
    my $machine = shift;
    my $verbose = shift;

    my $policy = $self->get_spf_policy();
    return unless defined $policy;

    my $sentinel;
    if ($policy eq "accept") {
	$sentinel = "+all";
    } elsif ($policy eq "reject") {
	$sentinel = "-all";
    } elsif ($policy eq "mark") {
	$sentinel = "~all";
    } else {
	$sentinel = "?all";
    }

    my $spf;
    my $comment;
    if ($name eq "\@" || $name eq "*") {
	my @machines = $self->get_spf_machines();

	my @ips;
	foreach my $machine (@machines) {
	    my $addrs = $self->get_machine($machine);
	    die "cannot find machine $machine" unless defined $addrs;
	    if (exists $addrs->{ipv4}) {
		push @ips, "ip4:" . $addrs->{ipv4};
	    }
	    if (exists $addrs->{ipv6}) {
		push @ips, "ip6:" . $addrs->{ipv6};
	    }
	}

	$comment = "Machine(s) " . join(", ", @machines);
	$spf = "v=spf1 " . join(" ", @ips, $sentinel);
    } else {
	my @machines = $self->get_spf_machines();

	$comment = "Machine $machine";
	if (grep { $_ eq $machine } @machines) {
	    my $addrs = $self->get_machine($machine);
	    die "cannot find machine $machine" unless defined $addrs;
	    my @ips;
	    if (exists $addrs->{ipv4}) {
		push @ips, "ip4:" . $addrs->{ipv4};
	    }
	    if (exists $addrs->{ipv6}) {
		push @ips, "ip6:" . $addrs->{ipv6};
	    }
	    $spf = "v=spf1 " . join(" ", @ips, $sentinel);
	} else {
	    $spf = "v=spf1 " . $sentinel;
	}
    }
    $self->_generate_record($fh, $name, "TXT", "", '"' . $spf . '"', $comment);
}

sub _generate_machine {
    my $self = shift;
    my $fh = shift;
    my $name = shift;
    my $machine = shift;
    my $verbose = shift;

    print "    - Generate [$name] for [$machine]\n" if $verbose;

    my $addrs = $self->get_machine($machine);

    die "cannot find machine $machine" unless defined $addrs;

    my $comment;
    if ($name ne $machine) {
	$comment = "Machine $machine";
    }

    $self->_generate_record($fh, $name, "A", "", $addrs->{ipv4}, $comment) if exists $addrs->{ipv4};
    $self->_generate_record($fh, $name, "AAAA", "", $addrs->{ipv6}, $comment) if exists $addrs->{ipv6};
    if (exists $addrs->{ipv4} || exists $addrs->{ipv6}) {
	$self->_generate_spf($fh, $name, $machine, $verbose);
    }
}


sub _generate_default {
    my $self = shift;
    my $fh = shift;
    my $cfg = shift;
    my $domain = shift;
    my $verbose = shift;

    print "    - Generate default\n" if $verbose;

    my $default = $self->get_default();

    if (defined $default) {
	print $fh "; Primary name records for unqualfied domain\n";
	$self->_generate_machine($fh, "\@", $default, $verbose);
	print $fh "\n";
    }
}


sub _generate_dns {
    my $self = shift;
    my $fh = shift;
    my $verbose = shift;

    print "    - Generate dns\n" if $verbose;

    my %dns = $self->get_dns();

    print $fh "; DNS server records\n";

    my @dns = sort { $a cmp $b } keys %dns;
    foreach my $name (@dns) {
	$self->_generate_record($fh, "\@", "NS", "", $name);
    }

    foreach my $name (@dns) {
	$self->_generate_machine($fh, $name, $dns{$name}, $verbose);
    }
    print $fh "\n";
}


sub _generate_mail {
    my $self = shift;
    my $fh = shift;
    my $verbose = shift;

    print "    - Generate mail\n" if $verbose;

    my %mail = $self->get_mail();

    print $fh "; E-Mail server records\n";

    my @mail = sort { $a cmp $b } keys %mail;
    foreach my $name (@mail) {
	my $prio = $mail{$name}->{'priority'};
	$self->_generate_record($fh, "\@", "MX", $prio, $name);
    }

    foreach my $name (@mail) {
	my $machine = $mail{$name}->{'machine'};
	$self->_generate_machine($fh, $name, $machine, $verbose);
    }
    print $fh "\n";
}


sub _generate_machines {
    my $self = shift;
    my $fh = shift;
    my $verbose = shift;

    print "    - Generate machines\n" if $verbose;

    my %names = $self->get_machines();

    if (%names) {
	print $fh "; Primary names\n";

	foreach my $name (sort { $a cmp $b } keys %names) {
	    $self->_generate_machine($fh, $name, $name, $verbose);
	}
	print $fh "\n";
    }
}


sub _generate_names {
    my $self = shift;
    my $fh = shift;
    my $verbose = shift;

    print "    - Generate names\n" if $verbose;

    my %names = $self->get_names();

    if (%names) {
	print $fh "; Extra names\n";

	foreach my $name (sort { $a cmp $b } keys %names) {
	    $self->_generate_machine($fh, $name, $names{$name}, $verbose);
	}
	print $fh "\n";
    }
}


sub _generate_aliases {
    my $self = shift;
    my $fh = shift;
    my $verbose = shift;

    print "    - Generate aliases\n" if $verbose;

    my %aliases = $self->get_aliases();

    if (%aliases) {
	print $fh "; Aliased names\n";

	foreach my $alias (sort { $a cmp $b } keys %aliases) {
	    $self->_generate_record($fh, $alias, "CNAME", "", $aliases{$alias});
	}
	print $fh "\n";
    }
}


sub _generate_txt {
    my $self = shift;
    my $fh = shift;
    my $verbose = shift;

    print "    - Generate txt\n" if $verbose;

    my %txt = $self->get_txt();

    if (%txt) {
	print $fh "; Extra TXT\n";

	foreach my $alias (sort { $a cmp $b } keys %txt) {
	    $self->_generate_record($fh, $alias, "TXT", "", $txt{$alias});
	}
	print $fh "\n";
    }
}


sub _generate_dkim {
    my $self = shift;
    my $fh = shift;
    my $verbose = shift;

    print "    - Generate dkim\n" if $verbose;

    my %selectors = $self->get_dkim_selectors();

    if (%selectors) {
	print $fh "; DKIM selectors\n";

	foreach my $selector (sort { $a cmp $b } keys %selectors) {
	    my $dkim = $selectors{$selector};
	    my $version = exists $dkim->{"version"} ? $dkim->{"version"} : "DKIM1";
	    my $keytype = exists $dkim->{"keytype"} ? $dkim->{"keytype"} : "rsa";
	    my $service = $dkim->{"service"};
	    my $pubkey = $dkim->{"pubkey"};
	    my $value = "v=$version; k=$keytype;";
	    if (defined $service) {
		$value .= " s=$service;";
	    }
	    $value .= " p=$pubkey";
	    $self->_generate_record($fh, $selector . "._domainkey", "TXT", "", '"' . $value . '"');
	}
	print $fh "\n";
    }
}


sub _generate_dmarc {
    my $self = shift;
    my $fh = shift;
    my $verbose = shift;

    print "    - Generate dmarc\n" if $verbose;

    my $config = $self->get_dmarc_config();

    return unless defined $config;

    my $version = exists $config->{version} ? $config->{version} : "DMARC1";
    my $policy = exists $config->{policy} ? $config->{policy} : "none";
    my $subpolicy = $config->{subdomain_policy};
    my $percent = $config->{percent};
    my $rua = $config->{aggregate_report};
    my $ruf = $config->{forensic_report};

    my $value = "v=$version; p=$policy;";
    if (defined $subpolicy) {
	$value .= " sp=$subpolicy;";
    }
    if (defined $percent) {
	$value .= " pct=$percent;";
    }
    if (defined $rua) {
	$value .= " rua=$rua;";
    }
    if (defined $ruf) {
	$value .= " ruf=$ruf;";
    }
    print $fh "; DMARC policy\n";
    $self->_generate_record($fh, "_dmarc", "TXT", "", '"' . $value . '"');
    print $fh "\n";
}


sub _generate_wildcard {
    my $self = shift;
    my $fh = shift;
    my $verbose = shift;

    print "    - Generate wildcard\n" if $verbose;
    my $wildcard = $self->get_wildcard();

    if (defined $wildcard) {
	print $fh "; Wildcard\n";
	$self->_generate_machine($fh, "*", $wildcard, $verbose);
	print $fh "\n";
    }
}


1;

=back

=head1 AUTHORS

C<nozone> was written by Daniel P. Berrange <dan@berrange.com>

=head1 LICENSE

C<nozone> is distributed under the terms of the GNU GPL version 3
or any later version. You should have received a copy of the GNU
General Public License along with this program.  If not, see
C<http://www.gnu.org/licenses/>.

=head1 SEE ALSO

L<NoZone>, C<nozone(1)>
