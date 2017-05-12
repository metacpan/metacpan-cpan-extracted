package Perl::Shell;

=pod

=head1 NAME

Perl::Shell - A Python-style "command line interpreter" for Perl

=head1 SYNOPSIS

  C:\Document and Settings\adamk> perlthon
  Perl 5.10.1 (Sat Oct 17 22:14:49 2009) [Win32 strawberryperl 5.10.1.0 #1 33 i386]
  Type "help;", "copyright;", or "license;" for more information.
  
  >>> print "Hello World!\n";
  Hello World!
  
  >>> 

=head1 DESCRIPTION

B<THIS MODULE IS HIGHLY EXPERIMENTAL AND SUBJECT TO CHANGE.>

B<YOU HAVE BEEN WARNED>

This module provides a lookalike implementation of a "command line
interpreter" for Perl, in the style of the Python equivalent.

This is part an attempt to make Perl more approachable (both in general
and specifically for Python programmers), partly an exercise to force
myself to explore Python's usability aspects, partly a way to provide
Strawberry Perl with a "Perl (command line)" start menu entry, and
partly as fodder for a funny lightning talk.

On the command line, you can start the shell with "perlthon".

=head2 Features

Multi-line statements are supported correctly by using L<PPI> to
detect statement boundaries (something it can do very reliably).

  >>> print
  ... "Hello World!\n"
  ... ;
  Hello World!
  
  >>> 

Lexical variables are supported correctly across multiple statements.

  >>> my $foo = "Hello World!\n";
  
  >>> print $foo;
  Hello World!
  
  >>>

Package scoping and state are correctly preserved across multiple
statments.

  >>> package Foo;
  
  >>> sub bar {
  ...     print "Hello World!\n";
  ... }
  
  >>> Foo::bar();
  Hello World!
  
  >>>

=head1 FUNCTIONS

=cut

use 5.006;
use strict;
use Config;
use Carp                 ();
use Params::Util    1.00 '_INSTANCE';
use Term::ReadLine     0 ();
use PPI            1.205 ();

our $VERSION = '0.04';





######################################################################
# Content

use constant INTRO => <<"END_TEXT";
Perl $Config{version} ($Config{cf_time}) [$Config{myuname}]
Type "help;", "copyright;", or "license;" for more information.
END_TEXT

use constant HELP => <<"END_TEXT";
Type help() for interactive help, or help(object) for help about object.
END_TEXT

use constant COPYRIGHT => <<"END_TEXT";
Perl is Copyright (C) 1993, 1994, 1995, 1996, 1997, 1998, 1999, 2000, 2001,
2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009 by Larry Wall and others.
All rights reserved.
END_TEXT

use constant LICENSE => <<"END_TEXT";
This program is free software; you can redistribute it and/or modify
it under the terms of either:

	a) the GNU General Public License as published by the Free
	Software Foundation; either version 1, or (at your option) any
	later version, or

	b) the "Artistic License" which comes with this Kit.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
the GNU General Public License or the Artistic License for more details.

You should have received a copy of the Artistic License with this
Kit, in the file named "Artistic".  If not, I'll be glad to provide one.

You should also have received a copy of the GNU General Public License
along with this program in the file named "Copying". If not, write to the
Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, 
Boston, MA 02110-1301, USA or visit their web page on the internet at
http://www.gnu.org/copyleft/gpl.html.

For those of you that choose to use the GNU General Public License,
my interpretation of the GNU General Public License is that no Perl
script falls under the terms of the GPL unless you explicitly put
said script under the terms of the GPL yourself.  Furthermore, any
object code linked with perl does not automatically fall under the
terms of the GPL, provided such object code only adds definitions
of subroutines and variables, and does not otherwise impair the
resulting interpreter from executing any standard Perl script.  I
consider linking in C subroutines in this manner to be the moral
equivalent of defining subroutines in the Perl language itself.  You
may sell such an object file as proprietary provided that you provide
or offer to provide the Perl source, as specified by the GNU General
Public License.  (This is merely an alternate way of specifying input
to the program.)  You may also sell a binary produced by the dumping of
a running Perl script that belongs to you, provided that you provide or
offer to provide the Perl source as specified by the GPL.  (The
fact that a Perl interpreter and your code are in the same binary file
is, in this case, a form of mere aggregation.)  This is my interpretation
of the GPL.  If you still have concerns or difficulties understanding
my intent, feel free to contact me.  Of course, the Artistic License
spells all this out for your protection, so you may prefer to use that.
END_TEXT





#####################################################################
# Top Level Commands

sub main::help () {
	print HELP;
}

sub main::copyright () {
	print COPYRIGHT;
}

sub main::license () {
	print LICENSE;
}





#####################################################################
# Shell Functions

=pod

=head2 shell

  Perl::Shell::shell();

The C<shell> function starts up the command line shell. It takes no
parameters and returns when the user does an exit().

Lexical and package persistance is B<NOT> maintained between multiple
shell runs.

=cut

sub shell {
	# Set up the lexical scope for the session
	my $state = Perl::Shell::_State->new;

	# Say hello to the user
	print INTRO;

	# The main command loop
	my @buffer  = ();
	my $package = 'main';
	while ( 1 ) {    
		# Read in a line
		my $line = _readline(@buffer ? '... ' : '>>> ');
		unless ( defined $line ) {
			die "Failed to readline\n";
		}
		push @buffer, $line;

		# Continue if the statement is not complete
		next unless complete( @buffer );

		# Execute the code
		local $@;
		my $code = join "\n", @buffer;
		my @rv   = eval {
			$state->do($code);
		};
		print "ERROR: $@" if $@;
		print "\n";

		# Clean up for the next command
		@buffer = ();
	}
}

my $term;
sub _readline {
	my $prompt = shift;
	if ( -t STDIN ) {
		unless ( $term ) {
			require Term::ReadLine;
			$term = Term::ReadLine->new('Perl-Shell');
		}
		return $term->readline($prompt);
	} else {
		print $prompt;
		my $line = <>; 
		chomp if defined $line;
		return $line;
	}
}





#####################################################################
# Support Functions

=head2 complete

  my $done = Perl::Shell::complete(@code);

The C<complete> function takes one or more strings of Perl code
(which it will join as lines if there are more than one) and uses
PPI to determine is the code is a "complete" Perl document.

That is, does the code represent a string of Perl where the topmost
level of nesting ( i.e. sub { ... } ) and the end of the string marks
a natural statement boundary.

Returns true if the code is a complete document, or false if not.

This function is documented and supported as a convenience for other
people implementing similar functionality (and may be moved into PPI
itself at a later time).

=cut

# To be "complete" a fragment of Perl must have no open structures
# and terminate with a clear statement end.
sub complete {
	my $string = join "\n", @_;

	# As a quick and dirty way to check for a clear statement
	# end, we append a semi-colon to the string. If this is
	# subsequently parsed as a null statement, we know the
	# string is a complete document.
	# The newline is added to get us out of comment blocks
	# and similar line-specific things.
	$string .= "\n;";

	# Parse the string into a document
	my $document = PPI::Document->new( \$string );
	unless ( $document ) {
		die "PPI failed to parse document";
	}

	# The document must end in a null statement
	unless ( _INSTANCE($document->child(-1), 'PPI::Statement::Null') ) {
		return '';
	}

	# The document must not contain any open braces
	$document->find_any( sub {
		$_[1]->isa('PPI::Structure') and ! $_[1]->finish
	} ) and return '';

	# The document is complete
	return 1;
}





######################################################################
# Enhanced Lexical::Persistance with sticky package

# Should probably move this to its own file at some point.

package Perl::Shell::_State;

use Lexical::Persistence 1.01 ();

our @ISA = 'Lexical::Persistence';

# Package changes are tracked by temporarily passing it via a global.
# This does not contain permanent state, and so shouldn't suffer most
# of the normal problems caused by globals.
our $PACKAGE = undef;

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);

	# Set the initial package
	$self->{package} = 'main';

	return $self;
}

sub get_package {
	$_[0]->{package};
}

sub set_package {
	$_[0]->{package} = $_[1];
}

sub prepare {
	my $self    = shift;
	my $code    = shift;
	my $package = $self->get_package;

	# Put the package handling tight around the code to execute
	$code = <<"END_PERL";
package $self->{package};

$code

BEGIN {
	\$Perl::Shell::_State::PACKAGE = __PACKAGE__;
}
END_PERL

	# Hand off to the parent version
	return $self->SUPER::prepare($code, @_);
}

# Modifications to the package are tracked at compile-time
sub compile {
	my $self = shift;
	my $sub  = $self->SUPER::compile(@_);

	# Save the package state
	$self->set_package($PACKAGE);

	return $sub;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Shell>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 ACKNOWLEGEMENTS

Thanks to Ingy for suggesting that this module should exist.

=head1 COPYRIGHT

Copyright 2008 - 2010 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
