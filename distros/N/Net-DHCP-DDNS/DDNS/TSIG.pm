package Net::DHCP::DDNS::TSIG;
use warnings;
use strict;

use Carp;
use Data::Dumper;
my %OBJ;

sub get {
	my ( $class, %args ) = @_;

	$class = ref( $class ) if ref( $class );

	unless ( $class->isa( __PACKAGE__ ) ) {
		confess __PACKAGE__ . "::get($class) is asinine";
	}

	my $dname = $args{domain} or return undef;
	my $kroot = $args{keydir} or return undef;

	$dname =~ s/\.$//;

	my @dname = split /\./, $dname;

	$dname = join( '.', reverse @dname );

	my $fname = join( '/', $kroot, $dname );

	return $OBJ{$fname} if $OBJ{$fname};

	my $fh;
	unless ( open $fh, "< $fname" ) {;
		warn "Failed to open $fname for reading: $!\n";
		return undef;
	}

	my $ktext = <$fh>;
	return undef unless defined $ktext;

	$fh->close;

	my ( $kname, $kdata );

	if ( $ktext =~ /IN KEY/ ) {
		my @parts = split /\s+/, $ktext;
		$kname = shift @parts;
		$kdata = pop @parts;
		$kname =~ s/\.$//;
	}

	elsif ( $ktext =~ /=/ ) {
		$ktext =~ s/^\s+//;
		$ktext =~ s/\s+$//;
		( $kname, $kdata ) = split /\s*=\s*/, $ktext, 2;
	}

	else {
		warn "Do not know how to parse key file $fname\n";
		return undef;
	}

	bless my $self = { kname => $kname, kdata => $kdata }, $class;

	return $OBJ{$fname} = $self;
}

sub name {
	my $self = shift;

	return $self->{kname};
}

sub value {
	my $self = shift;

	return $self->{kdata};
}


1;
