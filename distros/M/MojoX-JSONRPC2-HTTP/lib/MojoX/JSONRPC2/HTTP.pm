package MojoX::JSONRPC2::HTTP;

use Mojo::Base -base;
use Carp;

our $VERSION = 'v2.0.3';

use Mojo::UserAgent;
use JSON::RPC2::Client;
use JSON::XS;
use Scalar::Util qw(weaken);

use constant REQUEST_TIMEOUT    => 30;
use constant HTTP_200           => 200;


has url     => sub { croak '->url() not defined' };
has method  => 'POST';
has type    => 'application/json';
has headers => sub { {} };
has ua      => sub {
    Mojo::UserAgent->new
        ->inactivity_timeout(0)
        ->request_timeout(REQUEST_TIMEOUT)
};
has _client => sub { JSON::RPC2::Client->new };

sub call            { return shift->_request('call',         @_) }
sub call_named      { return shift->_request('call_named',   @_) }
sub notify          { return shift->_request('notify',       @_) }
sub notify_named    { return shift->_request('notify_named', @_) }

sub _request {
    my ($self, $func, $method, @params) = @_;
    # work either in blocking mode or non-blocking (if has \&cb in last param)
    my $cb = @params && ref $params[-1] eq 'CODE' ? pop @params : undef;

    # if $func is notify/notify_named then $call will be undef
    my ($json_request, $call) = $self->_client->$func($method, @params);

    my $tx; # will be set when in blocking mode
    weaken(my $this = $self);
    if ('GET' eq uc $self->method) {
        my $json = decode_json($json_request);
        if (exists $json->{params}) {
            $json->{params} = encode_json($json->{params});
        }
        $tx = $self->ua->get(
            $self->url,
            {
                'Content-Type'  => $self->type,
                'Accept'        => $self->type,
                %{ $self->headers },
            },
            form => $json,
            ($cb ? sub {$this && $this->_response($cb, $call, @_)} : ()),
        );
    }
    else {
        $tx = $self->ua->post(
            $self->url,
            {
                'Content-Type'  => $self->type,
                'Accept'        => $self->type,
                %{ $self->headers },
            },
            $json_request,
            ($cb ? sub {$this && $this->_response($cb, $call, @_)} : ()),
        );
    }
    return ($cb ? () : $self->_response($cb, $call, undef, $tx));
}

sub _response {
    my ($self, $cb, $call, undef, $tx) = @_;
    my $is_notify = !defined $call;

    my ($failed, $result, $error);
    my $res = $tx->res;
    # transport error (we don't have HTTP reply)
    if ($res->error && !$res->error->{code}) {
        $failed = $res->error->{message};
    }
    # use HTTP code as error message instead of 'Parse error' for:
    # - strange HTTP reply code or non-empty content (notify)
    elsif ($is_notify  && !($res->is_success && $res->body =~ /\A\s*\z/ms)) {
        $failed = sprintf '%d %s', $res->code, $res->message;
    }
    # - strange HTTP reply code or non-json content (call)
    elsif (!$is_notify && !($res->is_success && $res->body =~ /\A\s*[{\[]/ms)) {
        $failed = sprintf '%d %s', $res->code, $res->message;
    }
    elsif (!$is_notify) {
        ($failed, $result, $error) = $self->_client->response($res->body);
    }

    if ($failed && $call) {
        $self->_client->cancel($call);
    }

    if ($cb) {
        return $is_notify ? $cb->($failed) : $cb->($failed, $result, $error);
    } else {
        return $is_notify ?       $failed  :      ($failed, $result, $error);
    }
}


1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

MojoX::JSONRPC2::HTTP - Client for JSON RPC 2.0 over HTTP


=head1 VERSION

This document describes MojoX::JSONRPC2::HTTP version v2.0.3


=head1 SYNOPSIS

    use MojoX::JSONRPC2::HTTP;

    $client = MojoX::JSONRPC2::HTTP->new;

    # setup
    $client
        ->url('http://example.com/endpoint')
        ->method('GET')
        ->type('application/json-rpc')
        ->headers({'X-Answer'=>42,…})
        ;
    # get Mojo::UserAgent to setup it (timeouts, etc.)
    $ua = $client->ua;

    # blocking notifications and calls
    ($failed, $result, $error) = $client->call('method', @params);
    ($failed, $result, $error) = $client->call_named('method', %params);
    $failed = $client->notify('method', @params);
    $failed = $client->notify_named('method', %params);

    # non-blocking calls
    $client->call('method', @params, \&cb);
    $client->call_named('method', %params, \&cb);
    sub cb {
        my ($failed, $result, $error) = @_;
    }

    # non-blocking notifications
    $client->notify('method', @params, \&cb_failed);
    $client->notify_named('method', %params, \&cb_failed);
    sub cb_failed {
        my ($failed) = @_;
    }


=head1 DESCRIPTION

Provide HTTP transport for JSON RPC 2.0 using Mojo::UserAgent.

Implements this spec: L<http://www.simple-is-better.org/json-rpc/transport_http.html>.
The "pipelined Requests/Responses" is not supported yet.


=head1 ATTRIBUTES

All these methods return current value when called without params or set
new value and return their object (to allow method chaining) when called
with single param.

=head2 url

RPC endpoint url.

This is only required parameter which must be set before doing RPC calls.

=head2 method

Default is C<'POST'>, and only another supported value is C<'GET'>.

=head2 type

Default is C<'application/json'>.

=head2 headers

Default is empty HASHREF. Either modify it by reference or set it to your
own HASHREF with any extra headers you need to send with RPC call.

=head2 ua

C<Mojo::UserAgent> object used for sending HTTP requests - feel free to
setup it or replace with your own object.


=head1 METHODS

=head2 new

    $client = MojoX::JSONRPC2::HTTP->new( %attrs );
    $client = MojoX::JSONRPC2::HTTP->new( \%attrs );

You can set attributes listed above by providing their values when calling
C<new()> or later using individual attribute methods.

=head2 call

=head2 call_named

    ($failed, $result, $error) = $client->call( 'method', @params );
    ($failed, $result, $error) = $client->call_named( 'method', %params );
    $client->call( 'method', @params, \&cb );
    $client->call_named( 'method', %params, \&cb );

Do blocking or non-blocking (when C<\&cb> param provided) RPC calls, with
either positional or named params. Blocking calls will return these values
(non-blocking will call C<\&cb> with same values as params):

    ($failed, $result, $error)

In case of transport-level errors, when we fail to either send RPC request
or receive correct reply from RPC server the C<$failed> will contain error
message, while C<$result> and C<$error> will be undefined.

In case remote C<'method'> or RPC server itself will return error it will
be available in C<$error> as HASHREF with keys C<{code}>, C<{message}> and
optionally C<{data}>, while C<$failed> and C<$result> will be undefined.

Otherwise value returned by remote C<'method'> will be in C<$result>,
while C<$failed> and C<$error> will be undefined.

=head2 notify

=head2 notify_named

    $failed = $client->notify( 'method', @params );
    $failed = $client->notify_named( 'method', %params );
    $client->notify( 'method', @params, \&cb );
    $client->notify_named( 'method', %params, \&cb );

Do blocking or non-blocking (when C<\&cb> param provided) RPC calls, with
either positional or named params. Blocking calls will return this value
(non-blocking will call C<\&cb> with same value as param):

    $failed

It will contain error message in case of transport-level error or will be
undefined if RPC call was executes successfully.


=head1 SEE ALSO

L<JSON::RPC2::Client>, L<Mojolicious>, L<Mojolicious::Plugin::JSONRPC2>.


=head1 LIMITATIONS

=over

=item Batch/Multicall feature

Not supported because it is not implemented by L<JSON::RPC2::Client>.

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/powerman/perl-MojoX-JSONRPC2-HTTP/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.
Feel free to fork the repository and submit pull requests.

L<https://github.com/powerman/perl-MojoX-JSONRPC2-HTTP>

    git clone https://github.com/powerman/perl-MojoX-JSONRPC2-HTTP.git

=head2 Resources

=over

=item * MetaCPAN Search

L<https://metacpan.org/search?q=MojoX-JSONRPC2-HTTP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/MojoX-JSONRPC2-HTTP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MojoX-JSONRPC2-HTTP>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=MojoX-JSONRPC2-HTTP>

=item * CPANTS: A CPAN Testing Service (Kwalitee)

L<http://cpants.cpanauthors.org/dist/MojoX-JSONRPC2-HTTP>

=back


=head1 AUTHOR

Alex Efros E<lt>powerman@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014- by Alex Efros E<lt>powerman@cpan.orgE<gt>.

This is free software, licensed under:

  The MIT (X11) License


=cut
