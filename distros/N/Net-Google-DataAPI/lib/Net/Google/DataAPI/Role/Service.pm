package Net::Google::DataAPI::Role::Service;
use Any::Moose '::Role';
use Carp;
use LWP::UserAgent;
use URI;
use XML::Atom;
use XML::Atom::Entry;
use XML::Atom::Feed;
use Net::Google::DataAPI::Types;
use Net::Google::DataAPI::Auth::Null;
our $VERSION = '0.05';

$XML::Atom::ForceUnicode = 1;
$XML::Atom::DefaultVersion = 1;

# Make Net::HTTP not bail out on the connection if it doesn't receive
# a newline in a timely fashion.
my %OPTS = @LWP::Protocol::http::EXTRA_SOCK_OPTS;
$OPTS{MaxLineLength} ||= 1024 * 1024; # default was perhaps 8192
@LWP::Protocol::http::EXTRA_SOCK_OPTS = %OPTS;

has gdata_version => (
    isa => 'Str',
    is => 'ro',
    required => 1,
    default => '2.0',
);

has ua => (
    isa => 'LWP::UserAgent',
    is => 'ro',
    required => 1,
    lazy_build => 1,
);

has service => (
    does => 'Net::Google::DataAPI::Role::Service',
    is => 'ro',
    required => 1,
    lazy_build => 1,
);

has source => (
    isa => 'Str',
    is => 'ro',
    required => 1,
    default => __PACKAGE__,
);

has auth => (
    is => 'ro',
    does => 'Net::Google::DataAPI::Types::Auth',
    required => 1,
    lazy_build => 1,
    handles => ['sign_request'],
    coerce => 1,
);

has namespaces => (
    isa => 'HashRef[Str]',
    is => 'ro',
);

sub ns {
    my ($self, $name) = @_;

    if ($name eq 'gd') {
        return XML::Atom::Namespace->new('gd', 'http://schemas.google.com/g/2005')
    }
    $self->namespaces->{$name} or confess "Namespace '$name' is not defined!";
    return XML::Atom::Namespace->new($name, $self->namespaces->{$name});
};

sub _build_ua {
    my $self = shift;
    my $ua = LWP::UserAgent->new(
        agent => $self->source,
        requests_redirectable => [],
        env_proxy => 1,
    );
    $ua->default_headers(
        HTTP::Headers->new(
            GData_Version => $self->gdata_version,
        )
    );
    return $ua;
}

sub _build_auth { Net::Google::DataAPI::Auth::Null->new }

sub _build_service {return $_[0]}

sub request {
    my ($self, $args) = @_;
    my $req = $self->prepare_request($args);
    my $uri = $req->uri;
    my $res = eval {$self->ua->request($req)};
    if ($ENV{GOOGLE_DATAAPI_DEBUG} && $res) {
        warn $res->request ? $res->request->as_string : $req->as_string;
        warn $res->as_string;
    }
    if ($@ || $res->is_error) {
        confess sprintf(
            "request for '%s' failed:\n\t%s\n\t%s\n\t", 
            $uri, 
            ($res ? $res->status_line : $@),
            ($res ? $res->content : $!),
        );
    }
    if (my $res_obj = $args->{response_object}) {
        my $type = $res->content_type;
        if ($res->content_length && $type !~ m{^application/atom\+xml}) {
            confess sprintf(
                "Content-Type of response for '%s' is not 'application/atom+xml':  %s",
                $uri, 
                $type
            );
        }
        my $obj = eval {$res_obj->new(\($res->content))};
        confess sprintf(
            "response for '%s' is broken: %s", 
            $uri, 
            $@
        ) if $@;
        return $obj;
    }
    return $res;
}

sub prepare_request {
    my ($self, $args) = @_;
    if (ref($args) eq 'HTTP::Request') {
        return $args;
    }
    my $method = delete $args->{method};
    $method = $args->{content} || $args->{parts} ? 'POST' : 'GET' unless $method;
    my $uri = URI->new($args->{uri});
    my @existing_query = $uri->query_form;
    $uri->query_form(
        {
            @existing_query, 
            %{$args->{query}}
        }
    ) if $args->{query};
    my $req = HTTP::Request->new($method => "$uri");
    if (my $parts = $args->{parts}) {
        $req->header('Content-Type' => 'multipart/related');
        for my $part (@$parts) {
            ref $part eq 'HTTP::Message' 
                or confess "part argument should be a HTTP::Message object";
            $req->add_part($part);
        }
    }
    $req->content($args->{content}) if $args->{content};
    $req->header('Content-Type' => $args->{content_type}) if $args->{content_type};
    if ($args->{header}) {
        while (my @pair = each %{$args->{header}}) {
            $req->header(@pair);
        }
    }
    $self->sign_request($req, $args->{sign_host});
    return $req;
}

sub get_feed {
    my ($self, $url, $query) = @_;
    return $self->request(
        {
            uri => $url,
            query => $query,
            response_object => 'XML::Atom::Feed',
        }
    );
}

sub get_entry {
    my ($self, $url) = @_;
    return $self->request(
        {
            uri => $url,
            response_object => 'XML::Atom::Entry',
        }
    );
}

sub post {
    my ($self, $url, $entry, $header) = @_;
    return $self->request(
        {
            uri => $url,
            content => $entry->as_xml,
            header => $header || undef,
            content_type => 'application/atom+xml',
            response_object => ref $entry,
        }
    );
}

sub put {
    my ($self, $args) = @_;
    return $self->request(
        {
            method => 'PUT',
            uri => $args->{self}->editurl,
            content => $args->{entry}->as_xml,
            header => {'If-Match' => $args->{self}->etag },
            content_type => 'application/atom+xml',
            response_object => 'XML::Atom::Entry',
        }
    );
}

sub delete {
    my ($self, $args) = @_;
    my $res = $self->request(
        {
            uri => $args->{self}->editurl,
            method => 'DELETE',
            header => {'If-Match' => $args->{self}->etag},
        }
    );
    return $res;
}

no Any::Moose '::Role';

1;

__END__

=pod

=head1 NAME

Net::Google::DataAPI::Role::Service - provides base functionalities for Google Data API service 

=head1 SYNOPSIS

    package MyService;
    use Any::Moose;
    use Net::Google::DataAPI;
    with 'Net::Google::DataAPI::Role::Service' => {
        service => 'wise',
        source => __PACKAGE__,
        ns => {
            foobar => 'http://example.com/schema#foobar',
        },
    }

    feedurl hoge => (
        is => 'ro',
        isa => 'Str',
        entry_class => 'MyService::Hoge',
        default => 'http://example.com/feed/hoge',
    );

    1;

=head1 DESCRIPTION

=head1 AUTHOR

Nobuo Danjou E<lt>danjou@soffritto.orgE<gt>

=head1 SEE ALSO

L<Net::Google::AuthSub>

L<Net::Google::DataAPI>

=cut
