package Pcore::Util::URI;

use Pcore -class, -const;
use Pcore::Util::Net qw[get_free_port];
use Pcore::Util::Scalar qw[is_path is_uri is_ref];
use Pcore::Util::Data qw[:URI to_b64];
use Pcore::Util::Text qw[decode_utf8 encode_utf8];
use Pcore::Util::UUID qw[uuid_v4_str];
use Clone qw[];

use overload
  q[""]    => sub { return $_[0]->{uri} },
  q[bool]  => sub { return 1 },
  fallback => 1;

has uri        => ();    # escaped
has scheme     => ();    # unescaped, utf8
has authority  => ();    # escaped
has path       => ();    # object
has query      => ();    # escaped
has fragment   => ();    # escaped
has userinfo   => ();    # escaped
has username   => ();    # unescaped, utf8
has password   => ();    # unescaped, utf8
has host_port  => ();    # escaped
has host       => ();    # object
has socket     => ();    # unix socket
has port       => ();    # int
has path_query => ();    # escaped

has default_port => ();

has _canon        => ( init_arg => undef );    # escaped
has _userinfo_b64 => ( init_arg => undef );

sub IS_PCORE_URI ($self) { return 1 }

around new => sub ( $orig, $self, $uri = undef, %args ) {
    no warnings qw[uninitialized];

    state $class = {};

    my $base;

    if ( $uri eq $EMPTY ) {
        if ( !$args{listen} ) {
            if ( !defined $args{base} ) {

                # return empty uri object
                return $self->$orig;
            }
            else {
                if ( is_uri $args{base} ) {
                    $base = $args{base}->clone;
                }
                else {
                    $base = P->uri( $args{base} );
                }

                delete $base->@{qw[uri _canon]};

                # do not inherit fragment from the base uri
                $base->{fragment} = undef;

                $base->_build;

                return $base;
            }
        }

        else {

            # for windows use TCP loopback
            if ($MSWIN) {
                $uri = '//127.0.0.1:*';
            }

            # for linux use abstract UDS
            else {
                $uri = "///\x00" . uuid_v4_str;
            }
        }
    }

    my ( $scheme, $authority, $path, $query, $fragment );

    # parse source uri
    if ( is_uri $uri) {
        return $uri->clone if !defined $args{base};

        ( $scheme, $authority, $path, $query, $fragment ) = $uri->@{qw[scheme authority path query fragment]};
    }
    else {
        ( $scheme, $authority, $path, $query, $fragment ) = $uri =~ m[\A (?:([^:/?#]*):)? (?://([^/?#]*))? ([^?#]+)? (?:[?]([^#]*))? (?:[#](.*))? \z]smx;
    }

    my $target;

    # create empty target uri
    if ( $scheme ne $EMPTY ) {

        # decode scheme
        $scheme = lc from_uri_utf8 $scheme;

        # load target class if not loaded
        $class->{$scheme} = eval { P->class->load( $scheme, ns => 'Pcore::Util::URI' ) } if !exists $class->{$scheme};

        $target = ( $class->{$scheme} // $self )->new;

        $target->{scheme} = $scheme;
    }
    else {
        if ( !defined $args{base} ) {
            $target = $self->$orig;
        }
        else {
            $base = is_uri $args{base} ? $args{base} : P->uri("$args{base}");

            # Pre-parse the Base URI: https://tools.ietf.org/html/rfc3986#section-5.2.1
            # base URI MUST contain scheme
            if ( defined $base->{scheme} ) {
                $target = ( $class->{ $base->{scheme} } // $self )->new;

                # inherit scheme from the base URI
                $target->{scheme} = $base->{scheme};
            }
            else {
                undef $base;

                $target = $self->$orig;
            }
        }
    }

    # merge with the base uri, only if has no own authority
    if ( defined $base && !defined $authority ) {

        # inherit authority
        $authority = $base->{authority};

        # if source path is empty (undef or "")
        if ( $path eq $EMPTY ) {
            $path = $base->{path}->clone;

            $query = $base->{query} if !$query;
        }

        # source path is not empty
        else {

            # merge paths: https://tools.ietf.org/html/rfc3986#section-5.2.3
            $path = P->path( $path, from_uri => 1 )->merge( $base->{path} );
        }
    }

    # authority is emtpy (undef or "")
    if ( $authority eq $EMPTY ) {
        $target->{authority} = $authority;
    }
    else {
        $target->_set_authority($authority);
    }

    # extract unix socket from path
    if ( !defined $target->{host} && substr( $path, 0, 6 ) eq '/unix:' && $path =~ m[\A/unix:([^:]+):?(.*)]sm ) {
        $target->{socket} = $1;

        $path = $2 // '/';
    }

    # path
    if ( is_path $path) {
        $target->{path} = $path;
    }
    else {

        # set path to '/' it has authority and path is empty
        $path = '/' if defined $authority && $path eq $EMPTY;

        $target->{path} = P->path( $path, from_uri => 1 ) if $path ne $EMPTY;
    }

    # set query, if query is not empty
    $target->_set_query($query) if $query ne $EMPTY;

    # ser fragment, if fragment is not empty
    $target->_set_fragment($fragment) if $fragment ne $EMPTY;

    if ( $args{listen} ) {

        # host is defined, resolve port
        if ( defined $target->{host} ) {

            # resolve listen port
            $target->{port} = get_free_port $target->{host} if !$target->{port} || $target->{port} eq '*';
        }

        # host and path are not defined
        elsif ( !$target->{path} || $target->{path} eq '/' ) {

            # for windows use TCP loopback
            if ($MSWIN) {
                $target->{host} = P->host('127.0.0.1');

                $target->{port} = get_free_port $target->{host} if !$target->{port} || $target->{port} eq '*';
            }

            # for linux use abstract UDS
            else {
                $target->{path} = P->path( "/\x00" . uuid_v4_str );
            }
        }
    }

    # build uri
    $target->_build;

    return $target;
};

# authority
sub set_authority ( $self, $val = undef ) {
    no warnings qw[uninitialized];

    # clear related attributes
    delete $self->@{qw[uri _canon authority userinfo _userinfo_b64 username password host_port host port]};

    # $val match undef or ''
    if ( $val eq $EMPTY ) {
        $self->{authority} = $val;
    }
    else {
        $self->_set_authority($val);
    }

    # rebuild uri
    $self->_build;

    return $self;
}

sub _get_authority ( $self ) {
    no warnings qw[uninitialized];

    # build authority
    if ( !exists $self->{authority} ) {
        my $authority;

        $authority .= "$self->{userinfo}@" if defined $self->_get_userinfo;

        $authority .= $self->_get_host_port;

        \$self->{authority} = \$authority;
    }

    return $self->{authority};
}

# userinfo
sub set_userinfo ( $self, $val = undef ) {

    # clear related attributes
    delete $self->@{qw[uri _canon authority userinfo _userinfo_b64 username password]};

    $self->_set_userinfo($val) if defined $val;

    # rebuild uri
    $self->_build;

    return $self;
}

sub _get_userinfo ( $self ) {

    # build userinfo
    if ( !exists $self->{userinfo} ) {
        my $userinfo;

        $userinfo .= to_uri_component $self->{username} if defined $self->{username};

        $userinfo .= ':' . to_uri_component $self->{password} if defined $self->{password};

        \$self->{userinfo} = \$userinfo;
    }

    return $self->{userinfo};
}

# username
sub set_username ( $self, $val = undef ) {

    # clear related attributes
    delete $self->@{qw[uri _canon authority userinfo _userinfo_b64 username]};

    $self->{username} = from_uri_utf8 $val if defined $val;

    # rebuild uri
    $self->_build;

    return $self;
}

# password
sub set_password ( $self, $val = undef ) {

    # clear related attributes
    delete $self->@{qw[uri _canon authority userinfo _userinfo_b64 password]};

    $self->{password} = from_uri_utf8 $val if defined $val;

    # rebuild uri
    $self->_build;

    return $self;
}

# host_port
sub set_host_port ( $self, $val = undef ) {
    delete $self->@{qw[uri _canon authority host_port host port socket]};

    $self->_set_host_port($val) if defined $val;

    # rebuild uri
    $self->_build;

    return $self;
}

sub _get_host_port ( $self ) {

    # build host_port
    if ( !exists $self->{host_port} ) {
        no warnings qw[uninitialized];

        if ( defined $self->{port} ) {
            $self->{host_port} = "$self->{host}:$self->{port}";
        }
        else {
            $self->{host_port} = $self->{host};
        }
    }

    return $self->{host_port};
}

# host
sub set_host ( $self, $val = undef ) {

    # clear related attributes
    delete $self->@{qw[uri _canon authority host_port host socket]};

    $self->{host} = P->host($val) if defined $val;

    # rebuild uri
    $self->_build;

    return $self;
}

# socket
sub set_socket ( $self, $val = undef ) {

    # clear related attributes
    delete $self->@{qw[uri _canon authority host_port host]};

    $self->{socket} = $val;

    # rebuild uri
    $self->_build;

    return $self;
}

# port
sub set_port ( $self, $val = undef ) {
    delete $self->@{qw[uri _canon authority host_port port socket]};

    $self->{port} = $val;

    # rebuild uri
    $self->_build;

    return $self;
}

sub set_path ( $self, $val = undef ) {
    no warnings qw[uninitialized];

    # clear related attributes
    delete $self->@{qw[uri _canon path path_query]};

    # $val is defined and not ''
    if ( $val ne $EMPTY ) {
        my $path = P->path( $val, from_uri => 1 );

        # only abs path is allowed if uri has authority
        if ( defined $self->_get_authority || defined $self->{socket} ) {
            if ( $path->{is_abs} ) {
                $self->{path} = $path;
            }
            else {
                die q[Can't set relative path to uri with authority];
            }
        }

        # any path allowed
        else {
            $self->{path} = $path;
        }
    }

    # rebuild uri
    $self->_build;

    return $self;
}

sub set_query ( $self, $val = undef ) {

    # clear related attributes
    delete $self->@{qw[uri _canon query path_query]};

    no warnings qw[uninitialized];

    $self->_set_query($val) if $val ne $EMPTY;

    # rebuild uri
    $self->_build;

    return $self;
}

sub set_fragment ( $self, $val = undef ) {

    # clear related attributes
    delete $self->@{qw[uri _canon fragment]};

    no warnings qw[uninitialized];

    $self->_set_fragment($val) if $val ne $EMPTY;

    # rebuild uri
    $self->_build;

    return $self;
}

# UTIL
sub to_string ($self) { return $self->{uri} }

sub clone ($self) { return Clone::clone($self) }

sub has_scheme ($self) { return defined $self->{scheme} }

sub has_authority ($self) { return defined $self->{authority} }

sub to_abs ( $self, $base ) {

    # already absolute uri
    return $self if defined $self->{scheme};

    $base = P->uri("$base") unless is_uri $base;

    die q[Can't convert URI to absolute] if !defined $base->{scheme};

    my $uri = P->uri( $self, base => $base );

    bless $self, ref $uri;

    $self->%* = $uri->%*;

    return;
}

sub path_query ($self) {
    no warnings qw[uninitialized];

    if ( !exists $self->{path_query} ) {
        my $path_query = defined $self->{path} ? $self->{path}->to_uri : '/';

        $path_query .= "?$self->{query}" if defined $self->{query};

        $self->{path_query} = $path_query;
    }

    return $self->{path_query};
}

sub scheme_is_valid ($self) {
    return !$self->{scheme} ? 1 : $self->{scheme} =~ /\A[[:lower:]][[:lower:][:digit:]+.-]*\z/sm;
}

sub query_params ($self) {
    return if !defined $self->{query};

    return from_uri_query $self->{query};
}

sub query_params_utf8 ($self) {
    return if !defined $self->{query};

    return from_uri_query_utf8 $self->{query};
}

sub connect ($self) {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms]
    if ( defined $self->{host} ) {
        return $self->{host}, $self->{port} || $self->{default_port};
    }
    elsif ( defined $self->{socket} ) {
        return 'unix/', $self->{socket};
    }
    else {
        return 'unix/', $self->{path}->{path};
    }
}

sub connect_port ($self) {
    return $self->{port} // $self->{default_port};
}

sub userinfo_b64 ($self) {
    if ( !exists $self->{_userinfo_b64} ) {
        if ( defined $self->_get_userinfo ) {
            $self->{_userinfo_b64} = to_b64 $self->{userinfo}, $EMPTY;
        }
        else {
            $self->{_userinfo_b64} = $EMPTY;
        }
    }

    return $self->{_userinfo_b64};
}

# host - default port is 80
# 127.0.0.1 - default port is 80
# 127.0.0.1:999
# unix:/path-to-socket
# TODO
sub to_nginx_upstream_server ($self) {
    if ( defined $self->{host} ) {
        return "$self->{host}" . ( $self->{port} ? ":$self->{port}" : $EMPTY );
    }
    else {
        return 'unix:' . $self->{path}->{path};
    }

    return;
}

# used to compose url for nginx proxy_pass directive
# listen 127.0.0.1:12345
# listen *:12345
# listen 12345 - то же, что и *:12345
# listen localhost:12345
# listen unix:/var/run/nginx.sock
# proxy_pass http://localhost:8000/uri/
# proxy_pass http://unix:/tmp/backend.socket:/uri/
# TODO
sub to_nginx ( $self, $scheme = 'http' ) {
    if ( $self->{scheme} eq 'unix' ) {
        return "$scheme://unix:$self->{path}";
    }
    else {
        return "$scheme://" . ( $self->{host} || '*' ) . ( $self->{port} ? ":$self->{port}" : $EMPTY );
    }
}

sub _set_authority ( $self, $val ) {
    my $idx = index $val, '@';

    # has userinfo
    if ( $idx != -1 ) {
        my $userinfo = substr $val, 0, $idx;

        my $host_port = substr $val, $idx + 1;

        $self->_set_userinfo($userinfo) if $userinfo ne $EMPTY;

        $self->_set_host_port($host_port) if $host_port ne $EMPTY;
    }

    # no userinfo
    else {
        $self->_set_host_port($val) if $val ne $EMPTY;
    }

    return;
}

sub _set_userinfo ( $self, $val ) {

    # userinfo can be split to username / password
    if ( index( $val, ':' ) != -1 ) {
        my ( $username, $password ) = split /:/sm, $val, 2;

        $self->{username} = from_uri_utf8 $username;

        $self->{password} = from_uri_utf8 $password;
    }

    # userinfo can't be split, store in decoded format
    else {
        $self->{username} = from_uri_utf8 $val;
    }

    return;
}

sub _set_host_port ( $self, $val ) {
    encode_utf8 $val;

    my ( $host, $port ) = split /:/sm, $val, 2;

    $self->{host} = P->host($host) if $host ne $EMPTY;

    $self->{port} = $port;

    return;
}

sub _set_query ( $self, $val ) {
    $self->{query} = is_ref $val ? to_uri $val : to_uri_query_frag $val;

    return;
}

sub _set_fragment ( $self, $val ) {
    $self->{fragment} = is_ref $val ? to_uri $val : to_uri_query_frag $val;

    return;
}

sub _build ($self) {
    if ( !exists $self->{uri} ) {
        my $uri;

        $uri .= to_uri_scheme( $self->{scheme} ) . ':' if defined $self->{scheme};

        $uri .= "//$self->{authority}" if defined $self->_get_authority;

        if ( !defined $self->{host} && defined $self->{socket} ) {
            $uri .= "/unix:$self->{socket}";

            $uri .= ':' . $self->{path}->to_uri if defined $self->{path};
        }
        else {
            $uri .= $self->{path}->to_uri if defined $self->{path};
        }

        $uri .= "?$self->{query}" if defined $self->{query};

        $uri .= "#$self->{fragment}" if defined $self->{fragment};

        $self->{uri} = $uri;
    }

    return;
}

# TODO, sort query params
sub canon ($self) {
    ...;
}

# SERIALIZE
*TO_JSON = *TO_CBOR = sub ($self) {
    return $self->{uri};
};

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 1                    | Modules::ProhibitExcessMainComplexity - Main code has high complexity score (48)                               |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 94                   | RegularExpressions::ProhibitComplexRegexes - Split long regexps into smaller qr// chunks                       |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 662                  | ControlStructures::ProhibitYadaOperator - yada operator (...) used                                             |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::URI

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
