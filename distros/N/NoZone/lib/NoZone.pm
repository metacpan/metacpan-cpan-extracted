#!/usr/bin/perl
#
# NoZone: a Bind DNS zone file generator
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

package NoZone;

use strict;
use warnings;

use File::Spec::Functions qw(catfile);

use NoZone::Zone;

our $VERSION = '1.3';

=head1 NAME

NoZone - a Bind DNS zone file generator

=head1 SYNOPSIS

  use NoZone;
  use YAML qw();

  my $cfg = YAML::LoadFile("/etc/nozone.yml");

  my $nozone = NoZone->new();
  $nozone->load_config($cfg);
  $nozone->generate_zones();

=head1 DESCRIPTION

The C<NoZone> module provides a system for generating
Bind DNS zone files from data stored in a much simpler
configuration file format.

=head1 METHODS

=over 4

=item my $nozone = NoZone->new(
    datadir => "/var/named/data",
    confdir => "/etc/named",
    masters => []);

Creates a new C<NoZone> object instance. The C<datadir> parameter
specifies where the zone data files should be created, while C<confdir>
specifies where the zone conf files should be created. Both have
sensible defaults if omitted. The optional C<masters> list provides
a list of master servers. If present, only a slave zone config will
be generated.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    my %params = @_;

    $self->{datadir} = $params{datadir} ? $params{datadir} : "/var/named/data";
    $self->{confdir} = $params{confdir} ? $params{confdir} : "/etc/named";
    $self->{masters} = $params{masters} ? $params{masters} : [];

    bless $self, $class;

    return $self;
}

=item $nozone->load_config($cfg);

Load details for the DNS zones from the configuration
data in C<$cfg>, which is a hash reference, typically
resulting from loading a YAML file. See L<nozone.yml>
for a description of the required configuration file
format.

=cut

sub load_config {
    my $self = shift;
    my $cfg = shift;

    my $zones = exists $cfg->{"zones"} ? $cfg->{"zones"} : {};
    foreach my $name (keys %{$zones}) {
	my $subcfg = $zones->{$name};
	my $zone = NoZone::Zone->new(
	    default => exists $subcfg->{"default"} ? $subcfg->{"default"} : undef,
	    domains => exists $subcfg->{"domains"} ? $subcfg->{"domains"} : [],
	    lifetimes => exists $subcfg->{"lifetimes"} ? $subcfg->{"lifetimes"} : undef,
	    hostmaster => exists $subcfg->{"hostmaster"} ? $subcfg->{"hostmaster"} :  undef,
	    machines => exists $subcfg->{"machines"} ? $subcfg->{"machines"} :  {},
	    dns => exists $subcfg->{"dns"} ? $subcfg->{"dns"} :  {},
	    mail => exists $subcfg->{"mail"} ? $subcfg->{"mail"} :  {},
	    names => exists $subcfg->{"names"} ? $subcfg->{"names"} :  {},
	    aliases => exists $subcfg->{"aliases"} ? $subcfg->{"aliases"} :  {},
	    wildcard => exists $subcfg->{"wildcard"} ? $subcfg->{"wildcard"} :  undef,
	    spf => exists $subcfg->{"spf"} ? $subcfg->{"spf"} :  undef,
	    dkim => exists $subcfg->{"dkim"} ? $subcfg->{"dkim"} :  {},
	    dmarc => exists $subcfg->{"dmarc"} ? $subcfg->{"dmarc"} :  undef,
	    txt => exists $subcfg->{"txt"} ? $subcfg->{"txt"} :  {},
	    );
	$self->{zones}->{$name} = $zone;
    }

    foreach my $name (keys %{$zones}) {
	my $subcfg = $zones->{$name};
	my $inherits = exists $subcfg->{"inherits"} ? $subcfg->{"inherits"} : undef;
	if ($inherits) {
	    my $parentzone = $self->{zones}->{$inherits};
	    my $zone = $self->{zones}->{$name};
	    $zone->set_inherits($parentzone);
	}
    }
}


=item $nozone->generate_zones($verbose=0);

Generate all the bind DNS zone data files for loaded zones.
If the C<$verbose> flag is set to a true value, the progress
will be printed

=cut

sub generate_zones {
    my $self = shift;
    my $verbose = shift || 0;

    my $mainfile = catfile($self->{confdir}, "nozone.conf");
    my $mainfh = IO::File->new(">$mainfile")
	or die "cannot create $mainfile: $!";

    foreach my $name (sort { $a cmp $b } keys %{$self->{zones}}) {
	print "Processing zone $name\n" if $verbose;
	my $zone = $self->{zones}->{$name};
	foreach my $domain (sort { $a cmp $b } $zone->get_domains()) {
	    my $conffile = catfile($self->{confdir}, $domain . ".conf");
	    my $datafile = catfile($self->{datadir}, $domain . ".data");

	    print $mainfh "include \"$conffile\";\n";

	    my $conffh = IO::File->new(">$conffile")
		or die "cannot create $conffile: $!";
	    print " - Generating $conffile\n" if $verbose;
	    $zone->generate_conffile($conffh, $domain, $datafile, $self->{masters}, $verbose);
	    $conffh->close() or die "cannot save $conffile: $!";

	    next if int(@{$self->{masters}});

	    my $datafh = IO::File->new(">$datafile")
		or die "cannot create $datafile: $!";
	    print " - Generating $datafile\n" if $verbose;
	    $zone->generate_datafile($datafh, $domain, $verbose);
	    $datafh->close() or die "cannot save $datafile: $!";
	}
    }

    $mainfh->close() or die "cannot save $mainfile; $!";
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

L<NoZone::Zone>, C<nozone(1)>
