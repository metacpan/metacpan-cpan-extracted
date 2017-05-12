package Net::Google::Calendar;
{
  $Net::Google::Calendar::VERSION = '1.05';
}

use strict;
use LWP::UserAgent;
use HTTP::Cookies;
use HTTP::Request;
use HTTP::Headers;
use HTTP::Request::Common;
use XML::Atom::Feed;
use XML::Atom::Entry;
use Data::Dumper;
use Net::Google::AuthSub;
use Net::Google::Calendar::Entry;
use Net::Google::Calendar::Person;
use Net::Google::Calendar::Calendar;
use URI;
use URI::Escape;
use Carp qw(confess);

use vars qw($VERSION $APP_NAME $REDIRECT_MAX);

$APP_NAME = $Net::Google::OAuth::APP_NAME = __PACKAGE__."-${VERSION}"; 

$REDIRECT_MAX = 10; #Maximum number of redirects to allow

# ABSTRACT: Interface to Google calendars

=head1 NAME

Net::Google::Calendar - programmatic access to Google's Calendar API


=head1 SYNOPSIS

    # this will only get you a read only feed
    my $cal = Net::Google::Calendar->new( url => $private_url );

or

    # this will get you a read-write feed. 
    my $cal = Net::Google::Calendar->new;
    $cal->login($username, $password);

or

    # this will also get you a read-write feed
    my $cal = Net::Google::Calendar->new;
    $cal->auth($username, $auth_token);

or
    # this will again get you a read-write feed
    my $cal = Net::Google::Calendar->new;
    $cal->oauth(Net::Google::OAuth);

or you can pass in a url to specify a particular calendar

    my $cal = Net::Google::Calendar->new( url => $non_default_url );
    $cal->login($username, $password);
    # or $cal->auth($username, $auth_token) obviously


then

    for ($cal->get_events()) {
        print $_->title."\n";
        print $_->content->body."\n*****\n\n";
    }

    my $c;
    for ($cal->get_calendars) {
        print $_->title."\n";
        print $_->id."\n\n";
        $c = $_ if ($_->title eq 'My Non Default Calendar');
    }
    $cal->set_calendar($c);
    print $cal->id." has ".scalar($cal->get_events)." events\n";


    # everything below here requires a read-write feed
    my $entry = Net::Google::Calendar::Entry->new();
    $entry->title($title);
    $entry->content("My content");
    $entry->location('London, England');
    $entry->transparency('transparent');
    $entry->status('confirmed');
    $entry->when(DateTime->now, DateTime->now() + DateTime::Duration->new( hours => 6 ) );


    my $author = Net::Google::Calendar::Person->new();
    $author->name('Foo Bar');
    $author->email('foo@bar.com');
    $entry->author($author);

By default new or updated entries are modified in place with
any new information provided by Google.

   $cal->add_entry($entry);

   $entry->content('Updated');
   $cal->update_entry($entry);

   $cal->delete_entry($entry);

However if you don't want the entry updated in place pass
C<no_event_modification> in to the C<new()> method.

    my $cal = Net::Google::Calendar->new( no_event_modification => 1 );
    $cal->login($user, $pass);
   
    my $tmp = $cal->add_entry($entry);
    die "Couldn't add event: $@\n" unless defined $tmp;

    print "Events=".scalar($cal->get_events())."\n";

    $tmp->content('Updated');

    $tmp = $cal->update_entry($tmp) || die "Couldn't update ".$tmp->id.": $@\n";

    $cal->delete_entry($tmp) || die "Couldn't delete ".$tmp->id.": $@\n";



=head1 DESCRIPTION

Interact with Google's new calendar using the GData API.


=head1 AUTHENTICATION AND READ-WRITE CALENDARS

There are effectively four ways to get events from a Google calendar.

You can get any public events by querying

    http://www.google.com/calendar/feeds/<email>/public/full

Then there are the three ways to get private entries. The first of these 
involves a magic cookie in the url like this:

    http://www.google.com/calendar/feeds/<email>/private-<key>/full

Google has information on how to find this url here

    http://code.google.com/apis/calendar/developers_guide_protocol.html#find_feed_url

To use either the private or public feeds do

    my $cal = Net::Google::Calendar->new( url => $url);

Both these feeds will be read only however. This means that you won't be able to
add, update or delete entries.

You can also get all the private entries in a read-write feed by either logging in 
or using C<AuthSub>.

Logging in is the easiest. Simply do

     my $cal = Net::Google::Calendar->new;
     $cal->login($username, $password);

Where C<$username> and C<$password> are the same as if you were logging into the 
Google Calendar site.

Alternatively if you don't want to use username and password (if, for example you were 
providing Calendar reading as a service on your website and didn't want to have to ask 
your users for their Google login details) you can use C<AuthSub>.

     http://code.google.com/apis/accounts/AuthForWebApps.html

Once you have an AuthSub token (or you user has supplied you with one)
then you can login using

     my $cal = Net::Google::Calendar->new;
     $cal->auth($username, $token);

=head1 METHODS

=cut

=head2 new <opts>

Create a new instance. C<opts> is a hash which must contain your private Google url
as the key C<url> unless you plan to log in or authenticate.

See 

    http://code.google.com/apis/gdata/calendar.html#find_feed_url

for how to get that.

If you pass the option C<no_event_modification> as a psotive value then
add_entry and update_entry will not modify the entry in place.

=cut

sub new {
    my ($class, %opts) = @_;
    $opts{_ua}   = LWP::UserAgent->new( max_redirect => 0 );
    $opts{_ua}->env_proxy;
    $opts{_auth} = Net::Google::AuthSub->new( service => 'cl' );
    $opts{_cookie_jar} = HTTP::Cookies->new;
    $opts{no_event_modification} ||= 0;
    my $self = bless \%opts, $class;
    $self->_find_calendar_id if $opts{url};
    return $self;
}


=head2 login <username> <password> [opt[s]]

Login to google.

Can optionally take a hash of options which will override the 
default login params. 

=over 4

=item service

Name of the Google service for which authorization is requested.

Defaults to 'cl' for calendar.

=item source

Short string identifying your application, for logging purposes.

Defaults to 'Net::Google::Calendar-<VERSION>'

=item accountType

Type of account to be authenticated.

Defaults to 'HOSTED_OR_GOOGLE'.

=back

See http://code.google.com/apis/accounts/AuthForInstalledApps.html#ClientLogin for more details.

=cut

sub login {
    my $self  = shift;
    my $user  = shift;
    my $pass  = shift;
    my $r     = $self->{_auth}->login($user, $pass);
    my $error;
    if (!defined $r) {
        $error = $@; 
    } elsif (!$r->is_success) {
        $error = $r->error;
    } 
    die "Couldn't log in - $error" if defined $error;

    $self->{user} = $user;
    $self->_generate_url();
    return 1;
}


=head2 auth <username> <token>

Use the AuthSub method for calendar access.
See http://code.google.com/apis/accounts/AuthForWebApps.html 
for details.


=cut

sub auth {
    my $self  = shift;
    my $user  = shift;
    my $token = shift;
    $self->{_auth}->auth($user, $token);
    $self->{user} = $user;
    $self->_generate_url();
    return 1;
}

=head2 oauth Net::Google::OAuth

Use OAuth for calendar access

=cut

sub oauth {
    my $self = shift;
    $self->{_auth} = shift;
}

sub _generate_url {
    my $self= shift;
    $self->{url} ||=  $self->_get_protocol()."://google.com/calendar/feeds/$self->{user}/private/full";
    $self->{url}   =~ s!/private-[^/]+!/private!;
    $self->_find_calendar_id;

}

=head2 auth_object [Net::Google::AuthSub]

Get or set the current C<Net::Google::AuthSub> object.

=cut
sub auth_object {
    my $self = shift;
    $self->{_auth} = shift if @_;
    return $self->{_auth};
}

sub _find_calendar_id {
    my $self = shift;
    ($self->{calendar_id}) = ($self->{url} =~ m!/feeds/([^/]+)/!);
}

=head2 ssl bool

Use ssl or not.  Auth tokens (AuthSub and OAuth) have a scope that includes http:// or https://.  Make sure you use ssl(1) if your scope is https://www.google.com/calendar/feeds/.

=cut

sub ssl {
    my $self = shift;
    $self->{_use_ssl} = shift;
}

sub _get_protocol {
    my $self = shift;
    if ($self->{_use_ssl}) {
        return 'https';
    }
    return 'http';
}

=head2 get_events [ %opts ]

Return a list of Net::Google::Calendar::Entry objects;

You can pass in a hash of options which map to the Google Data API's generic 
searching mechanisms plus the specific calendar ones.

See

    http://code.google.com/apis/gdata/protocol.html#query-requests

for more details.


=over 4

=item q

Full-text query string

When creating a query, list search terms separated by spaces, in the
form q=term1 term2 term3. (As with all of the query parameter values,
the spaces must be URL encoded.) The GData service returns all entries
that match all of the search terms (like using AND between terms). Like
Google's web search, a GData service searches on complete words (and
related words with the same stem), not substrings.

To search for an exact phrase, enclose the phrase in quotation marks: 

    q => '"exact phrase'

To exclude entries that match a given term, use the form 

    q => '-term'

The search is case-insensitive.

Example: to search for all entries that contain the exact phrase
'Elizabeth Bennet' and the word 'Darcy' but don't contain the word
'Austen', use the following query: 

    q => '"Elizabeth Bennet" Darcy -Austen'


=item category

Category filter

To search in just one category do

    category => 'Fritz'    

You can query on multiple categories by listing multiple category parameters. For example

    category => [ 'Fritz', 'Laurie' ]

returns entries that match both categories.


To do an OR between terms, use a pipe character (|). For example


    category => 'Fritz|Laurie'

returns entries that match either category.

To exclude entries that match a given category, use the form 

    category => '-categoryname'

You can, of course, mix and match

    [ 'Jo', 'Fritz|Laurie', '-Simon' ]

means in category 

    (Jo AND ( Fritz OR Laurie ) AND (NOT Simon)) 


=item author

Entry author

The service returns entries where the author name and/or email address 
match your query string.

=item updated-min

=item updated-max

Bounds on the entry publication date.

Use DateTime objects or the RFC 3339 timestamp format. For example:
2005-08-09T10:57:00-08:00.

The lower bound is inclusive, whereas the upper bound is exclusive.

=item start-min

=item start-max

Respectively, the earliest event start time to match (If not specified, 
default is 1970-01-01) and the latest event start time to match (If 
not specified, default is 2031-01-01).

Use DateTime objects or the RFC 3339 timestamp format. For example:
2005-08-09T10:57:00-08:00.

The lower bound is inclusive, whereas the upper bound is exclusive.

=item start-index

1-based index of the first result to be retrieved

Note that this isn't a general cursoring mechanism. If you first send a 
query with 

    start-index => 1,
    max-results => 10 

and then send another query with

    start-index => 11,
    max-results => 10

the service cannot guarantee that the results are equivalent to
    
    start-index => 1
    max-results => 20

because insertions and deletions could have taken place in between the
two queries.

=item max-results

Maximum number of results to be retrieved.

For any service that has a default max-results value (to limit default 
feed size), you can specify a very large number if you want to receive 
the entire feed.

=item entryID

ID of a specific entry to be retrieved.

If you specify an entry ID, you can't specify any other parameters.

=back

=cut

sub get_events {
    my ($self, %opts) = @_;


    # check for DateTime objects and convert them to RFC 3339 
    for (keys %opts) {
        next unless UNIVERSAL::isa($opts{$_}, 'DateTime');
        # maybe we should chuck an error if it's a Ref and *not* a DateTime
        #next unless $opts{$_}->isa('DateTime');
        $opts{$_} = $opts{$_}->iso8601 . 'Z';
    }

    my $url = URI->new($self->{url});

    # special handling for single entryID lookup
    if (exists $opts{entryID}) {
        if (scalar(keys %opts)>1) {
            $@ = "You can't specify entryID and anything else";
            return undef;    
        }
        my $path = $url->path;
        $url->path("$path/".$opts{entryID});
        return $self->_get_entry("$url", "Net::Google::Calendar::Entry");
    }

    if (exists $opts{category} && 'ARRAY' eq ref($opts{category})) {
        my $path = $url->path."/".join("/", ( '-', @{delete $opts{category}}));
        $url->path("$path");
    }

    $url->query_form(%opts);
    $self->_get("$url", "Net::Google::Calendar::Entry");
}


=head2 add_entry <Net::Google::Calendar::Entry>

Create a new entry.

Returns the new entry with extra data provided by Google but will
also modify the entry in place unless the C<no_event_modification> 
option is passed to C<new()>.

Returns undef on failure.

=cut

sub add_entry {
    my ($self, $entry) = @_;

    # TODO for neatness' sake we could make calendar_id = 'default' when calendar_id = user
    my $url =  $self->_get_protocol()."://www.google.com/calendar/feeds/$self->{calendar_id}/private/full"; 
    push @_, ($url, 'POST');
    goto $self->can('_do');
}


=head2 delete_entry <Net::Google::Calendar::Entry>

Delete a given entry.

Returns undef on failure or the old entry on success.

=cut

sub delete_entry {
    my ($self, $entry) = @_;
    my $force = (scalar(@_)>2)? pop @_ : 0;
    my $url = $entry->edit_url($force) || return undef;
    push @_, ($url, 'DELETE');
    goto $self->can('_do');
}

=head2 update_entry <Net::Google::Calendar::Entry>

Update a given entry.

Returns the updated entry with extra data provided by Google but will
also modify the entry in place unless the C<no_event_modification>
option is passed to C<new()>.

Returns undef on failure.

=cut

sub update_entry {
    my ($self, $entry) = @_;
    my $url = $entry->edit_url || return undef;
    push @_, ($url, 'PUT');
    goto $self->can('_do');
}

=head2 get_calendars <owned>

Get a list of all of a user's Calendars as C<Net::Google::Calendar::Calendar> objects.

If C<owned> is true then only get the ones a user owns.
 
=cut

sub get_calendars {
    my $self  = shift;
    my $owned = shift || 0;
    my $which = ($owned)? "owncalendars" : "allcalendars";
    my $url   = $self->_get_protocol()."://www.google.com/calendar/feeds/default/$which/full";
    return $self->_get("$url", "Net::Google::Calendar::Calendar");
}


sub _get {
    my ($self, $url, $class, %opts) = @_;
    my $feed = $self->get_feed(URI->new("$url"), %opts);
    return map {  bless $_, $class; $_->_initialize(); $_ } $feed->entries;
}    

=head2 get_feed [feed] [opt[s]]

If C<feed> is a C<URI> object then feed is fetch remotely. 
Otherwise it is assumed to be XML data and is parsed.

Returns an C<XML::Atom::Feed> object.

=cut

sub get_feed {
    my ($self, $feed, %opts) = @_;
    if (ref($feed)){
        return $feed if $feed->isa('XML::Atom::Feed');
        if ($feed->isa('URI')) {
            my %params = ($self->{_auth}->auth_params('GET', $feed), %opts);
            my $r   = $self->{_ua}->get("$feed", %params);

            my $redirect_tries = 0;
            while ($r->code == 302 || $r->code == 301) {
                my $location = $r->header('location');
                %params = ($self->{_auth}->auth_params('GET', $location), %opts);
                $r   = $self->{_ua}->get($location, %params);
                $redirect_tries++;
            	die "Too many redirects ($redirect_tries)" 
            	  if $redirect_tries > $REDIRECT_MAX;
            }

            die $r->status_line unless $r->is_success;
            $feed = $r->content;
        }
    }
    return XML::Atom::Feed->new(\$feed);
}

=head2 update_feed <feed>

Take an C<XML::Atom::Feed> object with a C<http://schemas.google.com/g/2005#post> link and post it.

=cut

sub update_feed {
    my ($self, $feed) = @_;
     #my $uri = Net::Google::Calendar::Base::_generic_url($feed, 'http://schemas.google.com/g/2005#post') || die("Couldn't get url");
     my $uri = Net::Google::Calendar::Base::_generic_url($feed, 'edit') || die("Couldn't get url");
    push @_, ($uri, 'POST');
    goto $self->can('_do');
}

# TODO collapse this with _get somehow
sub _get_entry {
    my ($self, $url, $class) = @_;
    my %params = ($self->{_auth}->auth_params);
    my $r   = $self->{_ua}->get("$url", %params);
  
    if (!$r->is_success) {
         if ($r->code == 404) {
              $@ = "EntryID not found";
         } else {
              $@ = $r->status_line;
         }
         return;
    }
    my $atom = $r->content;

    my $entry = XML::Atom::Entry->new(\$atom);
    $entry = bless $entry, $class;
    $entry->_initialize();
    return $entry;
}

=head2 set_calendar <Net::Google::Calendar::Calendar>

Set the current calendar to use.

=cut

sub set_calendar {
    my $self = shift;
    my $cal  = shift;

    ($self->{calendar_id}) = (uri_unescape($cal->id) =~ m!([^/]+)$!);
    $self->{url} =  $self->_get_protocol()."://www.google.com/calendar/feeds/$self->{calendar_id}/private/full";
}


=head2 add_calendar  <Net::Google::Calendar::Calendar>

Create a new calendar 

Returns the new calendar with extra data provided by Google but will
also modify the entry in place unless the C<no_event_modification> 
option is passed to C<new()>.

Returns undef on failure.

=cut

sub add_calendar {
    my ($self, $entry) = @_;
    my $url = $self->_get_protocol()."://www.google.com/calendar/feeds/$self->{calendar_id}/owncalendars/full"; 
    push @_, ($url, 'POST');
    goto $self->can('_do');
}

=head2 update_calendar  <Net::Google::Calendar::Calendar>

Update a calendar.

Returns the updated calendar with extra data provided by Google but will
also modify the entry in place unless the C<no_event_modification>
option is passed to C<new()>.

Returns undef on failure.

=cut

sub update_calendar {
    my $self = shift;
    $self->update_entry(@_);
}


=head2 delete_calendar <Net::Google::Calendar::Calendar> [force]

Delete a given calendar.

Returns undef on failure or the old entry on success.

Note that, at the moment, only C<Calendar> objects returned 
by C<get_calendars> with the C<owned> parameter set to C<true> 
can be deleted (unlike editing - I don't know if this is a Google
bug or not). 

However, you can pass in an optional true C<force> parameter to this
method that will allow C<Calendar> objects returned by C<get_calendars> 
where no positive C<owned> paramemter was passed to be deleted. It uses 
an egregious hack though and might suddenly stop working if Google change 
things or I suddenly decide to remove it.

=cut


sub delete_calendar {
    my $self = shift;
    $self->delete_entry(@_);
}

sub _do {
    my ($self, $entry, $url, $method) = @_;

    unless (defined $self->{_auth}) {
        $@ = "You must log in to do a $method\n";
        return undef;
    }
    my $class = ref($entry);
    my $xml = eval { $entry->as_xml };
    confess($@) if $@;
    _utf8_off($xml);
    my %params = $self->{_auth}->auth_params;
    $params{Content_Type}             = 'application/atom+xml; charset=UTF-8';
    $params{Content}                  = $xml;
    $params{'X-HTTP-Method-Override'} = $method unless "POST" eq $method;

    if (defined $self->{_session_id} && !$self->{_force_no_session_id}) {
        my $tmp = URI->new($url);
        $tmp->query_form({ gsessionid => $self->{_session_id} });
        $url = "$tmp";
    }

    

    REQUEST: while (1) {
        my $rq = POST "$url", %params;
        $self->{_cookie_jar}->add_cookie_header($rq);
        #my $h  = HTTP::Headers->new(%params);
        #my $rq = HTTP::Request->new($method => $url, $h);
        my $r = $self->{_ua}->request( $rq );
        $self->{_cookie_jar}->extract_cookies($r);
        my $redirect_tries = 0;
        while (302 == $r->code || 301 == $r->code) {
            $url = $r->header('location');
            my %args = URI->new($url)->query_form;
            $self->{_session_id} = $args{gsessionid};
            $redirect_tries++;
			die "Too many redirects ($redirect_tries)" 
			  if $redirect_tries > $REDIRECT_MAX;
            next REQUEST;
        }
        #print $rq->as_string unless $params{'X-HTTP-Method-Override'} ;

        if (!$r->is_success) {
            $@ = $r->status_line." - ".$r->content." - $url";
            return undef;
        }
        my $c = $r->content;
        if (defined $c && length($c)) {
            my $tmp = $class->new(Stream => \$c);
            $_[1]   = $tmp unless $self->{no_event_modification};
            return $tmp;
        } else {
            # in the case of DELETE should we return 1 instead?
            return $entry;
        }
    }


}

sub _utf8_off {
    if ($] >= 5.008) {
        require Encode;
        return Encode::_utf8_off($_[0]);
    }
}

=head1 WARNING

This is ALPHA level software. 

Don't use it. Ever. Or something.

=head1 TODO

Abstract this out to Net::Google::Data

=head1 LATEST VERSION

The latest version can always be obtained from my 
Subversion repository.

    http://svn.unixbeard.net/simon/Net-Google-Calendar

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright Simon Wistow, 2006

Distributed under the same terms as Perl itself.

=head1 SEE ALSO

http://code.google.com/apis/gdata/calendar.html

=cut
1;
