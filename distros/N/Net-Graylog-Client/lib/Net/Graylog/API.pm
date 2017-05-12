
# ABSTRACT: API Client for Net::Graylog::API


# I am assuming you are using Dist::Zilla and have set [PkgVersion] in yout dist.ini
# to create the $Net::Graylog::API::VERSION variable

package Net::Graylog::API;
{
  $Net::Graylog::API::VERSION = '0.3';
}

use 5.16.0;
use strict;
use warnings;
use Furl;
use JSON;
use Moo;
use URI::Escape::XS qw/uri_escape/;
use Data::Printer;
use namespace::clean;

# -----------------------------------------------------------------------------



my %SearchResponse = (
    built_query => 'string',
    error       => {
        begin_column => 'integer',
        begin_line   => 'integer',
        end_column   => 'integer',
        end_line     => 'integer',
    },
    fields        => [ type => 'string', ],
    generic_error => {
        exception_name => 'string',
        message        => 'string',
    },
    messages => [
        properties => {
            index   => 'string',
            message => { additional_properties => 'any', },
        },
    ],
    query         => 'string',
    time          => 'integer',
    total_results => 'integer',
    used_indices  => [ type => 'string', ],
);


my %ReaderPermissionResponse = ( permissions => [ type => 'string', ], );


my %LdapTestConfigResponse = (
    connected            => 'boolean',
    entry                => { additional_properties => 'string', },
    exception            => 'string',
    login_authenticated  => 'boolean',
    system_authenticated => 'boolean',
);


my %LdapTestConfigRequest = (
    active_directory       => 'boolean',
    ldap_uri               => 'string',
    password               => 'string',
    principal              => 'string',
    search_base            => 'string',
    search_pattern         => 'string',
    system_password        => 'string',
    system_username        => 'string',
    test_connect_only      => 'boolean',
    trust_all_certificates => 'boolean',
    use_start_tls          => 'boolean',
);


my %SessionCreateRequest = (
    host     => 'string',
    password => 'string',
    username => 'string',
);


my %Session = (
    session_id  => 'string',
    valid_until => 'string',
);


my %Token = (
    last_access => 'string',
    name        => 'string',
    token       => 'string',
);


my %TokenList = (
    tokens => [
        properties => {
            last_access => 'string',
            name        => 'string',
            token       => 'string',
        },
    ],
);

my %_models = (
    SearchResponse           => \%SearchResponse,
    ReaderPermissionResponse => \%ReaderPermissionResponse,
    LdapTestConfigResponse   => \%LdapTestConfigResponse,
    LdapTestConfigRequest    => \%LdapTestConfigRequest,
    SessionCreateRequest     => \%SessionCreateRequest,
    Session                  => \%Session,
    Token                    => \%Token,
    TokenList                => \%TokenList,
);

# -----------------------------------------------------------------------------


has url => ( is => 'ro', required => 1 );
has user     => ( is => 'ro' );
has password => ( is => 'ro' );
has timeout  => ( is => 'ro', default => sub { 0.01; } );

# we need to set a timeout for the connection as Furl seems to wait
# for this time to elapse before giving us any response. If the default is used
# 180s then this will block for 3 minutes! crazy stuff, so I set it to 0.01
# which would allow me to send 100 messages/sec, which should be OK for my
# purposes especially as my graylog is on the local network
has _furl => (
    is      => 'lazy',
    default => sub {
        my $self = shift;
        return Furl->new(
            agent   => __PACKAGE__,
            headers => [
                'Accept'       => 'application/json',
                'content-type' => 'application/json',
            ],
            timeout => $self->timeout,
        );
    },
    init_arg => undef,
);

# -----------------------------------------------------------------------------
# validate a parameter against known types or the models
# returns an error string if there is an issue
# for the moment I am not going to attempt a full parse of the swagger spec
# https://github.com/wordnik/swagger-spec/blob/master/versions/1.2.md#433-data-type-fields
# just the ones I need for graylog2

sub _validate_parameter {
    my ( $data, $info ) = @_;
    my $response;
    my $type   = lc( $info->{type}   || "" );
    my $format = lc( $info->{format} || "" );

    # not having data is not an issue, the caller should already have checked if it
    # was a required field
    return "" if ( !$data );

    if ( $info->{'$ref'} ) {

        # are we are refering to an element in the data model
        die "Not setup to handle object references yet";
    }

    if ( $type eq 'integer' ) {
        if ( $data !~ /^[0-9]+$/ ) {

            # not checking the format int32/int64
            $response = 'is not an integer';
        }
        elsif ( $info->{maximum} && $data > $info->{maximum} ) {
            $response = "is greater than allowed maximum ($info->{maximum}";
        }
        elsif ( $info->{minimum} && $data < $info->{maximum} ) {
            $response = "is less than allowed minimum ($info->{minimum}";
        }

    }
    elsif ( $type eq 'number' ) {
        if ( $data !~ /^[0-9]{1,}(\.[0-9]{1,})$/ ) {

            # not checking the format float/double
            $response = 'is not a number';
        }
        elsif ( $info->{maximum} && $data > $info->{maximum} ) {
            $response = "is greater than allowed maximum ($info->{maximum}";
        }
        elsif ( $info->{minimum} && $data < $info->{maximum} ) {
            $response = "is less than allowed minimum ($info->{minimum}";
        }
    }
    elsif ( $type eq 'string' ) {

        # we will let most things though as strings, no validation
        if ($format) {
            if ( $format eq 'byte' ) {
                $response = 'is not a byte' if ( $data !~ /^\C$/ );
            }
            elsif ( $format eq 'date' ) {

                # I am not checking if the actual values in the fields make sense
                # allow dd/mm/yy dd/mm/yyyy yyyy/mm/dd xx/xx/xx
                # allow dd-mm-yy dd-mm-yyyy yyyy-mm-dd xx-xx-xx
                $response = 'does not look like a date' if ( m|^\d{2}[-\/]\d{2}[-\/]\d{2,4}$| || m|^\d{4}[-\/]\d{2}[-\/]\d{2}$| );
            }
            elsif ( $format eq 'date-time' ) {

                # assuming something like ISO8601 YYYY-MM-DD HH:mm:SS plus trailing bits
                $response = 'does not look like a datetime' if (m|^\d{2,4}[-\/]\d{2}[-\/]\d{2}[ T]\d{2}:\d{2}:d{2}|);
            }
        }
    }
    elsif ( $type eq 'boolean' ) {
        $response = "is not boolean" if ( $data !~ /true|false|1|0|yes|no/i );
    }
    elsif ( $_models{$type} ) {

        # one of the models, now we need to validate all the fields of it, groan
        die "Not handling models yet";
    }
    else {
        $response = "has unknown type - $info->{type}";
    }

    # prefix with the param name if there was an error
    $response = "$info->{name} $response" if ($response);
    return $response;
}

# -----------------------------------------------------------------------------
# get the url, add in the username and password if they exist
sub _action_url {
    my $self = shift;
    my ( $method, $url, $params, $content ) = @_;

    $url = $self->url . $url;

    # we are only using basic auth nothing fancy like oauth!
    if ( $self->user ) {
        my $auth = $self->user . ':' . $self->password . '@';
        $url =~ s|^(https?://)(.*)|$1$auth$2|;
    }

    if ( keys %{$params} ) {

        # we need to encode the parameters as part of the URL
        $url .= '?';
        foreach my $k ( keys %{$params} ) {
            next if ( !$params->{$k} );
            $url .= ( uri_escape($k) . '=' . uri_escape( $params->{$k} ) . '&' );
        }
    }
    $url =~ s/&$//;

    say STDERR "url [$method] $url" if ( $ENV{DEBUG} );
    my $headers;    #= [ 'Content-type' => ['application/json'] ] ;
    my $res = $self->_furl->request(
        method  => uc($method),
        url     => $url,
        headers => $headers,
        content => $content
    );

    if ( $res->is_success ) {
        my $json = decode_json( $res->content );
        $res->{json} = $json;
    }
    return $res;
}


# -----------------------------------------------------------------------------


sub alerts_list {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/streams/$params{streamId}/alerts";

    my $args = {
        streamId => {
            description => "The stream id this new alert condition belongs to.",
            name        => "streamId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "alerts_list is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to alerts_list ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in alerts_list for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub alerts_check_conditions {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/streams/$params{streamId}/alerts/check";

    my $args = {
        streamId => {
            description => "The ID of the stream to check.",
            name        => "streamId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "alerts_check_conditions is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to alerts_check_conditions ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in alerts_check_conditions for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub alerts_list_conditions {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/streams/$params{streamId}/alerts/conditions";

    my $args = {
        streamId => {
            description => "The stream id this new alert condition belongs to.",
            name        => "streamId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "alerts_list_conditions is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to alerts_list_conditions ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in alerts_list_conditions for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub alerts_create {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/streams/$params{streamId}/alerts/conditions";

    my $args = {
        "JSON body" => {
            description => "",
            name        => "JSON body",
            paramType   => "body",
            required    => 1,
            type        => "String"
        },
        streamId => {
            description => "The stream id this new alert condition belongs to.",
            name        => "streamId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "alerts_create is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to alerts_create ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in alerts_create for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'post', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub delete_alerts_list {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/streams/$params{streamId}/alerts/conditions/$params{conditionId}";

    my $args = {
        conditionId => {
            description => "The stream id this new alert condition belongs to.",
            name        => "conditionId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        },
        streamId => {
            description => "The stream id this new alert condition belongs to.",
            name        => "streamId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "delete_alerts_list is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to delete_alerts_list ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in delete_alerts_list for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'delete', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub alerts_add_receiver {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/streams/$params{streamId}/alerts/receivers";

    my $args = {
        entity => {
            description => "Name/ID of user or email address to add as alert receiver.",
            name        => "entity",
            paramType   => "query",
            required    => 1,
            type        => "String"
        },
        streamId => {
            description => "The stream id this new alert condition belongs to.",
            name        => "streamId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        },
        type => {
            description => "Type: users or emails",
            name        => "type",
            paramType   => "query",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "alerts_add_receiver is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to alerts_add_receiver ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in alerts_add_receiver for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'post', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub alerts_remove_receiver {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/streams/$params{streamId}/alerts/receivers";

    my $args = {
        entity => {
            description => "Name/ID of user or email address to remove from alert receivers.",
            name        => "entity",
            paramType   => "query",
            required    => 1,
            type        => "String"
        },
        streamId => {
            description => "The stream id this new alert condition belongs to.",
            name        => "streamId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        },
        type => {
            description => "Type: users or emails",
            name        => "type",
            paramType   => "query",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "alerts_remove_receiver is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to alerts_remove_receiver ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in alerts_remove_receiver for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'delete', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub alerts_send_dummy_alert {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/streams/$params{streamId}/alerts/sendDummyAlert";

    my $args = {
        streamId => {
            description => "The stream id this new alert condition belongs to.",
            name        => "streamId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "alerts_send_dummy_alert is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to alerts_send_dummy_alert ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in alerts_send_dummy_alert for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}


# -----------------------------------------------------------------------------


sub counts_total {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/count/total";

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}


# -----------------------------------------------------------------------------


sub dashboards_list {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/dashboards";

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub dashboards_create {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/dashboards";

    my $args = {
        "JSON body" => {
            description => "",
            name        => "JSON body",
            paramType   => "body",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "dashboards_create is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to dashboards_create ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in dashboards_create for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'post', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub dashboards_get {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/dashboards/$params{dashboardId}";

    my $args = {
        dashboardId => {
            description => "",
            name        => "dashboardId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "dashboards_get is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to dashboards_get ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in dashboards_get for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub dashboards_delete {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/dashboards/$params{dashboardId}";

    my $args = {
        dashboardId => {
            description => "",
            name        => "dashboardId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "dashboards_delete is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to dashboards_delete ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in dashboards_delete for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'delete', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub dashboards_update {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/dashboards/$params{dashboardId}";

    my $args = {
        "JSON body" => {
            description => "",
            name        => "JSON body",
            paramType   => "body",
            required    => 1,
            type        => "String"
        },
        dashboardId => {
            description => "",
            name        => "dashboardId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "dashboards_update is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to dashboards_update ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in dashboards_update for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'put', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub dashboards_set_positions {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/dashboards/$params{dashboardId}/positions";

    my $args = {
        "JSON body" => {
            description => "",
            name        => "JSON body",
            paramType   => "body",
            required    => 1,
            type        => "String"
        },
        dashboardId => {
            description => "",
            name        => "dashboardId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "dashboards_set_positions is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to dashboards_set_positions ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in dashboards_set_positions for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'put', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub dashboards_add_widget {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/dashboards/$params{dashboardId}/widgets";

    my $args = {
        "JSON body" => {
            description => "",
            name        => "JSON body",
            paramType   => "body",
            required    => 1,
            type        => "String"
        },
        dashboardId => {
            description => "",
            name        => "dashboardId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "dashboards_add_widget is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to dashboards_add_widget ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in dashboards_add_widget for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'post', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub dashboards_remove {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/dashboards/$params{dashboardId}/widgets/$params{widgetId}";

    my $args = {
        dashboardId => {
            description => "",
            name        => "dashboardId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        },
        widgetId => {
            description => "",
            name        => "widgetId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "dashboards_remove is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to dashboards_remove ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in dashboards_remove for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'delete', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub dashboards_update_cache_time {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/dashboards/$params{dashboardId}/widgets/$params{widgetId}/cachetime";

    my $args = {
        "JSON body" => {
            description => "",
            name        => "JSON body",
            paramType   => "body",
            required    => 1,
            type        => "String"
        },
        dashboardId => {
            description => "",
            name        => "dashboardId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        },
        widgetId => {
            description => "",
            name        => "widgetId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "dashboards_update_cache_time is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to dashboards_update_cache_time ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in dashboards_update_cache_time for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'put', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub dashboards_update_description {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/dashboards/$params{dashboardId}/widgets/$params{widgetId}/description";

    my $args = {
        "JSON body" => {
            description => "",
            name        => "JSON body",
            paramType   => "body",
            required    => 1,
            type        => "String"
        },
        dashboardId => {
            description => "",
            name        => "dashboardId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        },
        widgetId => {
            description => "",
            name        => "widgetId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "dashboards_update_description is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to dashboards_update_description ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in dashboards_update_description for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'put', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub dashboards_widget_value {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/dashboards/$params{dashboardId}/widgets/$params{widgetId}/value";

    my $args = {
        dashboardId => {
            description => "",
            name        => "dashboardId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        },
        widgetId => {
            description => "",
            name        => "widgetId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "dashboards_widget_value is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to dashboards_widget_value ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in dashboards_widget_value for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}


# -----------------------------------------------------------------------------


sub documentation_overview {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/api-docs";

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub documentation_route {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/api-docs/$params{route}";

    my $args = {
        route => {
            description => "Route to fetch. For example /system",
            name        => "route",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "documentation_route is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to documentation_route ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in documentation_route for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}


# -----------------------------------------------------------------------------


sub extractors_list {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/inputs/$params{inputId}/extractors";

    my $args = {
        inputId => {
            description => "",
            name        => "inputId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "extractors_list is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to extractors_list ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in extractors_list for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub extractors_create {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/inputs/$params{inputId}/extractors";

    my $args = {
        "JSON body" => {
            description => "",
            name        => "JSON body",
            paramType   => "body",
            required    => 1,
            type        => "String"
        },
        inputId => {
            description => "",
            name        => "inputId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "extractors_create is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to extractors_create ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in extractors_create for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'post', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub extractors_terminate {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/inputs/$params{inputId}/extractors/$params{extractorId}";

    my $args = {
        extractorId => {
            description => "",
            name        => "extractorId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        },
        inputId => {
            description => "",
            name        => "inputId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "extractors_terminate is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to extractors_terminate ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in extractors_terminate for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'delete', $url, \%clean_data, $body );
}


# -----------------------------------------------------------------------------


sub indexer_cluster_cluster_health {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/indexer/cluster/health";

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub indexer_cluster_cluster_name {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/indexer/cluster/name";

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}


# -----------------------------------------------------------------------------


sub indexer_failures_single {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/indexer/failures";

    my $args = {
        limit => {
            description => "Limit",
            name        => "limit",
            paramType   => "query",
            required    => 1,
            type        => "Integer"
        },
        offset => {
            description => "Offset",
            name        => "offset",
            paramType   => "query",
            required    => 1,
            type        => "Integer"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "indexer_failures_single is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to indexer_failures_single ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in indexer_failures_single for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub indexer_failures_count {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/indexer/failures/count";

    my $args = {
        since => {
            description => "ISO8601 date",
            name        => "since",
            paramType   => "query",
            required    => 0,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "indexer_failures_count is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to indexer_failures_count ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in indexer_failures_count for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}


# -----------------------------------------------------------------------------


sub indexer_indices_closed {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/indexer/indices/closed";

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub indexer_indices_single {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/indexer/indices/$params{index}";

    my $args = {
        index => {
            description => "",
            name        => "index",
            paramType   => "path",
            required    => 0,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "indexer_indices_single is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to indexer_indices_single ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in indexer_indices_single for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub indexer_indices_delete {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/indexer/indices/$params{index}";

    my $args = {
        index => {
            description => "",
            name        => "index",
            paramType   => "path",
            required    => 0,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "indexer_indices_delete is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to indexer_indices_delete ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in indexer_indices_delete for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'delete', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub indexer_indices_close {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/indexer/indices/$params{index}/close";

    my $args = {
        index => {
            description => "",
            name        => "index",
            paramType   => "path",
            required    => 0,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "indexer_indices_close is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to indexer_indices_close ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in indexer_indices_close for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'post', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub indexer_indices_reopen {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/indexer/indices/$params{index}/reopen";

    my $args = {
        index => {
            description => "",
            name        => "index",
            paramType   => "path",
            required    => 0,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "indexer_indices_reopen is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to indexer_indices_reopen ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in indexer_indices_reopen for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'post', $url, \%clean_data, $body );
}


# -----------------------------------------------------------------------------


sub messages_analyze {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/messages/$params{index}/analyze";

    my $args = {
        index => {
            description => "The index the message containing the string is stored in.",
            name        => "index",
            paramType   => "path",
            required    => 1,
            type        => "String"
        },
        string => {
            description => "The string to analyze.",
            name        => "string",
            paramType   => "query",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "messages_analyze is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to messages_analyze ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in messages_analyze for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub messages_search {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/messages/$params{index}/$params{messageId}";

    my $args = {
        index => {
            description => "The index this message is stored in.",
            name        => "index",
            paramType   => "path",
            required    => 1,
            type        => "String"
        },
        messageId => {
            description => "",
            name        => "messageId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "messages_search is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to messages_search ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in messages_search for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}


# -----------------------------------------------------------------------------


sub search_absolute_search_absolute {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/search/universal/absolute";

    my $args = {
        filter => {
            description => "Filter",
            name        => "filter",
            paramType   => "query",
            required    => 0,
            type        => "String"
        },
        from => {
            description => "Timerange start. See description for date format",
            name        => "from",
            paramType   => "query",
            required    => 1,
            type        => "String"
        },
        limit => {
            description => "Maximum number of messages to return.",
            name        => "limit",
            paramType   => "query",
            required    => 0,
            type        => "Integer"
        },
        offset => {
            description => "Offset",
            name        => "offset",
            paramType   => "query",
            required    => 0,
            type        => "Integer"
        },
        query => {
            description => "Query (Lucene syntax)",
            name        => "query",
            paramType   => "query",
            required    => 1,
            type        => "String"
        },
        sort => {
            description => "Sorting (field:asc / field:desc)",
            name        => "sort",
            paramType   => "query",
            required    => 0,
            type        => "String"
        },
        to => {
            description => "Timerange end. See description for date format",
            name        => "to",
            paramType   => "query",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "search_absolute_search_absolute is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to search_absolute_search_absolute ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in search_absolute_search_absolute for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub search_absolute_field_histogram_absolute {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/search/universal/absolute/fieldhistogram";

    my $args = {
        field => {
            description => "Field of whose values to get the histogram of",
            name        => "field",
            paramType   => "query",
            required    => 1,
            type        => "String"
        },
        filter => {
            description => "Filter",
            name        => "filter",
            paramType   => "query",
            required    => 0,
            type        => "String"
        },
        from => {
            description => "Timerange start. See search method description for date format",
            name        => "from",
            paramType   => "query",
            required    => 1,
            type        => "String"
        },
        interval => {
            description => "Histogram interval / bucket size. (year, quarter, month, week, day, hour or minute)",
            name        => "interval",
            paramType   => "query",
            required    => 1,
            type        => "String"
        },
        query => {
            description => "Query (Lucene syntax)",
            name        => "query",
            paramType   => "query",
            required    => 1,
            type        => "String"
        },
        to => {
            description => "Timerange end. See search method description for date format",
            name        => "to",
            paramType   => "query",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "search_absolute_field_histogram_absolute is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to search_absolute_field_histogram_absolute ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in search_absolute_field_histogram_absolute for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub search_absolute_histogram_absolute {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/search/universal/absolute/histogram";

    my $args = {
        filter => {
            description => "Filter",
            name        => "filter",
            paramType   => "query",
            required    => 0,
            type        => "String"
        },
        from => {
            description => "Timerange start. See search method description for date format",
            name        => "from",
            paramType   => "query",
            required    => 1,
            type        => "String"
        },
        interval => {
            description => "Histogram interval / bucket size. (year, quarter, month, week, day, hour or minute)",
            name        => "interval",
            paramType   => "query",
            required    => 1,
            type        => "String"
        },
        query => {
            description => "Query (Lucene syntax)",
            name        => "query",
            paramType   => "query",
            required    => 1,
            type        => "String"
        },
        to => {
            description => "Timerange end. See search method description for date format",
            name        => "to",
            paramType   => "query",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "search_absolute_histogram_absolute is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to search_absolute_histogram_absolute ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in search_absolute_histogram_absolute for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub search_absolute_stats_absolute {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/search/universal/absolute/stats";

    my $args = {
        field => {
            description => "Message field of numeric type to return statistics for",
            name        => "field",
            paramType   => "query",
            required    => 1,
            type        => "String"
        },
        filter => {
            description => "Filter",
            name        => "filter",
            paramType   => "query",
            required    => 0,
            type        => "String"
        },
        from => {
            description => "Timerange start. See search method description for date format",
            name        => "from",
            paramType   => "query",
            required    => 1,
            type        => "String"
        },
        query => {
            description => "Query (Lucene syntax)",
            name        => "query",
            paramType   => "query",
            required    => 1,
            type        => "String"
        },
        to => {
            description => "Timerange end. See search method description for date format",
            name        => "to",
            paramType   => "query",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "search_absolute_stats_absolute is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to search_absolute_stats_absolute ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in search_absolute_stats_absolute for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub search_absolute_terms_absolute {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/search/universal/absolute/terms";

    my $args = {
        field => {
            description => "Message field of to return terms of",
            name        => "field",
            paramType   => "query",
            required    => 1,
            type        => "String"
        },
        filter => {
            description => "Filter",
            name        => "filter",
            paramType   => "query",
            required    => 0,
            type        => "String"
        },
        from => {
            description => "Timerange start. See search method description for date format",
            name        => "from",
            paramType   => "query",
            required    => 1,
            type        => "String"
        },
        query => {
            description => "Query (Lucene syntax)",
            name        => "query",
            paramType   => "query",
            required    => 1,
            type        => "String"
        },
        size => {
            description => "Maximum number of terms to return",
            name        => "size",
            paramType   => "query",
            required    => 0,
            type        => "Integer"
        },
        to => {
            description => "Timerange end. See search method description for date format",
            name        => "to",
            paramType   => "query",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "search_absolute_terms_absolute is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to search_absolute_terms_absolute ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in search_absolute_terms_absolute for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}


# -----------------------------------------------------------------------------


sub search_keyword_search_keyword {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/search/universal/keyword";

    my $args = {
        filter => {
            description => "Filter",
            name        => "filter",
            paramType   => "query",
            required    => 0,
            type        => "String"
        },
        keyword => {
            description => "Range keyword",
            name        => "keyword",
            paramType   => "query",
            required    => 1,
            type        => "String"
        },
        limit => {
            description => "Maximum number of messages to return.",
            name        => "limit",
            paramType   => "query",
            required    => 0,
            type        => "Integer"
        },
        offset => {
            description => "Offset",
            name        => "offset",
            paramType   => "query",
            required    => 0,
            type        => "Integer"
        },
        query => {
            description => "Query (Lucene syntax)",
            name        => "query",
            paramType   => "query",
            required    => 1,
            type        => "String"
        },
        sort => {
            description => "Sorting (field:asc / field:desc)",
            name        => "sort",
            paramType   => "query",
            required    => 0,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "search_keyword_search_keyword is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to search_keyword_search_keyword ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in search_keyword_search_keyword for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub search_keyword_field_histogram_keyword {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/search/universal/keyword/fieldhistogram";

    my $args = {
        field => {
            description => "Field of whose values to get the histogram of",
            name        => "field",
            paramType   => "query",
            required    => 1,
            type        => "String"
        },
        filter => {
            description => "Filter",
            name        => "filter",
            paramType   => "query",
            required    => 0,
            type        => "String"
        },
        interval => {
            description => "Histogram interval / bucket size. (year, quarter, month, week, day, hour or minute)",
            name        => "interval",
            paramType   => "query",
            required    => 1,
            type        => "String"
        },
        keyword => {
            description => "Range keyword",
            name        => "keyword",
            paramType   => "query",
            required    => 1,
            type        => "String"
        },
        query => {
            description => "Query (Lucene syntax)",
            name        => "query",
            paramType   => "query",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "search_keyword_field_histogram_keyword is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to search_keyword_field_histogram_keyword ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in search_keyword_field_histogram_keyword for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub search_keyword_histogram_keyword {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/search/universal/keyword/histogram";

    my $args = {
        filter => {
            description => "Filter",
            name        => "filter",
            paramType   => "query",
            required    => 0,
            type        => "String"
        },
        interval => {
            description => "Histogram interval / bucket size. (year, quarter, month, week, day, hour or minute)",
            name        => "interval",
            paramType   => "query",
            required    => 1,
            type        => "String"
        },
        keyword => {
            description => "Range keyword",
            name        => "keyword",
            paramType   => "query",
            required    => 1,
            type        => "String"
        },
        query => {
            description => "Query (Lucene syntax)",
            name        => "query",
            paramType   => "query",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "search_keyword_histogram_keyword is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to search_keyword_histogram_keyword ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in search_keyword_histogram_keyword for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub search_keyword_stats_keyword {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/search/universal/keyword/stats";

    my $args = {
        field => {
            description => "Message field of numeric type to return statistics for",
            name        => "field",
            paramType   => "query",
            required    => 1,
            type        => "String"
        },
        filter => {
            description => "Filter",
            name        => "filter",
            paramType   => "query",
            required    => 0,
            type        => "String"
        },
        keyword => {
            description => "Range keyword",
            name        => "keyword",
            paramType   => "query",
            required    => 1,
            type        => "String"
        },
        query => {
            description => "Query (Lucene syntax)",
            name        => "query",
            paramType   => "query",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "search_keyword_stats_keyword is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to search_keyword_stats_keyword ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in search_keyword_stats_keyword for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub search_keyword_terms_keyword {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/search/universal/keyword/terms";

    my $args = {
        field => {
            description => "Message field of to return terms of",
            name        => "field",
            paramType   => "query",
            required    => 1,
            type        => "String"
        },
        filter => {
            description => "Filter",
            name        => "filter",
            paramType   => "query",
            required    => 0,
            type        => "String"
        },
        keyword => {
            description => "Range keyword",
            name        => "keyword",
            paramType   => "query",
            required    => 1,
            type        => "String"
        },
        query => {
            description => "Query (Lucene syntax)",
            name        => "query",
            paramType   => "query",
            required    => 1,
            type        => "String"
        },
        size => {
            description => "Maximum number of terms to return",
            name        => "size",
            paramType   => "query",
            required    => 0,
            type        => "Integer"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "search_keyword_terms_keyword is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to search_keyword_terms_keyword ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in search_keyword_terms_keyword for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}


# -----------------------------------------------------------------------------


sub search_relative_search_relative {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/search/universal/relative";

    my $args = {
        filter => {
            description => "Filter",
            name        => "filter",
            paramType   => "query",
            required    => 0,
            type        => "String"
        },
        limit => {
            description => "Maximum number of messages to return.",
            name        => "limit",
            paramType   => "query",
            required    => 0,
            type        => "Integer"
        },
        offset => {
            description => "Offset",
            name        => "offset",
            paramType   => "query",
            required    => 0,
            type        => "Integer"
        },
        query => {
            description => "Query (Lucene syntax)",
            name        => "query",
            paramType   => "query",
            required    => 1,
            type        => "String"
        },
        range => {
            description => "Relative timeframe to search in. See method description.",
            name        => "range",
            paramType   => "query",
            required    => 1,
            type        => "Integer"
        },
        sort => {
            description => "Sorting (field:asc / field:desc)",
            name        => "sort",
            paramType   => "query",
            required    => 0,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "search_relative_search_relative is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to search_relative_search_relative ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in search_relative_search_relative for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub search_relative_field_histogram_relative {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/search/universal/relative/fieldhistogram";

    my $args = {
        field => {
            description => "Field of whose values to get the histogram of",
            name        => "field",
            paramType   => "query",
            required    => 1,
            type        => "String"
        },
        filter => {
            description => "Filter",
            name        => "filter",
            paramType   => "query",
            required    => 0,
            type        => "String"
        },
        interval => {
            description => "Histogram interval / bucket size. (year, quarter, month, week, day, hour or minute)",
            name        => "interval",
            paramType   => "query",
            required    => 1,
            type        => "String"
        },
        query => {
            description => "Query (Lucene syntax)",
            name        => "query",
            paramType   => "query",
            required    => 1,
            type        => "String"
        },
        range => {
            description => "Relative timeframe to search in. See search method description.",
            name        => "range",
            paramType   => "query",
            required    => 1,
            type        => "Integer"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "search_relative_field_histogram_relative is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to search_relative_field_histogram_relative ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in search_relative_field_histogram_relative for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub search_relative_histogram_relative {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/search/universal/relative/histogram";

    my $args = {
        filter => {
            description => "Filter",
            name        => "filter",
            paramType   => "query",
            required    => 0,
            type        => "String"
        },
        interval => {
            description => "Histogram interval / bucket size. (year, quarter, month, week, day, hour or minute)",
            name        => "interval",
            paramType   => "query",
            required    => 1,
            type        => "String"
        },
        query => {
            description => "Query (Lucene syntax)",
            name        => "query",
            paramType   => "query",
            required    => 1,
            type        => "String"
        },
        range => {
            description => "Relative timeframe to search in. See search method description.",
            name        => "range",
            paramType   => "query",
            required    => 1,
            type        => "Integer"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "search_relative_histogram_relative is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to search_relative_histogram_relative ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in search_relative_histogram_relative for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub search_relative_stats_relative {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/search/universal/relative/stats";

    my $args = {
        field => {
            description => "Message field of numeric type to return statistics for",
            name        => "field",
            paramType   => "query",
            required    => 1,
            type        => "String"
        },
        filter => {
            description => "Filter",
            name        => "filter",
            paramType   => "query",
            required    => 0,
            type        => "String"
        },
        query => {
            description => "Query (Lucene syntax)",
            name        => "query",
            paramType   => "query",
            required    => 1,
            type        => "String"
        },
        range => {
            description => "Relative timeframe to search in. See search method description.",
            name        => "range",
            paramType   => "query",
            required    => 1,
            type        => "Integer"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "search_relative_stats_relative is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to search_relative_stats_relative ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in search_relative_stats_relative for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub search_relative_terms_relative {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/search/universal/relative/terms";

    my $args = {
        field => {
            description => "Message field of to return terms of",
            name        => "field",
            paramType   => "query",
            required    => 1,
            type        => "String"
        },
        filter => {
            description => "Filter",
            name        => "filter",
            paramType   => "query",
            required    => 0,
            type        => "String"
        },
        query => {
            description => "Query (Lucene syntax)",
            name        => "query",
            paramType   => "query",
            required    => 1,
            type        => "String"
        },
        range => {
            description => "Relative timeframe to search in. See search method description.",
            name        => "range",
            paramType   => "query",
            required    => 1,
            type        => "Integer"
        },
        size => {
            description => "Maximum number of terms to return",
            name        => "size",
            paramType   => "query",
            required    => 0,
            type        => "Integer"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "search_relative_terms_relative is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to search_relative_terms_relative ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in search_relative_terms_relative for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}


# -----------------------------------------------------------------------------


sub search_saved_list {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/search/saved";

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub search_saved_create {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/search/saved";

    my $args = {
        "JSON body" => {
            description => "",
            name        => "JSON body",
            paramType   => "body",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "search_saved_create is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to search_saved_create ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in search_saved_create for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'post', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub search_saved_get {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/search/saved/$params{searchId}";

    my $args = {
        searchId => {
            description => "",
            name        => "searchId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "search_saved_get is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to search_saved_get ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in search_saved_get for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub search_saved_delete {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/search/saved/$params{searchId}";

    my $args = {
        searchId => {
            description => "",
            name        => "searchId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "search_saved_delete is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to search_saved_delete ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in search_saved_delete for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'delete', $url, \%clean_data, $body );
}


# -----------------------------------------------------------------------------


sub sources_list {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/sources";

    my $args = {
        range => {
            description => "Relative timeframe to search in. See method description.",
            name        => "range",
            paramType   => "query",
            required    => 1,
            type        => "Integer"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "sources_list is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to sources_list ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in sources_list for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}


# -----------------------------------------------------------------------------


sub static_fields_create {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/inputs/$params{inputId}/staticfields";

    my $args = {
        "JSON body" => {
            description => "",
            name        => "JSON body",
            paramType   => "body",
            required    => 1,
            type        => "String"
        },
        inputId => {
            description => "",
            name        => "inputId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "static_fields_create is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to static_fields_create ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in static_fields_create for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'post', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub static_fields_delete {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/inputs/$params{inputId}/staticfields/$params{key}";

    my $args = {
        Key => {
            description => "",
            name        => "Key",
            paramType   => "path",
            required    => 1,
            type        => "String"
        },
        inputId => {
            description => "",
            name        => "inputId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "static_fields_delete is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to static_fields_delete ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in static_fields_delete for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'delete', $url, \%clean_data, $body );
}


# -----------------------------------------------------------------------------


sub stream_rules_get {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/streams/$params{streamid}/rules";

    my $args = {
        streamid => {
            description => "The id of the stream whose stream rules we want.",
            name        => "streamid",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "stream_rules_get is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to stream_rules_get ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in stream_rules_get for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub stream_rules_create {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/streams/$params{streamid}/rules";

    my $args = {
        "JSON body" => {
            description => "",
            name        => "JSON body",
            paramType   => "body",
            required    => 1,
            type        => "String"
        },
        streamid => {
            description => "The stream id this new rule belongs to.",
            name        => "streamid",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "stream_rules_create is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to stream_rules_create ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in stream_rules_create for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'post', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub get_stream_rules_get {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/streams/$params{streamid}/rules/$params{streamRuleId}";

    my $args = {
        streamRuleId => {
            description => "The stream rule id we are getting",
            name        => "streamRuleId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        },
        streamid => {
            description => "The id of the stream whose stream rule we want.",
            name        => "streamid",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "get_stream_rules_get is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to get_stream_rules_get ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in get_stream_rules_get for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub stream_rules_delete {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/streams/$params{streamid}/rules/$params{streamRuleId}";

    my $args = {
        streamRuleId => {
            description => "",
            name        => "streamRuleId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        },
        streamid => {
            description => "The stream id this new rule belongs to.",
            name        => "streamid",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "stream_rules_delete is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to stream_rules_delete ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in stream_rules_delete for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'delete', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub stream_rules_update {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/streams/$params{streamid}/rules/$params{streamRuleId}";

    my $args = {
        "JSON body" => {
            description => "",
            name        => "JSON body",
            paramType   => "body",
            required    => 1,
            type        => "String"
        },
        streamRuleId => {
            description => "The stream rule id we are updating",
            name        => "streamRuleId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        },
        streamid => {
            description => "The stream id this rule belongs to.",
            name        => "streamid",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "stream_rules_update is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to stream_rules_update ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in stream_rules_update for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'post', $url, \%clean_data, $body );
}


# -----------------------------------------------------------------------------


sub streams_get {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/streams";

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub streams_create {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/streams";

    my $args = {
        "JSON body" => {
            description => "",
            name        => "JSON body",
            paramType   => "body",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "streams_create is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to streams_create ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in streams_create for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'post', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub streams_get_enabled {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/streams/enabled";

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub streams_stream_throughput {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/streams/throughput";

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub get_streams_get {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/streams/$params{streamId}";

    my $args = {
        streamId => {
            description => "",
            name        => "streamId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "get_streams_get is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to get_streams_get ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in get_streams_get for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub streams_delete {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/streams/$params{streamId}";

    my $args = {
        streamId => {
            description => "",
            name        => "streamId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "streams_delete is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to streams_delete ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in streams_delete for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'delete', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub streams_update {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/streams/$params{streamId}";

    my $args = {
        "JSON body" => {
            description => "",
            name        => "JSON body",
            paramType   => "body",
            required    => 1,
            type        => "String"
        },
        streamId => {
            description => "",
            name        => "streamId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "streams_update is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to streams_update ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in streams_update for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'put', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub streams_clone_stream {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/streams/$params{streamId}/clone";

    my $args = {
        "JSON body" => {
            description => "",
            name        => "JSON body",
            paramType   => "body",
            required    => 1,
            type        => "String"
        },
        streamId => {
            description => "",
            name        => "streamId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "streams_clone_stream is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to streams_clone_stream ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in streams_clone_stream for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'post', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub streams_pause {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/streams/$params{streamId}/pause";

    my $args = {
        streamId => {
            description => "",
            name        => "streamId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "streams_pause is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to streams_pause ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in streams_pause for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'post', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub streams_resume {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/streams/$params{streamId}/resume";

    my $args = {
        streamId => {
            description => "",
            name        => "streamId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "streams_resume is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to streams_resume ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in streams_resume for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'post', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub streams_test_match {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/streams/$params{streamId}/testMatch";

    my $args = {
        "JSON body" => {
            description => "",
            name        => "JSON body",
            paramType   => "body",
            required    => 1,
            type        => "String"
        },
        streamId => {
            description => "",
            name        => "streamId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "streams_test_match is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to streams_test_match ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in streams_test_match for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'post', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub streams_one_stream_throughput {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/streams/$params{streamId}/throughput";

    my $args = {
        streamId => {
            description => "",
            name        => "streamId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "streams_one_stream_throughput is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to streams_one_stream_throughput ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in streams_one_stream_throughput for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}


# -----------------------------------------------------------------------------


sub system {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system";

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub system_fields {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/fields";

    my $args = {
        limit => {
            description => "Maximum number of fields to return. Set to 0 for all fields.",
            name        => "limit",
            paramType   => "query",
            required    => 0,
            type        => "Integer"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "system_fields is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to system_fields ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in system_fields for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub system_jvm {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/jvm";

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub system_permissions {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/permissions";

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub system_reader_permissions {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/permissions/reader/$params{username}";

    my $args = {
        username => {
            description => "",
            name        => "username",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "system_reader_permissions is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to system_reader_permissions ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in system_reader_permissions for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub system_pause_processing {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/processing/pause";

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'put', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub system_resume_processing {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/processing/resume";

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'put', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub system_threaddump {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/threaddump";

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}


# -----------------------------------------------------------------------------


sub system_buffers_utilization {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/buffers";

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}


# -----------------------------------------------------------------------------


sub system_cluster_node {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/cluster/node";

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub system_cluster_nodes {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/cluster/nodes";

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub get_system_cluster_node {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/cluster/nodes/$params{nodeId}";

    my $args = {
        nodeId => {
            description => "",
            name        => "nodeId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "get_system_cluster_node is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to get_system_cluster_node ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in get_system_cluster_node for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}


# -----------------------------------------------------------------------------


sub system_deflector_deflector {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/deflector";

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub system_deflector_config {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/deflector/config";

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub system_deflector_cycle {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/deflector/cycle";

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'post', $url, \%clean_data, $body );
}


# -----------------------------------------------------------------------------


sub system_index_ranges_list {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/indices/ranges";

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub system_index_ranges_rebuild {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/indices/ranges/rebuild";

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'post', $url, \%clean_data, $body );
}


# -----------------------------------------------------------------------------


sub system_inputs_list {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/inputs";

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub system_inputs_create {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/inputs";

    my $args = {
        "JSON body" => {
            description => "",
            name        => "JSON body",
            paramType   => "body",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "system_inputs_create is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to system_inputs_create ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in system_inputs_create for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'post', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub system_inputs_types {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/inputs/types";

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub system_inputs_info {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/inputs/types/$params{inputType}";

    my $args = {
        inputType => {
            description => "",
            name        => "inputType",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "system_inputs_info is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to system_inputs_info ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in system_inputs_info for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub system_inputs_single {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/inputs/$params{inputId}";

    my $args = {
        inputId => {
            description => "",
            name        => "inputId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "system_inputs_single is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to system_inputs_single ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in system_inputs_single for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub system_inputs_terminate {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/inputs/$params{inputId}";

    my $args = {
        inputId => {
            description => "",
            name        => "inputId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "system_inputs_terminate is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to system_inputs_terminate ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in system_inputs_terminate for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'delete', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub system_inputs_launch_existing {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/inputs/$params{inputId}/launch";

    my $args = {
        inputId => {
            description => "",
            name        => "inputId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "system_inputs_launch_existing is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to system_inputs_launch_existing ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in system_inputs_launch_existing for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}


# -----------------------------------------------------------------------------


sub system_jobs_trigger {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/jobs";

    my $args = {
        "JSON body" => {
            description => "",
            name        => "JSON body",
            paramType   => "body",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "system_jobs_trigger is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to system_jobs_trigger ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in system_jobs_trigger for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'post', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub system_jobs_list {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/jobs";

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub system_jobs_get {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/jobs/$params{jobId}";

    my $args = {
        jobId => {
            description => "",
            name        => "jobId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "system_jobs_get is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to system_jobs_get ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in system_jobs_get for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}


# -----------------------------------------------------------------------------


sub system_l_d_a_p_get_ldap_settings {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/ldap/settings";

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub system_l_d_a_p_update_ldap_settings {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/ldap/settings";

    my $args = {
        "JSON body" => {
            description => "",
            name        => "JSON body",
            paramType   => "body",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "system_l_d_a_p_update_ldap_settings is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to system_l_d_a_p_update_ldap_settings ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in system_l_d_a_p_update_ldap_settings for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'put', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub system_l_d_a_p_delete_ldap_settings {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/ldap/settings";

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'delete', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub system_l_d_a_p_test_ldap_configuration {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/ldap/test";

    my $args = {
        "Configuration to test" => {
            description => "",
            name        => "Configuration to test",
            paramType   => "body",
            required    => 1,
            type        => "LdapTestConfigRequest"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "system_l_d_a_p_test_ldap_configuration is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to system_l_d_a_p_test_ldap_configuration ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in system_l_d_a_p_test_ldap_configuration for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'post', $url, \%clean_data, $body );
}


# -----------------------------------------------------------------------------


sub system_loggers_loggers {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/loggers";

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub system_loggers_subsytems {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/loggers/subsystems";

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub system_loggers_set_subsystem_logger_level {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/loggers/subsystems/$params{subsystem}/level/$params{level}";

    my $args = {
        level => {
            description => "",
            name        => "level",
            paramType   => "path",
            required    => 1,
            type        => "String"
        },
        subsystem => {
            description => "",
            name        => "subsystem",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "system_loggers_set_subsystem_logger_level is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to system_loggers_set_subsystem_logger_level ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in system_loggers_set_subsystem_logger_level for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'put', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub system_loggers_set_single_logger_level {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/loggers/$params{loggerName}/level/$params{level}";

    my $args = {
        level => {
            description => "",
            name        => "level",
            paramType   => "path",
            required    => 1,
            type        => "String"
        },
        loggerName => {
            description => "",
            name        => "loggerName",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "system_loggers_set_single_logger_level is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to system_loggers_set_single_logger_level ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in system_loggers_set_single_logger_level for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'put', $url, \%clean_data, $body );
}


# -----------------------------------------------------------------------------


sub system_messages_all {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/messages";

    my $args = {
        page => {
            description => "Page",
            name        => "page",
            paramType   => "query",
            required    => 0,
            type        => "Integer"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "system_messages_all is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to system_messages_all ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in system_messages_all for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}


# -----------------------------------------------------------------------------


sub system_metrics_metrics {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/metrics";

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub system_metrics_metric_names {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/metrics/names";

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub system_metrics_by_namespace {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/metrics/namespace/$params{namespace}";

    my $args = {
        namespace => {
            description => "",
            name        => "namespace",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "system_metrics_by_namespace is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to system_metrics_by_namespace ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in system_metrics_by_namespace for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub system_metrics_single_metric {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/metrics/$params{metricName}";

    my $args = {
        metricName => {
            description => "",
            name        => "metricName",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "system_metrics_single_metric is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to system_metrics_single_metric ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in system_metrics_single_metric for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub system_metrics_historic_single_metric {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/metrics/$params{metricName}/history";

    my $args = {
        after => {
            description => "Only values for after this UTC timestamp (1970 epoch)",
            name        => "after",
            paramType   => "body",
            required    => 0,
            type        => "Long"
        },
        metricName => {
            description => "",
            name        => "metricName",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "system_metrics_historic_single_metric is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to system_metrics_historic_single_metric ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in system_metrics_historic_single_metric for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}


# -----------------------------------------------------------------------------


sub system_notifications_list_notifications {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/notifications";

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub system_notifications_delete_notification {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/notifications/$params{notificationType}";

    my $args = {
        notificationType => {
            description => "",
            name        => "notificationType",
            paramType   => "path",
            required    => 0,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "system_notifications_delete_notification is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to system_notifications_delete_notification ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in system_notifications_delete_notification for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'delete', $url, \%clean_data, $body );
}


# -----------------------------------------------------------------------------


sub system_radios_radios {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/radios";

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub system_radios_radio {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/radios/$params{radioId}";

    my $args = {
        radioId => {
            description => "",
            name        => "radioId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "system_radios_radio is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to system_radios_radio ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in system_radios_radio for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub system_radios_register_input {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/radios/$params{radioId}/inputs";

    my $args = {
        "JSON body" => {
            description => "",
            name        => "JSON body",
            paramType   => "body",
            required    => 1,
            type        => "String"
        },
        radioId => {
            description => "",
            name        => "radioId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "system_radios_register_input is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to system_radios_register_input ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in system_radios_register_input for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'post', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub system_radios_persisted_inputs {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/radios/$params{radioId}/inputs";

    my $args = {
        radioId => {
            description => "",
            name        => "radioId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "system_radios_persisted_inputs is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to system_radios_persisted_inputs ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in system_radios_persisted_inputs for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub system_radios_unregister_input {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/radios/$params{radioId}/inputs/$params{inputId}";

    my $args = {
        inputId => {
            description => "",
            name        => "inputId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        },
        radioId => {
            description => "",
            name        => "radioId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "system_radios_unregister_input is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to system_radios_unregister_input ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in system_radios_unregister_input for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'delete', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub system_radios_ping {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/radios/$params{radioId}/ping";

    my $args = {
        "JSON body" => {
            description => "",
            name        => "JSON body",
            paramType   => "body",
            required    => 1,
            type        => "String"
        },
        radioId => {
            description => "",
            name        => "radioId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "system_radios_ping is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to system_radios_ping ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in system_radios_ping for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'put', $url, \%clean_data, $body );
}


# -----------------------------------------------------------------------------


sub system_sessions_new_session {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/sessions";

    my $args = {
        "Login request" => {
            description => "Username and credentials",
            name        => "Login request",
            paramType   => "body",
            required    => 1,
            type        => "SessionCreateRequest"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "system_sessions_new_session is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to system_sessions_new_session ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in system_sessions_new_session for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'post', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub system_sessions_terminate_session {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/sessions/$params{sessionId}";

    my $args = {
        sessionId => {
            description => "",
            name        => "sessionId",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "system_sessions_terminate_session is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to system_sessions_terminate_session ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in system_sessions_terminate_session for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'delete', $url, \%clean_data, $body );
}


# -----------------------------------------------------------------------------


sub system_throughput_total {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/system/throughput";

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}


# -----------------------------------------------------------------------------


sub users_list_users {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/users";

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub users_create {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/users";

    my $args = {
        "JSON body" => {
            description => "",
            name        => "JSON body",
            paramType   => "body",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "users_create is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to users_create ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in users_create for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'post', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub users_change_user {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/users/$params{username}";

    my $args = {
        username => {
            description => "The name of the user to modify.",
            name        => "username",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "users_change_user is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to users_change_user ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in users_change_user for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'put', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub users_delete_user {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/users/$params{username}";

    my $args = {
        username => {
            description => "The name of the user to delete.",
            name        => "username",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "users_delete_user is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to users_delete_user ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in users_delete_user for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'delete', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub users_get {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/users/$params{username}";

    my $args = {
        username => {
            description => "The username to return information for.",
            name        => "username",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "users_get is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to users_get ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in users_get for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub users_change_password {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/users/$params{username}/password";

    my $args = {
        "JSON body" => {
            description => "The hashed old and new passwords.",
            name        => "JSON body",
            paramType   => "body",
            required    => 1,
            type        => "String"
        },
        username => {
            description => "The name of the user whose password to change.",
            name        => "username",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "users_change_password is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to users_change_password ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in users_change_password for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'put', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub users_edit_permissions {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/users/$params{username}/permissions";

    my $args = {
        "JSON body" => {
            description => "The list of permissions to assign to the user.",
            name        => "JSON body",
            paramType   => "body",
            required    => 1,
            type        => "String"
        },
        username => {
            description => "The name of the user to modify.",
            name        => "username",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "users_edit_permissions is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to users_edit_permissions ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in users_edit_permissions for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'put', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub users_delete_permissions {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/users/$params{username}/permissions";

    my $args = {
        username => {
            description => "The name of the user to modify.",
            name        => "username",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "users_delete_permissions is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to users_delete_permissions ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in users_delete_permissions for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'delete', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub users_list_tokens {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/users/$params{username}/tokens";

    my $args = {
        username => {
            description => "",
            name        => "username",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "users_list_tokens is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to users_list_tokens ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in users_list_tokens for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'get', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub users_generate_new_token {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/users/$params{username}/tokens/$params{name}";

    my $args = {
        name => {
            description => "Descriptive name for this token (e.g. 'cronjob') ",
            name        => "name",
            paramType   => "path",
            required    => 1,
            type        => "String"
        },
        username => {
            description => "",
            name        => "username",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "users_generate_new_token is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to users_generate_new_token ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in users_generate_new_token for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'post', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------


sub users_revoke_token {
    my $self = shift;
    my (%params) = @_;
    my ( %clean_data, $body );
    my $url = "/users/$params{username}/tokens/$params{token}";

    my $args = {
        "access token" => {
            description => "",
            name        => "access token",
            paramType   => "path",
            required    => 1,
            type        => "String"
        },
        username => {
            description => "",
            name        => "username",
            paramType   => "path",
            required    => 1,
            type        => "String"
        }
    };
    foreach my $a ( keys %{$args} ) {

        # check if the parameters exist if needed
        die "users_revoke_token is missing required parameter $a" if ( $args->{$a}->{required} && !$params{$a} );

        # validate the type of the parameter
        my $err = _validate_parameter( $params{$a}, $args->{$a} );
        die "Bad argument $params{$a} to users_revoke_token ($err)" if ($err);

        if ( $args->{$a}->{paramType} eq 'path' ) {
            $url =~ s/\$params\{$a\}/$params{$a}/;
            next;
        }
        if ( $args->{$a}->{paramType} eq 'body' ) {
            die "body has already been defined in users_revoke_token for $args->{$a}->{name}" if ($body);
            $body = $params{$a};
        }
        else {
            # we only want to send data that is allowed
            $clean_data{$a} = $params{$a} if ( defined $params{$a} );
        }
    }

    # if the body data does not look right, then convert it to JSON
    if ( ref($body) ne 'SCALAR' ) {
        $body = to_json($body) if ($body);
    }
    return $self->_action_url( 'delete', $url, \%clean_data, $body );
}

# -----------------------------------------------------------------------------
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Graylog::API - API Client for Net::Graylog::API

=head1 VERSION

version 0.3

=head1 SYNOPSIS

  use Net::Graylog::API ;
 
  my $api = Net::Graylog::API->new( url => 'http://server:12345' ) ;

  $api->api_command( message => 'testing', 'debug') ;

=head1 DESCRIPTION

This module has been autogenerated against a Swagger API, hopefully
the author has fixed up the documentation

Currently this module is only using Basic auth over HTTP, not yet got into the 
complexity of anything else.

=head1 NAME

Net::Graylog::API

=head1 AUTHOR

autogenerated by create_swagger_api, 
Which was created by kevin Mulholland, moodfarm@cpan.org

=head1 VERSIONS

v0.1  

=head1 Notes

Currently I am unsure if the PUT/POST actions work

Due to issues with Graylog2 documentation, I cannot test that any of the
methods that use post/put actions will work, so lets assume for now that
they do not 

=head1 Todo

Investigate L<HTTP::Async> instead of L<:Furl> as it will not block, so we can wait
for the response to be received, rather than the timeout to lapse

=head1 Data Models

=head2 SearchResponse

=over 4

=item built_query [String]

=item error [Object]

  * begin_column [Integer]
  * begin_line [Integer]
  * end_column [Integer]
  * end_line [Integer]

=item fields [Array]

  * type [String]

=item generic_error [Object]

  * exception_name [String]
  * message [String]

=item messages [Array]

  * properties [Object]
    * index [String]
    * message [Object]
      * additional_properties [Any]

=item query [String]

=item time [Integer]

=item total_results [Integer]

=item used_indices [Array]

  * type [String]

=back

=head2 ReaderPermissionResponse

=over 4

=item permissions [Array]

  * type [String]

=back

=head2 LdapTestConfigResponse

=over 4

=item connected [Boolean]

=item entry [Object]

  * additional_properties [String]

=item exception [String]

=item login_authenticated [Boolean]

=item system_authenticated [Boolean]

=back

=head2 LdapTestConfigRequest

=over 4

=item active_directory [Boolean]

=item ldap_uri [String]

=item password [String]

=item principal [String]

=item search_base [String]

=item search_pattern [String]

=item system_password [String]

=item system_username [String]

=item test_connect_only [Boolean]

=item trust_all_certificates [Boolean]

=item use_start_tls [Boolean]

=back

=head2 SessionCreateRequest

=over 4

=item host [String]

=item password [String]

=item username [String]

=back

=head2 Session

=over 4

=item session_id [String]

=item valid_until [String]

=back

=head2 Token

=over 4

=item last_access [String]

=item name [String]

=item token [String]

=back

=head2 TokenList

=over 4

=item tokens [Array]

  * properties [Object]
    * last_access [String]
    * name [String]
    * token [String]

=back

=head1 Public Methods

Any method may die, you may need to catch these.

=head2 new

Create a new instance of the api connection

    my $api = Net::Graylog::API->new( url => 'http://server:12345') ;

B<Parameters>
  url the url of the server API, of the form http://server:12345
  timeout, can be a float, default 0.01, Furl seems to wait until the timeout occurs 
    before giving a response, which really cuts into the speed of sending, you may want to make this
    bigger for non-local servers, ie 1s

=head2 Alerts

Manage stream alerts

=head3 alerts_list

Get the 100 most recent alarms of this stream.

=head4 Required parameters

=over 2

=item * streamId  [String]  The stream id this new alert condition belongs to.

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 alerts_check_conditions

Check for triggered alert conditions of this streams. Results cached for 30 seconds.

=head4 Required parameters

=over 2

=item * streamId  [String]  The ID of the stream to check.

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 alerts_list_conditions

Get all alert conditions of this stream

=head4 Required parameters

=over 2

=item * streamId  [String]  The stream id this new alert condition belongs to.

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 alerts_create

Create a alert condition

=head4 Required parameters

=over 2

=item * streamId  [String]  The stream id this new alert condition belongs to.

=item * JSON body [String]  

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 delete_alerts_list

Delete an alert condition

=head4 Required parameters

=over 2

=item * streamId  [String]  The stream id this new alert condition belongs to.

=item * conditionId [String]  The stream id this new alert condition belongs to.

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 alerts_add_receiver

Add an alert receiver

=head4 Required parameters

=over 2

=item * streamId  [String]  The stream id this new alert condition belongs to.

=item * entity  [String]  Name/ID of user or email address to add as alert receiver.

=item * type  [String]  Type: users or emails

=back

Returns: Normal Furl::Response, possible data in content

=head3 alerts_remove_receiver

Remove an alert receiver

=head4 Required parameters

=over 2

=item * streamId  [String]  The stream id this new alert condition belongs to.

=item * entity  [String]  Name/ID of user or email address to remove from alert receivers.

=item * type  [String]  Type: users or emails

=back

Returns: Normal Furl::Response, possible data in content

=head3 alerts_send_dummy_alert

Send a test mail for a given stream

=head4 Required parameters

=over 2

=item * streamId  [String]  The stream id this new alert condition belongs to.

=back

Returns: Normal Furl::Response, possible data in content

=head2 Counts

Message counts

=head3 counts_total

Total number of messages in all your indices.

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head2 Dashboards

Manage dashboards

=head3 dashboards_list

Get a list of all dashboards and all configurations of their widgets.

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head3 dashboards_create

Create a dashboard

=head4 Required parameters

=over 2

=item * JSON body [String]  

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 dashboards_get

Get a single dashboards and all configurations of its widgets.

=head4 Required parameters

=over 2

=item * dashboardId [String]  

=back

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head3 dashboards_delete

Delete a dashboard and all its widgets

=head4 Required parameters

=over 2

=item * dashboardId [String]  

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 dashboards_update

Update the settings of a dashboard.

=head4 Required parameters

=over 2

=item * JSON body [String]  

=item * dashboardId [String]  

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 dashboards_set_positions

Update/set the positions of dashboard widgets.

=head4 Required parameters

=over 2

=item * JSON body [String]  

=item * dashboardId [String]  

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 dashboards_add_widget

Add a widget to a dashboard

=head4 Required parameters

=over 2

=item * JSON body [String]  

=item * dashboardId [String]  

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 dashboards_remove

Delete a widget

=head4 Required parameters

=over 2

=item * dashboardId [String]  

=item * widgetId  [String]  

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 dashboards_update_cache_time

Update cache time of a widget

=head4 Required parameters

=over 2

=item * JSON body [String]  

=item * dashboardId [String]  

=item * widgetId  [String]  

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 dashboards_update_description

Update description of a widget

=head4 Required parameters

=over 2

=item * JSON body [String]  

=item * dashboardId [String]  

=item * widgetId  [String]  

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 dashboards_widget_value

Get a single widget value.

=head4 Required parameters

=over 2

=item * dashboardId [String]  

=item * widgetId  [String]  

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head2 Documentation

Documentation of this API in JSON format.

=head3 documentation_overview

Get API documentation

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 documentation_route

Get detailed API documentation of a single resource

=head4 Required parameters

=over 2

=item * route [String]  Route to fetch. For example /system

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head2 Extractors

Extractors of an input

=head3 extractors_list

List all extractors of an input

=head4 Required parameters

=over 2

=item * inputId [String]  

=back

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head3 extractors_create

Add an extractor to an input

=head4 Required parameters

=over 2

=item * JSON body [String]  

=item * inputId [String]  

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 extractors_terminate

Delete an extractor

=head4 Required parameters

=over 2

=item * inputId [String]  

=item * extractorId [String]  

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head2 Indexer/Cluster

Indexer cluster information

=head3 indexer_cluster_cluster_health

Get cluster and shard health overview

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head3 indexer_cluster_cluster_name

Get the cluster name

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head2 Indexer/Failures

Indexer failures

=head3 indexer_failures_single

Get a list of failed index operations.

=head4 Required parameters

=over 2

=item * limit [Integer] Limit

=item * offset  [Integer] Offset

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 indexer_failures_count

Total count of failed index operations since the given date.

=head4 Optional parameters

=over 2

=item * since [String]  ISO8601 date

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head2 Indexer/Indices

Index informations

=head3 indexer_indices_closed

Get a list of closed indices that can be reopened.

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 indexer_indices_single

Get information of an index and its shards.

=head4 Optional parameters

=over 2

=item * index [String]  

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 indexer_indices_delete

Delete an index. This will also trigger an index ranges rebuild job.

=head4 Optional parameters

=over 2

=item * index [String]  

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 indexer_indices_close

Close an index. This will also trigger an index ranges rebuild job.

=head4 Optional parameters

=over 2

=item * index [String]  

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 indexer_indices_reopen

Reopen a closed index. This will also trigger an index ranges rebuild job.

=head4 Optional parameters

=over 2

=item * index [String]  

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head2 Messages

Single messages

=head3 messages_analyze

Analyze a message string

Note: Returns what tokens/terms a message string (message or full_message) is split to.

=head4 Required parameters

=over 2

=item * index [String]  The index the message containing the string is stored in.

=item * string  [String]  The string to analyze.

=back

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head3 messages_search

Get a single message.

=head4 Required parameters

=over 2

=item * index [String]  The index this message is stored in.

=item * messageId [String]  

=back

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head2 Search/Absolute

Message search

=head3 search_absolute_search_absolute

Message search with absolute timerange.

Note: Search for messages using an absolute timerange, specified as from/to with format yyyy-MM-ddTHH:mm:ss.SSSZ (e.g. 2014-01-23T15:34:49.000Z) or yyyy-MM-dd HH-mm-ss.

=head4 Required parameters

=over 2

=item * query [String]  Query (Lucene syntax)

=item * from  [String]  Timerange start. See description for date format

=item * to  [String]  Timerange end. See description for date format

=back

=head4 Optional parameters

=over 2

=item * limit [Integer] Maximum number of messages to return.

=item * offset  [Integer] Offset

=item * filter  [String]  Filter

=item * sort  [String]  Sorting (field:asc / field:desc)

=back

Returns: [L</SearchResponse>] Normal Furl::Response, with decoded JSON in json element

=head3 search_absolute_field_histogram_absolute

Field value histogram of a query using an absolute timerange.

=head4 Required parameters

=over 2

=item * query [String]  Query (Lucene syntax)

=item * field [String]  Field of whose values to get the histogram of

=item * interval  [String]  Histogram interval / bucket size. (year, quarter, month, week, day, hour or minute)

=item * from  [String]  Timerange start. See search method description for date format

=item * to  [String]  Timerange end. See search method description for date format

=back

=head4 Optional parameters

=over 2

=item * filter  [String]  Filter

=back

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head3 search_absolute_histogram_absolute

Datetime histogram of a query using an absolute timerange.

=head4 Required parameters

=over 2

=item * query [String]  Query (Lucene syntax)

=item * interval  [String]  Histogram interval / bucket size. (year, quarter, month, week, day, hour or minute)

=item * from  [String]  Timerange start. See search method description for date format

=item * to  [String]  Timerange end. See search method description for date format

=back

=head4 Optional parameters

=over 2

=item * filter  [String]  Filter

=back

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head3 search_absolute_stats_absolute

Field statistics for a query using an absolute timerange.

Note: Returns statistics like min/max or standard deviation of numeric fields over the whole query result set.

=head4 Required parameters

=over 2

=item * field [String]  Message field of numeric type to return statistics for

=item * query [String]  Query (Lucene syntax)

=item * from  [String]  Timerange start. See search method description for date format

=item * to  [String]  Timerange end. See search method description for date format

=back

=head4 Optional parameters

=over 2

=item * filter  [String]  Filter

=back

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head3 search_absolute_terms_absolute

Most common field terms of a query using an absolute timerange.

=head4 Required parameters

=over 2

=item * field [String]  Message field of to return terms of

=item * query [String]  Query (Lucene syntax)

=item * from  [String]  Timerange start. See search method description for date format

=item * to  [String]  Timerange end. See search method description for date format

=back

=head4 Optional parameters

=over 2

=item * size  [Integer] Maximum number of terms to return

=item * filter  [String]  Filter

=back

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head2 Search/Keyword

Message search

=head3 search_keyword_search_keyword

Message search with keyword as timerange.

Note: Search for messages in a timerange defined by a keyword like "yesterday" or "2 weeks ago to wednesday".

=head4 Required parameters

=over 2

=item * query [String]  Query (Lucene syntax)

=item * keyword [String]  Range keyword

=back

=head4 Optional parameters

=over 2

=item * limit [Integer] Maximum number of messages to return.

=item * offset  [Integer] Offset

=item * filter  [String]  Filter

=item * sort  [String]  Sorting (field:asc / field:desc)

=back

Returns: [L</SearchResponse>] Normal Furl::Response, with decoded JSON in json element

=head3 search_keyword_field_histogram_keyword

Datetime histogram of a query using keyword timerange.

=head4 Required parameters

=over 2

=item * query [String]  Query (Lucene syntax)

=item * field [String]  Field of whose values to get the histogram of

=item * interval  [String]  Histogram interval / bucket size. (year, quarter, month, week, day, hour or minute)

=item * keyword [String]  Range keyword

=back

=head4 Optional parameters

=over 2

=item * filter  [String]  Filter

=back

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head3 search_keyword_histogram_keyword

Datetime histogram of a query using keyword timerange.

=head4 Required parameters

=over 2

=item * query [String]  Query (Lucene syntax)

=item * interval  [String]  Histogram interval / bucket size. (year, quarter, month, week, day, hour or minute)

=item * keyword [String]  Range keyword

=back

=head4 Optional parameters

=over 2

=item * filter  [String]  Filter

=back

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head3 search_keyword_stats_keyword

Field statistics for a query using a keyword timerange.

Note: Returns statistics like min/max or standard deviation of numeric fields over the whole query result set.

=head4 Required parameters

=over 2

=item * field [String]  Message field of numeric type to return statistics for

=item * query [String]  Query (Lucene syntax)

=item * keyword [String]  Range keyword

=back

=head4 Optional parameters

=over 2

=item * filter  [String]  Filter

=back

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head3 search_keyword_terms_keyword

Most common field terms of a query using a keyword timerange.

=head4 Required parameters

=over 2

=item * field [String]  Message field of to return terms of

=item * query [String]  Query (Lucene syntax)

=item * keyword [String]  Range keyword

=back

=head4 Optional parameters

=over 2

=item * size  [Integer] Maximum number of terms to return

=item * filter  [String]  Filter

=back

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head2 Search/Relative

Message search

=head3 search_relative_search_relative

Message search with relative timerange.

Note: Search for messages in a relative timerange, specified as seconds from now. Example: 300 means search from 5 minutes ago to now.

=head4 Required parameters

=over 2

=item * query [String]  Query (Lucene syntax)

=item * range [Integer] Relative timeframe to search in. See method description.

=back

=head4 Optional parameters

=over 2

=item * limit [Integer] Maximum number of messages to return.

=item * offset  [Integer] Offset

=item * filter  [String]  Filter

=item * sort  [String]  Sorting (field:asc / field:desc)

=back

Returns: [L</SearchResponse>] Normal Furl::Response, with decoded JSON in json element

=head3 search_relative_field_histogram_relative

Field value histogram of a query using a relative timerange.

=head4 Required parameters

=over 2

=item * query [String]  Query (Lucene syntax)

=item * field [String]  Field of whose values to get the histogram of

=item * interval  [String]  Histogram interval / bucket size. (year, quarter, month, week, day, hour or minute)

=item * range [Integer] Relative timeframe to search in. See search method description.

=back

=head4 Optional parameters

=over 2

=item * filter  [String]  Filter

=back

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head3 search_relative_histogram_relative

Datetime histogram of a query using a relative timerange.

=head4 Required parameters

=over 2

=item * query [String]  Query (Lucene syntax)

=item * interval  [String]  Histogram interval / bucket size. (year, quarter, month, week, day, hour or minute)

=item * range [Integer] Relative timeframe to search in. See search method description.

=back

=head4 Optional parameters

=over 2

=item * filter  [String]  Filter

=back

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head3 search_relative_stats_relative

Field statistics for a query using a relative timerange.

Note: Returns statistics like min/max or standard deviation of numeric fields over the whole query result set.

=head4 Required parameters

=over 2

=item * field [String]  Message field of numeric type to return statistics for

=item * query [String]  Query (Lucene syntax)

=item * range [Integer] Relative timeframe to search in. See search method description.

=back

=head4 Optional parameters

=over 2

=item * filter  [String]  Filter

=back

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head3 search_relative_terms_relative

Most common field terms of a query using a relative timerange.

=head4 Required parameters

=over 2

=item * field [String]  Message field of to return terms of

=item * query [String]  Query (Lucene syntax)

=item * range [Integer] Relative timeframe to search in. See search method description.

=back

=head4 Optional parameters

=over 2

=item * size  [Integer] Maximum number of terms to return

=item * filter  [String]  Filter

=back

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head2 Search/Saved

Saved searches

=head3 search_saved_list

Get a list of all saved searches

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head3 search_saved_create

Create a new saved search

=head4 Required parameters

=over 2

=item * JSON body [String]  

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 search_saved_get

Get a single saved search

=head4 Required parameters

=over 2

=item * searchId  [String]  

=back

Returns: [String] Normal Furl::Response, possible data in content

=head3 search_saved_delete

Delete a saved search

=head4 Required parameters

=over 2

=item * searchId  [String]  

=back

Returns: Normal Furl::Response, possible data in content

=head2 Sources

Listing message sources (e.g. hosts sending logs)

=head3 sources_list

Get a list of all sources (not more than 5000) that have messages in the current indices. The result is cached for 10 seconds.

Note: Range: The parameter is in seconds relative to the current time. 86400 means 'in the last day',0 is special and means 'across all indices'

=head4 Required parameters

=over 2

=item * range [Integer] Relative timeframe to search in. See method description.

=back

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head2 StaticFields

Static fields of an input

=head3 static_fields_create

Add a static field to an input

=head4 Required parameters

=over 2

=item * JSON body [String]  

=item * inputId [String]  

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 static_fields_delete

Remove static field of an input

=head4 Required parameters

=over 2

=item * Key [String]  

=item * inputId [String]  

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head2 StreamRules

Manage stream rules

=head3 stream_rules_get

Get a list of all stream rules

=head4 Required parameters

=over 2

=item * streamid  [String]  The id of the stream whose stream rules we want.

=back

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head3 stream_rules_create

Create a stream rule

=head4 Required parameters

=over 2

=item * streamid  [String]  The stream id this new rule belongs to.

=item * JSON body [String]  

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 get_stream_rules_get

Get a single stream rules

=head4 Required parameters

=over 2

=item * streamid  [String]  The id of the stream whose stream rule we want.

=item * streamRuleId  [String]  The stream rule id we are getting

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 stream_rules_delete

Delete a stream rule

=head4 Required parameters

=over 2

=item * streamid  [String]  The stream id this new rule belongs to.

=item * streamRuleId  [String]  

=back

Returns: Normal Furl::Response, possible data in content

=head3 stream_rules_update

Update a stream rule

=head4 Required parameters

=over 2

=item * streamid  [String]  The stream id this rule belongs to.

=item * streamRuleId  [String]  The stream rule id we are updating

=item * JSON body [String]  

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head2 Streams

Manage streams

=head3 streams_get

Get a list of all streams

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head3 streams_create

Create a stream

=head4 Required parameters

=over 2

=item * JSON body [String]  

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 streams_get_enabled

Get a list of all streams

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head3 streams_stream_throughput

Current throughput of all visible streams on this node in messages per second

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 get_streams_get

Get a single stream

=head4 Required parameters

=over 2

=item * streamId  [String]  

=back

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head3 streams_delete

Delete a stream

=head4 Required parameters

=over 2

=item * streamId  [String]  

=back

Returns: Normal Furl::Response, possible data in content

=head3 streams_update

Update a stream

=head4 Required parameters

=over 2

=item * JSON body [String]  

=item * streamId  [String]  

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 streams_clone_stream

Clone a stream

=head4 Required parameters

=over 2

=item * streamId  [String]  

=item * JSON body [String]  

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 streams_pause

Pause a stream

=head4 Required parameters

=over 2

=item * streamId  [String]  

=back

Returns: Normal Furl::Response, possible data in content

=head3 streams_resume

Resume a stream

=head4 Required parameters

=over 2

=item * streamId  [String]  

=back

Returns: Normal Furl::Response, possible data in content

=head3 streams_test_match

Test matching of a stream against a supplied message

=head4 Required parameters

=over 2

=item * streamId  [String]  

=item * JSON body [String]  

=back

Returns: [String] Normal Furl::Response, possible data in content

=head3 streams_one_stream_throughput

Current throughput of this stream on this node in messages per second

=head4 Required parameters

=over 2

=item * streamId  [String]  

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head2 System

System information of this node.

=head3 system

Get system overview

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head3 system_fields

Get list of message fields that exist

Note: This operation is comparably fast because it reads directly from the indexer mapping.

=head4 Optional parameters

=over 2

=item * limit [Integer] Maximum number of fields to return. Set to 0 for all fields.

=back

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head3 system_jvm

Get JVM information

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head3 system_permissions

Get all available user permissions.

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head3 system_reader_permissions

Get the initial permissions assigned to a reader account

=head4 Required parameters

=over 2

=item * username  [String]  

=back

Returns: [L</ReaderPermissionResponse>] Normal Furl::Response, with decoded JSON in json element

=head3 system_pause_processing

Pauses message processing

Note: Inputs that are able to reject or requeue messages will do so, others will buffer messages in memory. Keep an eye on the heap space utilization while message processing is paused.

Returns: Normal Furl::Response, possible data in content

=head3 system_resume_processing

Resume message processing

Returns: Normal Furl::Response, possible data in content

=head3 system_threaddump

Get a thread dump

Returns: [String] Normal Furl::Response, possible plain text response in content

=head2 System/Buffers

Buffer information of this node.

=head3 system_buffers_utilization

Get current utilization of buffers and caches of this node.

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head2 System/Cluster

Node discovery

=head3 system_cluster_node

Information about this node.

Note: This is returning information of this node in context to its state in the cluster. Use the system API of the node itself to get system information.

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head3 system_cluster_nodes

List all active nodes in this cluster.

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head3 get_system_cluster_node

Information about a node.

Note: This is returning information of a node in context to its state in the cluster. Use the system API of the node itself to get system information.

=head4 Required parameters

=over 2

=item * nodeId  [String]  

=back

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head2 System/Deflector

Index deflector management

=head3 system_deflector_deflector

Get current deflector status

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 system_deflector_config

Get deflector configuration. Only available on master nodes.

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 system_deflector_cycle

Cycle deflector to new/next index

Returns: Normal Furl::Response, possible data in content

=head2 System/IndexRanges

Index timeranges

=head3 system_index_ranges_list

Get a list of all index ranges

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head3 system_index_ranges_rebuild

Rebuild/sync index range information.

Note: This triggers a systemjob that scans every index and stores meta information about what indices contain messages in what timeranges. It atomically overwrites already existing meta information.

Returns: Normal Furl::Response, with decoded JSON in json element

=head2 System/Inputs

Message inputs of this node

=head3 system_inputs_list

Get all inputs of this node

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head3 system_inputs_create

Launch input on this node

=head4 Required parameters

=over 2

=item * JSON body [String]  

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 system_inputs_types

Get all available input types of this node

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head3 system_inputs_info

Get information about a single input type

=head4 Required parameters

=over 2

=item * inputType [String]  

=back

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head3 system_inputs_single

Get information of a single input on this node

=head4 Required parameters

=over 2

=item * inputId [String]  

=back

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head3 system_inputs_terminate

Terminate input on this node

=head4 Required parameters

=over 2

=item * inputId [String]  

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 system_inputs_launch_existing

Launch existing input on this node

=head4 Required parameters

=over 2

=item * inputId [String]  

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head2 System/Jobs

Systemjobs

=head3 system_jobs_trigger

Trigger new job

=head4 Required parameters

=over 2

=item * JSON body [String]  

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 system_jobs_list

List currently running jobs

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head3 system_jobs_get

Get information of a specific currently running job

=head4 Required parameters

=over 2

=item * jobId [String]  

=back

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head2 System/LDAP

LDAP settings

=head3 system_l_d_a_p_get_ldap_settings

Get the LDAP configuration if it is configured

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 system_l_d_a_p_update_ldap_settings

Update the LDAP configuration

=head4 Required parameters

=over 2

=item * JSON body [String]  

=back

Returns: Normal Furl::Response, possible data in content

=head3 system_l_d_a_p_delete_ldap_settings

Remove the LDAP configuration

Returns: Normal Furl::Response, possible data in content

=head3 system_l_d_a_p_test_ldap_configuration

Test LDAP Configuration

=head4 Required parameters

=over 2

=item * Configuration to test [LdapTestConfigRequest] 

=back

Returns: [L</LdapTestConfigResponse>] Normal Furl::Response, with decoded JSON in json element

=head2 System/Loggers

Internal Graylog2 loggers

=head3 system_loggers_loggers

List all loggers and their current levels

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head3 system_loggers_subsytems

List all logger subsystems and their current levels

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head3 system_loggers_set_subsystem_logger_level

Set the loglevel of a whole subsystem

Note: Provided level is falling back to DEBUG if it does not exist

=head4 Required parameters

=over 2

=item * subsystem [String]  

=item * level [String]  

=back

Returns: Normal Furl::Response, possible data in content

=head3 system_loggers_set_single_logger_level

Set the loglevel of a single logger

Note: Provided level is falling back to DEBUG if it does not exist

=head4 Required parameters

=over 2

=item * loggerName  [String]  

=item * level [String]  

=back

Returns: Normal Furl::Response, possible data in content

=head2 System/Messages

Internal Graylog2 messages

=head3 system_messages_all

Get internal Graylog2 system messages

=head4 Optional parameters

=over 2

=item * page  [Integer] Page

=back

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head2 System/Metrics

Internal Graylog2 metrics

=head3 system_metrics_metrics

Get all metrics

Note: Note that this might return a huge result set.

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head3 system_metrics_metric_names

Get all metrics keys/names

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head3 system_metrics_by_namespace

Get all metrics of a namespace

=head4 Required parameters

=over 2

=item * namespace [String]  

=back

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head3 system_metrics_single_metric

Get a single metric

=head4 Required parameters

=over 2

=item * metricName  [String]  

=back

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head3 system_metrics_historic_single_metric

Get history of a single metric

Note: The maximum retention time is currently only 5 minutes.

=head4 Required parameters

=over 2

=item * metricName  [String]  

=back

=head4 Optional parameters

=over 2

=item * after [Long]  Only values for after this UTC timestamp (1970 epoch)

=back

Returns: [String] Normal Furl::Response, possible data in content

=head2 System/Notifications

Notifications generated by the system

=head3 system_notifications_list_notifications

Get all active notifications

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head3 system_notifications_delete_notification

Delete a notification

=head4 Optional parameters

=over 2

=item * notificationType  [String]  

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head2 System/Radios

Management of graylog2-radio nodes.

=head3 system_radios_radios

List all active radios in this cluster.

Returns: [String] Normal Furl::Response, possible data in content

=head3 system_radios_radio

Information about a radio.

Note: This is returning information of a radio in context to its state in the cluster. Use the system API of the node itself to get system information.

=head4 Required parameters

=over 2

=item * radioId [String]  

=back

Returns: [String] Normal Furl::Response, possible data in content

=head3 system_radios_register_input

Register input of a radio.

Note: Radio inputs register their own inputs here for persistence after they successfully launched it.

=head4 Required parameters

=over 2

=item * JSON body [String]  

=item * radioId [String]  

=back

Returns: Normal Furl::Response, possible data in content

=head3 system_radios_persisted_inputs

Persisted inputs of a radio.

Note: This is returning the configured persisted inputs of a radio node. This is *not* returning the actually running inputs on a radio node. Radio nodes use this resource to get their configured inputs on startup.

=head4 Required parameters

=over 2

=item * radioId [String]  

=back

Returns: [String] Normal Furl::Response, possible data in content

=head3 system_radios_unregister_input

Unregister input of a radio.

Note: Radios unregister their inputs when they are stopped/terminated on the radio.

=head4 Required parameters

=over 2

=item * radioId [String]  

=item * inputId [String]  

=back

Returns: Normal Furl::Response, possible data in content

=head3 system_radios_ping

Ping - Accepts pings of graylog2-radio nodes.

Note: Every graylog2-radio node is regularly pinging to announce that it is active.

=head4 Required parameters

=over 2

=item * JSON body [String]  

=item * radioId [String]  

=back

Returns: Normal Furl::Response, possible data in content

=head2 System/Sessions

Login for interactive user sessions

=head3 system_sessions_new_session

Create a new session

Note: This request creates a new session for a user or reactivates an existing session: the equivalent of logging in.

=head4 Required parameters

=over 2

=item * Login request [SessionCreateRequest]  Username and credentials

=back

Returns: [Session] Normal Furl::Response, possible data in content

=head3 system_sessions_terminate_session

Terminate an existing session

Note: Destroys the session with the given ID: the equivalent of logging out.

=head4 Required parameters

=over 2

=item * sessionId [String]  

=back

Returns: Normal Furl::Response, possible data in content

=head2 System/Throughput

Message throughput of this node

=head3 system_throughput_total

Current throughput of this node in messages per second

Returns: [String] Normal Furl::Response, with decoded JSON in json element

=head2 Users

User accounts

=head3 users_list_users

List all users

Note: The permissions assigned to the users are always included.

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 users_create

Create a new user account.

=head4 Required parameters

=over 2

=item * JSON body [String]  

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 users_change_user

Modify user details.

=head4 Required parameters

=over 2

=item * username  [String]  The name of the user to modify.

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 users_delete_user

Removes a user account.

=head4 Required parameters

=over 2

=item * username  [String]  The name of the user to delete.

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 users_get

Get user details

Note: The user's permissions are only included if a user asks for his own account or for users with the necessary permissions to edit permissions.

=head4 Required parameters

=over 2

=item * username  [String]  The username to return information for.

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 users_change_password

Update the password for a user.

=head4 Required parameters

=over 2

=item * username  [String]  The name of the user whose password to change.

=item * JSON body [String]  The hashed old and new passwords.

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 users_edit_permissions

Update a user's permission set.

=head4 Required parameters

=over 2

=item * username  [String]  The name of the user to modify.

=item * JSON body [String]  The list of permissions to assign to the user.

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 users_delete_permissions

Revoke all permissions for a user without deleting the account.

=head4 Required parameters

=over 2

=item * username  [String]  The name of the user to modify.

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head3 users_list_tokens

Retrieves the list of access tokens for a user

=head4 Required parameters

=over 2

=item * username  [String]  

=back

Returns: [L</TokenList>] Normal Furl::Response, with decoded JSON in json element

=head3 users_generate_new_token

Generates a new access token for a user

=head4 Required parameters

=over 2

=item * username  [String]  

=item * name  [String]  Descriptive name for this token (e.g. 'cronjob') 

=back

Returns: [Token] Normal Furl::Response, with decoded JSON in json element

=head3 users_revoke_token

Removes a token for a user

=head4 Required parameters

=over 2

=item * username  [String]  

=item * access token  [String]  

=back

Returns: Normal Furl::Response, with decoded JSON in json element

=head1 AUTHOR

Kevin Mulholland <moodfarm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Kevin Mulholland.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
