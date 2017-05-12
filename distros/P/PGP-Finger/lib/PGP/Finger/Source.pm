package PGP::Finger::Source;

use Moose;

# ABSTRACT: base class for a gpgfinger source
our $VERSION = '1.1'; # VERSION

sub fetch {
	die('unimplemented');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PGP::Finger::Source - base class for a gpgfinger source

=head1 VERSION

version 1.1

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2 or later

=cut
