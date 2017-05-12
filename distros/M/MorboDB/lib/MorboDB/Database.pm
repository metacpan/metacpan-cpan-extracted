package MorboDB::Database;

# ABSTRACT: A MorboDB database

use Moo;
use Carp;
use MorboDB::Collection;

our $VERSION = "1.000000";
$VERSION = eval $VERSION;

=head1 NAME

MorboDB::Database - A MorboDB database

=head1 VERSION

version 1.000000

=head1 SYNOPSIS

	use MorboDB;

	my $morbodb = MorboDB->new;

	my $db = $morbodb->get_database('my_database');
	my $coll = $db->get_collection('articles');
	# use $coll as described in MorboDB::Collection

=head1 DESCRIPTION

This module is the API for handling databases in a L<MorboDB> container.

=head1 ATTRIBUTES

=head2 name

The name of the database. String, required.

=cut

has 'name' => (is => 'ro', required => 1);

has '_top' => (is => 'ro', required => 1, weak_ref => 1);

has '_colls' => (is => 'ro', default => sub { {} });

=head1 OBJECT METHODS

=head2 collection_names()

Returns a list with the names of all collections in the database.

=cut

sub collection_names { sort keys %{$_[0]->_colls} }

=head2 get_collection( $name )

Returns a L<MorboDB::Collection> object with the given name:

	my $db = $morbodb->get_database('users');
	my $coll = $db->get_collection('users');

Like MongoDB, you can create a child-collection (purely semantics really)
by using dots, so 'users.admins' can be thought of as a child collection
of users:

	my $admins = $db->get_collection('users.admins');
	# or
	my $admins = $db->get_collection('users')->get_collection('admins');

=cut

sub get_collection {
	my ($self, $name) = @_;

	confess "You must provide the name of the collection to get."
		unless $name;

	return $self->_colls->{$name} ||= MorboDB::Collection->new(name => $name, _database => $self);
}

=head2 get_gridfs()

Not implemented. Doesn't do anything here except returning false.

=cut

sub get_gridfs { return } # not implemented

=head2 drop()

Drops the database, removes any collections it had and data they had.

=cut

sub drop {
	my $self = shift;

	foreach (keys %{$self->_colls}) {
		$_->drop;
	}

	delete $self->_top->_dbs->{$self->name};
	return;
}

=head2 last_error()

Not implemented. Doesn't do anything here except returning false.

=cut

sub last_error { return } # not implemented

=head2 run_command()

Not implemented. Doesn't do anything here except returning false.

=cut

sub run_command { return } # not implemented

=head2 eval()

Not implemented. Doesn't do anything here except returning false.

=cut

sub eval { return } # not implemented

=head1 DIAGNOSTICS

=over

=item C<< You must provide the name of the collection to get. >>

This error is returned by the C<get_collection()> method when you do not
provide it with the name of the database you want to get/create.

=back

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-MorboDB@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MorboDB>.

=head1 SEE ALSO

L<MongoDB::Database>.

=head1 AUTHOR

Ido Perlmuter <ido@ido50.net>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011-2013, Ido Perlmuter C<< ido@ido50.net >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, either version
5.8.1 or any later version. See L<perlartistic|perlartistic> 
and L<perlgpl|perlgpl>.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

__PACKAGE__->meta->make_immutable;
__END__
