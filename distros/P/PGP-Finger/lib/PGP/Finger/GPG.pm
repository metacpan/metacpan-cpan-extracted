package PGP::Finger::GPG;

use Moose;

extends 'PGP::Finger::Source';

# ABSTRACT: gpgfinger source to query local gnupg
our $VERSION = '1.1'; # VERSION

use PGP::Finger::Result;
use PGP::Finger::Key;

use IPC::Run qw(run);

has 'cmd' => ( is => 'ro', isa => 'ArrayRef', lazy => 1,
	default => sub { [ '/usr/bin/gpg', '--export' ] },
);

sub fetch {
	my ( $self, $addr ) = @_;
	my @cmd = ( @{$self->cmd}, $addr );
	my ( $in, $out, $err );
	run( \@cmd, \$in, \$out, \$err )
		or die('error running gpg: '.$err.' ('.$!.')');

	my $result = PGP::Finger::Result->new;
	my $key = PGP::Finger::Key->new(
		mail => $addr,
		data => $out,
	);
	$key->set_attr( source => 'local GnuPG' );

	$result->add_key( $key );
	return $result;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PGP::Finger::GPG - gpgfinger source to query local gnupg

=head1 VERSION

version 1.1

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2 or later

=cut
