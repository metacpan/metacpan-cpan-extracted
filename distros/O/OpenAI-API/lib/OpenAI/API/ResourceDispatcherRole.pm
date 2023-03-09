package OpenAI::API::ResourceDispatcherRole;

use JSON::MaybeXS;
use LWP::UserAgent;

use OpenAI::API::Resource::Chat;
use OpenAI::API::Resource::Completion;
use OpenAI::API::Resource::Edit;
use OpenAI::API::Resource::Embedding;
use OpenAI::API::Resource::Model;
use OpenAI::API::Resource::Moderation;

use Moo::Role;
use strictures 2;

sub chat {
    my ( $self, %params ) = @_;
    my $request = OpenAI::API::Resource::Chat->new( \%params );
    return $self->_post($request);
}

sub completions {
    my ( $self, %params ) = @_;
    my $request = OpenAI::API::Resource::Completion->new( \%params );
    return $self->_post($request);
}

sub edits {
    my ( $self, %params ) = @_;
    my $request = OpenAI::API::Resource::Edit->new( \%params );
    return $self->_post($request);
}

sub embeddings {
    my ( $self, %params ) = @_;
    my $request = OpenAI::API::Resource::Embedding->new( \%params );
    return $self->_post($request);
}

sub moderations {
    my ( $self, %params ) = @_;
    my $request = OpenAI::API::Resource::Moderation->new( \%params );
    return $self->_post($request);
}

sub models {
    my ( $self, %params ) = @_;
    my $request = OpenAI::API::Resource::Model->new( \%params );
    return $self->_get($request);
}

sub _get {
    my ( $self, $resource ) = @_;

    my $method = $resource->endpoint();
    my %params = %{$resource};

    my $req = HTTP::Request->new(
        GET => "$self->{api_base}/$method",
        [
            'Content-Type'  => 'application/json',
            'Authorization' => "Bearer $self->{api_key}",
        ],
    );

    return $self->_http_send_request($req);
}

sub _post {
    my ( $self, $resource ) = @_;

    my $method = $resource->endpoint();
    my %params = %{$resource};

    my $req = HTTP::Request->new(
        POST => "$self->{api_base}/$method",
        [
            'Content-Type'  => 'application/json',
            'Authorization' => "Bearer $self->{api_key}",
        ],
        encode_json( \%params ),
    );

    return $self->_http_send_request($req);
}

sub _http_send_request {
    my ( $self, $req ) = @_;

    for my $attempt ( 1 .. $self->{retry} ) {
        my $res = $self->user_agent->request($req);

        if ( $res->is_success ) {
            return decode_json( $res->decoded_content );
        } elsif ( $res->code =~ /^(?:500|503|504|599)$/ && $attempt < $self->{retry} ) {
            sleep( $self->{sleep} );
        } else {
            die "Error: '@{[ $res->status_line ]}'";
        }
    }
}

1;
