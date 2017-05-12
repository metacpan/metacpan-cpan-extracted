package MongoDBx::Class::Cursor;

# ABSTRACT: A MongoDBx::Class cursor/iterator object for query results

our $VERSION = "1.030002";
$VERSION = eval $VERSION;

use Moose;
use namespace::autoclean;
use version;

extends 'MongoDB::Cursor';

=head1 NAME

MongoDBx::Class::Cursor - A MongoDBx::Class cursor/iterator object for query results

=head1 VERSION

version 1.030002

=head1 EXTENDS

L<MongoDB::Cursor>

=head1 SYNOPSIS

	my $cursor = $coll->find({ author => 'Conan Doyle' });

	print "Novels by Arthur Conan Doyle:\n";

	foreach ($cursor->sort({ year => 1 })->all) {
		print $_->title, '( ', $_->year, ")\n";
	}

=head1 DESCRIPTION

MongoDBx::Class::Cursor extends L<MongoDB::Cursor>. At its basis, it
adds automatic document expansion when traversing cursor results.

=head1 ATTRIBUTES

No special attributes are added.

=head1 OBJECT METHODS

Aside from methods provided by L<MonogDB::Cursor>, the following method
modifications are performed:

=head2 next( [ $do_not_expand ] )

Returns the next document in the cursor, if any. Automatically expands that
document to the appropriate class (if '_class' attribute exists, otherwise
document is returned as is). If C<$do_not_expand> is true, the document
will not be expanded and simply returned as is (i.e. as a hash-ref).

=cut

around 'next' => sub {
	my ($orig, $self, $do_not_expand) = (shift, shift);

	my $doc = $self->$orig || return;

	return $do_not_expand ? $doc : $self->_connection->expand($self->_ns, $doc);
};

=head2 sort( $rules )

Adds a sort to the cursor and returns the cursor itself for chaining.
C<$rules> can either be an unordered hash-ref, an ordered L<Tie::IxHash>
object, or an ordered array reference such as this:

	$cursor->sort([ date => -1, time => -1, subject => 1 ])

=cut

around 'sort' => sub {
	my ($orig, $self, $rules) = @_;

	if (ref $rules eq 'ARRAY') {
		return $self->$orig(Tie::IxHash->new(@$rules));
	} else {
		return $self->$orig($rules);
	}
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

	perldoc MongoDBx::Class::Cursor

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

L<MongoDBx::Class::Collection>, L<MongoDB::Cursor>.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Ido Perlmuter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

__PACKAGE__->meta->make_immutable;
