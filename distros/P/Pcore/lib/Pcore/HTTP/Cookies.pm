package Pcore::HTTP::Cookies;

use Pcore -class, -const;
use Pcore::Util::Scalar qw[is_ref];

has cookies => ( is => 'ro', isa => HashRef, default => sub { {} } );

const our $COOKIE_NAME    => 0;
const our $COOKIE_VAL     => 1;
const our $COOKIE_EXPIRES => 2;
const our $COOKIE_SECURE  => 3;

# https://tools.ietf.org/html/rfc6265#section-4.1.1
sub parse_cookies ( $self, $url, $set_cookie_header ) {
    $url = P->uri($url) if !is_ref $url;

    my $origin_domain = $url->host->name;
    my $origin_path   = $url->path->to_string;

  COOKIE: for my $str ( $set_cookie_header->@* ) {
        my $is_attr;

        my ( $domain, $path, $cookie );

        while ( $str =~ /\G[;\s]*([^=; ]+)\s*/smgc ) {
            my $key;

            if ( !defined $is_attr ) {
                $cookie->[$COOKIE_NAME] = $1;
            }
            else {
                $key = lc $1;
            }

            if ( $str =~ /\G=\s*(.*?)\s*(?:;|\z)/smgc ) {
                if ( !defined $is_attr ) {
                    $cookie->[$COOKIE_VAL] = $1;
                }
                else {
                    if ( $key eq 'domain' ) {

                        # http://bayou.io/draft/cookie.domain.html
                        # origin domain - domain from the request
                        # cover domain - domain from cookie attribute

                        my $cover_domain = $1;

                        # TODO if the origin domain is an IP, the cover domain must be null. A cookie with an IP origin is only applicable to that IP

                        # a cover domain should not contain a leading dot, like in .cats.com; if it does, the client should remove the leading do
                        $cover_domain =~ s/\A[.]+//sm;

                        if ( $cover_domain ne q[] ) {

                            # the cover domain must cover (be a substring) the origin domain
                            if ( ".$origin_domain" =~ /\Q.$cover_domain\E\z/sm ) {
                                $domain = ".$cover_domain";
                            }
                            else {

                                # if a cookie's cover domain is set illegally or incorrectly, the client should ignore the cookie entirely.
                                next COOKIE;
                            }
                        }
                    }
                    elsif ( $key eq 'path' ) {
                        $path = $1 if $1 ne q[];
                    }
                    elsif ( $key eq 'expires' ) {
                        if ( !defined $cookie->[$COOKIE_EXPIRES] ) {    # do not process expires attribute, if expires is already set by expires or max-age
                            if ( my $expires = eval { P->date->parse($1) } ) {
                                $cookie->[$COOKIE_EXPIRES] = $expires->epoch;
                            }
                        }
                    }
                    elsif ( $key eq 'max-age' ) {

                        # Number of seconds until the cookie expires.
                        # A zero or negative number will expire the cookie immediately.
                        # If both (Expires and Max-Age) are set, Max-Age will have precedence.
                        my $val = $1;

                        $cookie->[$COOKIE_EXPIRES] = time + $val if $val =~ /\A-?\d+\z/sm;
                    }
                }
            }

            if ( !defined $is_attr ) {
                $is_attr = 1;
            }
            else {
                $cookie->[$COOKIE_SECURE] = 1 if $key eq 'secure';
            }
        }

        next if !defined $cookie->[$COOKIE_NAME];

        $cookie->[$COOKIE_VAL] //= q[];
        $domain                //= $origin_domain;
        $path                  //= $origin_path;

        if ( defined $cookie->[$COOKIE_EXPIRES] && $cookie->[$COOKIE_EXPIRES] <= time ) {
            $self->remove_cookie( $domain, $path, $cookie->[$COOKIE_NAME] );
        }
        else {
            $self->{cookies}->{$domain}->{$path}->{ $cookie->[$COOKIE_NAME] } = $cookie;
        }
    }

    return;
}

sub get_cookies ( $self, $url ) {
    $url = P->uri($url) if !is_ref $url;

    my $origin_is_secure = $url->is_secure;
    my $origin_path      = $url->path->to_string;

    my @cookies;

    my @origin_domains = ( $url->host->name );

    if ( !$url->host->is_ip ) {
        my $cover_domain = '.' . $url->host->name;

        push @origin_domains, $cover_domain;

        while ( $cover_domain =~ s/\A[.][^.]+[.]/./sm ) {
            push @origin_domains, $cover_domain;
        }
    }

    for my $origin_domain (@origin_domains) {
        if ( my $domain = $self->{cookies}->{$origin_domain} ) {
            for my $path ( keys $domain->%* ) {
                for my $cookie ( values $domain->{$path}->%* ) {

                    # check expire
                    if ( defined $cookie->[$COOKIE_EXPIRES] && $cookie->[$COOKIE_EXPIRES] <= time ) {

                        # remove expired cookie
                        $self->remove_cookie( $domain, $path, $cookie->[$COOKIE_NAME] );

                        next;
                    }

                    # check secure
                    next if $cookie->[$COOKIE_SECURE] && !$origin_is_secure;

                    # match path, cookie path must be aa substring of the origin path
                    push @cookies, $cookie if index( $path, $origin_path ) == 0;
                }
            }
        }
    }

    return @cookies ? [ map {"$_->[$COOKIE_NAME]=$_->[$COOKIE_VAL]"} @cookies ] : ();
}

sub remove_cookie ( $self, $domain, $path, $name ) {
    if ( exists $self->{cookies}->{$domain}->{$path}->{$name} ) {
        delete $self->{cookies}->{$domain}->{$path}->{$name};

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
## |    3 | 14                   | Subroutines::ProhibitExcessComplexity - Subroutine "parse_cookies" with high complexity score (27)             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 53, 56, 70, 71       | ControlStructures::ProhibitDeepNests - Code structure is deeply nested                                         |
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

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
