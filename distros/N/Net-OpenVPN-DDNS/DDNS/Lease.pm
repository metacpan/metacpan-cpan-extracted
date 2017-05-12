package Net::OpenVPN::DDNS::Lease;
use warnings;
use strict;
#
# Attempts to snarf client identification from an ISC dhcpd leases file.
# 
###############################################################################
#

use Carp;
use IO::File;


###############################################################################
#

sub get {
	my ( $class, %args ) = @_;

	$class = ref( $class ) if ref( $class );

	unless ( $class->isa( __PACKAGE__ ) ) {
		confess __PACKAGE__ . "::get($class) is asinine";
	}

	my $file = $args{file};
	my $name = $args{name};

	bless my $self = { %args }, $class;

	$self->{wholefile} = $self->reread
		or return undef;

	$self->{clientids} = $self->{wholefile}->{$name}
		or return undef;

	return $self;
}

sub clientids {
	my ( $self ) = @_;

	return wantarray ? %{$self->{clientids}} : $self->{clientids};
}


###############################################################################
#

sub process {
	my $in = shift;
	my $rv;

	if ( $in =~ /^"/ ) {
		return eval $in;
	}

	$in =~ s/%/%%/g;

	return sprintf $in;

} 

sub reread {
	my $self = shift;

	my @in;

	my $fh = IO::File->new;
	$fh->open( '< ' .$self->{file} );
	while ( <$fh> ) { chomp $_; push @in, $_; }
	$fh->close;

	my %LEASES;
	my $inlease = undef;

	foreach my $in ( @in ) {

		if ( $in =~ /^lease/ ) {

			if ( $inlease ) {
				warn "parse error: expected }\n";
			}

			my @parts = split /\s+/, $in;
			my $addr = $parts[1];

			$LEASES{ $inlease = $addr } = {};
			next;
		}

		if ( $in =~ /\}/ ) {
			$inlease = undef;
			next;
		}

		$in =~ s/^\s+//;
		$in =~ s/\s+$//;
		$in =~ s/;$//;

		my @parts = split /\s+/, $in;
		my $first = shift @parts;

		if ( $first eq 'uid' ) {
			$LEASES{$inlease}->{dcid} = process( shift @parts );
			next;
		}

		if ( $first eq 'hardware' ) {
			next unless shift( @parts ) eq 'ethernet';
			$LEASES{$inlease}->{hwaddr} = process( shift @parts );
			next;
		}

		if ( $first eq 'client-hostname' ) {
			$LEASES{$inlease}->{name} = process( shift @parts );
			next;
		}

		if ( $first eq 'set' ) {
			$first = shift( @parts );
			shift( @parts );
		}

		if ( $first eq 'ddns-fwd-name' ) {
			$LEASES{$inlease}->{fqdn} = process( shift @parts );
		}
	}

	my %NAMES;

	foreach my $lease ( values %LEASES ) {
		next unless $lease->{name};
		$NAMES{$lease->{name}} = $lease;
	}

	return \%NAMES;
}


###############################################################################
1;
