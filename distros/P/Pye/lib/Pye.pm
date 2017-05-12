package Pye;

# ABSTRACT: Session-based logging platform on top of SQL/NoSQL databases

use Carp;
use Role::Tiny;

our $VERSION = "2.001001";
$VERSION = eval $VERSION;

=head1 NAME

Pye - Session-based logging platform on top of SQL/NoSQL databases

=head1 SYNOPSIS

	use Pye;

	# start logging on top of a certain backend, say Pye::MongoDB
	# (you can also call new() directly on the backend class, check
	#  out the documentation of the specific backend)

	my $pye = Pye->new('MongoDB',
		host => 'mongodb://logserver:27017',
		database => 'log_db',
		collection => 'myapp_log'
	);

	# if you've created your own backend, prefix it with a plus sign
	my $pye = Pye->new('+My::Pye::Backend', \%options);

	# now start logging
	$pye->log($session_id, "Some log message", { data => 'example data' });

=head1 DESCRIPTION

C<Pye> is a dead-simple, session-based logging platform where all logs are stored
in a database. Log messages in C<Pye> include a date, a text message, and possibly
a data structure (hash/array-ref) that "illustrates" the text.

I built C<Pye> due to my frustration with file-based loggers that generate logs that
are extremely difficult to read, analyze and maintain.

C<Pye> is most useful for services (e.g. web apps) that handle requests,
or otherwise work in sessions, but can be useful in virtually any application,
including automatic (e.g. cron) scripts.

In order to use C<Pye>, your program must define an ID for every session. "Session"
can really mean anything here: a client session in a web service, a request to your
web service, an execution of a script, whatever. As long as a unique ID can be generated,
C<Pye> can handle logging for you.

Main features:

=over

=item * B<Supporting data>

With C<Pye>, any complex data structure (i.e. hash/array) can be attached to any log message,
enabling you to illustrate a situation, display complex data, etc.

=item * B<No log levels>

Yeah, I consider this a feature. Log levels are a bother, and I don't need them. All log
messages in C<Pye> are saved into the database, nothing gets lost.

=item * B<Easy inspection>

C<Pye> comes with a command line utility, L<pye>, that offers quick inspection of the log.
You can easily view a list of current/latest sessions and read the log of a specific session.
No more mucking about through endless log files, trying to understand which lines belong to which
session, or trying to find that area of the file with messages from that certain date your software
died on.

=item * B<Multiple backends>

C<Pye> supports several database backends. Currently, L<Pye::MongoDB> supports MongoDB, and
L<Pye::SQL> supports MySQL, PostgreSQL and SQLite.

=back

This package provides two purposes. It provides a constructor that dynamically loads the
requested backend class and creates an object of it. It is also a role (with L<Role::Tiny>)
detailing methods backend classes are required to implement.

=head2 UPGRADING TO v2.0.0 AND UP

Originally, C<Pye> was purely a MongoDB logging system, and this module provided the
MongoDB functionality. Since v2.0.0, C<Pye> became a system with pluggable backends, and
the MongoDB functionality was moved to L<Pye::MongoDB> (not provided by this distribution,
so you should install that too if you've been using Pye before v2.0.0).

An improvement over v1.*.* was also introduced: before, every application had two collections
in the database - a log collection and a session collection. The session collection is not
needed anymore. You can remove these session collections from your current database with no
repercussions.

Unfortunately, the API for v2.0.0 is not backwards compatible with previous versions (but
previous I<data> is). You will probably need to make two changes:

=over

=item *

In your applications, change the lines instantiating a C<Pye> object to include
the name of the backend:

	my $pye = Pye->new('MongoDB', %options);

Alternatively, replace C<use Pye> with C<use Pye::MongoDB> and call:

	my $pye = Pye::MongoDB->new(%options);

Also, in C<%options>, the C<log_db> option was renamed C<database>, and C<log_coll> was
renamed C<table> (or C<collection>, both are supported).

=item *

The options for the L<pye> command line utility have changed. You will now need to provide
a C<-b|--backend> option (with "MongoDB" as the value), and instead of C<-l|--log_coll>
you need to provide C<-c|--collection>. Since the session collection
has been deprecated, the C<-s|--session_coll> option has been removed, and now C<-s>
is an alias for C<-S|--session_id>.

=back

Also note the following dependency changes:

=over

=item * L<Getopt::Long> instead of L<Getopt::Compact>

=item * L<JSON::MaybeXS> instead of L<JSON>

=back

=cut

=head1 CONSTRUCTOR

=head2 new( $backend, [ %options ] )

This is a convenience constructor to easily load a C<Pye> backend and
create a new instance of it. C<Pye> will load the C<$backend> supplied,
and pass C<%options> (if any) to its own constructor.

If you're writing your own backend which is not under the C<Pye::> namespace,
prefix it with a plus sign, otherwise C<Pye> will not find it.

=cut


sub new {
	my ($self, $backend, %options) = @_;

	if ($backend =~ m/^\+/) {
		$backend = $';
	} elsif ($backend !~ m/^Pye::/) {
		$backend = 'Pye::'.$backend;
	}

	eval "require $backend";

	if ($@) {
		croak "Can't load Pye backend $backend: $@";
	}

	return $backend->new(%options);
}

=head1 REQUIRED METHODS

The following methods must be implemented by consuming classes:

=head2 log( $session_id, $text, [ \%data ] )

Log a new message, with text C<$text>, under session ID C<$session_id>.
An optional reference can also be supplied and stored with the message.

=head2 session_log( $session_id )

Returns a list of all messages stored under session ID C<$session_id>.
Every item in the array is a hash-ref with the following keys: C<session_id>,
C<date> in (YYYY-MM-DD format), C<time> (in HH:MM:SS.SSS format), C<text>
and possibly C<data>.

=head2 list_sessions( [ \%options ] )

Returns a list of sessions in the log, based on the provided options. If no
options are provided, the latest 10 sessions should be returned. The following options
are supported:

=over

=item * sort - how to sort sessions (every backend will accept a different value;
defaults to descending order by C<date>)

=item * skip - after sorting, skip a number of sessions (defaults to 0)

=item * limit - limit the number of sessions returned (defaults to 10)

=back

Every item (i.e. session) in the list should be a hash-ref with the keys C<id>,
C<date> (in YYYY-MM-DD format) and C<time> (in HH:MM:SS.SSS format).

=head2 _remove_session_logs( $session_id )

Removes all messages for a specific session.

=cut

requires qw/log session_log list_sessions _remove_session_logs/;

=head1 CONFIGURATION AND ENVIRONMENT
  
C<Pye> requires no configuration files or environment variables.

=head1 DEPENDENCIES

C<Pye> depends on the following CPAN modules:

=over

=item * L<Carp>

=item * L<Role::Tiny>

=back

The command line utility, L<pye>, depends on:

=over

=item *  L<Getopt::Long>

=item *  L<JSON::MaybeXS>

=item *  L<Term::ANSIColor>

=item *  L<Text::SpanningTable>

=back

It is recommended to install L<Cpanel::JSON::XS> is recommended
for fast JSON (de)serialization.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-Pye@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Pye>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Pye

You can also look for information at:

=over 4
 
=item * RT: CPAN's request tracker
 
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Pye>
 
=item * AnnoCPAN: Annotated CPAN documentation
 
L<http://annocpan.org/dist/Pye>
 
=item * CPAN Ratings
 
L<http://cpanratings.perl.org/d/Pye>
 
=item * Search CPAN
 
L<http://search.cpan.org/dist/Pye/>
 
=back
 
=head1 AUTHOR
 
Ido Perlmuter <ido@ido50.net>
 
=head1 LICENSE AND COPYRIGHT
 
Copyright (c) 2013-2015, Ido Perlmuter C<< ido@ido50.net >>.

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
