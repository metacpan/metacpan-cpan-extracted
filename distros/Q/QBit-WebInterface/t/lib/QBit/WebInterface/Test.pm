package QBit::WebInterface::Test;

use qbit;

use base qw(QBit::WebInterface);

use URI::Escape qw(uri_escape_utf8);

use QBit::WebInterface::Test::Request;

sub get_response {
    my ($self, $path, $cmd, $params, %opts) = @_;

    $self->request(
        QBit::WebInterface::Test::Request->new(
            path => $path,
            cmd  => $cmd,
            query =>
              join('&', map {uri_escape_utf8($_) . '=' . uri_escape_utf8($params->{$_})} sort keys(%{$params || {}})),
            method  => $opts{'method'}  || 'GET',
            headers => $opts{'headers'} || {},
            scheme  => $opts{'scheme'}  || 'http'
        )
    );

    open($self->request->{'__STDIN__'}, '<', \$opts{'stdin'}) || throw "Cannot open file in memory"
      if defined($opts{'stdin'});

    $self->build_response();

    my $response = $self->response();

    $self->request(undef);
    $self->response(undef);

    return $response;
}

sub get_cmd {
    my ($self) = @_;

    return ($self->request->{'path'}, $self->request->{'cmd'});
}

sub make_cmd {
    my ($self, $new_cmd, $new_path, @params) = @_;

    my %vars = defined($params[0])
      && ref($params[0]) eq 'HASH' ? %{$params[0]} : @params;

    my ($path, $cmd) = $self->get_cmd();

    $path = uri_escape_utf8($self->_get_new_path($new_path, $path));
    $cmd = uri_escape_utf8($self->_get_new_cmd($new_cmd, $cmd));

    return "/$path/$cmd"
      . (
        %vars
        ? '?'
          . join(
            $self->get_option('link_param_separator', '&amp;'),
            map {uri_escape_utf8($_) . '=' . uri_escape_utf8($vars{$_})} keys(%vars)
          )
        : ''
      );
}

TRUE;
