package Net::OpenStack::Swift;
use Carp;
use Mouse;
use Mouse::Util::TypeConstraints;
use JSON;
use Path::Tiny;
use Data::Validator;
use Net::OpenStack::Swift::Util qw/uri_escape uri_unescape debugf/;
use Net::OpenStack::Swift::InnerKeystone;
use namespace::clean -except => 'meta';
our $VERSION = "0.15";


subtype 'Path' => as 'Path::Tiny';
coerce  'Path' => from 'Str' => via { Path::Tiny->new($_) };


has auth_version => (is => 'rw', required => 1, default => sub { $ENV{OS_AUTH_VERSION} || "2.0"});
has auth_url     => (is => 'rw', required => 1, default => sub { $ENV{OS_AUTH_URL}    || '' });
has user         => (is => 'rw', required => 1, default => sub { $ENV{OS_USERNAME}    || '' });
has password     => (is => 'rw', required => 1, default => sub { $ENV{OS_PASSWORD}    || '' });
has tenant_name  => (is => 'rw', required => 1, default => sub { $ENV{OS_TENANT_NAME} || '' });
has region       => (is => 'rw', required => 1, default => sub { $ENV{OS_REGION_NAME} || '' });
has storage_url  => (is => 'rw');
has token        => (is => 'rw');
has agent_options => (is => 'rw', isa => 'HashRef', default => sub{+{ timeout => 10 }});
has agent => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $furl_options = +{
            timeout => $self->agent_options->{timeout} || 10
        };
        $furl_options->{agent} ||= $self->agent_options->{user_agent};
        return Furl->new(%{$furl_options});
    },
);

sub _request {
    my $self = shift;
    my $args = shift;
    
    my $res = $self->agent->request(
        method          => $args->{method},
        url             => $args->{url},
        special_headers => $args->{special_headers},
        headers         => $args->{header},
        write_code      => $args->{write_code},
        write_file      => $args->{write_file},
        content         => $args->{content},
    );
    return $res;
}

sub auth_keystone {
    my $self = shift;
    (my $load_version = $self->auth_version) =~ s/\./_/;
    my $ksclient = "Net::OpenStack::Swift::InnerKeystone::V${load_version}"->new(
        auth_url => $self->auth_url,
        user     => $self->user,
        password => $self->password,
        tenant_name => $self->tenant_name,
    );
    $ksclient->agent($self->agent);
    my $auth_token = $ksclient->auth();
    my $endpoint = $ksclient->service_catalog_url_for(service_type=>'object-store', endpoint_type=>'publicURL', region=>$self->region);
    croak "Not found endpoint type 'object-store'" unless $endpoint;
    $self->token($auth_token);
    $self->storage_url($endpoint);
    return 1;
}

sub get_auth {
    my $self = shift;
    $self->auth_keystone();
    return ($self->storage_url, $self->token);
}

sub get_account {
    my $self = shift;
    my $rule = Data::Validator->new(
        url            => { isa => 'Str', default => $self->storage_url},
        token          => { isa => 'Str', default => $self->token },
        marker         => { isa => 'Str', default => undef },
        limit          => { isa => 'Int', default => undef },
        prefix         => { isa => 'Str', default => undef },
        end_marker     => { isa => 'Str', default => undef },
    );
    my $args = $rule->validate(@_);

    # make query strings
    my @qs = ('format=json');
    if ($args->{marker}) {
        push @qs, sprintf "marker=%s", uri_escape($args->{marker});
    }
    if ($args->{limit}) {
        push @qs, sprintf("limit=%d", $args->{limit});
    }
    if ($args->{prefix}) {
        push @qs, sprintf("prefix=%s", uri_escape($args->{prefix}));
    }
    if ($args->{end_marker}) {
        push @qs, sprintf("end_marker=%s", uri_escape($args->{end_marker}));
    }

    my $request_header = ['X-Auth-Token' => $args->{token}];
    my $request_url    = sprintf "%s?%s", $args->{url}, join('&', @qs);
    debugf("get_account() request header %s", $request_header);
    debugf("get_account() request url: %s",   $request_url);

    my $res = $self->_request({
        method => 'GET', url => $request_url, header => $request_header
    });

    croak "Account GET failed: ".$res->status_line unless $res->is_success;
    my @headers = $res->headers->flatten();
    debugf("get_account() response headers %s", \@headers);
    debugf("get_account() response body %s",    $res->content);
    my %headers = @headers;
    return (\%headers, from_json($res->content));
}

sub head_account {
    my $self = shift;
    my $rule = Data::Validator->new(
        url            => { isa => 'Str', default => $self->storage_url},
        token          => { isa => 'Str', default => $self->token },
    );
    my $args = $rule->validate(@_);

    my $request_header = ['X-Auth-Token' => $args->{token}];
    debugf("head_account() request header %s", $request_header);
    debugf("head_account() request url: %s",   $args->{url});

    my $res = $self->_request({
        method => 'HEAD', url => $args->{url}, header => $request_header
    });

    croak "Account HEAD failed: ".$res->status_line unless $res->is_success;
    my @headers = $res->headers->flatten();
    debugf("head_account() response headers %s", \@headers);
    debugf("head_account() response body %s",    $res->content);
    my %headers = @headers;
    return \%headers;
}

sub post_account {
    my $self = shift;
    my $rule = Data::Validator->new(
        url            => { isa => 'Str', default => $self->storage_url},
        token          => { isa => 'Str', default => $self->token },
        headers        => { isa => 'HashRef'},
    );
    my $args = $rule->validate(@_);
    my $request_header = ['X-Auth-Token' => $args->{token}];
    my @additional_headers = %{ $args->{headers} };
    push @{$request_header}, @additional_headers;
    my $request_url = $args->{url};
    debugf("post_account() request header %s", $request_header);
    debugf("post_account() request url: %s",   $request_url);

    my $res = $self->_request({
        method => 'POST', url => $request_url, header => $request_header
    });

    croak "Account POST failed: ".$res->status_line unless $res->is_success;
    my @headers = $res->headers->flatten();
    debugf("post_account() response headers %s", \@headers);
    debugf("post_account() response body %s",    $res->content);
    my %headers = @headers;
    return \%headers;
}

sub get_container {
    my $self = shift;
    my $rule = Data::Validator->new(
        url            => { isa => 'Str', default => $self->storage_url},
        token          => { isa => 'Str', default => $self->token },
        container_name => { isa => 'Path', coerce => 1 },
        marker         => { isa => 'Str', default => '', coerce => 1 },
        limit          => { isa => 'Int', default => 0,  coerce => 1 },
        prefix         => { isa => 'Str', default => '', coerce => 1 },
        delimiter      => { isa => 'Str', default => '', coerce => 1 },
        end_marker     => { isa => 'Str', default => '', coerce => 1 },
        full_listing   => { isa => 'Bool', default => 0, coerce => 1 },
    );
    my $args = $rule->validate(@_);

    if ($args->{full_listing}) {
        my @full_containers = ();
        my ($rv_h, $rv_c) = __PACKAGE__->new->get_container(
            url            => $args->{url},
            token          => $args->{token},
            container_name => $args->{container_name},
            marker         => $args->{marker},
            limit          => $args->{limit},
            prefix         => $args->{prefix},
            delimiter      => $args->{delimiter},
            end_marker     => $args->{end_marker},
        );  
		my $total_count = int $rv_h->{'x-container-object-count'};
        my $last_n      = scalar @{$rv_c};
        if (scalar @{$rv_c}) {
            push @full_containers, @{$rv_c};
        }
		until ($total_count == scalar @full_containers) {
            # find marker
			my $marker;
			unless ($args->{delimiter}) {
				$marker = $full_containers[scalar(@full_containers) - 1]->{name};
			} 
			else {
				if (exists $full_containers[scalar(@full_containers) - 1]->{name}) {
					$marker = $full_containers[scalar(@full_containers) - 1]->{name};
				}
				else {
					$marker = $full_containers[scalar(@full_containers) - 1]->{subdir};
				}
			}
            # 
			my ($rv_h2, $rv_c2) = __PACKAGE__->new->get_container(
				url            => $args->{url},
				token          => $args->{token},
				container_name => $args->{container_name},
				marker         => $marker,
				limit          => $args->{limit},
				prefix         => $args->{prefix},
				delimiter      => $args->{delimiter},
				end_marker     => $args->{end_marker},
			);  
			if (scalar @{$rv_c2}) {
				push @full_containers, @{$rv_c2};
			}
			else {
				last;
			}
		}
    	return ($rv_h, \@full_containers);
    }

    # make query strings
    my @qs = ('format=json');
    if ($args->{marker}) {
        push @qs, sprintf "marker=%s", uri_escape($args->{marker});
    }
    if ($args->{limit}) {
        push @qs, sprintf("limit=%d", $args->{limit});
    }
    if ($args->{prefix}) {
        push @qs, sprintf("prefix=%s", uri_escape($args->{prefix}));
    }
    if ($args->{delimiter}) {
        push @qs, sprintf("delimiter=%s", uri_escape($args->{delimiter}));
    }
    if ($args->{end_marker}) {
        push @qs, sprintf("end_marker=%s", uri_escape($args->{end_marker}));
    }

    my $request_header = ['X-Auth-Token' => $args->{token}];
    my $request_url    = sprintf "%s/%s?%s", $args->{url}, uri_escape($args->{container_name}->stringify), join('&', @qs);
    debugf("get_container() request header %s", $request_header);
    debugf("get_container() request url: %s",   $request_url);

    my $res = $self->_request({
        method => 'GET', url => $request_url, header => $request_header
    });

    croak "Container GET failed: ".$res->status_line unless $res->is_success;
    my @headers = $res->headers->flatten();
    debugf("get_container() response headers %s", \@headers);
    debugf("get_container() response body %s",    $res->content);
    my %headers = @headers;
    return (\%headers, from_json($res->content));
}

sub head_container {
    my $self = shift;
    my $rule = Data::Validator->new(
        url            => { isa => 'Str', default => $self->storage_url},
        token          => { isa => 'Str', default => $self->token },
        container_name => { isa => 'Path', coerce => 1 },
    );
    my $args = $rule->validate(@_);

    my $request_header = ['X-Auth-Token' => $args->{token}];
    my $request_url    = sprintf "%s/%s", $args->{url}, uri_escape($args->{container_name}->stringify);
    debugf("head_container() request header %s", $request_header);
    debugf("head_container() request url: %s",   $args->{url});

    my $res = $self->_request({
        method => 'HEAD', url => $request_url, header => $request_header
    });

    croak "Container HEAD failed: ".$res->status_line unless $res->is_success;
    my @headers = $res->headers->flatten();
    debugf("head_container() response headers %s", \@headers);
    debugf("head_container() response body %s",    $res->content);
    my %headers = @headers;
    return \%headers;
}

sub put_container {
    my $self = shift;
    my $rule = Data::Validator->new(
        url            => { isa => 'Str', default => $self->storage_url},
        token          => { isa => 'Str', default => $self->token },
        container_name => { isa => 'Path', coerce => 1 },
        content_length => { isa => 'Int', default => sub { 0 } },
        content_type   => { isa => 'Str', default => 'application/directory'},
    );
    my $args = $rule->validate(@_);

    my $request_header = [
        'X-Auth-Token' => $args->{token},
        'Content-Length' => $args->{content_length},
        'Content-Type'   => $args->{content_type},
    ];

    my $request_url    = sprintf "%s/%s", $args->{url}, uri_escape($args->{container_name}->stringify);
    debugf("put_account() request header %s", $request_header);
    debugf("put_account() request url: %s",   $request_url);

    my $res = $self->_request({
        method => 'PUT', url => $request_url, header => $request_header
    });

    croak "Container PUT failed: ".$res->status_line unless $res->is_success;
    my @headers = $res->headers->flatten();
    debugf("put_container() response headers %s", \@headers);
    debugf("put_container() response body %s",    $res->content);
    my %headers = @headers;
    return \%headers;
}

sub post_container {
    my $self = shift;
    my $rule = Data::Validator->new(
        url            => { isa => 'Str', default => $self->storage_url},
        token          => { isa => 'Str', default => $self->token },
        container_name => { isa => 'Path', coerce => 1 },
        headers        => { isa => 'HashRef'},
    );
    my $args = $rule->validate(@_);

    my $request_header = ['X-Auth-Token' => $args->{token}];
    unless (exists $args->{headers}->{'Content-Length'} || exists($args->{headers}->{'content-length'})) {
        $args->{headers}->{'Content-Length'} = 0;
    }
    my @additional_headers = %{ $args->{headers} };
    push @{$request_header}, @additional_headers;
    my $request_url    = sprintf "%s/%s", $args->{url}, uri_escape($args->{container_name}->stringify);
    debugf("post_container() request header %s", $request_header);
    debugf("post_container() request url: %s",   $request_url);

    my $res = $self->_request({
        method => 'POST', url => $request_url, header => $request_header
    });

    croak "Container POST failed: ".$res->status_line unless $res->is_success;
    my @headers = $res->headers->flatten();
    debugf("post_container() response headers %s", \@headers);
    debugf("post_container() response body %s",    $res->content);
    my %headers = @headers;
    return \%headers;
}

sub delete_container {
    my $self = shift;
    my $rule = Data::Validator->new(
        url            => { isa => 'Str', default => $self->storage_url},
        token          => { isa => 'Str', default => $self->token },
        container_name => { isa => 'Path', coerce => 1 },
    );
    my $args = $rule->validate(@_);

    # corecing nested path
    #$args->{container_name} = path($args->{container_name})->stringify;

    my $request_header = ['X-Auth-Token' => $args->{token}];
    my $request_url = sprintf "%s/%s", $args->{url}, uri_escape($args->{container_name}->stringify);
    debugf("delete_container() request header %s", $request_header);
    debugf("delete_container() request url: %s", $request_url);

    my $res = $self->_request({
        method => 'DELETE', url => $request_url, header => $request_header,
        content => []
    });

    croak "Container DELETE failed: ".$res->status_line unless $res->is_success;
    my @headers = $res->headers->flatten();
    debugf("delete_container() response headers %s", \@headers);
    debugf("delete_container() response body %s",    $res->content);
    my %headers = @headers;
    return \%headers;
}

sub get_object {
    my $self = shift;
    my $rule = Data::Validator->new(
        url            => { isa => 'Str', default => $self->storage_url },
        token          => { isa => 'Str', default => $self->token },
        container_name => { isa => 'Path', coerce => 1 },
        object_name    => { isa => 'Str'},
        write_file     => { isa => 'FileHandle', xor => [qw(write_code)] },
        write_code     => { isa => 'CodeRef' },
    );
    my $args = $rule->validate(@_);

    my $request_header = ['X-Auth-Token' => $args->{token}];
    my $request_url    = sprintf "%s/%s/%s", $args->{url},
        uri_escape($args->{container_name}->stringify),
        uri_escape($args->{object_name});
    my %special_headers = ('Content-Length' => undef);
    debugf("get_object() request header %s", $request_header);
    debugf("get_object() request special headers: %s", $request_url);
    debugf("get_object() request url: %s", $request_url);

    my $request_params = {
        method => 'GET', url => $request_url, header => $request_header,
        special_headers => \%special_headers,
        write_code      => undef,
        write_file      => undef,
    };
    if (exists $args->{write_code}) {
        $request_params->{write_code} = $args->{write_code};
    }
    if (exists $args->{write_file}) {
        $request_params->{write_file} = $args->{write_file};
    }
    my $res = $self->_request($request_params);

    croak "Object GET failed: ".$res->status_line unless $res->is_success;
    my @headers = $res->headers->flatten();
    debugf("get_object() response headers %s", \@headers);
    debugf("get_object() response body length %s byte", length($res->content || 0));
    my %headers = @headers;
    my $etag = $headers{etag};
    $etag =~ s/^\s*(.*?)\s*$/$1/; # delete spaces
    return $etag;
}

sub head_object {
    my $self = shift;
    my $rule = Data::Validator->new(
        url            => { isa => 'Str', default => $self->storage_url},
        token          => { isa => 'Str', default => $self->token },
        container_name => { isa => 'Path', coerce => 1 },
        object_name    => { isa => 'Str'},
    );
    my $args = $rule->validate(@_);

    my $request_header = ['X-Auth-Token' => $args->{token}];
    my $request_url    = sprintf "%s/%s/%s", $args->{url},
        uri_escape($args->{container_name}->stringify),
        uri_escape($args->{object_name});
    debugf("head_object() request header %s", $request_header);
    debugf("head_object() request url: %s", $request_url);

    my $res = $self->_request({
        method => 'HEAD', url => $request_url, header => $request_header,
        content => []
    });

    croak "Object HEAD failed: ".$res->status_line unless $res->is_success;
    my @headers = $res->headers->flatten();
    debugf("head_object() response headers %s", \@headers);
    debugf("head_object() response body %s",    $res->content);
    my %headers = @headers;
    return \%headers;
}

sub put_object {
    my $self = shift;
    my $rule = Data::Validator->new(
        url            => { isa => 'Str', default => $self->storage_url},
        token          => { isa => 'Str', default => $self->token },
        container_name => { isa => 'Path', coerce => 1 },
        object_name    => { isa => 'Str'},
        content        => { isa => 'Str|FileHandle'},
        content_length => { isa => 'Int', default => sub { 0 } },
        content_type   => { isa => 'Str', default => ''},
        etag           => { isa => 'Str', default => undef },
        query_string   => { isa => 'Str', default => sub {''} },
        headers        => { isa => 'HashRef', default => {} },
    );
    my $args = $rule->validate(@_);

    my $request_header = [
        'X-Auth-Token'   => $args->{token},
        'Content-Length' => $args->{content_length},
        'Content-Type'   => $args->{content_type},
    ];
    if ($args->{etag}) {
        push @{$request_header}, ('ETag' => $args->{etag});
    }
    push @{$request_header}, %{ $args->{headers} };

    my $request_url = sprintf "%s/%s/%s", $args->{url},
        uri_escape($args->{container_name}->stringify),
        uri_escape($args->{object_name});
    if ($args->{query_string}) {
        $request_url .= '?'.$args->{query_string};
    }
    debugf("put_object() request header %s", $request_header);
    debugf("put_object() request url: %s", $request_url);

    my $res = $self->_request({
        method => 'PUT', url => $request_url, header => $request_header, content => $args->{content}
    });

    croak "Object PUT failed: ".$res->status_line unless $res->is_success;
    my @headers = $res->headers->flatten();
    debugf("put_object() response headers %s", \@headers);
    debugf("put_object() response body %s",    $res->content);
    my %headers = @headers;
    my $etag = $headers{etag};
    $etag =~ s/^\s*(.*?)\s*$/$1/; # delete spaces
    return $etag;
}

sub post_object {
    my $self = shift;
    my $rule = Data::Validator->new(
        url            => { isa => 'Str', default => $self->storage_url},
        token          => { isa => 'Str', default => $self->token },
        container_name => { isa => 'Path', coerce => 1 },
        object_name    => { isa => 'Str'},
        headers        => { isa => 'HashRef'},
    );
    my $args = $rule->validate(@_);

    my $request_header = ['X-Auth-Token' => $args->{token}];
    my @additional_headers = %{ $args->{headers} };
    push @{$request_header}, @additional_headers;
    my $request_url    = sprintf "%s/%s/%s", $args->{url},
        uri_escape($args->{container_name}->stringify),
        uri_escape($args->{object_name});
    debugf("post_object() request header %s", $request_header);
    debugf("post_object() request url: %s",   $request_url);

    my $res = $self->_request({
        method => 'POST', url => $request_url, header => $request_header
    });

    croak "Object POST failed: ".$res->status_line unless $res->is_success;
    my @headers = $res->headers->flatten();
    debugf("post_object() response headers %s", \@headers);
    debugf("post_object() response body %s",    $res->content);
    my %headers = @headers;
    return \%headers;
}

sub delete_object {
    my $self = shift;
    my $rule = Data::Validator->new(
        url            => { isa => 'Str', default => $self->storage_url},
        token          => { isa => 'Str', default => $self->token },
        container_name => { isa => 'Path', coerce => 1 },
        object_name    => { isa => 'Str'},
    );
    my $args = $rule->validate(@_);

    my $request_header = ['X-Auth-Token' => $args->{token}];
    my $request_url = sprintf "%s/%s/%s", $args->{url},
        uri_escape($args->{container_name}->stringify),
        uri_escape($args->{object_name});
    debugf("delete_object() request header %s", $request_header);
    debugf("delete_object() request url: %s", $request_url);

    my $res = $self->_request({
        method => 'DELETE', url => $request_url, header => $request_header,
        content => []
    });

    croak "Object DELETE failed: ".$res->status_line unless $res->is_success;
    my @headers = $res->headers->flatten();
    debugf("delete_object() response headers %s", \@headers);
    debugf("delete_object() response body %s",    $res->content);
    my %headers = @headers;
    return \%headers;
}

1;
__END__

=head1 NAME

Net::OpenStack::Swift - Perl Bindings for the OpenStack Object Storage API, known as Swift.

=head1 SYNOPSIS

    use Net::OpenStack::Swift;

    my $sw = Net::OpenStack::Swift->new(
        auth_url       => 'https://auth-endpoint-url/v2.0',
        user           => 'userid',
        password       => 'password',
        tenant_name    => 'project_id',
        # region         => 'REGION', # prefered region
        # auth_version => '2.0',      # by default
        # agent_options => +{
        #    timeout    => 10,
        #    user_agent => "Furl::HTTP",
        #}  
    );

    my ($storage_url, $token) = $sw->get_auth();

    my ($headers, $containers) = $sw->get_account(url => $storage_url, token => $token);
    # or,  storage_url and token can be omitted.
    my ($headers, $containers) = $sw->get_account();

    # 1.0 auth
    my $sw = Net::OpenStack::Swift->new(
        auth_url       => 'https://auth-endpoint-url/1.0',

        user           => 'region:user-id',
        password       => 'secret-api-key',

        # or private, if you are under the private network.
        auth_version  => '1.0',
        tenant_name   => 'public',
    );

=head1 DESCRIPTION

Perl Bindings for the OpenStack Object Storage API, known as Swift.

=head1 METHODS

=head2 new

Creates a client.

=over

=item auth_url

Required. The url of the authentication endpoint.

=item user

Required.

=item password

Required.

=item tenant_name

Required.
tenant name/project

=item auth_version

Optional.
default 2.0

=item agent_options | HashRef

Optional.
Http Client options

=back

=head2 get_auth

Get storage url and auth token.

    my ($storage_url, $token) = $sw->get_auth();

response:

=over

=item storage_url

Endpoint URL

=item token

Auth Token

=back

=head2 get_account

Show account details and list containers.

    my ($headers, $containers) = $sw->get_account(marker => 'hoge');

=over

=item maker

Optional.

=item end_maker

Optional.

=item prefix

Optional.

=item limit

Optional.

=back


=head2 head_account

Show account metadata.

    my $headers = $sw->head_account();

=head2 post_account

Create, update, or delete account metadata.

=head2 get_container

Show container details and list objects.

    my ($headers, $containers) = $sw->get_container(container_name => 'container1');

=head2 head_container

Show container metadata.

    my $headers = $sw->head_container(container_name => 'container1');

=head2 put_container

Create container.

    my $headers = $sw->put_container(container_name => 'container1')

=head2 post_container

Create, update, or delete container metadata.

=head2 delete_container

Delete container.

    my $headers = $sw->delete_container(container_name => 'container1');

=head2 get_object

Get object content and metadata.

    open my $fh, ">>:raw", "hoge.jpeg" or die $!;
    my $etag = $sw->get_object(container_name => 'container_name1', object_name => 'masakystjpeg',
        write_file => $fh,
    );
    # or chunked
    open my $fh, ">>:raw", "hoge.jpeg" or die $!;
    my $etag = $sw->get_object(container_name => 'container1', object_name => 'hoge.jpeg',
        write_code => sub {
            my ($status, $message, $headers, $chunk) = @_;
            print $status;
            print length($chunk);
            print $fh $chunk;
    });

=over

=item container_name

=item object_name

=item write_file: FileHandle

the response content will be saved here instead of in the response object.

=item write_code: Code reference

the response content will be called for each chunk of the response content.

=back

=head2 head_object

Show object metadata.

    my $headers = $sw->head_object(container_name => 'container1', object_name => 'hoge.jpeg');

=head2 put_object

Create or replace object.

    my $file = 'hoge.jpeg';
    open my $fh, '<', "./$file" or die;
    my $headers = $sw->put_object(container_name => 'container1',
        object_name => 'hoge.jpeg', content => $fh, content_length => -s $file);

=over

=item content: Str|FileHandle

=item content_length: Int

=item content_type: Str

Optional.
default none

=item headers: HashRef

=back

=head2 post_object

Create or update object metadata.

=head2 delete_object

Delete object.

    my $headers = $sw->delete_object(container_name => 'container1', object_name => 'hoge.jpeg');


=head1 Command Line Tool

perl client for the Swift API. a command-line script (swift.pl).

setup openstack environments

    $ export OS_AUTH_VERSION='1.0' # default 2.0
    $ export OS_AUTH_URL='https://*******'
    $ export OS_TENANT_NAME='*******'
    $ export OS_USERNAME='*******'
    $ export OS_PASSWORD='************'

cli examples

    $ swift.pl put container1
    $ swift.pl put container1 hello.txt (upload file)
    $ swift.pl list
    $ swift.pl list container1
    $ swift.pl list container1/hello.txt
    $ swift.pl get container1/hello.txt > hello.txt (download file)
    $ swift.pl delete container1/hello.txt
    $ swift.pl delete container1
    $ swift.pl delete 'container1/*'  (require quoting!)
    $ swift.pl post static '{"X-Container-Read":".r:*"}'

multi cpu support (parallel downloads and uploads)

    $ swift.pl donwload 'container1/*' (require quoting!)
    $ swift.pl upload 'container1/*' (require quoting!)

creating a .swift.pl.conf file in the user's home directory

    $ cat .swift.pl.conf 
    timeout=200
    user_agent=perl Net::OpenStack::Swift
    workers=8
    os_auth_url=
    os_tenant_name=
    os_username=
    os_password=

=head1 Debug

To print request/response Debug messages, $ENV{LM_DEBUG} must be true.

example

    $ LM_DEBUG=1 carton exec perl test.pl


=head1 SEE ALSO

http://docs.openstack.org/developer/swift/

http://docs.openstack.org/developer/keystone/


=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

masakyst E<lt>masakyst.public@gmail.comE<gt>

=cut
