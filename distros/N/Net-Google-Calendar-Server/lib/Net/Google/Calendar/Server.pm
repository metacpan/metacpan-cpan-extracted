package Net::Google::Calendar::Server;

use strict;
use Net::Google::Calendar;
use Data::ICal::DateTime;
use XML::Atom::Feed;
use XML::Atom::Util qw( set_ns first nodelist iso2dt);

use vars qw($VERSION);

$VERSION="0.1";

=head1 NAME 

Net::Google::Calendar::Server - pretend to be like Google's Calendar

=head1 SYNOPSIS



    # in reality this will be something like the Apache handler
    my $handler  = Net::Google::Calendar::Server::Handler::Foo->new; 

    # $be_class might be ICalendar and $au_class might be Dummy
    my $cal = eval { 
        Net::Google::Calendar::Server->new( backend_class => $be_class, backend_opts => \%backend_opts,
                                            auth_class    => $au_class, auth_opts    => \%auth_opts     ) 
    };

    return $self->error($@) if $@;
    return $cal->handle_request($handle);
    
=head1 DESCRIPTION

This is an implementation of the Calendar portion of Google's GData API.

     http://code.google.com/apis/gdata/protocol.html

It's very incomplete but it's been lurking round in my Subversion repo for 
too long (nearly a year now) so it deserves to be free. Free! FREE! Emancipia!

A server requires a handler to call it (something like CGI or an Apache handler 
or a standalone server).

A server also requires a backend class (something that will retrieve and store
entries) and an auth class (something that will authentic the user) which can 
be the same as the backend class.

=head1 METHODS

=cut


=head2 new [ opts ]

Create a new server. Requires at least the options

=over 4

=item backend_class

A class that will retrieve and store entries.

Must be a subclass of a C<Net::Google::Calendar::Server::Backend> so for 
example to use  C<Net::Google::Calendar::Server::Backend::ICalendar> pass 
in 'ICalendar'.

=item backend_opts

Options for the backend class.

=item auth_class

A class that will authenticate a user. Can be the same as the backend class i.e
if you passed in 'ICalendar' for C<backend_class> and C<auth_class> then
the C<Net::Google::Calendar::Server::Backend::ICalendar> object instantiated
for the backend will be used for the auth class.

=item auth_opts

Options for the authentication class.

=back

=cut

sub new {
    my $class = shift;
    my %opts  = @_;

    my $dp_class = $opts{'backend_class'};
    my $au_class = $opts{'auth_class'};

    # require the backend class
    my $backend = $class->_require('Backend', $dp_class);
    die $@ if $@;

    # fetch the variables for the Backend and the Auth classes
    my %backend_opts = %{$opts{'backend_opts'}};
    my %auth_opts    = %{$opts{'auth_opts'}};

    # If auth is the same as backend then do some shennanigans
    # this will allow a backend to also act as an Auth class if necessary
    # useful for something like a DB backend or authenticating against Gmail or Exchange
    my $auth;
    if ($au_class eq $dp_class) {
        $backend = $auth =  $backend->new(%backend_opts, %auth_opts);
    } else {
        $auth = $class->_require('Auth', $au_class);
        die $@ if $@;
        $auth = $auth->new(%auth_opts);
    }
    $opts{backend} = $backend;
    $opts{auth}    = $auth;

    return bless \%opts, $class;
}

sub _require {
    my $self  = shift;
    my $base  = shift;
    my $class = shift;

    $class = "Net::Google::Calendar::Server::${base}::${class}";
    eval "CORE::require $class";
    return $class;
}

=head2 auth

The authentication object.

=cut

sub auth {
    return $_[0]->{auth};
}

=head backend

The backend object.

=cut

sub backend {
    return $_[0]->{backend};
}


=head2 fetch [ opts ]

Get an event or events. 

Returns an Atom feed.

=cut

sub fetch {
    my $self = shift;
    my %opts = @_;    

    # convert to DT first
    foreach my $key (keys %opts) {
        next if UNIVERSAL::isa($opts{$key},'DateTime');
        if ($key =~ m!-m(in|ax)$!) {
            $opts{$key} = iso2dt($opts{$key});
        }
    }
    my @events = $self->{backend}->fetch(%opts);
    my $feed = XML::Atom::Feed->new;
    for (@events) {
        $feed->add_entry($self->_to_atom($_));
    }
    return $feed;    

}

=head2 create

Takes an Atom entry, creates an entry, returns the updated Atom entry.

=cut

sub create {
    my $self   = shift;
    return $self->_do('create', @_);
}

=head2 update

Takes an Atom entry, updates the entry, returns the updated Atom entry.

=cut

sub update {
    my $self = shift;
    return $self->_do('update', @_);0
}


=head2 deletes

Takes an Atom entry, deletes an event, returns undef on failure.

=cut

sub delete {
    my $self = shift;
    return $self->_do('delete', @_);
}

sub _do {
    my $self   = shift;
    my $meth   = shift;
    my $entry  = shift;

    my $item   = $self->_from_atom($entry);
    $item      = eval { $self->{backend}->$meth($item) };
    return undef if $@;
    return $self->_to_atom($item);     

}

# TODO all the other fields

# take an atom entry and turn it into something useful
sub _from_atom {
    my $self   = shift;
    my $entry  = shift;
    my $e      = Net::Google::Calendar::Entry->new(\$entry);
    my $event  = Data::ICal::Entry::Event->new;

    my ($start, $end) = $e->when; 

    $event->uid($e->id) if $e->id;
    $event->summary($e->title);
    $event->description($e->content);
    $event->start($start);
    $event->end($end);
    $event->recurrence($e->recurrence);

    return $event;
}


# create an atom entry
sub _to_atom {
    my $self  = shift;
    my $entry = shift;
    my $e     = Net::Google::Calendar::Entry->new;
    
    my $start = $entry->start;
    my $end   = $entry->when;

    $e->id($entry->uid) if $entry->uid;
    $e->title($entry->summary);
    $e->content($entry->description);
    $e->when($start, $end);
    $e->recurrence($entry->recurrence);
    
    return $e;
}

=head2 handle_request <handler>

Requires a subclass of C<Net::Google::Calendar::Server::Handler>.

=cut

sub handle_request {
    my $self     = shift;
    my $handler  = shift;

    my $auth     = $self->auth;
    my $r_method = $handler->request_method();
    my $x_method = $handler->header_in('X-HTTP-Method-Override');

    my $path     = $handler->path;

    # NOTES on login
    # 1. We should be able to handle a magic cookie URL - note that this automatically returns a full list of events
    # 2. Stuff is POSTed to accounts/ClientLogin, not GETed (DONE)
    # 3. We need to be able to handle different feed types full/basic/private
    # 4. Once we've AUTHed we should redirect to the private feed
    # 5. Should this be moved into ::Server somehow?

    if ($r_method eq 'GET' && $path =~ m!feeds/([^/]+)/private-([^/]+)/full!) {
        my $email  = $1;
        my $cookie = $2;
        my $session_id = $auth->magic_cookie_auth($email, $cookie);
        return $handler->error('Invalid magic cookie auth', 'FORBIDDEN') unless $session_id;
        # generate session id (from auth)
        # redirect to feed with session id
    }



    # is this the login url?
    # accounts/ClientLogin
    if ($r_method eq 'POST' && $path eq 'accounts/ClientLogin') {
        # first off get the email and password
        my $email = $handler->header_in('email');
        my $pass  = $handler->header_in('password');
        # get the auth key and hand it back
        my $key   = $auth->validate($email, $pass);
        unless (defined $key) {
            return $handler->error("Login failed", 'DECLINED');
        }
        return $handler->send_reponse( type => 'text/plain', body => 'Auth=$key', code => 'OK' );
    }

    # if they're up to here then they must have an Auth key
    my $key = $handler->header_in('Authorization');

    # TODO session id

    unless (defined $key && $key =~ s!GoogleLogin auth=!!) {
        return $handler->error("You must pass an Authorization key", 'AUTH_REQUIRED');
    }
    unless ($auth->auth($key)) {
        return $handler->error("Login Failed", 'FORBIDDEN');
    }
    my $r_content;
    # Fetch entries
    # method=GET
    if ($r_method eq 'GET') {

        # get params
        my %opts = $handler->get_args();
        # get categories
        my @categories = split '/', $path;
        shift @categories if $categories[0] eq '-';
        $opts{'categories'} = [ @categories ];
        $r_content = eval { $self->fetch(%opts) };

    # method=Everything else
    } else {

        my %map = ( POST => 'create', PUT => 'update', DELETE => 'delete' );
        $r_method = $x_method if defined $x_method && $r_method eq 'POST';
        return $handler->error("No such method: $r_method") unless defined $map{$r_method};

        my $method  = $map{$r_method};
        my $content = $handler->header_in('Content');
        return $handler->error("No content") unless defined $content;

        my $backend = $self->backend();
        $r_content  = eval { $backend->$method($content) };

    }

    return $handler->error($@) if $@;
    return $handler->error("Got not content back from $r_method") unless defined $r_content;

    return $handler->send_response( type => 'application/atom+xml', body => $r_content->as_xml, code => 'OK' );


}

=head1 SEE ALSO

L<Net::Google::Calendar>

L<Net::Google::Calendar::Server::Backend>

The Lucene implementation of the GData server.
http://wiki.apache.org/lucene-java/GdataServer

=head1 SUBVERSION

https://svn.unixbeard.net/simon/Net-Google-Calendar-Server/

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright 2006, 2007 - Simon Wistow

=cut

1;
