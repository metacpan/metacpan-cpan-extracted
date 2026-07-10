package Net::Blossom::_URL;

use strictures 2;

use URI ();

sub http_base_url {
    my ($value) = @_;
    return _http_url($value, allow_path => 1);
}

sub http_root_url {
    my ($value) = @_;
    return _http_url($value, allow_path => 0);
}

sub _http_url {
    my ($value, %opts) = @_;
    return 0 unless defined $value && !ref($value) && length $value;
    return 0 if $value =~ /[\x00-\x20]/;

    my $uri = URI->new($value);
    my $scheme = $uri->scheme;
    return 0 unless defined $scheme && $scheme =~ /\Ahttps?\z/i;

    my $authority = eval { $uri->authority };
    return 0 unless _valid_http_authority($authority);

    my $host = eval { $uri->host };
    return 0 unless defined $host && length $host;

    my $userinfo = eval { $uri->userinfo };
    return 0 if defined $userinfo && length $userinfo;
    return 0 if defined $uri->query;
    return 0 if defined $uri->fragment;

    my $path = $uri->path;
    return 0 if !$opts{allow_path} && defined($path) && length($path) && $path ne '/';

    return 1;
}

sub _valid_http_authority {
    my ($authority) = @_;
    return 0 unless defined $authority && length $authority;
    return 0 if $authority =~ /\@/;

    my $port;
    if ($authority =~ /\A\[[0-9A-Fa-f:.]+\](?::([0-9]+))?\z/) {
        $port = $1;
    }
    elsif ($authority =~ /\A([^:]+)(?::([0-9]+))?\z/) {
        return 0 if $1 =~ /[\[\]]/;
        $port = $2;
    }
    else {
        return 0;
    }

    return 0 if defined $port && ($port < 1 || $port > 65535);
    return 1;
}

1;
