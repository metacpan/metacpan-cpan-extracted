package Monitoring::Icinga2::Client::REST;

use strict;
use warnings;
use 5.010_001;
use Carp;
use LWP::UserAgent;
use HTTP::Request;
use URI::Escape;
use JSON;
use Encode qw( encode_utf8 );
use Scalar::Util 'looks_like_number';
use version 0.77; our $VERSION = version->declare('2.0.3');

sub new {
    my ($class, $hostname, $port, $path, $version, $insecure) = @_;
    my $cafile;

    defined $hostname
        or croak "hostname argument is required";

    unless( looks_like_number($port) ) {
        # enable hash-style arg passing
        my %args = @_[2..$#_];
        $port = $args{port};
        $path = $args{path};
        $version = $args{version};
        $insecure = $args{insecure};

        if(defined $args{cacert}) {
            # Set ENV variable in case we're using Net::SSL for LWP's HTTPS
            $cafile = $ENV{HTTPS_CA_FILE} = $args{cacert};
        }
    }

    my $self  = bless {
        hostname => $hostname,
        port     => $port // 5665,
        path     => $path // '/',
        version  => $version // 1,
    }, $class;

    $self->{path} .= "/" unless $self->{path} =~ /\/$/;

    $self->{url} = sprintf(
        "https://%s:%d%sv%d",
        @$self{qw/ hostname port path version /}
    );

    $self->{ua} = LWP::UserAgent->new(
        $insecure ? (
            ssl_opts => {
                # Don't verify certs with either SSL module used by LWP
                verify_hostname => 0,
                SSL_verify_callback => sub { 1 },
                # Set ca_file for IO::Socket::SSL
                defined $cafile ? ( SSL_ca_file => $cafile) : (),
            },
        ) : (),
    );

    $self->{ua}->default_header( 'Accept' => 'application/json' );
    $self->{login_status} = "not logged in";

    return $self;
}

sub do_request {
    my ( $self, $method, $uri, $params, $data, $plaintext ) = @_;

    my $request_url = "$self->{url}/$uri";
    $request_url .= '?' . _encode_params($params) if $params;

    my $req = HTTP::Request->new( $method => $request_url );

    if ($data) {
        $data = encode_json($data);
        $req->content($data);
    }

    $self->{res} = $self->{ua}->request($req);

    return unless $self->{res}->is_success;

    # Try with first plaintext if plaintext is set
    if ($plaintext) {
        my $str = encode_utf8( $self->{res}->content );
        if ($str) {
            return $str;
        }
    }

    # Handle non utf8 chars
    my $json_result = decode_json( encode_utf8( $self->{res}->content ) );
    if ($json_result) {
        return $json_result;
    }
    return;
}

sub _encode_params {
    return join '&', map { _encode_param($_) } split /&/, shift;
}

sub _encode_param {
    return join '=', map { uri_escape( $_ ) } split /=/, shift;
}

{
    my %type2keys = (
        CheckCommand => [
            [ qw/ arguments command env vars timeout / ],
            [ qw/ templates zone / ],
        ],
        Downtime => [
            [ qw/ author comment duration end_time entry_time fixed
                host_name service_name start_time vars triggers /
            ],
            [ qw/ templates zone / ],
        ],
        Host => [
            [ qw/ address6 address check_command display_name event_command
                action_url notes notes_url vars icon_image icon_image_alt
                check_interval max_check_attempts retry_interval /
            ],
            [ qw/ check_period check_timeout enable_active_checks
                enable_event_handler enable_flapping enable_notifications
                enable_passive_checks enable_perfdata groups notes
                retry_interval templates zone /
            ],
        ],
        HostGroup => [
            [ qw/ action_url display_name notes notes_url vars / ],
            [ qw/ groups templates zone / ],
        ],
        ScheduledDowntime => [
            [ qw/ author comment duration fixed host_name ranges
                service_name /
            ],
            [ qw/ templates zone / ],
        ],
        Service => [
            [ qw/ vars action_url check_command check_interval display_name
                notes notes_url event_command max_check_attempts
                retry_interval /
            ],
            [ qw/ check_period check_timeout enable_active_checks
                enable_event_handler enable_flapping enable_notifications
                enable_passive_checks enable_perfdata groups icon_image
                icon_image_alt notes templates zone /
            ],
        ],
        ServiceGroup => [
            [ qw/ action_url display_name notes notes_url vars / ],
            [ qw/ groups templates zone / ],
        ],
        TimePeriod => [
            [ qw/ display_name excludes includes prefer_includes
                ranges vars /
            ],
            [ qw/ templates zone / ],
        ],
        User => [
            [ qw/ display_name email enable_notifications pager states
                period vars /
            ],
            [ qw/ groups templates zone / ],
        ],
        UserGroup => [
            [ qw/ display_name vars / ],
            [ qw/ groups templates zone / ],
        ],
    );

    sub export {
        my ( $self, $full, $api_only ) = @_;
        my $result = decode_json( encode_utf8( $self->{res}->content ) );
        my $type   = $result->{results}[0]{type};
        # Do nothing if there is nothing to export
        return unless $type;
        # We only support certain object types
        return unless exists $type2keys{$type};

        my @keys = @{$type2keys{$type}[0]};
        push @keys, @{$type2keys{$type}[1]} if $full;

        my @results;
        foreach my $object ( @{ $result->{results} } ) {
            next if $api_only and $object->{attrs}{package} ne "_api";

            # The object needs to know its own name stored in a read/write field
            $object->{attrs}{vars}{__export_name} = $object->{attrs}{__name};

            my %attrs;
            @attrs{@keys} = @{$object->{attrs}}{@keys};
            push @results, { attrs => \%attrs };
        }
        return \@results;
    }
}

sub login {
    my ( $self, $username, $password ) = @_;

    return if $self->{logged_in};

    $self->{ua}->credentials( "$self->{hostname}:$self->{port}",
        "Icinga 2", $username, $password );

    $self->do_request( "GET", "/status", "", "" );

    if ( $self->request_code == 200 ) {
        $self->{login_status} = "login successful";
        $self->{logged_in}    = 1;
    }
    elsif ( $self->request_code == 401 ) {
        $self->{login_status} = "wrong username/password";
    }
    else {
        $self->{login_status} =
          "unknown status line: " . $self->{res}->status_line;
    }

    return $self->{logged_in};
}

sub logout { shift->{logged_in} = undef; }
sub request_code { return shift->{res}->code; }
sub request_status_line { return shift->{res}->status_line; }
sub logged_in { return shift->{logged_in}; }
sub login_status { return shift->{login_status}; }

1;
