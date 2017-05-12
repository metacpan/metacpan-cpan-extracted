package Sailthru::Client;

use strict;
use warnings;

use Carp;
use JSON::XS;
use LWP::UserAgent;
use Digest::MD5 qw( md5_hex );
use Params::Validate qw( :all );
use Readonly;
use URI;

our $VERSION = '2.3.0';
Readonly my $API_URI => 'https://api.sailthru.com/';

#
# public api
#

# args:
#
# * api_key - scalar
# * secret - scalar
# * timeout - scalar (optional)
sub new {
    my ( $class, $api_key, $secret, $timeout ) = @_;
    my $self = {
        api_key => $api_key,
        secret  => $secret,
        ua      => LWP::UserAgent->new,
        last_rate_limit_info_ref => {}
    };
    $self->{ua}->timeout($timeout) if $timeout;
    $self->{ua}->default_header( 'User-Agent' => "Sailthru API Perl Client $VERSION" );
    return bless $self, $class;
}

# args:
#
# * template_name - scalar
# * email - scalar
# * vars - hashref (optional)
# * options - hashref (optional)
# * schedule_time - scalar (optional)
sub send {
    my $self   = shift;
    my @params = validate_pos(
        @_,
        { type => SCALAR },
        { type => SCALAR },
        { type => HASHREF, default => {} },
        { type => HASHREF, default => {} },
        { type => SCALAR, default => undef }
    );
    my ( $template_name, $email, $vars, $options, $schedule_time ) = @params;
    my $data = {};
    $data->{template}      = $template_name;
    $data->{email}         = $email;
    $data->{vars}          = $vars if keys %{$vars};
    $data->{options}       = $options if keys %{$options};
    $data->{schedule_time} = $schedule_time if $schedule_time;
    return $self->api_post( 'send', $data );
}

# args:
# * send_id - scalar
sub get_send {
    my $self      = shift;
    my @params    = validate_pos( @_, { type => SCALAR } );
    my ($send_id) = @params;
    return $self->api_get( 'send', { send_id => $send_id } );
}

# args:
# * email - scalar
sub get_email {
    my $self    = shift;
    my @params  = validate_pos( @_, { type => SCALAR } );
    my ($email) = @params;
    return $self->api_get( 'email', { email => $email } );
}

# args:
# * email - scalar
# * vars - hashref (optional)
# * lists - hashref (optional)
# * templates - hashref (optional)
sub set_email {
    my $self   = shift;
    my @params = validate_pos(
        @_,
        { type => SCALAR },
        { type => HASHREF, default => {} },
        { type => HASHREF, default => {} },
        { type => HASHREF, default => {} }
    );
    my ( $email, $vars, $lists, $templates ) = @params;
    my $data = {};
    $data->{email}     = $email;
    $data->{vars}      = $vars if keys %{$vars};
    $data->{lists}     = $lists if keys %{$lists};
    $data->{templates} = $templates if keys %{$templates};
    return $self->api_post( 'email', $data );
}

# args:
# * name - scalar
# * list - scalar
# * schedule_time - scalar
# * from_name - scalar
# * from_email - scalar
# * subject - scalar
# * content_html - scalar
# * content_text - scalar
# * options - hashref (optional)
sub schedule_blast {
    my $self   = shift;
    my @params = validate_pos(
        @_,
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => HASHREF, default => {} }
    );
    my ( $name, $list, $schedule_time, $from_name, $from_email, $subject, $content_html, $content_text, $options ) =
      @params;
    # initialize our data hash by copying the contents of the options hash
    my $data = { %{$options} };
    $data->{name}          = $name;
    $data->{list}          = $list;
    $data->{schedule_time} = $schedule_time;
    $data->{from_name}     = $from_name;
    $data->{from_email}    = $from_email;
    $data->{subject}       = $subject;
    $data->{content_html}  = $content_html;
    $data->{content_text}  = $content_text;
    return $self->api_post( 'blast', $data );
}

# args:
# * template_name - scalar
# * list - scalar
# * schedule_time - scalar
# * options - hashref (optional)
sub schedule_blast_from_template {
    my $self   = shift;
    my @params = validate_pos(
        @_,
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => HASHREF, default => {} },
    );
    my ( $template_name, $list, $schedule_time, $options ) = @params;
    # initialize our data hash by copying the contents of the options hash
    my $data = { %{$options} };
    $data->{copy_template} = $template_name;
    $data->{list}          = $list;
    $data->{schedule_time} = $schedule_time;
    return $self->api_post( 'blast', $data );

}

# args:
# * blast_id - scalar
sub get_blast {
    my $self       = shift;
    my @params     = validate_pos( @_, { type => SCALAR } );
    my ($blast_id) = @params;
    return $self->api_get( 'blast', { blast_id => $blast_id } );
}

# args:
# * template_name - scalar
sub get_template {
    my $self            = shift;
    my @params          = validate_pos( @_, { type => SCALAR } );
    my ($template_name) = @params;
    return $self->api_get( 'template', { template => $template_name } );
}

# args:
# * action - scalar
# * data - hashref
sub api_get {
    my $self = shift;
    my @params = validate_pos( @_, { type => SCALAR }, { type => HASHREF } );
    my ( $action, $data ) = @params;
    return $self->_api_request( $action, $data, 'GET' );
}

# args:
# * action - scalar
# * data - hashref
# * TODO: optional binary_key arg
sub api_post {
    my $self = shift;
    my @params = validate_pos( @_, { type => SCALAR }, { type => HASHREF } );
    my ( $action, $data ) = @params;
    return $self->_api_request( $action, $data, 'POST' );
}

# args:
# * action - scalar
# * data - hashref
sub api_delete {
    my $self = shift;
    my @params = validate_pos( @_, { type => SCALAR }, { type => HASHREF } );
    my ( $action, $data ) = @params;
    return $self->_api_request( $action, $data, 'DELETE' );
}

# args:
#
# * action - scalar
# * method - scalar
sub get_last_rate_limit_info {
    my $self   = shift;
    my @params = validate_pos(
        @_,
        { type => SCALAR },
        { type => SCALAR }
    );
    my ( $action, $method ) = @params;
    $method = uc($method);

    if (exists $self->{last_rate_limit_info_ref}->{$action} and $self->{last_rate_limit_info_ref}->{$action}->{$method}) {
        return $self->{last_rate_limit_info_ref}->{$action}->{$method};
    }

    return;
}

#
# private helper methods
#

# args:
# * action - scalar
# * data - hashref
# * request_type - scalar
sub _api_request {
    my $self = shift;
    my @params = validate_pos( @_, { type => SCALAR }, { type => HASHREF }, { type => SCALAR } );
    my ( $action, $data, $request_type ) = @params;
    my $payload    = $self->_prepare_json_payload($data);
    my $action_uri = $API_URI . $action;
    my $response   = $self->_http_request( $action_uri, $payload, $request_type );

    # update rate limit information
    if ( defined $response->header('x-rate-limit-limit') and
         defined $response->header('x-rate-limit-remaining') and
         defined $response->header('x-rate-limit-reset') ) {
         $self->{last_rate_limit_info_ref}->{$action}->{$request_type} = {
             limit => $response->header('x-rate-limit-limit'),
             remaining => $response->header('x-rate-limit-remaining'),
             reset => $response->header('x-rate-limit-reset')
         };
    }

    return decode_json( $response->content );
}

# args:
# * uri - scalar
# * data - hashref
# * method - scalar
sub _http_request {
    my $self = shift;
    my @params = validate_pos( @_, { type => SCALAR }, { type => HASHREF }, { type => SCALAR } );
    my ( $uri, $data, $method ) = @params;
    $uri = URI->new($uri);
    my $response;
    if ( $method eq 'GET' ) {
        $uri->query_form($data);
        $response = $self->{ua}->get($uri);
    }
    elsif ( $method eq 'POST' ) {
        $response = $self->{ua}->post( $uri, $data );
    }
    elsif ( $method eq 'DELETE' ) {
        $uri->query_form($data);
        $response = $self->{ua}->delete($uri);
    }
    else {
        croak "Invalid method: $method";
    }
    return $response;
}

# args:
# * data - hashref
sub _prepare_json_payload {
    my $self    = shift;
    my @params  = validate_pos( @_, { type => HASHREF } );
    my ($data)  = @params;
    my $payload = {};
    $payload->{api_key} = $self->{api_key};
    $payload->{format}  = 'json';
    # this gives us nice clean utf8 encoded json text
    $payload->{json} = encode_json($data);
    $payload->{sig} = $self->_get_signature_hash( $payload, $self->{secret} );
    return $payload;
}

# Every request must also generate a signature hash called sig according to the
# following rules:
#
# * take the string values of every parameter, including api_key
# * sort the values alphabetically, case-sensitively (i.e. ordered by Unicode code point)
# * concatenate the sorted values, and prepend this string with your shared secret
# * generate an MD5 hash of this string and use this as sig
# * now generate your URL-encoded query string from your parameters plus sig

# args:
# * params - hashref
# * secret - scalar
# NOTE This internal method assumes a single level hash with values for only 'api_key', 'format', and 'json'
# NOTE Since we pack everything into the 'json' value this is safe and we do not need to recurse down a nested hash.
sub _get_signature_hash {
    my $self = shift;
    my @params = validate_pos( @_, { type => HASHREF }, { type => SCALAR } );
    my ( $api_param_hash, $secret ) = @params;
    my @api_param_values = values %{$api_param_hash};
    my $sig_string = join '', $secret, sort @api_param_values;
    # assumes utf8 encoded text, works fine because we use encode_json internally
    return md5_hex($sig_string);
}

### XXX
### DEPRECATED METHODS
### XXX

# args:
# * email - scalar
sub getEmail {
    my $self = shift;
    warnings::warnif( 'deprecated', 'getEmail is deprecated, use get_email instead' );
    return $self->get_email(@_);
}

# args:
# * email - scalar
# * vars - hashref (optional)
# * lists - hashref (optional)
# * templates - hashref (optional)
sub setEmail {
    my $self = shift;
    warnings::warnif( 'deprecated', 'setEmail is deprecated, use set_email instead' );
    return $self->set_email(@_);
}

# args:
# * send_id - scalar
sub getSend {
    my $self = shift;
    warnings::warnif( 'deprecated', 'getSend is deprecated, use get_send instead' );
    return $self->get_send(@_);
}

# args:
# * name - scalar
# * list - scalar
# * schedule_time - scalar
# * from_name - scalar
# * from_email - scalar
# * subject - scalar
# * content_html - scalar
# * content_text - scalar
# * options - hashref (optional)
sub scheduleBlast {
    my $self = shift;
    warnings::warnif( 'deprecated', 'scheduleBlast is deprecated, use schedule_blast instead' );
    return $self->schedule_blast(@_);
}

# args:
# * blast_id - scalar
sub getBlast {
    my $self = shift;
    warnings::warnif( 'deprecated', 'getBlast is deprecated, use get_blast instead' );
    return $self->get_blast(@_);
}

sub copyTemplate {
    my $self   = shift;
    my @params = validate_pos(
        @_,
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR },
        { type => HASHREF, default => {} }
    );
    my ( $template, $data_feed, $setup, $subject_line, $schedule_time, $list, $options ) = @params;
    warnings::warnif( 'deprecated', 'copyTemplate is deprecated, use schedule_blast_from_template instead' );
    # initialize our data hash by copying the contents of the options hash
    my $data = { %{$options} };
    $data->{copy_template} = $template;
    $data->{data_feed_url} = $data_feed;
    $data->{setup}         = $setup;
    $data->{name}          = $subject_line;
    $data->{schedule_time} = $schedule_time;
    $data->{list}          = $list;
    return $self->api_post( 'blast', $data );
}

# args:
# * template_name - scalar
sub getTemplate {
    my $self = shift;
    warnings::warnif( 'deprecated', 'getTemplate is deprecated, use get_template instead' );
    return $self->get_template(@_);
}

# args:
# * email - scalar
# * password - scalar
# * include_names - scalar (optional)
sub importContacts {
    my $self = shift;
    my @p = validate_pos( @_, { type => SCALAR }, { type => SCALAR }, { type => SCALAR, default => 0 } );
    my ( $email, $password, $include_names ) = @p;
    warnings::warnif( 'deprecated',
        'importContacts is deprecated. The contacts API has been discontinued as of August 1st, 2011.' );
    my $data = {
        email         => $email,
        password      => $password,
        include_names => $include_names,
    };
    return $self->api_post( 'contacts', $data );
}

1;

__END__

=head1 NAME

Sailthru::Client - Perl module for accessing Sailthru's API

=head1 SYNOPSIS

    use Sailthru::Client;

    # instantiate a new Sailthru::Client with an api_key and secret
    $sc = Sailthru::Client->new('api_key', 'secret');

    # send an email to a single email address
    %vars = (
       name => "Joe Example",
       from_email => "approved_email@your_domain.com",
       your_variable => "some_value"
    );
    %options = ( reply_to => "your reply_to header");
    $sc->send('template_name', 'example@example.com', \%vars, \%options);

=head1 DESCRIPTION

Sailthru::Client is a Perl module for accessing the Sailthru API.

Methods return a reference to a hash containing the response values. Dump the
hash or read the Sailthru API documentation for which values are returned
by which API calls.

L<http://docs.sailthru.com/api>

Some options might change. Consult the Sailthru API documentation for
the latest information.

=head1 METHODS

=head2 Sailthru::Client->new( $api_key, $secret, [$timeout] )

Returns a new Sailthru::Client object.

=over

=item $api_key

Sailthru API key.

=item $secret

Sailthru API secret.

=item $timeout

Optional network timeout in seconds.

=back

=head2 $sc->send( $template_name, $email, [\%vars, \%options, $schedule_time] )

Remotely send an email template to a single email address.

API docs: L<http://docs.sailthru.com/api/send>

=over

=item $template_name

The name of the template to send.

=item $email

The email address to send to.

=item \%vars

An optional hashref of the replacement vars to use in the send. Each var may be referenced as {varname} within the template itself.

=item \%options

An optional hashref to include a replyto header, test keys, etc. See the API documentation for details.

=item $schedule_time

Do not send the email immediately, but at some point in the future. Any date recognized by PHP's strtotime function is valid, but be sure to specify timezone or use a UTC time to avoid confusion. You may also use relative time.

=back

=head2 $sc->get_send( $send_id )

Get the status of a send.

API docs: L<http://docs.sailthru.com/api/send>

=over

=item $send_id

The unique identifier of the send returned in the response from C<$sc-E<gt>send()>.

=back

=head2 $sc->get_email( $email )

Get information about a user.

API docs: L<http://docs.sailthru.com/api/email>

=over

=item $email

The email address to look up.

=back

=head2 $sc->set_email( $email, [\%vars, \%lists, \%templates] )

Update information about a user, including adding and removing the user from lists.

API docs: L<http://docs.sailthru.com/api/email>

=over

=item $email

The email address to modify.

=item \%vars

An optional hashref of replacement variables you want to set or a JSON string

=item \%lists

An optional hashref. Each key is the name of a list and each value is
1 to subscribe the user to that list or 0 to remove the user from the list.

=item \%templates

An optional hashref. Each key is the name of a template, and each value is 1 to
opt the user back in to template delivery or 0 to opt the user out of template
delivery.

=back

=head2 $sc->schedule_blast( $name, $list, $schedule_time, $from_name, $from_email, $subject, $content_html, $content_text, [\%options] )

Schedule a mass mail blast.

API docs: L<http://docs.sailthru.com/api/blast>

=over

=item $name

The name to give to this new blast.

=item $list

The mailing list name to send to.

=item $schedule_time

When the blast should send. Dates in the past will be scheduled for immediate
delivery. Any English textual datetime format known to PHP's strtotime function
is acceptable, such as 2012-03-18 23:57:22 UTC, now (immediate delivery), +3
hours (3 hours from now), or March 18, 9:30 EST. Be sure to specify a timezone
if you use an exact time.

=item $from_name

The name to use in "From" in the email.

=item $from_email

The email address to use in "From". Choose from any of your verified emails.

=item $subject

The subject line of the email.

=item $content_html

The HTML format version of the email.

=item $content_text

The text format version of the email.

=item \%options

An optional hashref containing the optional parameters for a blast. See the API documentation for details.

=back

=head2 $sc->schedule_blast_from_template( $template_name, $list, $schedule_time, [\%options] )

Schedule a mass mail blast from a template.

API docs: L<http://docs.sailthru.com/api/blast>

=over

=item $template_name

The template to copy from.

=item $list

The mailing list name to send to.

=item $schedule_time

When the blast should send. Dates in the past will be scheduled for immediate
delivery. Any English textual datetime format known to PHP's strtotime function
is acceptable, such as 2012-03-18 23:57:22 UTC, now (immediate delivery), +3
hours (3 hours from now), or March 18, 9:30 EST. Be sure to specify a timezone
if you use an exact time.

=item \%options

An optional hashref containing the optional parameters for a blast. See the API documentation for details.

=back

=head2 $sc->get_blast( $blast_id )

Get data on a single blast.

API docs: L<http://docs.sailthru.com/api/blast>

=over

=item $blast_id

The blast id returned in the response from C<$sc-E<gt>scheduleBlast()>.

=back

=head2 $sc->get_template( $template_name )

Get information about a template

API docs: L<http://docs.sailthru.com/api/template>

=over

=item $template_name

The name of the template.

=back

=head2 $sc->api_get( $action, \%data )

This is a generic HTTP GET call to the API.

=over

=item $action

The name of the API action to call.

=item \%data

A hashref of arguments to pass to the API.

=back

For example, you could get information about an email with

 $sc->api_get('GET', 'email', {email=>'somebody@example.com'});

=head2 $sc->api_post( $action, \%data )

This is a generic HTTP POST call to the API.

=over

=item $action

The name of the API action to call.

=item \%data

A hashref of arguments to pass to the API.

=back

=head2 $sc->api_delete( $action, \%data )

This is a generic HTTP DELETE call to the API.

=over

=item $action

The name of the API action to call.

=item \%data

A hashref of arguments to pass to the API.

=back

=head2 $sc->get_last_rate_limit_info( $action, $method )

Get the last rate limit information .

=over

=item $action

The name of the API action to call.

=item $method

Http request type. One of GET, POST or DELETE.

=item return

Hash reference with three fields (limit, remaining and reset) or undef if not exists.

=back

=head1 SEE ALSO

See the Sailthru API documentation for more details on their API.

L<http://docs.sailthru.com/api>

=head1 AUTHOR

Finn Smith

Steve Sanbeg

Steve Miketa

Sam Gerstenzang

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 by Finn Smith <finn@timeghost.net>

Copyright (C) 2012 by Steve Sanbeg <stevesanbeg@buzzfeed.com>

Copyright (C) 2011 by Steve Miketa <steve@sailthru.com>

Adapted from the original Sailthru::Client & Triggermail modules created by Sam
Gerstenzang and Steve Miketa.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself, either Perl version 5.10.0 or, at your option,
any later version of Perl 5 you may have available.

=cut
