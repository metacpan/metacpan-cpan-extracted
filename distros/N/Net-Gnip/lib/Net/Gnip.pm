package Net::Gnip;

use strict;

use DateTime;
use DateTime::Format::Strptime;
use LWP::UserAgent;

use Net::Gnip::ActivityStream;
use Net::Gnip::FilterStream;
use Net::Gnip::PublisherStream;

our $VERSION = "0.3";

use constant GNIP_BASE_ADDRESS => 'prod.gnipcentral.com';
use constant GNIP_BASE_URL     => 'https://'.GNIP_BASE_ADDRESS;

=head1 NAME

Net::Gnip - interact with Gnip

=head1 SYNOPSIS

    use Net::Gnip;
    my $gnip       = Net::Gnip->new($user, $pass, $publisher_name);

    # Get a list of publisher
    my @publisher = $gnip->publishers();
    $gnip->create_publisher($name);


    # Create an activity and publish it
    my $activity   = Net::Gnip::Activity->new('added_friend', 'me');
    $gnip->publish($publisher_name, $activity);
    # or
    $gnip->publish($publisher_name, @activities);
    # or
    $gnip->publish($activity_stream);

    # Retrieve activities for a given publisher
    my $stream     = $gnip->fetch(notification => $publisher_name);
    foreach my $activity ($stream->activities) {
        print "Type=".$activity->type."\n";
    }

    # Retrieve activities for a given publisher 10 minutes ago
    my $stream     = $gnip->fetch(notification => $publisher_name, time => 10*60);

    # Retrieve activities for a given publisher from a specific time
    my $stream     = $gnip->fetch(notification => $publisher_name, time => $dt);

    # The same but get the full date
    my $stream     = $gnip->fetch(activity => $publisher_name, time => $dt);


    # Create a filter and 
    my @rules  = ( { type => 'actor', value => 'joe' } );
    my $filter     = Net::Gnip::Filter->new('my_filter', 'true', [@rules]);
    my $result     = $gnip->create_filter($publisher_name, $filter); 

    # Get a list of filters
    foreach my $filters ($gnip->filters($publisher_name)) {
        print $filter->name."\n";
    }

    
    # Get the activities from it
    my $stream     = $gnip->fetch(activity => $publisher_name, filter => $filter_name);
    foreach my $activity ($stream->activities) {
        print "Type=".$activity->type."\n";
    }
    
    # Update it
    $filter->full('false');
    $gnip->update_filter($publisher_name, $filter);

    $gnip->add_filter_rule($filter,    'actor', 'simon');
    $gnip->delete_filter_rule($filter, 'actor', 'simon')

    
    # Delete it
    $gnip->delete_filter($publisher_name, $filter);



=head2 METHODS

=cut

=head2 new  <username> <password>

Create a new Gnip object

=cut

sub new {
    my ($class, $username, $password, %self) = @_;
    $self{'_username'} = $username;
    $self{'_password'} = $password;
    return bless {%self}, $class;
}



=head2 fetch <publisher> [datetime])

Gets all of the data for a specific publisher, based on the
datetime parameter. 

If datetime is not passed in, the current time will be used. 

Note that all times need to be as UTC DateTime objects.

Returns a C<Net::Gnip::ActivityStream> object.

=cut

sub fetch {
    my $self          = shift;
    my %opts          = @_;

    my $what;
    my $name;

    for my $key (qw(notification activity)) {
        next unless defined $opts{$key};
        $what = $key;
        $name = $opts{$key};
    }
    die "You must must pass in either a 'notification' or 'activity' key with a publisher name"
        unless defined $what;

    
    my $path = "publishers/${name}";
    if (defined $opts{filter}) {
        $path .= "/filters/".$opts{filter};
    }
    $path .= "/${what}";

    my $datetime      = $opts{time};
    my $file          = "current.xml";

    if (defined $datetime) {
        $datetime = DateTime->now->subtract( seconds => $datetime) unless ref($datetime);
        unless ($self->{no_time_sync}) {
            my $gnip_time     = $self->sync_with_gnip_clock;
            my $local_time    = DateTime->now;
            $datetime         = $datetime + ($gnip_time - $local_time);
        }
        my $rounded       = $self->round_time_to_nearest_bucket($datetime);
        my $time_string   = $self->time_to_string($rounded);
        $file             = "${time_string}.xml";
    }
    my $url = $self->GNIP_BASE_URL."/".$path."/".$file;
    my $xml = $self->get($url) || return;
    return Net::Gnip::ActivityStream->parse($xml, _no_dt => $self->{_no_dt});
}

=head2 publish <activity stream>

Publish an activity stream.

=cut

=head2 publish <publisher name> <activity[s]>

=cut
sub publish {
    my $self       = shift;
    my $publisher  = shift;
    my $stream;
    if (ref $publisher) {
        $stream    = $publisher;
        $publisher = $stream->publisher;
        die "An activity stream must have a publisher set if it's the only argument to publish()" 
            unless defined $publisher; 
    }
    die "You need to pass in some activities" unless @_;
    $stream        = Net::Gnip::ActivityStream->new( publisher => $publisher);
    $stream->activities(@_);
    my $url        = $self->GNIP_BASE_URL."/publishers/" . $publisher . "/activity";
    $self->post($url, $stream);
}



=head2 filters <publisher name>

Get a list of filters for this publisher.

Returns a list of C<Net::Gnip::Filter> objects.

=cut
sub filters {
    my $self      = shift;
    my $publisher = shift;
    my $url       = $self->GNIP_BASE_URL."/publishers/$publisher/filters.xml";
    my $xml       = $self->get($url) || return;
    return Net::Gnip::FilterStream->parse($xml)->filters;
}


=head2 create_filter <publisher name> <filter>

Creates a new filter.

=cut
sub create_filter {
   my ($self, $publisher, $filter) = @_;
   my $url = $self->GNIP_BASE_URL."/publishers/$publisher/filters.xml";
   return $self->post($url, $filter);
}

=head2 get_filter <publisher name> <filter>

Fetches an existing filter.

C<filter> can either be a filter object or a name.

Returns a C<Net::Gnip::Filter> object.

=cut
sub get_filter {
    my $self = shift;
    my $xml  = $self->_filter_method('get', @_) || return;
    return Net::Gnip::Filter->parse($xml);
}

=head2 update_filter <publisher name> <filter>

Updates an existing filter.

C<filter> can either be a filter object or a name.

Returns 1 on success and 0 on failure.

=cut
sub update_filter {
    my $self = shift;
    return $self->_filter_method('put', @_);
}

=head2 delete_filter <publisher name> <filter>

Deletes an existing filter.

C<filter> can either be a filter object or a name.

=cut
sub delete_filter {
    my $self = shift;
    return $self->_filter_method('delete', @_);
}

=head2 add_filter_rule <publisher> <filter> <type> <value>

Incrementally add a filter rule.

=cut
sub add_filter_rule {
    my $self      = shift;
    $self->_filter_method('post', @_);
}

=head2 delete_filter_rule <publisher> <filter> <type> <value>

Incrementally delete a filter rule.

=cut
sub delete_filter_rule {
    my $self = shift;
    $self->_filter_method('delete', @_);
}

sub _filter_method {
    my $self      = shift;
    my $method    = shift;
    my $publisher = shift;
    my $filter    = shift;
    my $type      = shift; 
    my $value     = shift;
    my $name = (ref($filter))? $filter->name : $filter;
    my $url = $self->GNIP_BASE_URL."/publishers/$publisher/filters/$name";
    if (defined $type && defined $value) {
        $url .= "/rules.xml?type=${type}&value=${value}";
        if ($method eq 'post') {
            $filter = Net::Gnip::Filter->_create_rule({ type => $type, value => $value })->toString(1);
        }
    } else {
        $url .= ".xml";
    }
    return $self->$method($url, $filter);
}


=head2 publishers

Gets a list of publishers on the system

=cut
sub publishers {
   my ($self) = @_;

   my $url = $self->GNIP_BASE_URL."/publishers.xml";

   my $xml = $self->get($url) || return;
   return map { $_->name } Net::Gnip::PublisherStream->parse($xml)->publishers;
}



=head2 create_publisher <publisher[s]>

Takes one or more C<Net::Gnip::Publisher> objects and creates them.

Returns 1 on success and undef on failure (and sets C<$@>)

=cut
sub create_publisher {
   my $self   = shift;
   my $name   = shift;
   my $stream = Net::Gnip::PublisherStream->new(children => [ @_ ] );
   my $url = $self->GNIP_BASE_URL."/publishers.xml";
   return $self->post($url, $stream);

}

=head2 get <url>

Does an HTTP GET request of the passed in C<url>, and returns 
the result from the server.

Returns undef on failure (and sets C<$@>)

=cut

sub get {
   my $self = shift;
   return $self->_do_http('GET', @_);
}

=head2 post <url> <data object>

Does a HTTP POST request of the passed in url and data object, and returns 
the result from the server.

Returns undef on failure (and sets C<$@>)

=cut

sub post {
    my $self = shift;
    return $self->_do_http('POST', @_);
}

sub _do_http {
    my $self = shift;
    my $type = shift;
    my $url  = shift;
    my $response = $self->_do_request(1, $type, $url, @_);
    # Check the outcome of the response
    if ($response->is_success) {
        return $response->content;
    } else {
        $@ = "Failed to $type $url ".$response->status_line."\n\n".$response->as_string;
        return;
    }
}

sub _do_request {
    my $self = shift;
    my ($auth, $type, $url, $data) = @_;
    my $agent = $self->{_agent} ||= LWP::UserAgent->new;
    # Load proxy settings from *_proxy environment variables
    $agent->env_proxy;
    $agent->agent(__PACKAGE__."-".$VERSION);
    my $request = HTTP::Request->new($type => $url);
    $request->authorization_basic($self->{_username}, $self->{_password}) if $auth;
    if (defined $data) {
        $request->content_type('application/xml');
        $request->content((ref $data)?$data->as_xml:$data);
    }
    return $agent->request($request);
}


=head2 put <url> <data>

Does an HTTP PUT request of the passed in url and data object, and returns
the result from the server.

Returns undef on failure (and sets C<$@>)

=cut

sub put {
   my $self = shift;
   return $self->_do_http('PUT', @_)
}

=head2 delete <url>

Does a HTTP Delete request of the passed in url and returns
the result from the server.

Returns undef on failure (and sets C<$@>)

=cut

sub delete {
   my $self = shift;
   return $self->_do_http('DELETE', @_)
}

=head2 round_time_to_nearest_bucket <datetime>

Rounds the time passed in down to the previous 1 minute mark.

Returns a new C<DateTime> object.

=cut

sub round_time_to_nearest_bucket {
   my $self     = shift;
   my $datetime = shift->clone;

   my $min = $datetime->minute();
   my $new = $min - ($min % 1);

   $datetime->set(minute => $new);
   $datetime->set(second => 0);

   return $datetime;
}

=head2 sync_with_gnip_clock <datetime>

This method gets the current time from the Gnip server.

Returns a new C<DateTime> object.

=cut

sub sync_with_gnip_clock {
    my $self = shift;

    my $response   = $self->_do_request(0, 'HEAD', GNIP_BASE_URL);
    my $formatter  = DateTime::Format::Strptime->new( pattern => '%a, %d %b %Y %H:%M:%S %Z' );
    my $gnip_time  = $formatter->parse_datetime($response->header('Date'));
    return $gnip_time;
}

=head2 time_to_string <datetime>

Converts the time passed in to a string of the form YYYYMMDDHHMM.

=cut

sub time_to_string {
   my ($self, $datetime) = @_;
   return $datetime->strftime("%Y%m%d%H%M");
}

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

Based on code by ajackson from http://github.com/gnip/gnip-perl/tree/master

=head1 COPYRIGHT

Copyright 2008, Simon Wistow

Release under the same terms as Perl itself.

=cut
1;

