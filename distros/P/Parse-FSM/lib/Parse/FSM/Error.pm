# $Id: Lexer.pm,v 1.10 2013/07/27 00:34:39 Paulo Exp $

package Parse::FSM::Error;

#------------------------------------------------------------------------------

=head1 NAME

Parse::FSM::Error - Format error and waring messages

=cut

#------------------------------------------------------------------------------

use 5.010;
use strict;
use warnings;

our $VERSION = '1.13';

#------------------------------------------------------------------------------

=head1 SYNOPSIS

  use Parse::FSM::Error qw( error warning );

  error($message);
  error($message, $file, $line_nr);
  
  warning($message);
  warning($message, $file, $line_nr);

=head1 DESCRIPTION

This module formats an error or warning message and displays it on C<STDERR>,
exiting with die for C<error>.

=head1 EXPORTS

None by default.

=cut

#------------------------------------------------------------------------------
use Exporter 'import';
our @EXPORT_OK = qw( error warning );
#------------------------------------------------------------------------------

=head2 error

Formats the error message, shows it on C<STDERR> and dies. 
The file name and line number are optional.

=cut

#------------------------------------------------------------------------------
sub error { 
	die _error_msg("Error", @_);
}
#------------------------------------------------------------------------------

=head2 warning

Formats the warning message and shows it on C<STDERR>. 
The file name and line number are optional.

=cut

#------------------------------------------------------------------------------
sub warning { 
	warn _error_msg("Warning", @_);
}

#------------------------------------------------------------------------------
sub _error_msg {
	my($type, $message, $file, $line_nr) = @_;

	$file    = defined($file) ? "file '$file'"  : undef;
	$line_nr = $line_nr       ? "line $line_nr" : undef;
	my $pos  = (defined($file) || defined($line_nr)) ?
				"at ".join(", ", grep {defined} $file, $line_nr) :
				undef;

	if (defined($message)) {
		$message =~ s/\s+\z//;		# in case message comes from die, has a "\n"
		if ($message eq "") {
			undef $message;
		}
		else {
			$message = ": ".$message;
		}
	}
	
	return join(" ", grep {defined} $type, $pos, $message)."\n";
}

#------------------------------------------------------------------------------

=head1 AUTHOR, BUGS, FEEDBACK, LICENSE, COPYRIGHT

See L<Parse::FSM|Parse::FSM>

=cut

#------------------------------------------------------------------------------

1;
