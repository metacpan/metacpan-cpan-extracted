package Net::Zemanta::Preferences;

=head1 NAME

Net::Zemanta::Preferences - Perl interface to Zemanta user preferences

=cut

use warnings;
use strict;

use Net::Zemanta::Method;
our @ISA = qw(Net::Zemanta::Method);

=head1 SYNOPSIS

	use Net::Zemanta::Preferences;

	my $zemanta = Net::Zemanta::Preferences->new(
			APIKEY => 'your-API-key' 
		);

	my $preferences = $zemanta->get();

	# URL of the web page for setting preferences
	$preferences->{config_url}

	# User's Amazon affiliate ID
	$preferences->{config_url}

=head1 METHODS

=over 8

=item B<new()>

	Net::Zemanta::Preferences->new(PARAM => ...);

Acceptable parameters:

=over 4

=item  APIKEY

The API key used for authentication with the service.

=item  USER_AGENT

If supplied the value is prepended to this module's identification string 
to become something like:

	your-killer-app/0.042 Perl-Net-Zemanta/0.1 libwww-perl/5.8

Otherwise just Net::Zemanta's user agent string will be sent.

=back

C<new()> returns C<undef> on error.

=cut

sub new {
	my $class 	= shift;
	my %params	= @_;

	$params{METHOD} = "zemanta.preferences";

	my $self = $class->SUPER::new(%params);

	return unless $self;

	bless ($self, $class);
	return $self;
}

=item B<get()>

Returns current settings for the specified API key in form of a hash reference.

See L<http://developer.zemanta.com> for a list of all available settings.

Returns C<undef> on error.

=item B<error()>

If the last call to C<suggest()> returned an error, this function returns a
string containing a short description of the error. Otherwise it returns
C<undef>.

=back

=cut

sub get {
	my $self = shift;

	return $self->execute();
}

=head1 SEE ALSO

=over 4

=item * L<http://zemanta.com>

=item * L<http://developer.zemanta.com>

=back

=head1 AUTHOR

Tomaz Solc E<lt>tomaz@zemanta.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Zemanta ltd.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself, either Perl version 5.8.7 or, at your option,
any later version of Perl 5 you may have available.

=cut
