package Net::RackSpace::CloudServers::Image;
$Net::RackSpace::CloudServers::Image::VERSION = '0.15';
use warnings;
use strict;
use Any::Moose;
use Carp;

has 'cloudservers' =>
    (is => 'rw', isa => 'Net::RackSpace::CloudServers', required => 1);
has 'id'       => (is => 'ro', isa => 'Int',        required => 1);
has 'name'     => (is => 'ro', isa => 'Str',        required => 1);
has 'serverid' => (is => 'ro', isa => 'Maybe[Int]', required => 1);
has 'updated'  => (is => 'ro', isa => 'Maybe[Str]', required => 1);
has 'created'  => (is => 'ro', isa => 'Maybe[Str]', required => 1);
has 'status'   => (is => 'ro', isa => 'Maybe[Str]', required => 1);
has 'progress' => (is => 'ro', isa => 'Maybe[Int]', required => 1);

no Any::Moose;
__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 NAME

Net::RackSpace::CloudServers::Image - a RackSpace CloudServers Image

=head1 VERSION

version 0.15

=head1 SYNOPSIS

  use Net::RackSpace::CloudServers;
  use Net::RackSpace::CloudServers::Image;
  my $cs = Net::RackSpace::CloudServers->new( user => 'myusername', key => 'mysecretkey' );
  my $img = Net::RackSpace::CloudServers::Image->new(
    cloudservers => $cs,
    id => '1', name => 'test',
  );
  # get list:
  my @images = $cs->get_image();
  foreach my $image ( @images ) {
    print 'Have image ', $image->name, ' id ', $image->id, "\n";
  }
  # get detailed list
  my @images = $cs->get_image_detail();
  foreach my $image ( @images ) {
    print 'Have image ', $image->name, ' id ', $image->id,
      ' created ', $image->created, ' updated ', $image->updated,
      # ...
      "\n";
  }

=head1 METHODS

=head2 new / BUILD

The constructor creates an Image:

  my $image = Net::RackSpace::CloudServers::Image->new(
    cloudserver => $cs
    id => 'id', name => 'name',
  );

This normally gets created for you by L<Net::RackSpace::Cloudserver>'s L<get_image> or L<get_image_details> methods.
Needs a Net::RackSpace::CloudServers object.

=head2 id

The id is used for the creation of new images

=head2 name

The name which identifies the image

=head2 serverid

In case of a backup, which server ID does the backup image refer to

=head2 created

When was the image created, format: 2010-10-10T12:00:00Z

=head2 updated

When was the image last updated, format: 2010-10-10T12:00:00Z

=head2 status

In case of a backup, whether it's SAVING; for a standard image, whether it's ACTIVE.

=head2 progress

In case of a backup, the status progress

=head1 AUTHOR

Marco Fontani, C<< <mfontani at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-rackspace-cloudservers at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-RackSpace-CloudServers>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::RackSpace::CloudServers::Image

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-RackSpace-CloudServers>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-RackSpace-CloudServers>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-RackSpace-CloudServers>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-RackSpace-CloudServers/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Marco Fontani, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
