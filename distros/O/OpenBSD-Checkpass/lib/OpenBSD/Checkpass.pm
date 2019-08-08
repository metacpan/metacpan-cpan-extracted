package OpenBSD::Checkpass;

use 5.028002;
use strict;
use warnings;

use parent 'Exporter';

 our @ISA = qw(Exporter);
our @EXPORT = qw(checkpass newhash);
our $VERSION = '0.01';

require XSLoader;
XSLoader::load( 'OpenBSD::Checkpass', $VERSION );

sub checkpass
{
	my ($password, $hash) = @_;

	return _checkpass( $password, $hash );
}

sub newhash
{
	my $password = shift;

	return _newhash( $password );
}

1;

__END__

=head1 NAME

OpenBSD::Checkpass - Perl interface to OpenBSD crypt_checkpass(3)

=head1 SYNOPSIS

  use OpenBSD::Checkpass;
  
  my $password = qw/password/;
  my $hash = &newhash($password);

  print "Good password.\n" if (&checkpass($password, $hash) == 0);

=head1 DESCRIPTION

This module provides a perl interface to OpenBSD's crypt_checkpass(3) and crypt_newhash(3) functions.

=head1 EXPORT

Exports "checkpass" and "newhash" by default.

=head1 SEE ALSO

crypt_checkpass(3)

<http://man.openbsd.org/crypt_checkpass.3>

=head1 AUTHOR

Edgar Pettijohn, E<lt>edgar@pettijohn-web.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Edgar Pettijohn

Permission to use, copy, modify, and distribute this software for any purpose with or without fee is hereby granted, provided
that the above copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR
CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA, OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

=cut
