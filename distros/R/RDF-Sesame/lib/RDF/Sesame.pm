package RDF::Sesame;

use strict;
use warnings;

use RDF::Sesame::Connection;
use RDF::Sesame::Response;
use RDF::Sesame::TableResult;

our $VERSION = "0.17";
our $errstr;  # holds the error string from a failed connect

=head1 NAME

RDF::Sesame - Interact with Sesame RDF servers

=head1 SYNOPSIS

 use RDF::Sesame;
 
 # Connect anonymously to Sesame on localhost port 80
 my $sesame = RDF::Sesame->connect;
 
 # or anonymously on a remote Sesame server
 $sesame = RDF::Sesame->connect('openrdf.org');
 
 # or explicitly specify the options
 $sesame = RDF::Sesame->connect(
    host      => "openrdf.org",
    port      => 80
    directory => "sesame",
    username  => "testuser",
    password  => "opensesame"
 ) or die "Couldn't connect to Sesame : $RDF::Sesame::errstr\n";
 
 # or explicitly specify using a single URI
 $sesame = RDF::Sesame->connect(
    uri => 'http://testuser:opensesame@openrdf.org:80/sesame'
 );
 
 my @repos = $sesame->repositories;
 
 # open a repository the easy way
 my $vcard  = $sesame->open("vcard");
 
 # or the more flexible way (allowing other named options)
 my $museum = $sesame->open(id => "museum");
 
 my $serql = <<END;
    select x, given, family
    from
     {x} vCard:N {n},
     {n} vCard:Given  {given};
         vCard:Family {family}
    using namespace
      vCard = <http://www.w3.org/2001/vcard-rdf/3.0#>
 END
 
 my $results = $vcard->select(
     query    => $serql,
     language => "SeRQL"
 );
 
 $vcard->query_language("SeRQL");
 $results = $vcard->select($serql);
 
 # $results is a Data::Table object (via RDF::Sesame::TableResults)

=head1 DESCRIPTION

The RDF::Sesame module implements a wrapper around the RESTful API
(HTTP protocol) provided by Sesame L<http://openrdf.org>.  It facilitates
connecting, adding data and querying a Sesame server from Perl.

RDF::Sesame itself only provides a method for creating a Connection
object.  See the documentation for L<RDF::Sesame::Connection>,
L<RDF::Sesame::Repository>, and L<RDF::Sesame::TableResults>.

=head1 STATUS

This module is in beta testing.  The algorithms have been tested
thoroughly and are stable.  The API might change in a few particulars,
hopefully in a backwards-compatible manner.

=head1 METHODS

=head2 connect ( %opts )

Connects to a Sesame server and creates an instance of an
RDF::Sesame::Connection object.  This object can be used to create
an RDF::Sesame::Repository object or (less likely) to execute commands
against a Sesame server.  Creating an RDF::Sesame::Repository object is
the preferred way, so do that.

The HTTP connection to the server is created with Keep-Alive enabled in
an attempt to make consecutive requests speedier.

The C<%opts> parameter is a hash of options to use when creating the
connection.  Below is a list of the currently understood options.  If a single
scalar is provided to connect(), it will be treated as the host and
all other options will use the default values.

=head3 host

The host name or address of the sesame server. For example 'openrdf.org'
or 'openrdf.org:8080'.  It's B<not> a URI.

Default: localhost

=head3 port

The port number on which the Sesame server is listening.

Default: 80

=head3 directory 

The sesame directory on the host.  The directory should be specified without
leading or trailing '/' characters.  However, if those characters are provided,
they will be stripped before further processing.

Default: sesame

=head3 username

The username to use for logging in to the server.  If this option is not
specified (or C<undef>), no login will be attempted and only publicly available
repositories will be visible.

=head3 password

The password to use for logging in to the server.  If this option is not
supplied but the 'username' option is specified, a password consisting of
the empty string will be used to log in.

=head3 uri

A URI specifying how to connect to the Sesame server.  All of the above
options may be specified at once by providing them in the URI in standard
format.  Here is an example URI

 http://username:password@host:port/directory

If any of the parts are not specified, the defaults explained above will be
used instead.

=head3 timeout

When communicating with the Sesame server, RDF::Sesame usually waits 10
seconds for the server to respond.  If there is no response within that
time, the server is considered unreachable.  This option allows you
to change this behavior.

=cut

sub connect {
    shift @_;  # remove the class name
    RDF::Sesame::Connection->new(@_);
}

=head1 CONFIGURATION AND ENVIRONMENT
 
RDF::Sesame can generate very limited debugging/profiling output.  By setting
the environment variable C<RDFSESAME_DEBUG> to a true value, each request to
the Sesame server will generate a message on STDERR.  Here is a short sample:

   Command 0 : Ran login in 30 ms
   Command 1 : Ran evaluateTableQuery in 45 ms
   Command 2 : Ran evaluateTableQuery in 120 ms

The time value generated with each message is the number of milliseconds it
took to process the command including network time, database processing time
and response processing time.

=head1 COMPATIBILITY

The following table indicates RDF::Sesame's compatibility with different
versions of Sesame and different sail implementations.

  Sesame 1.2.6 : native - OK
                 memory - OK
  Sesame 1.2.4 : native - OK
                 memory - OK
  Sesame 1.2.3 : native - OK
                 memory - OK
  Sesame 1.2.2 : native - OK
                 memory - OK
  Sesame 1.2.1 : native - OK
                 memory - OK
  Sesame 1.2   : native - FAIL (known bug)
                 memory - OK
  Sesame 1.1.3 : native - OK
                 memory - OK

I've not personally tested Sesame versions earlier than 1.1.3 but they may work.

=head1 COVERAGE

Test coverage results provided by L<Devel::Cover>

 ----------------------------------- ------ ------ ------ ------ ------ ------
 File                                  stmt   bran   cond    sub   time  total
 ----------------------------------- ------ ------ ------ ------ ------ ------
 lib/RDF/Sesame.pm                    100.0    n/a    n/a  100.0    1.1  100.0
 lib/RDF/Sesame/Connection.pm         100.0  100.0  100.0  100.0   20.5  100.0
 lib/RDF/Sesame/Repository.pm          96.7   95.9    n/a  100.0    9.0   96.7
 lib/RDF/Sesame/Response.pm           100.0  100.0    n/a  100.0   46.4  100.0
 lib/RDF/Sesame/TableResult.pm         91.2   82.4    n/a  100.0   23.0   88.7
 Total                                 96.2   92.2  100.0  100.0  100.0   95.4
 ----------------------------------- ------ ------ ------ ------ ------ ------

=head1 HELPING OUT

The latest source code for RDF-Sesame is available with git from
L<git://ndrix.com/RDF-Sesame>.  You may also browse the repository
at L<http://git.ndrix.com/?p=RDF-Sesame;a=summary>.

Please email patches to the author.

=head1 SEE ALSO

=over 4

=item L<RDF::Sesame::Connection>

=item L<RDF::Sesame::Repository>

=item L<RDF::Sesame::TableResult>

=back

=head1 ACKNOWLEDGEMENTS

Southwest Counseling Service for sponsoring the initial development
L<http://swcounseling.org>.

=head1 AUTHOR

Michael Hendricks <michael@ndrix.com>

=head1 LICENSE AND COPYRIGHT
 
Copyright (c) 2005-2006 Michael Hendricks (<michael@ndrix.com>). All rights
reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
