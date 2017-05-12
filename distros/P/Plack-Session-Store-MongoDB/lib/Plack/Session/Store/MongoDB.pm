package Plack::Session::Store::MongoDB;

# ABSTRACT: MongoDB based session store for Plack apps.

our $VERSION = "1.000000";
$VERSION = eval $VERSION;

use warnings;
use strict;
use parent 'Plack::Session::Store';
use version;

use Carp;
use MongoDB;
use Plack::Util::Accessor qw/coll_name db/;

=head1 NAME

Plack::Session::Store::MongoDB - MongoDB based session store for Plack apps.

=head1 SYNOPSIS

	use Plack::Builder;
	use Plack::Middleware::Session;
	use Plack::Session::Store::MongoDB;

	my $app = sub {
		return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello Foo' ] ];
	};

	builder {
		enable 'Session',
			store => Plack::Session::Store::MongoDB->new(
				session_db_name => 'myapp',
				coll_name => 'myapp_sessions',	# defaults to 'session'
				host => 'mongodb.myhost.com',	# defaults to 'localhost'
				port => 27017			# this is the default
			);
		$app;
	};

	# alternatively, you can just pass a MongoDB::Connection object:
	builder {
		enable 'Session',
			store => Plack::Session::Store::MongoDB->new(
				session_db_name => 'myapp',
				conn => MongoDB::Connection->new
			);
		$app;
	};

=head1 DESCRIPTION

This module implements a L<MongoDB> storage for session data. This has the
advantage of being a simple (no need to generate a database scheme or even
create the necessary database/collections), yet powerful backend.

It requires, of course, a running MongoDB daemon to work with.

=head1 METHODS

=head2 new( %params )

Creates a new instance of this module. Requires a hash of parameters
containing 'session_db_name' with the name of the MongoDB database to use
and any options available by L<MongoDB::Connection>, most probably
'host' (the hostname of the server where the MongoDB daemon is running,
defaults to 'localhost') and 'port' (the port where the MongoDB daemon is
listening, defaults to 27017, the default MongoDB port). You can also
optionally pass the 'coll_name' parameter, denoting the name of the collection
in which sessions will be stored (will default to 'sessions').

Alternatively, you can pass a 'conn' parameter and give it an already
created L<MongoDB::Connection> object. You will still need to pass
'session_db_name' when doing this.

NOTE: in versions before C<0.3>, the 'session_db_name' option was called 'db_name'.
This has been changed since 'db_name' is a MongoDB::Connection option
that might differ from you session database, and you should be able to
pass both if you need to.

=cut

sub new {
	my ($class, %params) = @_;

	croak "You must provide the name of the database to use (parameter 'session_db_name')."
		unless $params{session_db_name};

	my $db_name = delete $params{session_db_name};

	my $self = {};
	$self->{coll_name} = delete $params{coll_name} || 'sessions';

	my $isa = version->parse($MongoDB::VERSION) < v0.502.0 ?
		'MongoDB::Connection' :
			'MongoDB::MongoClient';

	# initiate connection to the MongoDB backend
	if ($params{conn} && $params{conn}->isa($isa)) {
		$self->{db} = $params{conn}->get_database($db_name);
	} else {
		$self->{db} = $isa->new(%params)->get_database($db_name);
	}

	return bless $self, $class;
}

=head2 fetch( $session_id )

Fetches a session object from the database.

=cut

sub fetch {
	my ($self, $session_id) = @_;

	my $session_obj = $self->db->get_collection($self->coll_name)->find_one({ _id => $session_id });

	if ($session_obj) {
		delete $session_obj->{_id};
		return $session_obj;
	}
	
	return; 
}

=head2 store( $session_id, \%session_obj )

Stores a session object in the database. If a database error occurs when
attempting to store the session, this method will die.

=cut

sub store {
	my ($self, $session_id, $session_obj) = @_;

	$session_obj->{_id} = $session_id;

	$self->db->get_collection($self->coll_name)->update({ _id => $session_id }, $session_obj, { upsert => 1, safe => 1 })
		|| croak "Failed inserting session object to MongoDB database: ".$self->db->last_error;
}

=head2 remove( $session_id )

Removes the session object from the database. If a database error occurs
when attempting to remove the session, this method will generate a warning.

=cut

sub remove {
	my ($self, $session_id) = @_;

	$self->db->get_collection($self->coll_name)->remove({ _id => $session_id }, { just_one => 1, safe => 1 })
		|| carp "Failed removing session object from MongoDB database: ".$self->db->last_error;
}

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50 dot net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-plack-session-store-mongodb at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Plack-Session-Store-MongoDB>. I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Plack::Session::Store::MongoDB

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Plack-Session-Store-MongoDB>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Plack-Session-Store-MongoDB>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Plack-Session-Store-MongoDB>

=item * Search CPAN

L<http://search.cpan.org/dist/Plack-Session-Store-MongoDB/>

=back

=head1 ACKNOWLEDGEMENTS

Daisuke Maki, author of L<Plack::Session::Store::DBI>, on which this
module is based.

Tests adapted from the L<Plack::Middleware::Session> distribution.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Ido Perlmuter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
