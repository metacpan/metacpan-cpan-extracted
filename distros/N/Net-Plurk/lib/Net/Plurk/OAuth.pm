package Net::Plurk::OAuth;
use Moose;
use Net::OAuth;
use AnyEvent::HTTP;
use Digest::MD5 'md5_hex';
$Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;

use namespace::autoclean;
has consumer_key => ( isa => 'Str', is => 'ro', required => 1);
has consumer_secret => ( isa => 'Str', is => 'ro', required => 1);
has access_token => ( isa => 'Str', is => 'rw', default => '');
has access_token_secret => ( isa => 'Str', is => 'rw', default => '');
has _errormsg => ( isa => 'Maybe[Str]', is => 'rw');
has _errorcode => ( isa => 'Int', is => 'rw', default => 0);
has base_url => ( isa => 'Str', is => 'ro', default => 'http://www.plurk.com');
has request_url => ( isa => 'Str', is => 'rw');
has request_token_path => ( isa => 'Str',
    is => 'ro', default => '/OAuth/request_token');
has authorization_path => ( isa => 'Str',
    is => 'ro', default => '/OAuth/authoriz');
has access_token_path => ( isa => 'Str',
    is => 'ro', default => '/OAuth/access_token');
has request_method => ( isa => 'Str', is => 'rw', default => 'POST');
has signature_method => ( isa => 'Str', is => 'ro', default => 'HMAC-SHA1');
has _request => (isa => 'Net::OAuth::Request', is => 'rw');
has json_parser => (isa => 'JSON::Any', is => 'ro', default => sub {JSON::Any->new()});

=head1 NAME

Net::Plurk::OAuth 

=head1 SYNOPSIS

Access Plurk OAuth API via Net::OAuth

=head2 _make_request

=cut 

sub _make_request {
    my ($self, $request_url, %args) = @_;
    $args{message_type} //= 'protected resource';
    $self->_request(
	Net::OAuth->request(delete $args{message_type})->new(
	consumer_key => $self->consumer_key,
	consumer_secret => $self->consumer_secret,
	token => $self->access_token,
	token_secret => $self->access_token_secret,
	request_url => $request_url,
	request_method => $self->request_method,
	signature_method => $self->signature_method,
	timestamp => time,
	nonce => md5_hex(time() * rand()),
	callback => (delete $args{callback}),
	extra_params => { %args },
	)
    );
    $self->_request->sign;
}

=head2 authorize

=cut

sub authorize {
    my ($self, %args) = @_;
    $self->access_token($args{access_token});
    $self->access_token_secret($args{access_token_secret});
}

=head2 request

=cut

sub request {
    my ($self, $path, %args) = @_;
    my ($header, $data);
    my $request_url = $self->base_url.$path;
    $self->_make_request($request_url, %args);

    my $w = AE::cv;
    http_post ($self->_request->to_url,
        sub {
            ($data, $header) = @_;
            $self->_errormsg(undef); # clear errormsg
	    $self->_errorcode(0); # clear errorcode
	    if ($header->{Status} ne '200') {
		$self->_errormsg($header->{Reason});
		$self->_errorcode($header->{Status});
	    }
            $data = $self->json_parser->from_json($data);
            $w->send;
        }
    );
    $w->recv;
    return wantarray ? ($data, $header) : $data;
}

=head2 get_request_token

=cut

sub get_request_token {

}

no Moose;
1;
