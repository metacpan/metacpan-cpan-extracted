#
# This file is part of POE-Component-SpreadClient
#
# This software is copyright (c) 2014 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
package POE::Driver::SpreadClient;
$POE::Driver::SpreadClient::VERSION = '1.003';
our $AUTHORITY = 'cpan:APOCAL';

# ABSTRACT: Implements the Spread driver for POE

# Import some stuff
use Spread;

# magic number taken from Spread's MAX_READS
my $MAX_READS = 256;

sub new {
	my $type = shift;
	my $mbox = shift;
	my $self = bless \$mbox, $type;
	return $self;
}

sub get {
	my $self = shift;

	my $reads_performed = 1;
	my @buf;

	# read once:
	push @buf, [ Spread::receive( $$self ) ];

	# Spread::poll returns 0 if no messages pending;
	while( Spread::poll( $$self ) and ++$reads_performed <= $MAX_READS ) {
		push @buf, [ Spread::receive( $$self ) ];
	}

	return [ @buf ];
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Apocalypse

=for Pod::Coverage get new

=head1 NAME

POE::Driver::SpreadClient - Implements the Spread driver for POE

=head1 VERSION

  This document describes v1.003 of POE::Driver::SpreadClient - released November 10, 2014 as part of POE-Component-SpreadClient.

=head1 DESCRIPTION

This module implements the L<POE::Driver> interface for Spread.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<POE::Component::SpreadClient|POE::Component::SpreadClient>

=back

=head1 AUTHOR

Apocalypse <APOCAL@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Apocalypse.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=head1 DISCLAIMER OF WARRANTY

THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
