package Padre::Plugin::Nopaste::Services;

use v5.10;
use strict;
use warnings;

use English qw( -no_match_vars );
local $OUTPUT_AUTOFLUSH = 1;

our $VERSION = '0.08';

use Padre::Unload ();
use Moo;

has 'servers' => (
	is      => 'ro',
	default => sub {
		my $self = shift;

		return [
			'Codepeek',
			'Debian',
			'Gist',
			'PastebinCom',
			'Pastie',
			'Shadowcat',
			'Snitch',
			'Ubuntu',
			'ssh',
		];
	},
);
has 'Codepeek' => (
	is      => 'ro',
	default => sub {
		my $self = shift;
		return [];
	},
);
has 'Debian' => (
	is      => 'ro',
	default => sub {
		my $self = shift;
		return [];
	},
);
has 'Gist' => (
	is      => 'ro',
	default => sub {
		my $self = shift;
		return [];
	},
);
has 'PastebinCom' => (
	is      => 'ro',
	default => sub {
		my $self = shift;
		return [];
	},
);
has 'Pastie' => (
	is      => 'ro',
	default => sub {
		my $self = shift;
		return [];
	},
);
has 'Shadowcat' => (
	is      => 'ro',
	default => sub {
		my $self = shift;

		return [
			'#angerwhale',
			'#axkit-dahut',
			'#catalyst',
			'#catalyst-dev',
			'#cometd',
			'#dbix-class',
			'#distzilla',
			'#handel',
			'#iusethis',
			'#killtrac',
			'#london.pm',
			'#miltonkeynes.pm',
			'#moose',
			'#p5p',
			'#padre',
			'#perl',
			'#perl-help',
			'#perlde',
			'#pita',
			'#poe',
			'#reaction',
			'#rt',
			'#soap-lite',
			'#tt',
		];
	},
);
has 'Snitch' => (
	is      => 'ro',
	default => sub {
		my $self = shift;
		return [];
	},
);
has 'Ubuntu' => (
	is      => 'ro',
	default => sub {
		my $self = shift;
		return [];
	},
);
has 'ssh' => (
	is      => 'ro',
	default => sub {
		my $self = shift;
		return [];
	},
);


1;

__END__

=pod

=encoding utf8

=head1 NAME

Padre::Plugin::Nopaste::Services - NoPaste plugin for Padre, The Perl IDE.

=head1 VERSION

version: 0.08

=head1 DESCRIPTION

This just a utility module with information about App::Nopaste Services and
 Channels respectively serviced known to us.


=head1 ATTRIBUTES

=over 4

=item *	Codepeek

=item *	Debian

=item *	Gist

=item *	PastebinCom

=item *	Pastie

=item *	Shadowcat

=item *	Snitch

=item *	Ubuntu

=item *	channels

=item *	servers

=item *	ssh

=back

=head1 BUGS AND LIMITATIONS

None known.

=head1 DEPENDENCIES

Moo

=head1 SEE ALSO

See L<Padre::Plugin::Nopaste>.

=head1 AUTHOR

See L<Padre::Plugin::Nopaste>

=head2 CONTRIBUTORS

See L<Padre::Plugin::Nopaste>

=head1 COPYRIGHT

See L<Padre::Plugin::Nopaste>

=head1 LICENSE

See L<Padre::Plugin::Nopaste>

=cut

