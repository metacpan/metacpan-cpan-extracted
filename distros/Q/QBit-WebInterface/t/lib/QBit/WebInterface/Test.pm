package QBit::WebInterface::Test;

use qbit;

use base qw(QBit::WebInterface);

use URI::Escape qw(uri_escape_utf8);

use QBit::WebInterface::Test::Request;

sub get_response {
    my ($self, $path, $cmd, $params, %opts) = @_;

    my $request = $self->get_request(
        path   => $path,
        cmd    => $cmd,
        params => $params,
        %opts
    );

    $self->request($request);

    $self->build_response();

    my $response = $self->response();

    $self->request(undef);
    $self->response(undef);

    return $response;
}

sub get_request {
    my ($self, %opts) = @_;

    my $request = QBit::WebInterface::Test::Request->new(
        path  => $opts{'path'},
        cmd   => $opts{'cmd'},
        query => $opts{'params'}
        ? join('&',
            map {uri_escape_utf8($_) . '=' . uri_escape_utf8($opts{'params'}->{$_})}
            sort keys(%{$opts{'params'} || {}}))
        : '',
        method  => $opts{'method'}  || 'GET',
        headers => $opts{'headers'} || {},
        scheme  => $opts{'scheme'}  || 'http'
    );

    open($request->{'__STDIN__'}, '<', \$opts{'stdin'}) || throw "Cannot open file in memory"
      if defined($opts{'stdin'});

    return $request;
}

TRUE;
