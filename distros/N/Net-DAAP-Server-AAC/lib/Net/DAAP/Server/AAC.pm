package Net::DAAP::Server::AAC;

use strict;
our $VERSION = '0.01';

use base qw( Net::DAAP::Server );
use File::Find::Rule;
use Net::DAAP::Server::Track;
use Net::DAAP::Server::AAC::Track;

sub find_tracks {
    my $self = shift;
    for my $file ( find name => [ '*.mp3', '*.mp4', '*.m4a' ], in => $self->path) {
        my $track;
        if ($file =~ /\.mp3$/i) {
            $track = Net::DAAP::Server::Track->new_from_file( $file );
        } else {
            $track = Net::DAAP::Server::AAC::Track->new_from_file( $file );
        }
        $track or next;
        $self->tracks->{ $track->dmap_itemid } = $track;
    }
}

1;
__END__

=head1 NAME

Net::DAAP::Server::AAC - DAAP server that handles MP3 and AAC

=head1 SYNOPSIS

  use POE;
  use Net::DAAP::Server::AAC;

  # same as Net::DAAP::Server
  my $server = Net::DAAP::Server::AAC->new(
      path => "/home/miyagawa/music",
      port => 9999,
      name => "My Music",
  );
  $poe_kernel->run;

=head1 DESCRIPTION

Net::DAAP::Server::AAC is a Net::DAAP::Server's subclass that handles
MP4/AAC files as well, in addition to the MP3 music files.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

Richard Clamp wrote Net::DAAP::Server and Net::DAAP::Server::Track,
from which a lot of code is used and subclassed.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Net::DAAP::Server>, L<MP4::Info>

=cut
