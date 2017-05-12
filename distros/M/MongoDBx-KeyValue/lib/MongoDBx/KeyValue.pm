package MongoDBx::KeyValue;

# ABSTRACT: Use MongoDB as if it were a key-value store.

use strict;
use warnings;
use MongoDB;
use Carp;

our $VERSION = "0.001001";
$VERSION = eval $VERSION;

=head1 NAME

MongoDBx::KeyValue - Use MongoDB as if it were a key-value store.

=head1 VERSION

version 0.001001

=head1 SYNOPSIS

	use MongoDBx::KeyValue;

	my $mkv = MongoDBx::KeyValue->new(kvdb => 'my_key_value_database', %opts);
		# 'kvdb' is required, other options are passed to MongoDB::Connection->new()

	$mkv->set('cache', 'index.html', '<html><head><title>Index</title></head><body>Index</body></html>');

	my $index = $mkv->get('cache', 'index.html');
	print $index; # prints '<html><head><title>Index</title></head><body>Index</body></html>'

=head1 DESCRIPTION

MongoDBx::KeyValue is a very simple module for easy usage of L<MongoDB> as
a key-value store (similar to Redis, Riak or Memcached).

The interface is very simple: you I<set> the values of keys and I<get> the
values of keys. Every key-value pair is stored in a bucket, which is really
just a MongoDB collection (the "bucket" terminology is used merely for
resemblance with other key-value stores), so the same key can exist, with
possibly different values, in multiple buckets.

To get the value of a key, just pass the C<get()> method the name of the
bucket and the key. If it is not found, C<undef> is returned. To set the
value for a key, just provide the C<set()> method with the name of the
bucket, the key and the value. If the key already exists in the bucket,
its value will be replaced.

The value for a key can be anything that MongoDB supports, including simple
scalars (strings, numbers, etc.), hash or array references, and whatever
else MongoDB natively supports such as L<DateTime> objects. While no checking is
made for keys, you probably should only use scalars for them.

Every key-value pair is stored in the database as a document with two
attributes: "_id", which holds the key; and "value", which holds the value.

=head1 CLASS METHODS

=head2 new( %opts )

Creates a new instance of this module and connects to the MongoDB server.
The only required option is 'kvdb', which should hold the name of the
database to use for the key-value store. All other options will be passed
to C<< MongoDB::Connection->new() >>, so take a look at L<MongoDB::Connection/"ATTRIBUTES">
for a list of all supported options.

=cut

sub new {
	my ($class, %opts) = @_;

	my $kvdb = delete $opts{kvdb}
		|| croak "You must provide the name of the key-value database to use (as parameter 'kvdb').";

	bless { db => MongoDB::Connection->new(%opts)->get_database($kvdb) }, $class;
}

=head1 OBJECT METHODS

=head2 get( $bucket, $key )

Attempts to find the value for the key C<$key> in the bucket named
C<$bucket>. Returns C<undef> if not found.

=cut

sub get {
	my ($self, $bucket, $key) = @_;

	my $entry = $self->bucket($bucket)->find_one({ _id => $key });
	return $entry ? $entry->{value} : undef;
}

=head2 set( $bucket, $key, $value )

Sets the value for the key named C<$key> inside the bucket named C<$bucket>.
If the key already exists, its value will be replaced with the new one.

It's probably better for keys to be scalars, but values can be anything,
including hash-refs, array-refs and whatever L<MongoDB> can store natively
(take a look at L<MongoDB::DataTypes> for more info).

=cut

sub set {
	my ($self, $bucket, $key, $value) = @_;

	$self->bucket($bucket)->update({ _id => $key }, { '$set' => { value => $value } }, { upsert => 1 });
}

=head2 db()

Returns the L<MongoDB::Database> object of the key-value store.

=cut

sub db { shift->{db} }

=head2 bucket( $bucket_name )

All this really does is return a L<MongoDB::Collection> object for the
collection named C<$bucket_name>. Use it if you need MongoDB collection
objects for some reason.

=cut

sub bucket {
	my ($self, $bucket) = @_;

	return unless $bucket;

	return $self->db->get_collection($bucket);
}

=head1 DIAGNOSTICS

This module generates the following errors:

=over

=item * "You must provide the name of the key-value database to use (as parameter 'kvdb')."

This error will be issued by the C<new()> method if you don't provide it with
the 'kvdb' parameter, which should hold the name of the database to use
as the key-value store.

=back

=head1 DEPENDENCIES

This module only depends on L<MongoDB>.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-MongoDBx-KeyValue@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MongoDBx-KeyValue>.

=head1 AUTHOR

Ido Perlmuter <ido at ido50 dot net>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011, Ido Perlmuter C<< ido at ido50 dot net >>.

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

1;
__END__