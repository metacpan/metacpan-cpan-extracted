package POE::Component::Pastebin::Create;
# ABSTRACT: Non-blocking wrapper to the WWW::Pastebin::*::Create modules

use strict;
use warnings;
use Carp;
use POE;
use base 'POE::Component::NonBlockingWrapper::Base';

sub _prepare_wheel {
	my $self = shift;

	my $type = $self->{pastebin_class} // 'Sprunge';
	my $pkg_name = ($type =~ /^\+/) ? substr($type, 1) : "WWW::Pastebin::${type}::Create";
	eval "use $pkg_name";
	croak "Cannot load the module $pkg_name\n" if $@;

	my $options = $self->{pastebin_args} // {};
	$self->{writer} = $pkg_name->new(%{$options});

	return $self;
}

sub _methods_define {
	return (paste => '_wheel_entry');
}

sub _process_request {
	my ($self, $request) = @_;

	if ($self->{writer}->paste($request->{text}, %{$request})) {
		$request->{uri} = $self->{writer}->paste_uri;
	} else {
		$request->{error} = $self->{writer}->error;
	}
}

sub paste {
	$poe_kernel->post(shift->{session_id} => paste => @_);
}

1;


__END__
=pod

=head1 NAME

POE::Component::Pastebin::Create - Non-blocking wrapper to the WWW::Pastebin::*::Create modules

=head1 VERSION

version 0.001

=head1 SYNOPSIS

	use strict;
	use warnings;

	use POE qw(Component::Pastebin::Create);

	my $poco = POE::Component::Pastebin::Create->spawn;

	POE::Session->create(
		package_states => [ main => [qw(_start pasted)] ],
	);

	$poe_kernel->run;
	
	sub _start {
		my %info = (text => 'Lorem ipsum', event => 'pasted');

		$poco->paste(\%info);
		# Alternative syntax:
		# $poe_kernel->post($poco->session_id, 'paste', \%info);
	}

	sub pasted {
		my $data = $_[ARG0];

		say "Pasted URL: ".$data->{uri};

		$poco->shutdown;
	}

=head1 DESCRIPTION

This module is a non-blocking POE wrapper around the various
WWW::Pastebin::*::Create classes.

As of the time of writing, it should work with every one of those modules on
CPAN except for WWW::Pastebin::PastebinCom::Create, due to a few API
differences. This will be fixed later.

=head1 NAME

POE::Component::Pastebin::Create - non-blocking wrapper around the various
WWW::Pastebin::*::Create classes

=head1 CONSTRUCTOR

=head2 C<spawn>

	my $poco = POE::Component::Pastebin::Create->spawn;

	POE::Component::Pastebin::Create->spawn(
		alias => 'pastebin',
		pastebin_class => 'Sprunge',
		pastebin_args => {},
		options => {
			debug => 1,
			trace => 1,
			# POE::Session arguments for the component
		},
		debug => 1, # output some debug info
	);

=head3 C<alias>

	->spawn( alias => 'pastebin' );

B<Optional>. Specifies a POE Kernel alias for the component.

=head3 C<pastebin_class>

	->spawn( pastebin_class => 'Sprunge' );
	->spawn( pastebin_class => '+WWW::Pastebin::Sprunge::Create' );

Specifies the name of the class that will be used to create pastes. Normally,
the class is interpolated like this:
C<WWW::Pastebin::${name}::Create>. If you prefix the name with +,
it is used as an absolute module name. B<Defaults to:>
C<Sprunge>.

=head3 C<pastebin_args>

	->spawn( pastebin_args => {} );

B<Optional>. Options/arguments that will be passed into the "new" method
of the pastebin class.

=head3 C<options>

	->spawn(
		options => {
			trace => 1,
			default => 1,
		},
	);

B<Optional>.
A hashref of POE Session options to pass to the component's session.

=head3 C<debug>

	->spawn(
		debug => 1
	);

When set to a true value turns on output of debug messages. B<Defaults to:>
C<0>.

=head1 METHODS

=head2 C<paste>

	$poco->paste( {
			event       => 'event_for_output',
			text        => 'Lorem ipsum dolor sit amet, ...',
			_blah       => 'pooh!',
			session     => 'other',
		}
	);

Takes a hashref as an argument, does not return a sensible return value.
See C<paste> event's description for more information.

=head2 C<session_id>

	my $poco_id = $poco->session_id;

Takes no arguments. Returns component's session ID.

=head2 C<shutdown>

	$poco->shutdown;

Takes no arguments. Shuts down the component.

=head1 ACCEPTED EVENTS

=head2 C<paste>

	$poe_kernel->post( pastebin => paste => {
			event       => 'event_for_output',
			text        => 'Lorem ipsum dolor sit amet ...',
			_blah       => 'pooh!',
			session     => 'other',
		}
	);

Instructs the component to create a new paste. Takes a hashref as an
argument, the possible keys/value of that hashref are as follows:

=head3 event

	{ event => 'pasted_event', }

B<Mandatory>. Specifies the name of the event to emit when the paste has
been created. See OUTPUT section for more information.

=head3 text

	{ text => 'Lorem ipsum dolor sit amet ...' }

B<Mandatory>. The text that will be pasted.

=head3 C<session>

	{ session => 'other' }

	{ session => $other_session_reference }

	{ session => $other_session_ID }

B<Optional>. Takes either an alias, reference or an ID of an alternative
session to send output to.

=head3 extra parameters

	{ nick => 'Treeki', lang => 'perl', }

B<Optional>. These will be passed directly to the C<paste>
method of the pastebin object, and are specific to whichever class is used.

=head3 user defined

	{
		_user    => 'random',
		_another => 'more',
	}

B<Optional>. Any keys starting with C<_> (underscore) will not affect the
component and will be passed back in the result intact.

=head2 C<shutdown>

	$poe_kernel->post( pastebin => 'shutdown' );

Takes no arguments. Tells the component to shut itself down.

=head1 OUTPUT

	$VAR1 = {
		'uri' => URI->new("http://www.example.com/12345"),
		'_blah' => 'foos'
	};

The event handler set up to handle the event which you've specified in
the C<event> argument to C<paste()> method/event will recieve input
in the C<$_[ARG0]> in a form of a hashref. The possible keys/value of
that hashref are as follows:

=head2 uri

	Will be present if the paste creation completed. Contains a L<URI> object.

=head2 error

	Will be present if something went wrong during the paste creation. Contains
	an explanation of the failure.

=head2 user defined

	{ '_blah' => 'foos' }

Any arguments beginning with C<_> (underscore) passed into the C<paste()>
event/method will be present intact in the result.

=head1 SEE ALSO

L<POE>, L<WWW::Pastebin::Sprunge::Create>

=head1 AUTHOR

Jan A. (Treeki) <treeki@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jan A. (Treeki).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

