package Store::Digest;

use 5.010;
use strict;
use warnings FATAL => 'all';

use Moose;
use namespace::autoclean;

# actually this doesn't do what i wanted
#use Module::Pluggable search_path => __PACKAGE__ . '::Driver';

# MooseX::Object::Pluggable maybe?

# nope, this!
use String::RewritePrefix ();
use Class::Load           ();

=head1 NAME

Store::Digest - Store opaque data objects keyed on their cryptographic digests

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

has _driver => (
    is      => 'rw',
    does    => 'Store::Digest::Driver',
    handles => 'Store::Digest::Driver',
);

=head1 SYNOPSIS

    use Store::Digest;

    # initialize the store

    my $store = Store::Digest->new(
        driver  => 'FileSystem',
        # all other options pass through to the driver
        dir     => '/var/db/store-digest',
    );

    # add an object

    my $obj = $store->add(
        content  => $fh,
        language => 'en',
        mtime    => DateTime->now,
    );

    # if you want to get the object back

    my $str = 'ni:///sha-256;IcnxQtEMlihv1wFHTMjkMprLO-9-ZXZD2lcsQLmQ1xA';
    my $uri = URI->new($str);
    my $obj = $store->get($uri);

=head1 METHODS

This module will eventually act as a unifying interface for multiple
storage drivers, but there is currently only one implemented:
L<Store::Digest::Driver::FileSystem>. Go see that.

=over 4

B<Note to users prior to this version> (all two of you): The
C<control> database that contains the store-wide metadata was for some
stupid reason a L<BerkeleyDB::Hash>, and I have changed it to be a
L<BerkeleyDB::Btree>. I have included a conversion routine in the
driver which I<should> do the job transparently, but since it deletes
the old control database, you may run into trouble if you don't shut
down all processes attached to this database before upgrading.

=back

=cut

sub BUILD {
    my ($self, $p) = @_;

    my $driver = delete $p->{driver} || 'FileSystem';
    ($driver) = String::RewritePrefix->rewrite(
        { '' => 'Store::Digest::Driver::', '+' => '' }, $driver);

    Class::Load::load_class($driver);
    $self->_driver($driver->new(%$p));
}

=head1 SEE ALSO

=over 4

=item

L<Store::Digest::Driver::FileSystem>

=item

L<Store::Digest::Object>

=item

L<URI::ni>

=item

L<https://tools.ietf.org/html/rfc6920>

=back

=cut

=head1 AUTHOR

Dorian Taylor, C<E<lt>dorian at cpan.orgE<gt>>

=head1 BUGS

Please report any issues to
L<https://github.com/doriantaylor/p5-store-digest/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Store::Digest

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Store-Digest>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Store-Digest>

=item * Search CPAN

L<http://search.cpan.org/dist/Store-Digest/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2018 Dorian Taylor.

Licensed under the Apache License, Version 2.0 (the "License"); you
may not use this file except in compliance with the License. You may
obtain a copy of the License at
L<http://www.apache.org/licenses/LICENSE-2.0>.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied.  See the License for the specific language governing
permissions and limitations under the License.

=cut

__PACKAGE__->meta->make_immutable;

1; # End of Store::Digest
