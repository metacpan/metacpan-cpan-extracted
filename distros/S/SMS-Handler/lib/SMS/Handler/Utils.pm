package SMS::Handler::Utils;

require 5.005_62;

use strict;
use warnings;
require Exporter;

# $Id: Utils.pm,v 1.4 2003/01/03 02:03:34 lem Exp $

our $VERSION = q$Revision: 1.4 $;
$VERSION =~ s/Revision: //;

our @EXPORT_OK = qw(Split Split_msg);
our @ISA = qw(Exporter);

=pod

=head1 NAME

SMS::Handler::Utils - Utility functions used by some SMS::Handler modules

=head1 SYNOPSIS

  use SMS::Handler::Utils;

  ...

=head1 DESCRIPTION

This module provides various utility functions for use by
C<SMS::Handler::...> modules.

The exported functions are:

=over 3

=item C<Split($msg)>

Separates an incoming SMS into a command and body section. It is
separated either by the first newline or the first occurrence of two
consecutive spaces.

=cut

sub Split
{
    my $msg = shift;
    my $body;

    my $i;

    ($msg, $body) = split(qr(\n|  ), $msg, 2);

    $body = '' unless defined $body;

    return $msg, $body;
}

=pod

=item C<Split_msg($maxlen, \$text)>

Splits the given message (passed as a reference to a scalar) into
C<$maxlen> characters wide messages. Returns an array of scalar
references pointing to each chunk, which include a counter.

=cut

sub Split_msg
{
    my $maxlen	= shift;
    my $text	= shift;

    my @msg = ();

    my $join = '...';
    my $sjoin = length($join);
    my $size = $maxlen - $sjoin;

    push @msg, $_ while $_ = substr($$text, 0, $size - 4, '');
    
    my $change;
				# Now iterate through the list of chunks
				# fixing lengths up.
    do 
    {
	$change = 0;
	for my $c (0 .. $#msg)
	{
#	    warn "# Checking $c $msg[$c] " . scalar @msg . "\n";
	    if (length($msg[$c]) 
		+ length($c) 
		+ length(scalar @msg) + 2 > $size)
	    {
		$msg[$c + 1] = '' unless $msg[$c + 1];
		substr($msg[$c + 1], 0, 0, 
		       substr($msg[$c],
			      $size
			      - length($msg[$c]) 
			      - length($c) 
			      - length(scalar @msg)
			      - 2
			      - $sjoin, length($msg[$c]), ''));
		$change = 1;
	    }
	}
    } while $change;
				# Fixup the strings in each chunk
    my $c = 0;

    return [ map 
	     { ++$c . '/' . scalar @msg . "\n$_" . 
		   ($c < scalar @msg ? $join : '');
	   } @msg ];
}

__END__

=pod

=back

=head2 EXPORT

All the methods cited above can be exported to the caller.

=head1 LICENSE AND WARRANTY

This code comes with no warranty of any kind. The author cannot be
held liable for anything arising of the use of this code under no
circumstances.

This code is released under the terms and conditions of the
GPL. Please see the file LICENSE that accompains this distribution for
more specific information.

This code is (c) 2002 Luis E. Muñoz.

=head1 HISTORY

$Log: Utils.pm,v $
Revision 1.4  2003/01/03 02:03:34  lem
Minor improvement in Utils::Split. Tests fixed accordingly

Revision 1.3  2003/01/03 00:52:46  lem
Fixed SMS-splitting bug when delimiting message and body with two spaces. Added tests for this

Revision 1.2  2003/01/02 23:55:22  lem
Fixed delimiter bug in ::Utils::Split. Added tests for this bug

Revision 1.1  2002/12/27 19:43:42  lem
Added ::Dispatcher and ::Utils to better distribute code. This should make easier the writting of new methods easier


=head1 AUTHOR

Luis E. Muñoz <luismunoz@cpan.org>

=head1 SEE ALSO

L<SMS::Handler>, perl(1).

=cut
