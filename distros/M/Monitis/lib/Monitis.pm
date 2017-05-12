package Monitis;

use warnings;
use strict;

use LWP::UserAgent;
use HTTP::Request;
use HTTP::Headers;
use HTTP::Request::Common;

use Digest::SHA 'hmac_sha1_base64';
use JSON;

our $VERSION = '0.9';

use constant DEBUG => $ENV{MONITIS_DEBUG} || 0;

require Carp;

our $TOKEN_TTL = $ENV{MONITIS_TOKEN_TTL} || 60 * 60 * 24;    # 24 hours
my $API_VERSION = 2;

our $MAPPING = {
    sub_accounts            => 'SubAccounts',
    layout                  => 'Layout',
    contacts                => 'Contacts',
    predefined_monitors     => 'PredefinedMonitors',
    external_monitors       => 'ExternalMonitors',
    internal_monitors       => 'InternalMonitors',
    agents                  => 'Agents',
    cpu                     => 'CPU',
    memory                  => 'Memory',
    drive                   => 'Drive',
    process                 => 'Process',
    load_average            => 'LoadAverage',
    http                    => 'HTTP',
    ping                    => 'Ping',
    transaction_monitors    => 'TransactionMonitors',
    custom_monitors         => 'CustomMonitors',
    full_page_load_monitors => 'FullPageLoadMonitors',
    visitor_trackers        => 'VisitorTrackers',
    cloud_instances         => 'CloudInstances'
};

our $MAPPING_LOADED = {};

sub new {
    my $class = shift;
    my $self  = {@_};

    $self->{ua} ||= LWP::UserAgent->new(agent => "perl-monitis-api/$VERSION");

    $self->{json} ||= JSON->new;

    bless $self, $class;
}

sub auth_token {
    my ($self, $token, $expires) = @_;

    # Set
    if ($token && ref $token ne 'CODE') {
        $self->{auth_token} = $token;
        $self->{auth_token_expires} = $expires || $self->token_ttl + time;
        return $self;
    }

    my $callback = ref $token eq 'CODE' ? $token : undef;

    # Cached token
    if ($self->{auth_token} && $self->{auth_token_expires} > time) {
        return $callback->($self, $self->{auth_token}) if $callback;
        return $self->{auth_token};
    }

    # Token expired
    delete $self->{auth_token};
    delete $self->{auth_token_expires};

    unless ($self->api_key && $self->secret_key) {
        Carp::croak("API key and Secret key required for this action");
    }

    my $uri = URI->new($self->api_url);

    $uri->query_form(
        action    => 'authToken',
        output    => 'json',
        version   => $API_VERSION,
        secretkey => $self->secret_key,
        apikey    => $self->api_key
    );

    my $response = $self->ua->get($uri);

    unless ($response->is_success) {
        die "Failed to get auth token: " . $response->status_line;
    }

    my $result = $self->json->decode($response->decoded_content);

    unless ($result || exists $result->{authToken}) {
        die "Failed to get auth token, wrong response:\n"
          . $response->decoded_content . "\n";
    }

    #Success
    $self->auth_token($result->{authToken});

    $result->{authToken};
}

sub api_get {
    my $self    = shift;
    my $request = $self->build_get_request(@_);

    warn "GET>\n" if DEBUG;
    warn $request->as_string if DEBUG;

    my $response = $self->ua->request($request);

    warn "GET<\n" if DEBUG;
    warn $response->decoded_content if DEBUG;

    $self->parse_response($response);

}

sub api_post {
    my $self    = shift;
    my $request = $self->build_post_request(@_);

    warn "POST>\n" if DEBUG;
    warn $request->as_string if DEBUG;

    my $response = $self->ua->request($request);

    warn "POST<\n" if DEBUG;
    warn $response->decoded_content if DEBUG;

    $self->parse_response($response);
}

sub parse_response {
    my ($self, $res) = @_;

    my $obj = $self->json->decode($res->decoded_content);

    Carp::croak("Wrong responce: " . $res->decoded_content) unless $obj;

    $obj;
}

sub build_get_request {
    my ($self, $action, $params) = @_;
    $params ||= [];

    unless ($self->api_key) {
        Carp::croak("API key and Secret key required for this action");
    }

    my @auth = (
        apikey  => $self->api_key,
        output  => 'JSON',
        version => $API_VERSION,
    );
    my $url = URI->new($self->api_url);
    $url->query_form(@$params, @auth, action => $action);

    HTTP::Request::Common::GET($url);
}

sub build_post_request {
    my ($self, $action, $params) = @_;
    $params ||= [];

    unless ($self->api_key && $self->secret_key) {
        Carp::croak("API key and Secret key required for this action");
    }

    my ($sec, $min, $hour, $mday, $mon, $year, $wday) = localtime(time);
    my $timestamp = sprintf "%4d-%02d-%02d %02d:%02d:%02d",
      $year + 1900, $mon + 1, $mday, $hour, $min, $sec;

    my @auth = (
        apikey     => $self->api_key,
        validation => 'HMACSHA1',
        output     => 'JSON',
        version    => $API_VERSION,
        timestamp  => $timestamp
    );

    my @final_params = (@$params, @auth, 'action' => $action);

    push @final_params, checksum => $self->checksum(\@final_params);

    HTTP::Request::Common::POST($self->api_url => \@final_params);
}

sub checksum {
    my ($self, $parameters) = @_;

    Carp::croak("Monitis secret key required for checksum generation")
      unless $self->secret_key;

    my @sorted_params;

    for (my $i = 0; $i <= $#$parameters; $i += 2) {
        push @sorted_params, [@{$parameters}[$i, $i + 1]];
    }

    @sorted_params =
      sort { $a->[0] cmp $b->[0] or $a->[1] cmp $b->[1] } @sorted_params;

    my $validation_string = join '', map { $_->[0] . $_->[1] } @sorted_params;

    my $checksum = hmac_sha1_base64 $validation_string, $self->secret_key;

    $checksum .= '=' while length($checksum) % 4;

    $checksum;
}

sub api_url {
    my $self   = shift;
    my $typeof = ref($self) ? $self->{_typeof} || '' : '';
    my $class  = ref($self) || $self;

    return 'http://monitis.com/api' unless $typeof;
    return 'http://monitis.com/api' if $class eq $typeof;

    return 'http://monitis.com/api' unless $typeof->can('api_url');

    # Mapped class has own API url
    return $typeof->api_url;
}

sub DESTROY {

# Placeholder for AUTOLOAD

}

sub AUTOLOAD {
    my $self = shift;
    my ($package, $method) = our $AUTOLOAD =~ /^([\w\:]+)\:\:(\w+)$/;

    # Map instance to certain package
    if (exists $MAPPING->{$method}) {
        return $self->_map_to($MAPPING->{$method});
    }

    unless ($self->{_typeof} && $self->{_typeof}->can($method)) {
        Carp::croak qq/Can't locate object method "$method" via "$package"/;
    }

    # Get mapped package method
    no strict 'refs';
    my $package_method = \&{"$self->{_typeof}::$method"};
    use strict;

    # Unmap instance
    my $typeof = delete $self->{_typeof};
    local $self->{_typeof} = $typeof;

    $self->$package_method(@_);
}

sub ua {
    my $self = shift;

    return $self->{ua} unless @_;

    $self->{ua} = shift;
    $self;
}

sub json {
    my $self = shift;

    return $self->{json} unless @_;

    $self->{json} = shift;
    $self;
}

sub token_ttl {
    my $self = shift;

    return $self->{token_ttl} || $TOKEN_TTL unless @_;

    $self->{token_ttl} = shift;
    $self;
}

sub _map_to {
    my ($self, $package) = @_;

    $self->{_typeof} = "Monitis::$package";

    if (!$MAPPING_LOADED->{$package}) {

        # TODO: Make pretty warning
        eval "require $self->{_typeof};";
        if ($@) {
            delete $self->{_typeof};
            $MAPPING_LOADED->{$package} = -1;
            Carp::croak($@);
        }
        $MAPPING_LOADED->{$package} = 1;
    }
    elsif ($MAPPING_LOADED->{$package} < 0) {
        my $error = delete $self->{_typeof};
        Carp::croak("Package '$error' contains errors");
    }

    $self;
}

sub context {
    my $self = shift;

    return $self->{_typeof} unless @_;

    $self->{_typeof} = shift;
    $self;
}

sub api_key {
    my $self = shift;

    return $self->{api_key} unless @_;

    $self->{api_key} = shift;
    $self;
}

sub secret_key {
    my $self = shift;

    return $self->{secret_key} unless @_;

    $self->{secret_key} = shift;
    $self;
}

sub prepare_params {
    my ($self, $params, $mandatory, $optional) = @_;

    $mandatory ||= [];
    $optional  ||= [];

    my %existing_keys;

    # Save callback, if provided
    my $callback = ref $params->[-1] eq 'CODE' ? pop @$params : undef;

    for (my $i = 0; $i <= $#$params; $i += 2) {
        $existing_keys{$params->[$i]} = 1;
    }

    my @lack = grep !exists $existing_keys{$_}, @$mandatory;
    if (@lack) {
        Carp::croak("Missing mandatory parameters: " . join(', ', @lack));
    }

    my %param_keys = map { $_ => 1 } @$mandatory, @$optional;
    my @final_params;


    my @extra;
    for (my $i = 0; $i <= $#$params; $i += 2) {
        unless (exists $param_keys{$params->[$i]}) {
            push @extra, $params->[$i];
        }
        push @final_params, @{$params}[$i, $i + 1];
    }

    if (@extra) {
        Carp::carp("Unexpected parameters: " . join(', ', @extra));
    }

    push @final_params, $callback if $callback;

    return \@final_params;
}

1;

__END__

=head1 NAME

Monitis - Monitis.com API Perl interface


=head1 VERSION

This document describes Monitis version 0.8_3


=head1 SYNOPSIS

    use Monitis;

    my $api =
      Monitis->new(sekret_key => $SECRET_KEY, api_key => $API_KEY);

    # Create subaccount, see Monitis::SubAccounts
    my $response = $api->sub_accounts->add(
        firstName => 'John',
        lastName  => 'Smith',
        email     => 'john@smith.com',
        password  => '****',
        group     => 'test user'
    );

    die "Failed to create account: $response->{status}"
      unless $response->{status} eq 'ok';

    # Add memory monitor, see Monitis::Memory
    $response = $api->memory->add(
        agentkey      => 'test-agent',
        name          => 'memory_monitor',
        tag           => 'test_from_api',
        platform      => 'LINUX',
        freeLimit     => 100,
        freeSwapLimit => 500,
        bufferedLimit => 500,
        cachedLimit   => 500
    );

    die "Failed to create memory monitor: $response->{status}"
      unless $response->{status} eq 'ok';


=head1 DESCRIPTION

This library provides interface to Monitis.com API

=head1 ATTRIBUTES

L<Monitis> implements following attributes:


=head2 api_url

Monitis API URL. May vary for different calls.
See 'API URL' section of  corresponding API manual.

=head2 ua

UserAgent that L<Monitis> uses as transport.

=head2 json

JSON decoder.

=head2 api_key

Monitis API key.

=head2 secret_key

Monitis API secret.

=head2 auth_token

Monitis API auth_token.

Read/write. If no token set, but secret_key and api_key are set,
L<Monitis> try to get auth_token from Monitis API.

auth_token auto-updates token, when it expires (after 24 hours).

=head2 token_ttl

Auth token time-to-live in seconds. 24 hours by default.

=head2 context

Context of execution

=head1 METHODS

L<Monitis> implements following methods:


=head2 new

    my $monitis = Monitis->new(sekret_key => '***', api_key => '***');

Construct a new L<Monitis> instance.

=head2 context methods

=head3 sub_accounts layout contacts predefined_monitors external_monitors

=head3 itnernal_monitors agents cpu memory drive process load_average http ping

=head3 transaction_monitors full_page_load_monitors

=head3 visitor_trackers cloud_instances

This methods switch API context to corresponding section.
There's map of available contexts and corresponding packages:

    sub_accounts            =>    Monitis::SubAccounts
    layout                  =>    Monitis::Layout
    contacts                =>    Monitis::Contacts
    predefined_monitors     =>    Monitis::PredefinedMonitors
    external_monitors       =>    Monitis::ExternalMonitors
    internal_monitors       =>    Monitis::InternalMonitors
    agents                  =>    Monitis::Agents
    cpu                     =>    Monitis::CPU
    memory                  =>    Monitis::Memory
    drive                   =>    Monitis::Drive
    process                 =>    Monitis::Process
    load_average            =>    Monitis::LoadAverage
    http                    =>    Monitis::HTTP
    ping                    =>    Monitis::Ping
    transaction_monitors    =>    Monitis::TransactionMonitors
    custom_monitors         =>    Monitis::CustomMonitors
    full_page_load_monitors =>    Monitis::FullPageLoadMonitors
    visitor_trackers        =>    Monitis::VisitorTrackers
    cloud_instances         =>    Monitis::CloudInstances

Please refer to documentation of corresponding package (see L<SEE ALSO>)
and to Monitis API manual.

=head2 api_get

    my $response =
      $monitis->api_get(actionName => [param1 => 'value', param2 => 'value']);

Executes action at Monitis.com API and returns result.

Returns parsed JSON: array or hash, depending on server response.

Requires api_key to be set.

=head2 api_post

    my $response = $monitis->api_post(
        actionName => [param1 => 'value', param2 => 'value']);

Executes action at Monitis.com API and returns result.

Returns parsed JSON: array or hash, depending on server response.

Requires api_key and secret_key to be set.

=head2 parse_response

    my $json = $monitis->parse_response($response);

Takes one argument: L<HTTP::Response>.

Returns decoded JSON (hashref or arrayref) of response content.

=head2 build_get_request

    my $request = $monitis->build_get_request(
        actionName => [param1 => 'value', param2 => 'value']);

Prepares HTTP GET request to Monitis API with provided parameters.

Returns HTTP::Request object.

=head2 build_post_request

    my $request = $monitis->build_post_request(
        actionName => [param1 => 'value', param2 => 'value']);

Prepares HTTP POST request to Monitis API with provided parameters.

Returns HTTP::Request object.

=head2 prepare_params

    my $params = $monitis->prepare_params(\@params, \@mandatory, \@optional);
    my $params = $monitis->prepare_params(\@params, \@mandatory);

Checks for mandatory and removes wrong parameters.

Returns arrayref.

=head2 checksum

    my $checksum = $monitis->checksum(\@params);
    my $checksum =
      $monitis->checksum([param1 => 'value1', param2 => 'value2']);

Produces checksum of list of parameters.

Requires api_secret to be set.

=head1 SEE ALSO

L<Monitis::SubAccounts> L<Monitis::Layout>
L<Monitis::Contacts> L<Monitis::PredefinedMonitors>
L<Monitis::ExternalMonitors> L<Monitis::InternalMonitors>
L<Monitis::Agents> L<Monitis::CPU> L<Monitis::Memory>
L<Monitis::Drive> L<Monitis::Process>
L<Monitis::LoadAverage> L<Monitis::HTTP>
L<Monitis::Ping>
L<Monitis::TransactionMonitors> L<Monitis::FullPageLoadMonitors>
L<Monitis::VisitorTrackers> L<Monitis::CloudInstanses>
L<Monitis::CustomMonitors>

Official API page: L<http://monitis.com/api/api.html>


=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests at Github
L<https://github.com/monitisexchange/Perl-SDK/issues>.


=head1 AUTHORS

Yaroslav Korshak  C<< <yko@cpan.org> >>

Alexandr Babenko  C<< <foxcool@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (C) 2006-2011, Monitis Inc.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


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
