package QBit::WebInterface::Request;
$QBit::WebInterface::Request::VERSION = '0.031';
use qbit;

use base qw(QBit::Class);

use Exception::Request;
use Exception::Request::UnknownMethod;

__PACKAGE__->abstract_methods(
    qw(
      http_header
      method
      uri
      scheme
      server_name
      server_port
      remote_addr
      query_string
      _read_from_stdin
      )
);

our $MAX_POST_REQEST_SIZE = 15 * 1024 * 1024;

sub param_names {
    my ($self) = @_;

    $self->_parse_params() unless exists($self->{'__PARAMS__'});

    return keys(%{$self->{'__PARAMS__'}});
}

sub param_array {
    my ($self, $name) = @_;

    $self->_parse_params() unless exists($self->{'__PARAMS__'});

    return $self->{'__PARAMS__'}{$name || ''} || [];
}

sub param {
    my ($self, $name, $default) = @_;

    my $res = $self->param_array($name)->[0];
    return defined($res) ? $res : $default;
}

sub cookie {
    my ($self, $name, $struc_type) = @_;

    $self->_parse_cookies() unless exists($self->{'__COOKIES__'});

    return undef unless $self->{'__COOKIES__'}{$name};
    my $cookie = [@{$self->{'__COOKIES__'}{$name}}];

    if (ref($struc_type) eq 'ARRAY') {
        return $cookie;
    } elsif (ref($struc_type) eq 'HASH') {
        push(@$cookie, undef) if @$cookie % 2;
        return {@$cookie};
    } else {
        return $cookie->[0];
    }
}

sub url {
    my ($self, %opts) = @_;

    my $url = $self->scheme() . '://';
    $url .= $self->server_name();
    $url .= ':' . $self->server_port() if !in_array($self->server_port(), [80, 443]);
    $url .= $self->uri() unless $opts{'no_uri'};

    return $url;
}

sub _parse_params {
    my ($self) = @_;

    $self->{'__PARAMS__'} = {};

    my @pairs;

    if ($self->method ne 'GET') {
        my ($buffer, $tmp, $size) = ('', '', 0);
        while (my $cnt = $self->_read_from_stdin(\$tmp, 1024 * 1024)) {
            $size += $cnt;
            throw gettext('Too big request') if $size > $MAX_POST_REQEST_SIZE;
            $buffer .= $tmp;
        }

        if ($self->http_header('content-type') =~ /^multipart\/form\-data/) {
            my ($spliter, $end, $data) = $buffer =~ m/^([^ \r\n]+)([\r\n]{1,2})(.*?)\2\1--.?.?$/s;

            foreach my $block (split(/$end\Q$spliter\E$end/, $data)) {
                my ($header, $content) = split($end . $end, $block, 2);

                my %header;

                foreach my $line (split(/(?:$end)|(?:\s*;\s*)/, $header)) {
                    my ($name, $value) = split(/=|:\s*/, $line, 2);
                    $value =~ s/^"?(.*?)"?$/$1/;
                    $header{$name} = $value;
                }

                if ($header{'filename'}) {
                    $self->_unescape(\$header{'filename'});
                    for ($header{'filename'}) {
                        s/^"([^"]+)"$/$1/;
                        s/[\\\/]([^\\\/]+)$/$1/;
                    }
                    push(@pairs, [$header{'name'}, {filename => $header{'filename'}, content => $content}]);
                } elsif ($header{'name'}) {
                    push(@pairs, [$header{'name'}, \$content]);
                }
            }
        } elsif ($self->http_header('content-type') =~ /^application\/x\-www\-form\-urlencoded/) {
            push(@pairs, map {[split('=', $_, 2)]} split('&', $buffer));
        } else {
            push(@pairs, ['', \$buffer]);
        }
    }

    push(@pairs, map {[split('=', $_, 2)]} split('&', $self->query_string));

    foreach (@pairs) {
        my ($pname, $pvalue) = @$_;

        next unless defined($pname);

        $self->_unescape(\$pname);
        $self->_unescape(\$pvalue) if defined($pvalue) && ref($pvalue) ne 'HASH';

        $self->{'__PARAMS__'}{$pname} = []
          unless exists($self->{'__PARAMS__'}{$pname});
        push(@{$self->{'__PARAMS__'}{$pname}}, $pvalue);
    }
}

sub _parse_cookies {
    my ($self) = @_;

    $self->{'__COOKIES__'} = {};

    my $cookie_str = $self->http_header('Cookie');

    foreach (split('[;,] ?', $cookie_str)) {
        s/\s*(.*?)\s*/$1/;
        my ($key, $value) = split('=', $_, 2);
        next unless defined($key);

        my @values = defined($value) ? split(/[&;]/, $value) : ();
        $self->_unescape(\$_) foreach @values;

        $self->{'__COOKIES__'}{$key} ||= [];
        push(@{$self->{'__COOKIES__'}{$key}}, @values);
    }
}

sub _unescape {
    my ($self, $str_ptr) = @_;

    if (ref($$str_ptr) eq 'SCALAR') {
        $$str_ptr = $$$str_ptr;
    } else {
        $$str_ptr =~ tr/+/ /;
        $$str_ptr =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
    }
    utf8::decode($$str_ptr);
}

TRUE;
