#########################################################################
# Copyright (c) 2010-2012 Alexander Bluhm <alexander.bluhm@gmx.net>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
##########################################################################

use strict;
use warnings;

=pod

=head1 NAME

B<OSPF::LSDB> - class containing OSPF link state database

=head1 SYNOPSIS

use OSPF::LSDB;

my $ospf = OSPF::LSDB-E<gt>L<new>();

=head1 DESCRIPTION

The B<OSPF::LSDB> module serves as base class for all the other
B<OSPF::LSDB::...> modules.
It contains the link state database, can do versioning and validation.
To parse, load, store or display the LSDB, convert it into instances
of more specific classes.
The B<new()> method implements a copy constructor to share LSDB
references with minimal overhead.

Most names of the database fields are named after RFC 2328 - OSPF
version 2.
Keys of RFC 5340 - OSPF for IPv6 with a comparable semantics in
version 2, have kept their old names to allow code reuse.

=cut

package OSPF::LSDB;
use Data::Validate::Struct;
use fields qw(ospf errors ssh);

=pod

=over

=item $OSPF::LSDB::VERSION

The version number of the B<OSPF::LSDB> modules.
It is also stored in the database dump and thus can be used to
upgrade the file.

=cut

our $VERSION = '1.07';

=pod

=item OSPF::LSDB-E<gt>L<new>($other)

Construct a B<OSPF::LSDB> object.
If another B<OSPF::LSDB> object is passed as argument, the new object
is contructed with the other's objects database as reference.
This can be used to convert between different B<OSPF::LSDB::...>
instances and use their specific features.

=cut

sub new {
    my OSPF::LSDB $self = shift;
    my $other = shift if UNIVERSAL::isa($_[0], "OSPF::LSDB");
    my %args = @_;
    $self = fields::new($self) unless (ref $self);
    $self->{ospf}{version} = $VERSION;
    $self->{ospf} = $other->{ospf} if $other;  # copy constructor
    $self->{ssh} = $args{ssh};
    return $self;
}

# error() is an internal method to collect errors

sub error {
    my OSPF::LSDB $self = shift;
    push @{$self->{errors}}, @_;
}

=pod

=item $self-E<gt>L<get_errors>()

Returns a list with all errors occured so far.
The internal error array gets reset.

=cut

sub get_errors {
    my OSPF::LSDB $self = shift;
    my @errors = @{delete $self->{errors} || []};

    return @errors;
}

=pod

=item $self-E<gt>L<ipv6>()

Returns true if the ospf database is version 3 for ipv6.

=cut

sub ipv6 {
    my OSPF::LSDB $self = shift;

    return $self->{ospf}{ipv6};
}

# %CONVERTER is a hash of methods to do the version upgrade step by step

my %CONVERTER = (
    0.1 => sub {
	my OSPF::LSDB $self = shift;
	foreach my $e (@{$self->{ospf}{database}{externals}}) {
	    $e->{forward} ||= "0.0.0.0";
	}
	$self->{ospf}{version} = 0.1;
    },
    0.2 => sub {
	my OSPF::LSDB $self = shift;
	foreach my $r (@{$self->{ospf}{database}{routers}}) {
	    foreach my $b (qw(B E V)) {
		$r->{bits}{$b} ||= 0;
	    }
	}
	$self->{ospf}{version} = 0.2;
    },
    0.3 => sub {
	my OSPF::LSDB $self = shift;
	foreach my $r (@{$self->{ospf}{database}{routers}}) {
	    my $links = delete($r->{links}) || [];
	    foreach my $l (@$links) {
		my $type = delete $l->{type}
		  or die "No type in link";
		push @{$r->{$type.'s'}}, $l;
	    }
	}
	$self->{ospf}{version} = 0.3;
    },
    0.4 => sub {
	my OSPF::LSDB $self = shift;
	foreach my $r (@{$self->{ospf}{database}{routers}}) {
	    $r->{router} ||= $self->{ospf}{ipv6} ? "0.0.0.0" : $r->{routerid};
	}
	$self->{ospf}{version} = 0.4;
    },
    0.5 => sub {
	my OSPF::LSDB $self = shift;
	$self->{ospf}{ipv6} //= 0;
	if ($self->{ospf}{ipv6}) {
	    foreach my $r (@{$self->{ospf}{database}{routers}}) {
		$r->{bits}{W} ||= 0;
	    }
	}
	$self->{ospf}{version} = 0.5;
    },
    1.0 => sub {
	my OSPF::LSDB $self = shift;
	$self->{ospf}{version} = 1.0;
    },
);

=pod

=item $self-E<gt>L<convert>()

While the version of the current database is less than the module
version, apply the conversion functions step by step.
The conversion fails if the final major and minor numbers
of the database version do not match the module version.
The patchlevel is ignored.

=cut

sub convert {
    my OSPF::LSDB $self = shift;
    $self->{ospf}{version} ||= 0.0;
    return if $self->{ospf}{version} eq $VERSION;
    foreach my $ver (sort keys %CONVERTER) {
	$CONVERTER{$ver}->($self) if $self->{ospf}{version} < $ver;
    }
    if (int(10 * $self->{ospf}{version}) == int(10 * $VERSION)) {
	$self->{ospf}{version} = $VERSION
    } else {
	die "Converison incomplete.\n";
    }
}

# $VALIDATOR is a Data::Validate::Struct reference
# As Data::Validate::Struct does not support optional fields,
# split it into a common part and ipv4 and ipv6 only parts.
# The fields age and sequence are not used and not validated.

# common for ipv4 and ipv6
my $VALIDATOR46 = {
    database => {
	boundarys => [ {
	    area	=> 'ipv4',
	    asbrouter	=> 'ipv4',
	    metric	=> 'int',
	    routerid	=> 'ipv4',
	}, {}, ],
	externals => [ {
	    address	=> 'ipv4',
	    metric	=> 'int',
	    routerid	=> 'ipv4',
	    type	=> 'int',
	}, {}, ],
	networks => [ {
	    address	=> 'ipv4',
	    area	=> 'ipv4',
	    attachments => [ {
		routerid	=> 'ipv4',
	    }, {} ],
	    routerid	=> 'ipv4',
	}, {}, ],
	routers => [ {
	    area	=> 'ipv4',
	    bits => {
		B	=> 'int',
		E	=> 'int',
		V	=> 'int',
	    },
	    pointtopoints => [ {
		interface	=> 'ipv4',
		metric		=> 'int',
		routerid	=> 'ipv4',
	    }, {} ],
	    transits => [ {
		address		=> 'ipv4',
		interface	=> 'ipv4',
		metric		=> 'int',
	    }, {} ],
	    virtuals => [ {
		interface	=> 'ipv4',
		metric		=> 'int',
		routerid	=> 'ipv4',
	    }, {} ],
	    router	=> 'ipv4',
	    routerid	=> 'ipv4',
	}, {}, ],
	summarys => [ {
	    address	=> 'ipv4',
	    area	=> 'ipv4',
	    metric	=> 'int',
	    routerid	=> 'ipv4',
	}, {}, ],
    },
    ipv6 => 'int',
    self => {
	areas		=> [ 'ipv4', '' ],
	routerid	=> 'ipv4',
    },
    version => 'number',
};

# ipv4 only
my $VALIDATOR = {
    database => {
	externals => [ {
	    forward	=> 'ipv4',
	    netmask	=> 'ipv4',
	}, {}, ],
	networks => [ {
	    netmask	=> 'ipv4',
	}, {}, ],
	routers => [ {
	    stubs => [ {
		metric		=> 'int',
		netmask		=> 'ipv4',
		network		=> 'ipv4',
	    }, {} ],
	}, {}, ],
	summarys => [ {
	    netmask	=> 'ipv4',
	}, {}, ],
    },
};

# ipv6 only
my $VALIDATOR6 = {
    database => {
	boundarys => [ {
	    address	=> 'ipv4',
	}, {}, ],
	externals => [ {
	    prefixaddress	=> 'ipv6',
	    prefixlength	=> 'int',
	}, {}, ],
	intranetworks => [ {
	    address	=> 'ipv4',
	    area	=> 'ipv4',
	    interface	=> 'ipv4',
	    prefixes => [ {
		prefixaddress	=> 'ipv6',
		prefixlength	=> 'int',
	    }, {}, ],
	    router	=> 'ipv4',
	    routerid	=> 'ipv4',
	}, {}, ],
	intrarouters => [ {
	    address	=> 'ipv4',
	    area	=> 'ipv4',
	    interface	=> 'ipv4',
	    prefixes => [ {
		prefixaddress	=> 'ipv6',
		prefixlength	=> 'int',
	    }, {}, ],
	    router	=> 'ipv4',
	    routerid	=> 'ipv4',
	}, {}, ],
	links => [ {
	    area	=> 'ipv4',
	    interface	=> 'ipv4',
	    linklocal	=> 'ipv6',
	    prefixes => [ {
		prefixaddress	=> 'ipv6',
		prefixlength	=> 'int',
	    }, {}, ],
	    routerid	=> 'ipv4',
	}, {}, ],
	routers => [ {
	    bits => {
		W	=> 'int',
	    },
	    pointtopoints => [ {
		address		=> 'ipv4',
	    }, {} ],
	    transits => [ {
		routerid	=> 'ipv4',
	    }, {} ],
	    virtuals => [ {
		address		=> 'ipv4',
	    }, {} ],
	}, {}, ],
	summarys => [ {
	    prefixaddress	=> 'ipv6',
	    prefixlength	=> 'int',
	}, {}, ],
    },
};

=pod

=item $self-E<gt>L<validate>()

Ensure that the internal data structure has the correct version and
is valid.

=back

=cut

sub validate {
    my OSPF::LSDB $self = shift;
    my $ospf = $self->{ospf};

    die "Ospf not set.\n" unless $ospf;
    die "No version.\n" unless $ospf->{version};
    die "Bad version: $ospf->{version}\n" unless $ospf->{version} eq $VERSION;

    foreach my $vtor ($VALIDATOR46, $self->ipv6 ? $VALIDATOR6 : $VALIDATOR) {
	my $dvs = Data::Validate::Struct->new($vtor);
	die "Ospf invalid: ", $dvs->errstr(), "\n" unless $dvs->validate($ospf);
    }
}

=pod

=head1 ERRORS

The methods die if any error occures.

=head1 SEE ALSO

L<OSPF::LSDB::View>,
L<OSPF::LSDB::View6>,
L<OSPF::LSDB::YAML>,
L<OSPF::LSDB::gated>,
L<OSPF::LSDB::ospfd>

L<ospfconvert>

RFC 2328 - OSPF Version 2 - April 1998

RFC 5340 - OSPF for IPv6 - July 2008

=head1 AUTHORS

Alexander Bluhm

=cut

1;
