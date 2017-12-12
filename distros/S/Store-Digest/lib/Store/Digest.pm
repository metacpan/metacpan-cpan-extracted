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

Version 0.03

=cut

our $VERSION = '0.03';

has _driver => (
    is      => 'rw',
    does    => 'Store::Digest::Driver',
    handles => 'Store::Digest::Driver',
);

=head1 SYNOPSIS

    use Store::Digest;

    my $store = Store::Digest->new(
        driver  => 'FileSystem',
        # all other options pass through to the driver
        dir     => '/var/db/store-digest',
    );

    my $obj = $store->add(
        content  => $fh,
        language => 'en',
        mtime    => DateTime->now,
    );

=head1 METHODS

=head2 function1

=cut

sub BUILD {
    my ($self, $p) = @_;

    my $driver = delete $p->{driver} || 'FileSystem';
    ($driver) = String::RewritePrefix->rewrite(
        { '' => 'Store::Digest::Driver::', '+' => '' }, $driver);

    Class::Load::load_class($driver);
    $self->_driver($driver->new(%$p));
}

=head1 AUTHOR

Dorian Taylor, C<< <dorian at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-store-digest at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Store-Digest>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Store::Digest


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Store-Digest>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Store-Digest>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Store-Digest>

=item * Search CPAN

L<http://search.cpan.org/dist/Store-Digest/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Dorian Taylor.

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
