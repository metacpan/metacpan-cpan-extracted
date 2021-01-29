package API::Matterbridge::Message;
use strict;
use warnings;
use Moo 2;
use JSON 'decode_json';

use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.02';

# This is just a hash-with-(currently no)-methods

has [
  "text",
  "channel",
  "username",
  "userid",
  "avatar",
  "account",
  "event",
  "protocol",
  "gateway",
  "parent_id",
  "timestamp",
  "id",
  "Extra",
 ] => (
    is => 'ro',
);

sub from_bytes( $class, $bytes ) {
    return $class->new( decode_json($bytes))
}

sub reply( $msg, $text, %options ) {
    my %reply = (
        gateway => $msg->gateway,
        text => $text,
        %options
    );
    return (ref $msg)->new(\%reply)
}

1;


=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/Mojolicious-Matterbridge>.

=head1 SUPPORT

The public support forum of this module is L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the Github bug queue at
L<https://github.com/Corion/Mojolicious-Matterbridge/issues>

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2020 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
