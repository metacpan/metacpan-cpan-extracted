package String::ExpandEscapes;
#
#	String::ExpandEscapes - Expand printf-style %-escapes in a string. 
#
#	Copyright (c) 2003 Matthias Friedrich <matt@mafr.de>.
#
#	$Id: ExpandEscapes.pm,v 1.1.1.1 2003/04/03 19:10:10 matthias Exp $
#

use 5.008;
use strict;
use warnings;
use Carp;

require Exporter;

#
# Change version number for each release!
#
our $VERSION = '0.01';

our @ISA = qw(Exporter);

#
# This allows declaration	use String::ExpandEscapes ':all';
#
our %EXPORT_TAGS = (
	'all' => [ qw(expand expand_handler) ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

# Export nothing by default.
#
our @EXPORT = qw(
);


#
# This is the default substitution function.
#
sub expand_handler($$$$$)
{
	my $flags = shift;		# left or right alignment
	my $width = shift;		# maximum field width
	my $precision = shift;		# precision
	my $format = shift;		# key for the conversation table
	my $table = shift;		# conversation table (hash reference)

	$precision = ".$precision" if $precision ne '';

	# rewrite '%%' to '%'
	return '%' if $format eq '%';

	# check if we have a rewrite rule for this format specifier
	return undef unless defined $table->{ $format };

	# everything worked fine, now return the string
	return sprintf("%${flags}${width}${precision}s", $table->{ $format } );
}


#
# expand()
#
#	Expand printf-style escape sequences in a string according to a
#	given conversation table.
#
#	Arguments:	source string
#			hash reference to the conversation table or code ref
#			optional user data that is passed to each handler call
#
#	Returns:	destination string
#
#	Examples:	expand('%s', \&handler, ...)
#			expand('%s', \%table)
#
sub expand($$@)
{
	my $str = shift;	# The string containing the escape sequences.
	my $arg = shift;	# First argument: either HASH or CODE.
	my $handler;		# Code reference for a handler function.
	my @user_data;		# Arguments that are passed to the handler.

	#
	# two possibilities:
	#	1. handler is code reference
	#	2. handler is hash reference
	#
	if ( ref $arg eq 'CODE' ) {
		$handler = $arg;
		@user_data = @_;
	}
	elsif ( ref $arg eq 'HASH' ) {

		# If called with a hash reference, no further arguments are
		# allowed
		#
		if ( @_ != 0 ) {
			croak 'expand called in table mode with '
				. 'to many arguments';
		}
		$handler = \&expand_handler;
		@user_data = $arg;
	}
	else {
		croak 'expand called with an argument that is '
			. 'neither a code nor a hash reference';
	}

	#
	# Parse the format string. The code below is executed for each match.
	#
	$str =~ s/	%
			([- +0#]*)	# flags
			(\d*)		# minimum field width aka width
			(\.?)
			(\d*)		# maximum field width aka precision
			(.)		# format selection
		/
			# Special case: "%-10.s" means "%-10.0s".
			#
			my $prec = ( $3 eq '.' and $4 eq '' ) ? 0 : $4;

			# The handler returns the string to substitute.
			#
			my $result = &$handler($1, $2, $prec, $5, @user_data);

			# Leave the function if the handler returned an error.
			#
			return (undef, $&) unless defined $result;

			$result;		# Do the replacement.
		/gesx;

	#
	# We got here without errors, return the string.
	#
	#return $str;
	return ($str, 0);
}


1;

__END__

=head1 NAME

String::ExpandEscapes - Expand printf-style %-escapes in a string. 
        
=head1 SYNOPSIS
        
    use String::ExpandEscapes qw(expand);
        
    my %escapes = (
        a => 'Tori Amos',
        t => 'Silent All These Years'
    )
                                      
    my ($result, $error) = expand('%.1a/%a/%t.mp3', \%escapes);

    die "Illegal escape sequence $error\n" if $error;
                                      
=head1 ABSTRACT

This module contains functions for parsing and doing substitutions in
format strings similar to those used by printf. The %-escapes to be
replaced can either be given using a hash, or, for maximum flexibility,
using a callback function.            

=head1 DESCRIPTION

The expand() function can be called in two different ways, differing
in the type and number of expected arguments.


=head2 expand(string, hashref)

The first one, as described in the SYNOPSIS section, expects two
arguments: A string that possibly contains escape sequences and a
reference to a hash. The hash acts as a conversation table between
valid escape sequences and replacement strings. In this mode, a default
handler is used which is very close in behaviour to perl's builtin
sprintf(). Here is another example:
 
 my %table = (
	a => 'Hello World',
	b => 'Test'
 );

 my ($mystr, $err) = expand('[%.5a] [%-10b] [%10b]', \%table);

 # content of $mystr: "[Hello] [Test      ] [      Test]"


=head2 expand(string, coderef, [data])

The second method is more flexible. Instead of merely passing a
conversation table, you can give a code reference to expand() that is
used as a callback each time an escape sequence is detected in the
string. Your handler is called with four or five arguments, depending
on how you called expand():

=over

=item *

flags: an arbitrary set of '-', '+', '0' and '#'

=item *

width: integer value

=item *

precision: integer value

=item *

format: a single letter

=item *

data: the data you passed to expand()

=back


In case of error (such as an unexpected format character), your handler
should return undef. That causes expand() to return undef as well.

Have a look at the default handler expand_handler of this module for
an example.


=head1 EXPORT

Nothing by default.

=head1 AUTHOR

Matthias Friedrich, E<lt>matt@mafr.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003 by Matthias Friedrich <matt@mafr.de>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
