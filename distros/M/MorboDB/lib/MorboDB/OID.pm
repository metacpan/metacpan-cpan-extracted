package MorboDB::OID;

# ABSTRACT: An object ID in MorboDB

use Moo;
use Carp;
use Data::UUID;

our $VERSION = "1.000000";
$VERSION = eval $VERSION;

=head1 NAME

MorboDB::OID - An object ID in MorboDB

=head1 VERSION

version 1.000000

=head1 SYNOPSIS

When inserting documents into a collection, if you don't provide an '_id'
attribute, this module will create one automatically.

	my $id = $collection->insert({ name => 'Alice', age => 20 });

C<$id> will be a C<MorboDB::OID> object that can be used to retreive or
update the saved document:

	$collection->update({ _id => $id }, { age => { '$inc' => 1 } });
	# now Alice is 21

To create a copy of an existing OID, you must set the value attribute in
the constructor. For example:

	my $id1 = MongoDB::OID->new;
	my $id2 = MongoDB::OID->new(value => $id1->value);

Now C<$id1> and C<$id2> will have the same value.

=head1 DESCRIPTION

A MorboDB::OID object uniquely represents a document in a L<MorboDB::Collection>.
When you don't provide a documents with the '_id' attribute during insertion,
this module will create an ID automatically.

OIDs in MorboDB are created using L<Data::UUID>, so they are 36-characters
long and do not resemble OIDs in MongoDB.

=head1 ATTRIBUTES

=head2 value

A 36-characters long string representation of the OID in conventional UUID format.
See L<UUID on Wikipedia|https://secure.wikimedia.org/wikipedia/en/w/index.php?title=Universally_unique_identifier&oldid=443132869>
for more information on UUID format.

=cut

has 'value' => (is => 'ro', builder => '_build_value');

=head1 OBJECT METHODS

=head2 to_string()

This really just returns the 'value' attribute.

=cut

sub to_string { shift->value }

=head2 get_time()

Not implemented. Only returns C<undef> here.

=cut

sub get_time { undef }

=head2 TO_JSON()

Meant to be called by the L<JSON> family of modules to create a JSON
representation of the OID. So, for example, "4162F712-1DD2-11B2-B17E-C09EFE1DC403"
will be represented as C<{ "$oid" : "4162F712-1DD2-11B2-B17E-C09EFE1DC403" }>.

	my $json = JSON->new->allow_blessed->convert_blessed;
	$json->encode(MorboDB::OID->new);

=cut

sub TO_JSON { { '$oid' => shift->value } }

sub _build_value { Data::UUID->new->create_str }

=head1 DIAGNOSTICS

This module does not throw any errors of its own.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-MorboDB@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MorboDB>.

=head1 SEE ALSO

L<Data::UUID>, L<MongoDB::OID>.

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
