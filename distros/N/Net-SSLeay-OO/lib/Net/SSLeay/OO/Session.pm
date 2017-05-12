
package Net::SSLeay::OO::Session;

use Moose;

has 'session'    => isa => 'Int',
	is       => "ro",
	required => 1,
	;

use Net::SSLeay::OO::Functions 'session';

sub DESTROY {
	my $self = shift;
	$self->free;
}

1;

__END__

=head1 NAME

Net::SSLeay::OO::Session - representation of SSL_SESSION* objects

=head1 SYNOPSIS

 my $session = $ssl->get_session;

 say "Your SSL session has been active for ".
     (time - $session->get_time)."s";

=head1 DESCRIPTION

This is a wrapper for SSL_SESSION methods.  defined methods are:

=over

=item B<get_time()>

=item B<set_time($epoch)>

Get/set the time that this SSL session was established.

=item B<get_timeout()>

=item B<set_timeout($epoch)>

Set the timeout value for the session.  See
L<SSL_SESSION_set_timeout(3ssl)>.

=back

=head1 AUTHOR

Sam Vilain, L<samv@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2009  NZ Registry Services

This program is free software: you can redistribute it and/or modify
it under the terms of the Artistic License 2.0 or later.  You should
have received a copy of the Artistic License the file COPYING.txt.  If
not, see <http://www.perlfoundation.org/artistic_license_2_0>

=head1 SEE ALSO

L<Net::SSLeay::OO>, L<Net::SSLeay::OO::SSL>

=cut

# Local Variables:
# mode:cperl
# indent-tabs-mode: t
# cperl-continued-statement-offset: 8
# cperl-brace-offset: 0
# cperl-close-paren-offset: 0
# cperl-continued-brace-offset: 0
# cperl-continued-statement-offset: 8
# cperl-extra-newline-before-brace: nil
# cperl-indent-level: 8
# cperl-indent-parens-as-block: t
# cperl-indent-wrt-brace: nil
# cperl-label-offset: -8
# cperl-merge-trailing-else: t
# End:
# vim: filetype=perl:noexpandtab:ts=3:sw=3

