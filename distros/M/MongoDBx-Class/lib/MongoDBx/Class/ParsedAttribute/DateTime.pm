package MongoDBx::Class::ParsedAttribute::DateTime;

# ABSTRACT: An automatic DateTime parser for MongoDBx::Class document classes

our $VERSION = "1.030002";
$VERSION = eval $VERSION;

use Moose;
use namespace::autoclean;
use DateTime::Format::W3CDTF;

with 'MongoDBx::Class::ParsedAttribute';

=head1 NAME

MongoDBx::Class::ParsedAttribute::DateTime - An automatic DateTime parser for MongoDBx::Class document classes

=head1 VERSION

version 1.030002

=head1 SYNOPSIS

	# in one of your document classes
	has 'datetime' => (is => 'ro', isa => 'DateTime', traits => ['Parsed'], required => 1);

=head1 DESCRIPTION

This class implements the L<MongoDBx::Class::ParsedAttribute> role. It
provides document classes with the ability to automatically expand and
collapse L<DateTime> values.

While the Perl L<MongoDB> driver already supports L<DateTime> objects
natively, due to a bug with MongoDB, you can't save dates earlier than
the UNIX epoch. This module overcomes this limitation by simply saving
dates as strings and automatically turning them into DateTime objects
(and vica-versa). The DateTime strings are formatted by the L<DateTime::Format::W3CDTF>
module, which parses dates in the format recommended by the W3C. This is
good for web apps, and also makes it easier to edit dates from the
MongoDB shell. But most importantly, it also allows sorting by date.

Note that if you already have date attributes in your database, you can't
just start using this parser, you will first have to convert them to the
W3C format.

=head1 ATTRIBUTES

=head2 f

A L<DateTime::Format::W3CDTF> object used for expanding/collapsing. Automatically
created.

=cut

has 'f' => (is => 'ro', isa => 'DateTime::Format::W3CDTF', default => sub { DateTime::Format::W3CDTF->new });

=head1 CLASS METHODS

=head2 new()

Creates a new instance of this module.

=head1 OBJECT METHODS

=head2 expand( $str )

Converts a W3C datetime string to DateTime object.

=cut

sub expand {
	return eval { $_[0]->f->parse_datetime($_[1]) } || undef;
}

=head2 collapse( $dt )

Converts a DateTime object to a W3C datetime string.

=cut

sub collapse {
	return eval { $_[0]->f->format_datetime($_[1]) } || undef;
}

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mongodbx-class at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MongoDBx-Class>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc MongoDBx::Class::ParsedAttribute::DateTime

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

L<MongoDBx::Class::EmbeddedDocument>.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Ido Perlmuter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

__PACKAGE__->meta->make_immutable;
