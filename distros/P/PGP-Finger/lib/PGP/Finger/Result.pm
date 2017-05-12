package PGP::Finger::Result;

use Moose;

# ABSTRACT: a gpgfinger result object
our $VERSION = '1.1'; # VERSION

has 'keys' => (
	is => 'ro', isa => 'ArrayRef[PGP::Finger::Key]', lazy => 1,
	traits => [ 'Array' ],
	default => sub { [] },
	handles => {
		add_key => 'push',
		count => 'count',
	},
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PGP::Finger::Result - a gpgfinger result object

=head1 VERSION

version 1.1

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2 or later

=cut
