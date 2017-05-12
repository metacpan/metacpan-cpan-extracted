# vim modeline vim600: set foldmethod=marker :
package RDF::Sesame::Connection;

use strict;
use warnings;

use Carp;
use LWP::UserAgent;
use Time::HiRes qw( gettimeofday tv_interval );

use RDF::Sesame;
use RDF::Sesame::Repository;

our $VERSION = '0.17';

=head1 NAME

RDF::Sesame::Connection - A connection to a Sesame server

=head1 DESCRIPTION

This class represents a connection to a specific Sesame server and provides
methods which are generally useful for interacting with a Sesame server.
This class is predominantly used to create an RDF::Sesame::Repository object
which is in turn used to execute queries, remove triples, upload triples, etc.

=head1 METHODS

=head2 open ( %opts )

Creates an RDF::Sesame::Repository object.  There is no communication with
the Sesame server during this call, so it should be very fast.  The C<%opts>
parameter provides a series of named options to use when creating the Repository
object.  A list of options which are currently understood is provided below.
If a single scalar is given instead of C<%opts>, the scalar will be treated
as the value of the 'id' option.

=head3 id

The ID of the repository that you want to open.  The method will return
successfully even if there is no repository on the server with the
repository ID provided.  However, subsequent attempts to do anything
useful with the Repository object will fail.

If you're not sure what the valid repository IDs are, use the
C<repositories> method documented below.  If no repository ID is given,
the method returns the empty string.

=head3 query_language

This is equivalent to calling query_language() on the newly created Repository
object.  See that documentation for further information.

=head3 strip

This option serves as a default for the strip option to
RDF::Sesame::Repository::select  Typically, that method defaults to 'none'
however specifying this option when opening the repository changes the default.

=cut

sub open {
    RDF::Sesame::Repository->new(@_);
}

=head2 repositories ( [ $refresh ] )

When called in list context, returns a list of the IDs of the repositories
which are available through this connection.  The response in scalar context
is reserved for future use.  So don't call repositories() in scalar
context yet (currently, it returns C<undef>).

Only the first call to repositories() communicates with the server.
Subsequent calls return a cached copy of the results from the first
communication.  If you want to get new results directly from the server, 
pass a true value for the $refresh parameter.  These new results will replace
the previously cached results.

=cut

sub repositories {
    my $self = shift;

    return undef unless wantarray;

    # check the repositories cache
    if( $self->{repos} && !$_[0] ) {
        return @{ $self->{repos} };
    }

    # call listRepositories on the server
    my $r = $self->command(undef, 'listRepositories');
    my @repos;
    if( $r->success ) {
        foreach ( @{ $r->parsed_xml->{repository} } ) {
            push(@repos, $_->{id});
        }

        $self->{repos} = \@repos;
    } else {
        # there was an error, so no repositories are available
        return ();
    }

    return @repos;
}

=head2 disconnect

Logs out of the Sesame server and closes any connections to the server.
Attempts to use this object or any of the RDF::Sesame::Repository objects
created by this object after it has been disconnected will result in ugly
problems.

This method is B<not> called when an RDF::Sesame::Connection object is
destroyed.  If you want to explicitly logout of the server, you must
call this method.

Returns true upon success, false otherwise.

=cut

sub disconnect {
    my $self = shift;

    my $resp = 0;
    if( $self->{authed} ) {
        $resp = $self->command(undef, 'logout')->success;
    } else {
        $resp = 1; # we can't fail if we're already logged out
    }

    if( $resp ) {
        $self->{authed} = 0;
        delete $self->{ua};
    }

    return $resp;
}

=head1 INTERNAL METHODS

These methods might be useful to some users, so they're documented, but
most will never need them.

=head2 command ( $repository_id, $name [, $parameters ] )

This method executes a command against a repository
using the parameters provided in the hashref.  The intended way to execute
commands against the server is to use an RDF::Sesame::Repository object.

The C<$repository_id> parameter is just a shortcut for adding a I<repository>
parameter in the call to the server.  If you pass C<undef> as the repository
ID, the method should still work fine and no I<repository> parameter will
be passed to the server.

The result of this method is an RDF::Sesame::Response object.  That object
can be used to determine whether the command succeeded or failed.

 Parameters :
    $repository_id  The ID of the repository you want to execute
        the query against.

    $name  The name of the command to execute.

    $parameters  An optional hashref containing the parameter
        names and values to pass to the server when executing
        the command.
 
 Return : 
    RDF::Sesame::Response

=cut

# TODO use XML::SAX instead of XML::Simple (details follow)
# The basic implementation might be something like this
#
#   my ($self, $cmd) = @_;
#   my $handler_class = $handlers{$cmd};
#   my $handler = $handler_class->new();
#   $parser = XML::SAX::ParserFactory( Handler => $handler );
#   $self->{ua}->post(
#       ...,
#       ':content_cb' => sub { $parser->parse_string(...) }
#   );
#   return $handler->response();
#
# I should be able to implement the above if I make the new response
# objects implement the current Response interface.  Once that works,
# I can change the way the old code uses the response objects
# (if that's still necessary).

{ my $count = 0;
sub command {
    my $self = shift;

    # make sure we have a hash
    my $params;
    if( ref($_[2]) eq 'HASH' ) {
        $params = $_[2];
    } else {
        $params = {};
    }

    # add the repository name to the hash
    $params->{repository} = $_[0] if defined $_[0];

    my $cmd = $_[1];

    # make the request. Either GET or POST depending on the command
    my $cmd_uri = $self->{server} . $cmd;
    my $r;  # the server's HTTP::Response
    my $content_cb = delete $params->{':content_cb'};
    my $start = [ gettimeofday() ];
    if( $cmd eq 'listRepositories' or $cmd eq 'logout' ) {
        # send a request using HTTP-GET
        $r = $self->{ua}->get( $cmd_uri, %$params );
    } else {
        # send a request using HTTP-POST ('multipart/form-data' encoded)
        $r = $self->{ua}->post(
            $cmd_uri,
            {},  # empty form since the real stuff is in 'Content'
            Content_Type => 'form-data',
            Content      => $params,
            ( $content_cb ? (':content_cb' => $content_cb) : () )
        );
    }

    # make an RDF::Sesame::Response object for return
    my $response = RDF::Sesame::Response->new($r);

    if ( $ENV{RDFSESAME_DEBUG} ) {
        my $elapsed = int( 1000 * tv_interval($start) );  # in milliseconds
        printf STDERR "Command %d : Ran $cmd in $elapsed ms\n", $count++;
    }

    return $response;
}
}

# This method should really only be called by
# RDF::Sesame::connect and it's documented there, so
# there's no need to document it here also.

sub new {
    my $class = shift;

    # Establish the defaults for each option
    my %defaults = (
        host      => 'localhost',
        port      => 80,
        directory => 'sesame',
        timeout   => 10,
    );

    my %opts;
    if( @_ == 1 ) {
        $opts{host} = shift;
    } else {
        %opts = @_;
    }

    if( $opts{host} and $opts{host} =~/^(.*):(\d+)$/ ) {
        $opts{host} = $1;
        $opts{port} = $2;
    } elsif( $opts{uri} ) {
        require URI;
        my $uri = URI->new( $opts{uri} );

        # set the individual options based on the URI
        $opts{host} = $uri->host;
        $opts{port} = $uri->port;
        $opts{directory} = $uri->path;

        my($user, $pass) = split(/:/, $uri->userinfo || '', 2);
        $opts{username} = $user if defined $user;
        $opts{password} = $pass if defined $pass;
    }

    # set the defaults
    while( my ($k,$v) = each %defaults ) {
        $opts{$k} = $v unless exists $opts{$k};
    }

    # normalize the sesame directory
    $opts{directory} =~ s#^/+##g;
    $opts{directory} =~ s#/+$##g;

    # create a user agent for making HTTP requests
    my $ua = LWP::UserAgent->new(
            agent      => "rdf-sesame/$RDF::Sesame::VERSION ",
            keep_alive => 1,
            cookie_jar => {},
            timeout    => $opts{timeout},
    );

    # create our new self
    my $self = bless {
        server => "http://$opts{host}:$opts{port}/$opts{directory}/servlets/",
        ua     => $ua,
        authed => 0,     # are we logged in?
        repos  => undef, # list of available repositories
    }, $class;

    # do we even need to login ?
    return $self unless defined $opts{username};

    # yup, so go ahead and do it
    my $r;
    $opts{password} = '' unless defined $opts{password};
    $r = $self->command(
        undef,
        'login',
        {user=>$opts{username}, password=>$opts{password}}
    );

    unless( $r->success ) {
        $RDF::Sesame::errstr = $r->errstr;
        return '';
    }

    $self->{authed} = 1;
    return $self;
}

=head1 AUTHOR

Michael Hendricks <michael@ndrix.com>

=cut

return 1;
