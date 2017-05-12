package PGP::Finger::App;

use Moose;

our $VERSION = '1.1'; # VERSION
# ABSTRACT: commandline interface to PGP::Finger

extends 'PGP::Finger';
with 'MooseX::Getopt';

use PGP::Finger::DNS;
use PGP::Finger::Keyserver;
use PGP::Finger::GPG;
use PGP::Finger::File;

has '+sources' => (
	traits => [ 'NoGetopt' ],
	default => sub {
		my $self = shift;
		my @srcs;
		foreach my $q ( @{$self->_query} ) {
			my $src;
			$q = lc($q);
			if( $q eq 'dns' ) {
				$src = PGP::Finger::DNS->new();
			} elsif( $q eq 'keyserver' ) {
				$src = PGP::Finger::Keyserver->new();
			} elsif( $q eq 'gpg' ) {
				$src = PGP::Finger::GPG->new();
			} elsif( $q eq 'file' ) {
				$src = PGP::Finger::File->new(
					input => $self->input,
					format => $self->format,
				);
			} else {
				die('unknown query type: '.$q);
			}
			push( @srcs, $src );
		}
		return( \@srcs );
	},
);

has 'format' => ( is => 'ro', isa => 'Str', default => 'armored',
	traits => ['Getopt'],
	cmd_aliases => 'f',
	documentation => 'format of input (armored or binary)',
);

has 'input' => ( is => 'ro', isa => 'Str', default => '-',
	traits => ['Getopt'],
	cmd_aliases => 'i',
	documentation => 'path or - for stdin',
);

has 'query' => ( is => 'ro', isa => 'Str', default => 'dns,keyserver',
	traits => ['Getopt'],
	cmd_aliases => 'q',
	documentation => 'sources to query (default: dns,keyserver)',
);

has '_query' => ( is => 'ro', isa => 'ArrayRef[Str]', lazy => 1,
	default => sub {
		my $self = shift;
		return [ split(/\s*,\s*/, $self->query) ];
	},
);

has 'output' => ( is => 'ro', isa => 'Str', default => 'armored',
	traits => ['Getopt'],
	cmd_aliases => 'o',
	documentation => 'output format: armored,rfc or generic (default: armored)',
);

sub _usage_format {
	return "usage: %c %o <uid> <more uids ...>";
}

sub run {
	my $self = shift;
	my @uids = @{$self->extra_argv};

	if( ! @uids ) {
		print $self->usage;
		exit 1;
	}

	foreach my $uid ( @uids ) {
		my $resultset = $self->fetch( $uid );
		print $resultset->as_string( $self->output );
	}

	return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PGP::Finger::App - commandline interface to PGP::Finger

=head1 VERSION

version 1.1

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2 or later

=cut
