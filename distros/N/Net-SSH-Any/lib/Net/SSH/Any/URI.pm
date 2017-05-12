package Net::SSH::Any::URI;

use strict;
use warnings;
use Carp;
use Encode;

use Net::SSH::Any::Util qw(_warn);

my @slots = qw(scheme user host port path);
my %is_slot = map { $_ => $_ } @slots;

my %alias = (passwd => 'password', pwd => 'password');



my %unsafe = (password => 1, passphrase => 1);

my $IPv6_re = qr((?-xism::(?::[0-9a-fA-F]{1,4}){0,5}(?:(?::[0-9a-fA-F]{1,4}){1,2}|:(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})))|[0-9a-fA-F]{1,4}:(?:[0-9a-fA-F]{1,4}:(?:[0-9a-fA-F]{1,4}:(?:[0-9a-fA-F]{1,4}:(?:[0-9a-fA-F]{1,4}:(?:[0-9a-fA-F]{1,4}:(?:[0-9a-fA-F]{1,4}:(?:[0-9a-fA-F]{1,4}|:)|(?::(?:[0-9a-fA-F]{1,4})?|(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))))|:(?:(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))|[0-9a-fA-F]{1,4}(?::[0-9a-fA-F]{1,4})?|))|(?::(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))|:[0-9a-fA-F]{1,4}(?::(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))|(?::[0-9a-fA-F]{1,4}){0,2})|:))|(?:(?::[0-9a-fA-F]{1,4}){0,2}(?::(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))|(?::[0-9a-fA-F]{1,4}){1,2})|:))|(?:(?::[0-9a-fA-F]{1,4}){0,3}(?::(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))|(?::[0-9a-fA-F]{1,4}){1,2})|:))|(?:(?::[0-9a-fA-F]{1,4}){0,4}(?::(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))|(?::[0-9a-fA-F]{1,4}){1,2})|:))));

sub uri_escape {
    my $str = shift;
    $str =~ s/([^A-Za-z0-9\-\._~\[\]])/sprintf "%%%02x", ord $1/ge if defined $str;
    $str
}

sub uri_escape_path { # doesn't escape slashes
    my $str = shift;
    $str =~ s/([^A-Za-z0-9\-\._~\[\]\/])/sprintf "%%%02x", ord $1/ge if defined $str;
    $str
}



sub uri_unescape {
    my $str = shift;
    $str =~ s/\%([\da-f]{2})/chr hex $1/ige if defined $str;
    $str
}

sub new {
    my $class = shift;
    my %opt = (@_ & 1 ? (uri => @_) : @_);
    $_ = encode(latin1 => $_, Encode::FB_CROAK) for values %opt;
    my $uri = delete $opt{uri};
    my %c_params;
    my %uri = (c_params => \%c_params);

    for (keys %alias) {
        if (defined (my $opt = delete $opt{$_})) {
            $opt{$alias{$_}} //= $opt;
        }
    }

    if (defined $uri) {
        if (my ($scheme, $user, $password, $c_params, $ipv6, $host, $port, $path) =
            $uri =~ m{^
                      \s*                  # trim space
                      (?:([\w+-]+)://)?+   # scheme
                      (?:
                          (?:([^\@:;]+))?+ # username
                          (?::([^\@;]*))?+ # : password
                          (?:;([^\@]*))?+  # c-params
                          \@               # @
                      )?+
                      (?>                  # host
                          (                #   IPv6...
                              \[$IPv6_re\] #     [IPv6]
                          |                #     or
                              $IPv6_re     #     IPv6
                          )
                      |                    #   or
                          ([^\[\]\@:/]+)   #   hostname / ipv4
                      )
                      (?::([\w\%]+))?+     # port
                      (/.*)?+              # path
                      \s*                  # trim space
                      $}xo) {
            @uri{qw(scheme user port path)} = map uri_unescape($_), $scheme, $user, $port, $path;

            if (defined $ipv6) {
                $ipv6 =~ /^\[?(.*?)\]?$/;
                $uri{host} = $1;
            }
            else {
                $uri{host} = uri_unescape $host;
            }

            $c_params{password} = [uri_unescape $password] if defined $password;

            if (defined $c_params) {
                while ($c_params =~ /\G([^,=]*)=([^,=]*)(?:,|$)/gc) {
                    my ($k, $v) = ($1, $2);
                    my $k_unescaped = uri_unescape $k;
                    $k_unescaped = $alias{$k_unescaped} // $k_unescaped;
                    push @{$c_params{$k_unescaped}}, uri_unescape $v;
                }
                $c_params =~ /\G./gc and return;
            }
        }
        else {
            return;
        }
    }
    else {
        defined $opt{host} or croak "both uri and host are undefined";
    }

    for (@slots) {
        my $v = delete $opt{$_};
        $uri{$_} //= $v if defined $v;
    }

    if (defined (my $password = delete $opt{password})) {
        $uri{c_params}{password} //= [$password];
    }

    for (keys %opt) {
        my $v = delete $opt{$_};
        $c_params{$_} //= [$v] if defined $v;
    }

    my $self = \%uri;
    bless $self, $class;
}

for my $slot (@slots) {
    my $sub = sub {
        my $self = shift;
        if (@_) {
            if (defined (my $v = shift)) {
                $self->{$slot} = encode latin1 => $v, Encode::FB_CROAK;
            }
            else {
                $slot eq 'host' and croak "attribute host is mandatory";
                delete $self->{$slot};
            }
            return;
        }
        $self->{$slot};
    };
    no strict 'refs';
    *$slot = $sub;
}

sub bracketed_host {
    my $self = shift;
    @_ and croak 'bracketed_host is read only';
    my $h = $self->{host};
    ($h =~ /^$IPv6_re$/o ? "[$h]" : $h);
}

sub c_params {
    my $self = shift;
    my $c_params = $self->{c_params} or return;
    my @out;
    for my $k (%$c_params) {
        push @out, map { $k, $_ } @{$c_params->{$k}};
    }
    @out;
}

sub c_param_count {
    my ($self, $key) = @_;
    $key = $alias{$key} // $key;
    my $c_params = $self->{c_params} or return 0;
    my $vs = $c_params->{$key} or return 0;
    scalar (@$vs);
}

sub c_param {
    my ($self, $key) = @_;
    $key = $alias{$key} // $key;
    my $c_params = $self->{c_params} or return;
    my $vs = $c_params->{$key} or return;
    wantarray or croak "c_param used in scalar context is not supported";
    @$vs;
}

sub set_c_param {
    my $self = shift;
    my $key = shift;
    $key = $alias{$key} // $key;
    $self->{c_params}{$key} = [@_];
    return
}

sub password {
    my $self = shift;
    $self->{c_params}{password}[0];
}

sub get {
    my $self = shift;
    my $key = shift;
    $key = $alias{$key} // $key;
    my @r = $self->{$key} // do {
        my $a = $self->{c_params}{$key};
        ($a ? @$a : ())
    };
    if (@r > 1 and not wantarray) {
        _warn("\$uri->get($key) called on scalar context when it contains more than one entry");
    }
    wantarray ? @r : $r[0];
}

sub set {
    my $self = shift;
    my $key = shift;
    $key = $alias{$key} // $key;
    if ($is_slot{$key}) {
        @_ > 1 and _warn "URI attribute $key is an scalar but set($key) called with ".scalar(@_)." arguments";
        $self->$key($_[0]);
    }
    else {
        $self->set_c_param($key, @_);
    }
    ()
}

sub or_set {
    my $self = shift;
    my $key = shift;
    $key = $alias{$key} // $key;
    $self->set($key, @_) unless defined $self->{$key} or defined $self->{c_params}{$key};
    ()
}

sub _c_params_escaped {
    my ($self, $safe) = @_;
    my $c_params = $self->{c_params} // return;
    my @parts;
    my $ix = 0;
    for my $k (sort keys %$c_params) {
        my $k_escaped = uri_escape $k;
        for my $v (@{$c_params->{$k}}) {
            push(@parts, ($ix++ ? ',' : ';'), $k_escaped, '=',
                 (($safe and $unsafe{$k}) ? '*****' : uri_escape $v));
        }
    }
    @parts;
}

sub uri {
    my ($self, $safe) = @_;
    my @parts;
    push @parts, uri_escape($self->{user}) if defined $self->{user};
    push @parts, $self->_c_params_escaped($safe);
    push @parts, '@', if @parts;
    unshift @parts, uri_escape($self->{scheme}), '://' if defined $self->{scheme};
    my $h = $self->{host};
    push @parts, ($h =~ /^$IPv6_re$/o ? "[$h]" : uri_escape($h));
    push @parts, ':', uri_escape($self->{port}) if defined $self->{port};
    push @parts, uri_escape_path($self->{path}) if defined $self->{path};
    join '', @parts;
}

*as_string = \&uri;

1;
