package POE::Loop::Kqueue;
# $Id: Kqueue.pm,v 1.8 2005/03/14 08:49:43 godegisel Exp $

use strict;

use vars qw($VERSION @ISA);
$VERSION='0.02';

require DynaLoader;
@ISA = qw(DynaLoader);
bootstrap POE::Loop::Kqueue;
#use XSLoader;
#XSLoader::load 'POE::Loop::Kqueue', $VERSION;

# Include common signal handling.
use POE::Loop::PerlSignals;

# Everything plugs into POE::Kernel.
package POE::Kernel;

use strict;
use Carp;

sub poe_kernel_loop	{
	'POE::Loop::Kqueue';
}

sub loop_attach_uidestroy	{
	# does nothing
}

1;
__END__
=pod

=head1 NAME

POE::Loop::Kqueue - a bridge that supports kqueue(2) from POE

=head1 SYNOPSIS

	use POE qw(Loop::Kqueue);

=head1 DESCRIPTION

This class is an implementation of the abstract POE::Loop interface.
It follows POE::Loop's public interface exactly.  Therefore, please
see L<POE::Loop> for its documentation.

kqueue(2) currently supported in FreeBSD 4.1+, NetBSD 2.0,
OpenBSD 2.9+, MacOS X, DragonFlyBSD.

=head1 IMPLEMENTATION NOTES

THIS IS ALPHA VERSION.

The module is thread-safe.

Signals are handled via POE::Loop::PerlSignals.
This limitation will be fixed in the next release.

=head1 AUTHOR

Sergey Skvortsov E<lt>skv@protey.ruE<gt>

=head1 SEE ALSO

L<POE>, L<POE::Loop>, L<kqueue>

L<http://kegel.com/c10k.html>

=head1 COPYRIGHT

Copyright 2005 Sergey Skvortsov E<lt>skv@protey.ruE<gt>.
All rights reserved.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
