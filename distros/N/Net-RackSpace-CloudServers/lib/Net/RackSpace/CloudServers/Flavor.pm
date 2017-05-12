package Net::RackSpace::CloudServers::Flavor;
$Net::RackSpace::CloudServers::Flavor::VERSION = '0.15';
use warnings;
use strict;
use Any::Moose;
use Carp;

has 'cloudservers' =>
    (is => 'rw', isa => 'Net::RackSpace::CloudServers', required => 1);
has 'id'   => (is => 'ro', isa => 'Int',        required => 1);
has 'name' => (is => 'ro', isa => 'Str',        required => 1);
has 'ram'  => (is => 'ro', isa => 'Maybe[Int]', required => 1);
has 'disk' => (is => 'ro', isa => 'Maybe[Int]', required => 1);

no Any::Moose;
__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 NAME

Net::RackSpace::CloudServers::Flavor - a RackSpace CloudServers Flavor

=head1 VERSION

version 0.15

=head1 SYNOPSIS

  use Net::RackSpace::CloudServers;
  use Net::RackSpace::CloudServers::Flavor;
  my $cs = Net::RackSpace::CloudServers->new( user => 'myusername', key => 'mysecretkey' );
  my $flavor = Net::RackSpace::CloudServers::Flavor->new(
    cloudservers => $cs,
    id => '1', name => 'test', ram => 5, disk => 10,
  );
  # get list:
  my @flavors = $cs->flavors;
  foreach my $flavor ( @flavors ) {
    print 'Have flavor ', $flavor->name, ' id ', $flavor->id, "\n";
  }
  # get detailed list
  my @flavors = $cs->flavors(1);
  foreach my $flavor ( @flavors ) {
    print 'Have flavor ', $flavor->name, ' id ', $flavor->id,
      ' ram ', $flavor->ram, ' disk ', $flavor->disk,
      "\n";
  }

=head1 METHODS

=head2 new / BUILD

The constructor creates a Flavor:

  my $flavor = Net::RackSpace::CloudServers::Flavor->new(
    cloudserver => $cs
    id => 'id', name => 'name',
  );

This normally gets created for you by L<Net::RackSpace::Cloudserver>'s L<flavors> or L<flavorsdetails> methods.
Needs a Net::RackSpace::CloudServers::Flavor object.

=head2 id

The id is used for the creation of new cloudservers

=head2 name

The name which identifies the flavor

=head2 ram

How much RAM does this flavor have

=head2 disk

How much disk space does this flavor have

=head1 AUTHOR

Marco Fontani, C<< <mfontani at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-rackspace-cloudservers at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-RackSpace-CloudServers>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::RackSpace::CloudServers::Flavor

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
