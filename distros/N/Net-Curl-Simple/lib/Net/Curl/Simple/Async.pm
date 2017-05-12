package Net::Curl::Simple::Async;

use strict; no strict 'refs';
use warnings; no warnings 'redefine';
use Net::Curl;

our $VERSION = '0.13';

sub warn_noasynchdns($) { warn @_ }


# load specified backend (left) if appropriate module (right)
# is loaded already
my @backends = (
	# Coro backends, CoroEV is preffered, but let's play it safe
	CoroEV => 'Coro::EV',
	AnyEvent => 'Coro::AnyEvent',
	AnyEvent => 'Coro::Event',
	CoroEV => 'Coro',
	AnyEvent => 'Coro',
	Select => 'Coro',

	# backends we support directly
	EV => 'EV',
	Irssi => 'Irssi',
	AnyEvent => 'AnyEvent',

	# AnyEvent supports some implementations we don't
	AnyEvent => 'AnyEvent::Impl::Perl',
	AnyEvent => 'Cocoa::EventLoop',
	AnyEvent => 'Event',
	AnyEvent => 'Event::Lib',
	AnyEvent => 'Glib',
	AnyEvent => 'IO::Async::Loop',
	AnyEvent => 'Qt',
	AnyEvent => 'Tk',

	# POE::Loop::* implementations, our backend stinks a bit
	# so try AnyEvent first
	AnyEvent => 'POE::Kernel',
	AnyEvent => 'Prima',
	AnyEvent => 'Wx',

	# some POE::Loop::* implementations,
	# AnyEvent is preffered as it gives us a more
	# direct access to most backends
	POE => 'POE::Kernel',
	POE => 'Event',
	POE => 'Event::Lib',
	POE => 'Glib',
	POE => 'Gtk', # not gtk2
	POE => 'Prima',
	POE => 'Tk',
	POE => 'Wx',

	# forced backends: try to load if nothing better detected
	EV => undef, # most efficient implementation
	AnyEvent => undef, # AnyEvent may have some nice alternative
	Select => undef, # will work everywhere and much faster than POE
);

sub import
{
	my $class = shift;
	return if not @_;
	# force some implementation
	@backends = map +($_, undef), @_;
}

my $multi;
sub multi()
{
	while ( my ( $impl, $pkg ) = splice @backends, 0, 2 ) {
		if ( not defined $pkg or defined ${ $pkg . '::VERSION' } ) {
			my $implpkg = __PACKAGE__ . '::' . $impl;
			eval "require $implpkg";
			next if $@;
			eval {
				$multi = $implpkg->new();
			};
			last if $multi;
		}
	}
	@backends = ();
	die "Could not load " . __PACKAGE__ . " implementation\n"
		unless $multi;

	warn_noasynchdns "Please rebuild libcurl with AsynchDNS to avoid blocking"
		. " DNS requests\n" unless Net::Curl::Simple::can_asynchdns;

	*multi = sub () { $multi };

	return $multi;
};

END {
	# destroy multi object before global destruction
	if ( $multi ) {
		foreach my $easy ( $multi->handles ) {
			$multi->remove_handle( $easy );
		}
		$multi = undef;
	}
}

1;

__END__

=head1 NAME

Net::Curl::Simple::Async - perform Net::Curl requests asynchronously

=head1 SYNOPSIS

 use Net::Curl::Simple;
 use Net::Curl::Simple::Async qw(AnyEvent Select);

=head1 DESCRIPTION

This module is loaded by L<Net::Curl::Simple>. The only reason to use it
directly would be to force some event implementation.

 use Irssi;
 # Irssi backend would be picked
 use Net::Curl::Simple::Async qw(AnyEvent POE);

=head1 FUNCTIONS

=over

=item multi

Returns internal curl multi handle. You can use it to add bare
L<Net::Curl::Easy> objects. L<Net::Curl::Simple> objects add themselves
to this handle automatically.

=item warn_noasynchdns

Function used to warn about lack of AsynchDNS. You can overwrite it if you
hate the warning.

 {
     no warnings 'redefine';
     # don't warn at all
     *Net::Curl::Simple::Async::warn_noasynchdns = sub ($) { };
 }

Lack of AsynchDNS support in libcurl can severely reduce
C<Net::Curl::Simple::Async> efficiency. You should not disable the warning,
just replace it with a method more suitable in your application.

=back

=head1 BACKENDS

C<Net::Curl::Simple::Async> will check backends in this order:

=over

=item CoroEV

Used with L<Coro> only.

=item EV

Based on L<EV> - an awesome and very efficient event library.
Use it whenever you can.

=item Irssi

Will be used if L<Irssi> has been loaded. Does not support join() method - it
will issue a warning and won't block.

=item AnyEvent

Will be used if L<AnyEvent> has been loaded. In most cases you will already have
a looping mechanism on your own, but you can call C<< Net::Curl::Simple->join >>
if you don't need anything better.

=item POE

Used under L<POE>, only if no other backend could be detected. Slooow, avoid it.
If you're using L<POE> try L<POE::Loop::EV>.

=item Select

Direct loop implementation using perl's builtin select. Will be used if no
other backend has been found. You must call join() to get anything done.

=back

=head1 SEE ALSO

L<Net::Curl::Simple>
L<Net::Curl::Simple::UserAgent>
L<Net::Curl::Multi>

=head1 COPYRIGHT

Copyright (c) 2011 Przemyslaw Iskra <sparky at pld-linux.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as perl itself.

=cut

# vim: ts=4:sw=4
