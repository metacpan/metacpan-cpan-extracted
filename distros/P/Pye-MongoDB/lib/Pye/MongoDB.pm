package Pye::MongoDB;

# ABSTRACT: Log with Pye on top of MongoDB

use version;

use Carp;
use MongoDB;
use MongoDB::Code;
use Role::Tiny::With;
use Tie::IxHash;

our $VERSION = "1.000001";
$VERSION = eval $VERSION;

with 'Pye';

our $NOW = MongoDB::Code->new(code => 'function() { return new Date() }');

=head1 NAME

Pye::MongoDB - Log with Pye on top of MongoDB

=head1 SYNOPSIS

	use Pye::MongoDB;

	my $pye = Pye::MongoDB->new(
		host => 'mongodb://logserver1:27017,logserver2:27017',
		find_master => 1,
		database => 'log_db',
		collection => 'myapp_log'
	);

	# now start logging
	$pye->log($session_id, "Some log message", { data => 'example data' });

	# inspect the logs from the command line
	pye -b MongoDB -d log_db -c myapp_log

=head1 DESCRIPTION

This package provides a MongoDB backend for the L<Pye> logging system. This is
currently the easiest backend to use, since no setup is needed in order to start
logging with it.

Messages will be stored in a MongoDB database with the following keys:

=over

=item * C<session_id> - the session ID, a string, always exists

=item * C<date> - the date the messages was logged, in ISODate format, always exists

=item * C<text> - the text of the message, a string, always exists

=item * C<data> - supplemental JSON structure, optional

=back

An index on the C<session_id> field will automatically be created.

=head2 NOTES AND RECOMMENDATIONS

As of this writing (MongoDB v2.6), MongoDB is kind of a storage guzzler. You might
find it useful to create a TTL index on the log collection. For example, the following
line (entered into the C<mongo> shell) will create a time-to-live index of 2 days
on a log collection:

	db.log_collection.ensureIndex({ date: 1 }, { expireAfterSeconds: 172800 })

Alternatively, you could make the collection capped and limit it by size. Note, however,
that the _remove_session_logs() method will not work in that case.

Also, consider using TokuMX as a drop-in replacement for MongoDB. It it faster, uses
much less storage space and supports ACID transactions.

=head2 USING THE pye COMMAND LINE UTILITY

The L<pye> command line utility, used to inspect logs, provides all command line options
to the L<new( [ %options ] )> constructor, which in turn passes anything to L<MongoDB::MongoClient>.
This means that if your database has replication, or requires authentication, you can
provide these options from the command line.

For example:

	pye -b MongoDB
	    --host mongodb://server1:27017,server2:27017
	    --find_master=1
	    -d log_db
	    -c myapp_log
	    --username log_user
	    --password very_secret

C<host>, C<find_master>, C<username> and C<password> in this example will be passed to C<MongoDB::MongoClient>.

=head1 CONSTRUCTOR

=head2 new( [ %options ] )

Create a new instance of this class. All options are optional.

=over

=item * database - the name of the database, defaults to "logs"

=item * collection (or table) - the name of the collection, defaults to "logs"

=item * be_safe - whether to enable the C<safe> flag when inserting log messages,
defaults to a false value

=back

Any other option you provide will be passed to L<MongoDB::MongoClient>, so pass anything
needed in order to connect to the database server (such as C<host>, C<find_master>, etc.).

=cut

sub new {
	my ($class, %opts) = @_;

	my $db_name = delete($opts{database}) || 'logs';
	my $coll_name = delete($opts{collection}) || delete($opts{table}) || 'logs';
	my $safety = delete($opts{be_safe}) || 0;

	# use the appropriate mongodb connection class
	# depending on the version of the MongoDB driver
	# installed
	my $conn = version->parse($MongoDB::VERSION) >= v0.502.0 ?
		MongoDB::MongoClient->new(%opts) :
			MongoDB::Connection->new(%opts);

	my $db = $conn->get_database($db_name);
	my $coll = $db->get_collection($coll_name);

	$coll->ensure_index({ session_id => 1 });

	return bless {
		db => $db,
		coll => $coll,
		safety => $safety
	}, $class;
}

=head1 OBJECT METHODS

The following methods implement the L<Pye> role, so you should refer to C<Pye>
for their documentation. Some methods, however, have some MongoDB-specific notes,
so keep reading.

=head2 log( $session_id, $text, [ \%data ] )

If C<\%data> is provided, this module will traverse it recursively, replacing any
hash-key that contains dots with semicolons, as MongoDB does not support dots in
field names.

=cut

sub log {
	my ($self, $sid, $text, $data) = @_;

	my $date = $self->{db}->eval($NOW);

	my $doc = Tie::IxHash->new(
		session_id => "$sid",
		date => $date,
		text => $text,
	);

	if ($data) {
		# make sure there are no dots in any hash keys,
		# as mongodb cannot accept this
		$doc->Push(data => $self->_remove_dots($data));
	}

	$self->{coll}->insert($doc, { safe => $self->{safety} });
}

=head2 session_log( $session_id )

=cut

sub session_log {
	my ($self, $session_id) = @_;

	my $_map = sub {
		my $d = shift;

		my $doc = {
			session_id => $d->{session_id},
			date => $d->{date}->ymd,
			time => $d->{date}->hms.'.'.$d->{date}->millisecond,
			text => $d->{text}
		};
		$doc->{data} = $d->{data} if $d->{data};
		return $doc;
	};

	local $MongoDB::Cursor::slave_okay = 1;

	map($_map->($_), $self->{coll}->find({ session_id => "$session_id" })->sort({ date => 1 })->all);
}

=head2 list_sessions( [ \%opts ] )

Takes all options defined by L<Pye>. The C<sort> option, however, takes a MongoDB
sorting definition, that is a hash-ref, e.g. C<< { _id => 1 } >>. This will
default to C<< { date => -1 } >>.

=cut

sub list_sessions {
	my ($self, $opts) = @_;

	local $MongoDB::Cursor::slave_okay = 1;

	$opts			||= {};
	$opts->{skip}	||= 0;
	$opts->{limit}	||= 10;
	$opts->{sort}	||= { date => -1 };

	map +{
		id => $_->{_id},
		date => $_->{date}->ymd,
		time => $_->{date}->hms.'.'.$_->{date}->millisecond
	}, @{$self->{coll}->aggregate([
		{ '$group' => { _id => '$session_id', date => { '$min' => '$date' } } },
		{ '$sort' => $opts->{sort} },
		{ '$skip' => $opts->{skip} },
		{ '$limit' => $opts->{limit} }
	])};
}

###################################
# _remove_dots( \%data )          #
#=================================#
# replaces dots in the hash-ref's #
# keys with semicolons, so that   #
# mongodb won't complain about it #
###################################

sub _remove_dots {
	my ($self, $data) = @_;

	if (ref $data eq 'HASH') {
		my %data;
		foreach (keys %$data) {
			my $new = $_;
			$new =~ s/\./;/g;

			if (ref $data->{$_} && ref $data->{$_} eq 'HASH') {
				$data{$new} = $self->_remove_dots($data->{$_});
			} elsif (ref $data->{$_} && ref $data->{$_} eq 'ARRAY') {
				$data{$new} = [];
				foreach my $item (@{$data->{$_}}) {
					push(@{$data{$new}}, $self->_remove_dots($item));
				}
			} else {
				$data{$new} = $data->{$_};
			}
		}
		return \%data;
	} elsif (ref $data eq 'ARRAY') {
		my @data;
		foreach (@$data) {
			push(@data, $self->_remove_dots($_));
		}
		return \@data;
	} else {
		return $data;
	}
}

#####################################
# _remove_session_logs($session_id) #
#===================================#
# removes all log messages for the  #
# supplied session ID.              #
#####################################

sub _remove_session_logs {
	my ($self, $session_id) = @_;

	$self->{coll}->remove({ session_id => "$session_id" }, { safe => $self->{safety} });
}

=head1 CONFIGURATION AND ENVIRONMENT
  
C<Pye::MongoDB> requires no configuration files or environment variables.

=head1 DEPENDENCIES

C<Pye::MongoDB> depends on the following CPAN modules:

=over

=item * L<version>

=item * L<Carp>

=item * L<MongoDB>

=item * L<Pye>

=item * L<Role::Tiny>

=item * L<Tie::IxHash>

=back

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-Pye-MongoDB@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Pye-MongoDB>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Pye::MongoDB

You can also look for information at:

=over 4
 
=item * RT: CPAN's request tracker
 
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Pye-MongoDB>
 
=item * AnnoCPAN: Annotated CPAN documentation
 
L<http://annocpan.org/dist/Pye-MongoDB>
 
=item * CPAN Ratings
 
L<http://cpanratings.perl.org/d/Pye-MongoDB>
 
=item * Search CPAN
 
L<http://search.cpan.org/dist/Pye-MongoDB/>
 
=back
 
=head1 AUTHOR
 
Ido Perlmuter <ido@ido50.net>
 
=head1 LICENSE AND COPYRIGHT
 
Copyright (c) 2015, Ido Perlmuter C<< ido@ido50.net >>.

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
