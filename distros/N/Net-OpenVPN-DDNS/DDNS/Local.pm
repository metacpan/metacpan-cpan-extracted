package Net::OpenVPN::DDNS::Local;
use warnings;
use strict;
#
# Attempts to read client identification from local server-side files.
# 
###############################################################################
#

use Carp;
use IO::File;

my %OBJ;


sub get {
	my ( $class, %args ) = @_;

	$class = ref( $class ) if ref( $class );

	unless ( $class->isa( __PACKAGE__ ) ) {
		confess __PACKAGE__ . "::get($class) is asinine";
	}

	my $path = $args{path};
	my $name = $args{name};

	my $fname = join( '/', $path, $name );

	return $OBJ{$fname} if $OBJ{$fname};

	my $fh;
	unless ( open $fh, "< $fname" ) {
		# warn if it isn't a not-present
		return undef;
	}

	my %clientids;
	while ( my $txt = <$fh> ) {
		chomp( $txt );

		my ( $type, $value ) = split /\s*=\s*/, $txt, 2
			or next;

		$clientids{$type} = $value;

	}

	return undef unless scalar( %clientids );

	bless my $self = { clientids => \%clientids }, $class;

	return $OBJ{$fname} = $self;
}

sub clientids {
	my ( $self ) = @_;

	return wantarray ? %{$self->{clientids}} : $self->{clientids};
}


###############################################################################
1;
