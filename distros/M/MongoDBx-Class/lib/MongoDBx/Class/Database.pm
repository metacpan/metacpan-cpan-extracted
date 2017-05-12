package MongoDBx::Class::Database;

# ABSTRACT: A MongoDBx::Class database object

our $VERSION = "1.030002";
$VERSION = eval $VERSION;

use Moose;
use namespace::autoclean;
use version;

extends 'MongoDB::Database';

=head1 NAME

MongoDBx::Class::Database - A MongoDBx::Class database object

=head1 VERSION

version 1.030002

=head1 EXTENDS

L<MongoDB::Database>

=head1 SYNOPSIS

	# get a database object from your connection object
	my $db = $conn->get_database($db_name); # or simply $conn->$db_name

=head1 DESCRIPTION

MongoDBx::Class::Database extends L<MongoDB::Database>. All it actually
does is override the C<get_collection> method such that it returns a
L<MongoDBx::Class::Collection> object instead of a L<MongoDB::Collection>
object.

=head1 ATTRIBUTES

No special attributes are added.

=head1 OBJECT METHODS

Only the C<get_collection> method is modified as described above.

=cut

override 'get_collection' => sub {
	MongoDBx::Class::Collection->new(_database => shift, name => shift);
};

sub _connection {
	version->parse($MongoDB::VERSION) < v0.502.0 ? $_[0]->SUPER::_connection : $_[0]->_client;
}

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mongodbx-class at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MongoDBx-Class>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc MongoDBx::Class::Database

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MongoDBx::Class>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MongoDBx::Class>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MongoDBx::Class>

=item * Search CPAN

L<http://search.cpan.org/dist/MongoDBx::Class/>

=back

=head1 SEE ALSO

L<MongoDBx::Class::Connection>, L<MongoDB::Database>.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Ido Perlmuter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

__PACKAGE__->meta->make_immutable;
