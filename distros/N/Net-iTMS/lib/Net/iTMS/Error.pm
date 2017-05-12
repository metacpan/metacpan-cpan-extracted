package Net::iTMS::Error;
#
# Written by Thomas R. Sibley, <http://zulutango.org:82/>
#
use warnings;
use strict;

use vars qw($VERSION @EXPORT);
$VERSION = '0.13';

use Exporter::Lite;
@EXPORT = qw(error _debug _set_error);

=head1 NAME

Net::iTMS::Error - Handles errors in Net::iTMS

=head1 DESCRIPTION

Error handling parts of the L<Net::iTMS> distribution.

=head2 Methods

=over 12

=item C<error>

Returns a string containing an error message (if there is one).
Usually useful after a method has returned C<undef> for finding
out what went wrong.

=cut
sub error {
    my $self = shift;
    return $self->{error};
}

sub _debug {
    my $self = shift;
    print STDERR @_, "\n" if $self->{debug};
    return 1;
}

sub _set_error {
    my $self = shift;
    $self->{error} = join '', @_;
    $self->_debug($self->{error});
    return undef;
}

=back

=head1 LICENSE

Copyright 2004, Thomas R. Sibley.

You may use, modify, and distribute this package under the same terms as Perl itself.

=head1 AUTHOR

Thomas R. Sibley, L<http://zulutango.org:82/>

=cut

42;
