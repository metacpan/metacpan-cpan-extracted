package Net::DPAP::Client::Album;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(count id name images));

1;

__END__

=head1 NAME

Net::DPAP::Client::Album - Remote DPAP album

=head1 DESCRIPTION

This module represents a remote iPhoto shared album.

=head1 METHODS

=head2 count

The returns the number of images in the album.

=head2 id

This returns the internal iPhoto ID for the album. You probably don't
need to worry about this.

=head2 images

This returns an arrayref of Net::DPAP::Client::Image objects,
representing the images in the album.

=head2 name

This returns the name of the album. Note that if you are sharing
individual albums, iPhoto tends to share all the images in the
collection in an album named "Photo album", as well as in the
individual albums. So you may see photos twice in that case.

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 COPYRIGHT

Copyright (C) 2004, Leon Brocard

This module is free software; you can redistribute it or modify it under
the same terms as Perl itself.
