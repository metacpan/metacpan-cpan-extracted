package Pcore::HTTP::Cookies;

use Pcore -class;

has cookies => ( is => 'ro', isa => HashRef, default => sub { {} } );

sub clear ($self) {
    $self->{cookies} = {};

    return;
}

# COOKIES LIMITATIONS:
# http://browsercookielimits.squawky.net/
#
# RFC 2965 - http://www.ietf.org/rfc/rfc2965.txt;
# To get a good understanding of cookies read this - http://www.quirksmode.org/js/cookies.html;
# Cookies are stored as a single string containing name, value, expiry etc.;
# Size limits apply to the entire cookie, not just its value;
# If you use characters only in the ASCII range, each character takes 1 byte, so you can typically store 4096 characters;
# In UTF-8 some characters are more than 1 byte, hence you can not store as many characters in the same amount of bytes;
# The ';' character is reserved as a separator. Do not use it in the key or value;
# jQuery Cookie plugin stores the cookie using encodeURIComponent. Hence ÿ is stored as %C3%BF, 6 characters. This works well, as other you would lose the ';' character;
# You cannot delete cookies with a key that hits the size limit and has a small value. The method to delete a cookie is to set its expiry value, but when the key is large there is not enough room left to do this. Hence I have not tested limitations around key size;
# It appears that some browsers limit by bytes, while others limit the number of characters;

sub parse_cookies ( $self, $url, $set_cookie_header ) {
    $url = P->uri($url) if !ref $url;

  COOKIE: for ( $set_cookie_header->@* ) {
        my ( $kvp, @attrs ) = split /;/sm;

        next if !defined $kvp;

        # trim
        $kvp =~ s/\A\s+//sm;
        $kvp =~ s/\s+\z//sm;

        next if $kvp eq q[];

        my $origin_domain_name = $url->host->name;

        my $cookie = {
            domain   => $origin_domain_name,
            path     => $url->path->to_string,
            expires  => 0,
            httponly => 0,
            secure   => 0,
        };

        # parse and set key and value
        if ( ( my $idx = index $kvp, q[=] ) != -1 ) {
            $cookie->{name} = substr $kvp, 0, $idx;

            $cookie->{val} = substr $kvp, $idx + 1;
        }
        else {
            $cookie->{name} = $kvp;

            $cookie->{val} = q[];
        }

        # parse attributes
        for my $attr (@attrs) {

            # trim
            $attr =~ s/\A\s+//sm;
            $attr =~ s/\s+\z//sm;

            next if $attr eq q[];

            my ( $k, $v );

            if ( ( my $idx = index $attr, q[=] ) != -1 ) {
                $k = lc substr $attr, 0, $idx;

                $v = substr $attr, $idx + 1;
            }
            else {
                $k = lc $attr;

                $v = q[];
            }

            if ( $k eq 'domain' ) {
                if ( $v ne q[] ) {

                    # http://bayou.io/draft/cookie.domain.html
                    # origin domain - domain from the request
                    # cover domain - domain from cookie attribute

                    # if a cookie's origin domain is an IP, the cover domain must be null
                    next COOKIE if $url->host->is_ip;

                    # parse cover domain
                    my $cover_domain = P->host($v);

                    # a cover domain must not be a IP address
                    next COOKIE if $cover_domain->is_ip;

                    my $cover_domain_name = $cover_domain->name;

                    # if the origin domain is the same domain
                    if ( $cover_domain_name eq $origin_domain_name ) {

                        # permit a public suffix domain to specify itself as the cover domain
                        # ignore cover domain, if cover domain is pub. suffix
                        next if $cover_domain->is_pub_suffix;
                    }
                    else {
                        # the cover domain must not be a TLD, a public suffix, or a parent of a public suffix
                        next COOKIE if $cover_domain->is_pub_suffix;

                        # the cover domain must cover (be a parent) the origin domain
                        if ( ( my $idx = index $origin_domain_name, q[.] . $cover_domain_name ) > 0 ) {
                            next COOKIE if length($origin_domain_name) != 1 + $idx + length $cover_domain_name;
                        }
                        else {
                            next COOKIE;
                        }
                    }

                    # accept cover domain cookie
                    $cookie->{domain} = q[.] . $cover_domain_name;
                }
            }
            elsif ( $k eq 'path' ) {
                if ( $v ne q[] ) {
                    $cookie->{path} = $v;
                }
            }
            elsif ( $k eq 'expires' ) {
                if ( $v ne q[] ) {
                    if ( !$cookie->{expires} ) {    # do not process expires attribute, if expires is already set by expires or max-age
                        if ( my $expires = eval { P->date->parse($v) } ) {
                            $cookie->{expires} = $expires->epoch;
                        }
                        else {
                            # ignore cookie if expires value is invalid
                            next COOKIE;
                        }
                    }
                }
            }
            elsif ( $k eq 'max-age' ) {
                if ( $v ne q[] ) {
                    if ( $v =~ /\A\d+\z/sm ) {
                        $cookie->{expires} = time + $v;
                    }
                    else {
                        # ignore cookie if max-age value is invalid
                        next COOKIE;
                    }
                }
            }
            elsif ( $k eq 'httponly' ) {
                $cookie->{httponly} = 1;
            }
            elsif ( $k eq 'secure' ) {
                $cookie->{secure} = 1;
            }
        }

        if ( $cookie->{expires} && $cookie->{expires} <= time ) {
            $self->remove_cookie( $cookie->{domain}, $cookie->{path}, $cookie->{name} );
        }
        else {
            $self->{cookies}->{ $cookie->{domain} }->{ $cookie->{path} }->{ $cookie->{name} } = $cookie;
        }
    }

    return;
}

sub get_cookies ( $self, $url ) {
    state $match_path = sub ( $url_path, $cookie_path ) {
        return 1 if $cookie_path eq $url_path;

        return 1 if $cookie_path eq q[/];

        if ( $url_path =~ /\A\Q$cookie_path\E(.*)/sm ) {
            my $rest = $1;

            return 1 if substr( $cookie_path, -1, 1 ) eq q[/];

            return 1 if substr( $rest, 0, 1 ) eq q[/];
        }

        return;
    };

    state $match_domain = sub ( $self, $domain, $domain_cookies, $url ) {
        my $cookies;

        my $time = time;

        for my $cookie_path ( keys $domain_cookies->%* ) {
            if ( $match_path->( $url->path, $cookie_path ) ) {
                for my $cookie ( values $domain_cookies->{$cookie_path}->%* ) {
                    if ( $cookie->{expires} && $cookie->{expires} < $time ) {

                        # remove expired cookie
                        $self->remove_cookie( $domain, $cookie_path, $cookie->{name} );
                    }
                    else {
                        next if $cookie->{secure} && !$url->is_secure;

                        push $cookies->@*, $cookie->{name} . q[=] . $cookie->{val};
                    }
                }
            }
        }

        return $cookies;
    };

    $url = P->uri($url) if !ref $url;

    my $cookies;

    # origin cookie
    my $origin_domain_name = $url->host->name;

    if ( my $origin_cookies = $self->{cookies}->{$origin_domain_name} ) {
        if ( my $match_cookies = $match_domain->( $self, $origin_domain_name, $origin_cookies, $url ) ) {
            push $cookies->@*, $match_cookies->@*;
        }
    }

    # cover cookies
    # http://bayou.io/draft/cookie.domain.html#Coverage_Model
    if ( !$url->host->is_ip ) {
        my @labels = split /[.]/sm, $url->host->name;

        my $origin = 1;

        while ( @labels > 1 ) {
            my $domain = P->host( join q[.], @labels );

            my $cover_domain_name = q[.] . $domain->name;

            if ( my $cover_cookies = $self->{cookies}->{$cover_domain_name} ) {
                if ( my $match_cookies = $match_domain->( $self, $cover_domain_name, $cover_cookies, $url ) ) {
                    push $cookies->@*, $match_cookies->@*;
                }
            }

            last if $domain->is_pub_suffix && !$origin;

            $origin = 0;

            shift @labels;
        }
    }

    return $cookies;
}

sub remove_cookie ( $self, $domain, $path, $name ) {
    if ( delete $self->{cookies}->{$domain}->{$path}->{$name} ) {
        delete $self->{cookies}->{$domain}->{$path} if !keys $self->{cookies}->{$domain}->{$path}->%*;

        delete $self->{cookies}->{$domain} if !keys $self->{cookies}->{$domain}->%*;
    }

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 |                      | Subroutines::ProhibitExcessComplexity                                                                          |
## |      | 27                   | * Subroutine "parse_cookies" with high complexity score (38)                                                   |
## |      | 175                  | * Subroutine "get_cookies" with high complexity score (23)                                                     |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 115, 135             | ControlStructures::ProhibitDeepNests - Code structure is deeply nested                                         |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::HTTP::Cookies

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
