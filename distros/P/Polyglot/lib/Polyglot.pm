use 5.008;

package Polyglot;
use strict;
use vars qw($VERSION);

use warnings;
no warnings;

=encoding utf8

=head1 NAME

Polyglot - a little language interpreter

=head1 SYNOPSIS

	# THIS IS ALPHA SOFTWARE

	use Polyglot;

	my $interpreter = Polyglot->new();

	$polyglot->add_action( ... );

	$interpreter->run();

=head1 DESCRIPTION

This module implements a simple, little language interpreter to
describe the language.

For this interpreter, a program is a series of lines with one
directive perl line.  The first group of non-whitespace characters in
the line is a the I<directive> and the remainder of the line becomes
its arguments.  The interpreter reads one line, does what it says,
then moves to the next line until it reaches the end of the file.  If
the interpreter does not read from a file, it prompts for standard
input.

A small program to control an CD player may look like:

	VOLUME 5
	PLAY
	SLEEP 50
	STOP
	EJECT

The interpreter does not support loops, conditionals, or other fancy
things, and I do not have plans to add those things.

The interpret provides a few commands, but I expect other people to
create their own little languages specialized for their task. Most of
the methods deal with creating the language description at the
interpreter level.  I plan on creating another layer above this to
make the language description even more simple.

=cut

use autouse 'Data::Dumper' => 'Dumper';

use Carp qw(carp);
use Text::ParseWords qw( quotewords );

our $VERSION = '1.005';

my $Debug = $ENV{DEBUG} || 0;

=head2 Methods

=over 4

=item new

Creates a new Polyglot object and returns it.

=cut

sub new {
	my( $class, @args )  = @_;

	my $self = bless {}, $class;

	$self->add_action( 'POLYGLOT',
		sub {
			my( $self, $package ) = @_;
			eval{ eval "require $package" };
			} );
	$self->add_action( 'HELP', sub { my $self = shift; $self->help( @_ ) } );
	$self->add_action( 'EXIT', sub { exit } );
	$self->add_action( 'REFLECT', sub { print Dumper( $_[0] ) } );
	$self->add_action( 'SHOW', sub {
		my( $self, $name ) = ( shift, uc shift );
		print "$name = ", $self->value($name), "\n";
		$self; } );
	}

=item run

Start the interpreter.  It will read lines from the file names in
@ARGV or from standard input using the diamond operator.  It splits
lines on whitespace and assumes the first element of that list is
the directive name.  If the directive does not exist, it prints a
warning and continues.

This method uses the diamond operator and assumes that nothing else
has mucked with it.

=cut

sub run {
	my $self = shift;

	my $prompt = "$0> ";

	print "H: Waiting for commands on standard input\n$prompt"
		unless @ARGV;

	while( <> ) {
		print "$ARGV\[$.]: $_";
		chomp;
		next if /^\s*#?$/;
		my( $directive, $string ) = split /\s+/, $_, 2;

		$directive = uc $directive;
		carp "DEBUG: directive is $directive\n" if $Debug;

		my @arguments = quotewords( '\s+', 0, $string );
		carp "DEBUG: arguments are @arguments\n" if $Debug;

		eval {
			die "Undefined subroutine" unless exists $self->{$directive};
			$self->{$directive}[1]( $self, @arguments );
			};

		warn "Not a valid directive: [$directive] at $ARGV line $.\n"
			if $@ =~ m/Undefined subroutine/;

		print "$prompt" if $ARGV eq '-';
		}

	print "\n";
	}

=item state

Returns the string used to mark a directive that affects the program
state.

=cut

sub state ()  { 'state' }

=item action

Returns the string used to mark a directive that performs an action.

=cut

sub action () { 'action' }


=item add( DIRECTIVE, TYPE, CODEREF, INITIAL_VALUE, HELP )

Adds DIRECTIVE to the little language with TYPE (state or action).
The value of the directive (for those that represent program state) is
INITIAL_VALUE or undef. The CODEREF is executed when the interpreter
encounters the directive.  The built-in HELP directive returns the
HELP string for this DIRECTIVE.

=cut

sub add {
	my( $self, $name, $state, $sub, $value, $help ) = @_;

	$self->{$name} = [ $state, $sub, $help ];

	$self;
	}

=item value( DIRECTIVE [, VALUE ] )

Returns the value for DIRECTIVE, or sets it if you specify VALUE.

=cut

sub value {
	my( $self, $name, $value ) = @_;
	carp "Setting $name with $value\n" if $Debug;

	return unless exists $self->{ $name };

	return $self->{$name}[2] unless defined $value;

	$self->{$name}[2] = $value;

	}

=item add_action( DIRECTIVE, CODEREF, INITIAL_VALUE, HELP )

Like add(), but without TYPE which is automatically filled in.  Use
this for a directive that does something other than setting a value.

The CODEREF can be anything.  The first argument is always the
interpreter object, and the rest of the arguments are from the current
line.

=cut

sub add_action {
	my $self = shift;
	my $name = uc shift;
	my( $sub, $value, $help ) = @_;

	$self->{$name} = [ $self->action, $sub, $value, $help ];

	$self;
	}

=item add_state( DIRECTIVE, INITIAL_VALUE, HELP )

Like add(), but without TYPE and CODEREF which is automatically filled in.
Use this for a directive that can set a value.

=cut

sub add_state {
	my $self = shift;
	my $name = uc shift;
	my( $value, $help ) = @_;

	$self->{$name} = [ $self->state,
		sub{ my $self = shift; $self->value( $name, @_ ) }, $value, $help ];

	$self;
	}

=item add_toggle( DIRECTIVE, INITIAL_VALUE, HELP )

Like add(), but without TYPE and CODEREF which is automatically filled in.
Use this for a value that can be either "on" or "off".

=cut

sub add_toggle {
	my $self = shift;
	my $name = uc shift;
	my( $value, $help ) = @_;

	my $code = sub {
			my $self = shift;

			return $self->{$name}[2] unless @_;
			my $value = lc shift;
			warn "saw $name with value [$value]\n";

			unless( $value eq 'on' or $value eq 'off' ) {
				warn "$name can be only 'on' or 'off', line $.\n";
				return
				}

			$self->{$name}[2] = $value;

			print "$name is [$$self{$name}[2]]\n";
			};

	$self->{$name} = [ $self->state, $code, $value, $help ];

	$self;
	}

=item help

Returns a help message: you want to override this.

=cut

sub help {
	my $self = shift;
	my $name = uc shift;

	print "This is a help message for [$name]\n";

	$self;
	}

=item directives

Returns a list of directives.

=cut

sub directives {
	my $self = shift;

	return sort keys %$self;
	}

=back

=head1 POLYGLOT LANGUAGES

At the moment you are stuck with the examples and examining
the source.

=head2 Built in directives

The Polyglot module provides some basic directives.

=over 4

=item POLYGLOT PACKAGE

Load a Perl package.

=item SHOW DIRECTIVE

Displays the value of DIRECTIVE

=item DUMP

Displays all of the "state" DIRECTIVES with their values

=item REFLECT

Displays the Polyglot object

=item HELP DIRECTIVE

Displays the help message for DIRECTIVE

=back

=head1 TO DO

* I should really make all of these methods class methods that
access a Singleton object stored as class data.

=head1 SOURCE AVAILABILITY

The source is in GitHub:

	https://github.com/briandfoy/polyglot

=head1 AUTHOR

brian d foy, C<< <briandfoy@pobox.com> >>.

=head1 COPYRIGHT AND LICENSE

Copyright © 2002-2024, brian d foy <briandfoy@pobox.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

"ein";
