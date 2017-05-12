package Mojo::Unicode::UTF8;

use strict;
use warnings;
use Mojo::Util 'decode', 'encode', 'monkey_patch';
use Unicode::UTF8 'decode_utf8', 'encode_utf8';

our $VERSION = '0.002';

monkey_patch 'Mojo::Util', 'decode', sub {
	goto &decode unless $_[0] eq 'UTF-8';
	my ($encoding, $bytes) = @_;
	local $@;
	return undef unless eval {
		use warnings FATAL => 'utf8';
		$bytes = decode_utf8 $bytes; 1
	};
	return $bytes;
};

monkey_patch 'Mojo::Util', 'encode', sub {
	goto &encode unless $_[0] eq 'UTF-8';
	return encode_utf8 $_[1];
};

1;

=head1 NAME

Mojo::Unicode::UTF8 - use Unicode::UTF8 as the UTF-8 encoder for Mojolicious

=head1 SYNOPSIS

 use Mojo::Unicode::UTF8;
 use Mojo::Util 'decode', 'encode';
 
 # Preload for scripts using Mojo::Util
 $ perl -MMojo::Unicode::UTF8 $(which morbo) myapp.pl
 
 # Must be set in environment for hypnotoad
 $ PERL5OPT=-MMojo::Unicode::UTF8 hypnotoad myapp.pl

=head1 DESCRIPTION

L<Mojo::Unicode::UTF8> is a monkey-patch module for using L<Unicode::UTF8> as
the UTF-8 encoder for a L<Mojolicious> application, or anything else using
L<Mojo::Util>. It must be loaded before L<Mojo::Util> so the new functions will
be properly exported. Calling L<Mojo::Util/"decode"> or L<Mojo::Util/"encode">
with any encoding other than C<UTF-8> will fall back to L<Encode> as normal.
For details on the benefits, see L<Unicode::UTF8/"COMPARISON">.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Mojo::Util>, L<Unicode::UTF8>, L<Encode>
