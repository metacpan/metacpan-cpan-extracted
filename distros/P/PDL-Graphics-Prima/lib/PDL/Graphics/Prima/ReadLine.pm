package PDL::Graphics::Prima::ReadLine;
use strict;
use warnings;
use Carp;

our $VERSION = 0.17;   # update with update-version.pl

my $is_setup = 0;

sub is_happy_with {
	# Stop-gap until I figure out better readline support for Windows
	return 0 if $^O =~ /Win/ or $^O =~ /cygwin/;
	my ($class, $readline_obj) = @_;
	return eval{ $readline_obj->can('event_loop')
		and not $readline_obj->tkRunning };
}

sub setup {
	my ($class, $readline_obj) = @_;
	
	return if $is_setup;
	
	# Make sure we have a readline object that knows how to work with the
	# event loop:
	if (not $class->is_happy_with($readline_obj)) {
		croak("PDL::Graphics::Prima::ReadLine expects a readline object")
			unless eval { $readline_obj->isa('Term::ReadLine::Stub') };
		croak("PDL::Graphics::Prima::ReadLine expects a readline object that knows how to event_loop.\n"
				. "This is provided in Term::ReadLine v1.09 or newer");
	}
	
	# We must call the import method for this to work, even though we don't need
	# need any functions imported. The reason is that Prima sets up the
	# application object during the import if it hasn't already been set up (by
	# a previous call to Prima::Application::import).
	require Prima::Application;
	Prima::Application->import;
	
	# This io watcher will (eventually) watch whatever the readline is
	# monitoring. That will be established later in the call to event_loop.
	# Die'ing is a simple way to exit the "go" method invoked during the
	# event loop
	my $prima_io_watcher = Prima::File->new(
		onRead => sub { die 'user pressed a key' },
	);
	
	$readline_obj->event_loop( sub {
			local $@;
			# Run the event loop. If a key is pressed, the io watcher's
			# callback will get called, throwing an exception.
			eval { $::application->go };
			# Rethrow the exception if it's not one that we threw
			die unless $@ =~ /user pressed a key/;
		},
		sub {
			# Register the event loop, which means associating the io
			# watcher with the specific io handle the readline wants
			my $fh = shift;
			$prima_io_watcher->file($fh);
		},
	);
	$is_setup = 1;
}

# Status method
sub is_setup { $is_setup }

1;

__END__

=head1 NAME

PDL::Graphics::Prima::ReadLine - allowing Prima and Term::ReadLine to play
together

=head1 SYNOPSIS

 # This pulls in PDL::Graphics::Prima::ReadLine, and
 # associate's the PDL Shell's readline object if it
 # exists:
 use PDL::Graphics::Prima;
 
 # Did it set up the readline event loop callback?
 print "Set up Prima/ReadLine interaction\n"
     if PDL::Graphics::Prima::ReadLine->is_setup;
 
 # If you are not in the PDL shell, you can supply
 # your own ReadLine object.
 if (PDL::Graphics::Prima::ReadLine->is_happy_with($my_readline) {
     PDL::Graphics::Prima::ReadLine->setup($my_readline);
 }
 
 # If you don't validate first, setup() may croak.
 # In other words, instead of this:
 if (PDL::Graphics::Prima::ReadLine->is_happy_with($my_readline) {
     PDL::Graphics::Prima::ReadLine->setup($my_readline);
 }
 else {
     die "Unable to setup Prima/ReadLine interaction\n";
 }
 # You could just say this instead:
 PDL::Graphics::Prima::ReadLine->setup($my_readline);

=head1 DESCRIPTION

This module's job is to encapsulate the vagaries of setting up interaction
between the L<Prima event loop|Prima::Application/go> and
L<Term::ReadLine's event loop|Term::ReadLine/event_loop>. Loading the
module does not have any side-effects, and it is always loaded by
L<PDL::Graphics::Prima|PDL::Graphics::Prima/>. Furthermore,
L<PDL::Graphics::Prima|PDL::Graphics::Prima/> will set up the event loop
interaction with the L<PDL shell|perldl/> if it detects the shell's
ReadLine object.

Generally speaking, if you intend to have user interaction and want to use
L<PDL::Graphics::Prima|PDL::Graphics::Prima/>, you should probably just use
L<Prima|Prima/> to build a simple interactive application. (Docmentation for
getting started with this is coming soon, I promise.) However, if you want
to integrate L<PDL::Graphics::Prima|PDL::Graphics::Prima/> into a pluggable
application that already uses L<Term::ReadLine|Term::ReadLine/>, this
module should make that procedure as straight-forward as one can hope.

C<PDL::Graphics::Prima::ReadLine> can only hook into the event loop for
newer versions of L<Term::ReadLine|Term::ReadLine/> (specifically, versions
that support L<event_loop|Term::ReadLine/event_loop>). Also, due to current
limitations in my knowledge of Prima's monitoring of STDIN, this module
cannot hook into the event loop on Windows operating systems, both Cygwin
and Strawberry Perl.

=head2 is_happy_with

If you want to set up the event loop interaction on your own ReadLine object,
you can ask C<PDL::Graphics::Prima::ReadLine> if it can work with your
object by calling the C<is_happy_with> class method and supplying your
objects. This method returns a boolean value indicating whether or not the
object can do what C<PDL::Graphics::Prima::ReadLine> needs:

 if (PDL::Graphics::Prima::ReadLine->is_happy_with($my_readline) {
     print "Setting up Prima/ReadLine interaction\n";
     PDL::Graphics::Prima::ReadLine->setup($my_readline);
 }

=head2 setup

To hook Prima's event loop into your ReadLine's event loop, you can call the
C<setup> class method:

 PDL::Graphics::Prima::ReadLine->setup($readline_obj);

This method may (should) fail if the ReadLine object provided cannot support
the functionality needed for hooking Prima into ReadLine. This could happen
either because your version of ReadLine is too old or because you are running
on Windows, which is not (yet) supported by C<PDL::Graphics::Prima::ReadLine>.

=head1 SEE ALSO

For purposes of this module, you should check out L<Term::ReadLine>. This
module is implemented using L<Prima::File>.

=head1 AUTHOR

David Mertens (dcmertens.perl@gmail.com)

=head1 ADDITIONAL MODULES

Here is the full list of modules in this distribution:

=over

=item L<PDL::Graphics::Prima|PDL::Graphics::Prima/>

Defines the Plot widget for use in Prima applications

=item L<PDL::Graphics::Prima::Axis|PDL::Graphics::Prima::Axis/>

Specifies the behavior of axes (but not the scaling)

=item L<PDL::Graphics::Prima::DataSet|PDL::Graphics::Prima::DataSet/>

Specifies the behavior of DataSets

=item L<PDL::Graphics::Prima::Limits|PDL::Graphics::Prima::Limits/>

Defines the lm:: namespace

=item L<PDL::Graphics::Prima::Palette|PDL::Graphics::Prima::Palette/>

Specifies a collection of different color palettes

=item L<PDL::Graphics::Prima::PlotType|PDL::Graphics::Prima::PlotType/>

Defines the different ways to visualize your data

=item L<PDL::Graphics::Prima::ReadLine|PDL::Graphics::Prima::ReadLine/>

Encapsulates all interaction with the L<Term::ReadLine> family of
modules.

=item L<PDL::Graphics::Prima::Scaling|PDL::Graphics::Prima::Scaling/>

Specifies different kinds of scaling, including linear and logarithmic

=item L<PDL::Graphics::Prima::Simple|PDL::Graphics::Prima::Simple/>

Defines a number of useful functions for generating simple and not-so-simple
plots

=back

=head1 LICENSE AND COPYRIGHT

Unless otherwise stated, all contributions in code and documentation are
copyright (c) their respective authors, all rights reserved.

Portions of this module's code are copyright (c) 2011 The Board of
Trustees at the University of Illinois.

Portions of this module's code are copyright (c) 2011-2013 Northwestern
University.

Portions of this module's code are copyright (c) 2013-2014 Dickinson
College.

This module's documentation is copyright (c) 2011-2014 David Mertens.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
