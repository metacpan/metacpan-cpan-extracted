#!/usr/local/bin/perl

=head1 NAME

Output::Buffer - module that assists in the capturing of output

=head1 DESCRIPTION

This module assists in the capture and buffer of data outputted from a program.
For more information please see http://www.theperlreview.com Volume 0 Issue 5
"Filehandle Ties".

=head1 TODO

=over 4

=item *

test.pl

=back

=head1 BUGS

This is a new module and has not been thoroughly tested.

=cut

package Output::Buffer;

# BEHAVIORAL CONSTANTS
use constant WARN => 2;
use constant FLUSH => 1;
use constant CLEAN => 0;

# EXPORT
use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS $VERSION);
@ISA = qw(Exporter);
@EXPORT_OK = qw(WARN FLUSH CLEAN);
%EXPORT_TAGS = ( constants => [@EXPORT_OK] );

# VERSION
$VERSION = 0.1;

# DEPENDENCIES
use Tie::FileHandle::Buffer;
use Symbol;
use Carp;
use strict;

# Create a new output buffer
# Usage: my $buffer = Output::Buffer->new( behavior )
# where behavior is either FLUSH, CLEAN, or WARN
#    FLUSH - when the object loses scope, print its buffer
#    CLEAN - when the object loses scope, discard its buffer
#    WARN - when the object loses scope, discard its buffer
#           but issue a warning
sub new {
	my $fh = gensym; # create an anonymous filehandle
	tie *{$fh}, 'Tie::FileHandle::Buffer';

	# store our behavior, our handle, and the handle we replaced
	bless [ $_[1], $fh, select $fh ], $_[0];
}

# clean the output buffer, discarding its contents
sub clean {
	(tied *{$_[0]->[1]})->clear;
}

# get our contents
sub get_contents {
	(tied *{$_[0]->[1]})->get_contents;
}

# flush the output buffer, printing its contents
sub flush {
	my $self = shift;
	my $handle = $self->[2];

	# print our contents to our parent
	print $handle $self->get_contents;

	# then discard them
	$self->clean;
}

# Our scope has ended - deal with it by acting out our behavior
sub DESTROY {
	my $self = shift;
	if ( $self->[0] == FLUSH ) {
		# FLUSH means flush!
		$self->flush;
	} else {
		# only WARN carps - and only if there was buffered output
		carp "Discarded output buffer contents"
		   if ( ($self->[0] == WARN) && (length($self->get_contents) != 0));
		# both CLEAN and WARN imply cleaning
		$self->clean;
	}

	# return the old filehandle to domination
	my $handle = $self->[2];
	select $handle;
}

1;

=head1 AUTHORS AND COPYRIGHT

Written by Robby Walker ( robwalker@cpan.org ) for Point Writer ( http://www.pointwriter.com/ ).

You may redistribute/modify/etc. this module under the same terms as Perl itself.

