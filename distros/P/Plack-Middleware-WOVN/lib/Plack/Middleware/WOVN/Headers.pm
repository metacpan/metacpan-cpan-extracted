package Plack::Middleware::WOVN::Headers;
use strict;
use warnings;
use utf8;
use v5.10;
use parent 'Class::Accessor::Fast';

use Plack::Middleware::WOVN::Lang;

__PACKAGE__->mk_accessors(
    qw/
        unmasked_url url protocol unmasked_host host unmasked_pathname pathname redis_url query
        env settings
        /
);

sub new {
    my $class = shift;
    my ( $env, $settings ) = @_;
    my $self = $class->SUPER::new( { env => $env, settings => $settings, } );

    $self->protocol( $env->{'psgi.url_scheme'} );
    $self->unmasked_host( $env->{HTTP_HOST} );
    unless ( exists $env->{REQUEST_URI} ) {
        $env->{REQUEST_URI} = join '',
            (
            $env->{PATH_INFO} =~ /^[^\/]/ ? '/' : '',
            $env->{PATH_INFO},
            length $env->{QUERY_STRING} ? '?' . $env->{QUERY_STRING} : '',
            );
    }
    if ( $env->{REQUEST_URI} =~ /:\/\// ) {
        $ENV->{REQUEST_URI} =~ s/^.*:\/\/[^\/]+//;
    }

    my ($unmasked_pathname) = split /\?/, $env->{REQUEST_URI};
    $unmasked_pathname .= '/'
        unless $unmasked_pathname =~ /\/$/
        || $unmasked_pathname =~ /\/[^\/.]+\.[^\/.]+$/;
    $self->unmasked_pathname($unmasked_pathname);

    $self->unmasked_url( $self->protocol . '://'
            . $self->unmasked_host
            . $self->unmasked_pathname );

    if ( $settings->{url_pattern} eq 'subdomain' ) {
        $self->host(
            $self->remove_lang( $env->{HTTP_HOST}, $self->lang_code ) );
    }
    else {
        $self->host( $env->{HTTP_HOST} );
    }

    my ( $pathname, $query ) = split /\?/, $env->{REQUEST_URI};
    if ( $settings->{url_pattern} eq 'path' ) {
        $self->pathname( $self->remove_lang( $pathname, $self->lang_code ) );
    }
    else {
        $self->pathname($pathname);
    }
    $self->query( $query || '' );

    my $url = join '',
        (
        $self->host, $self->pathname,
        length $self->query ? '?' : '',
        $self->remove_lang( $self->query, $self->lang_code ),
        );
    $self->url($url);

    if ( @{ $settings->{query} || [] } ) {
        my @query_vals;
        for my $qv ( @{ $settings->{query} } ) {
            my $reg = "(^|&)(?<query_val>" . $qv . "[^&]+)(&|$)/";
            if ( $self->query =~ /$reg/ && $+{query_val} ) {
                push @query_vals, $+{query_val};
            }
        }
        if (@query_vals) {
            $self->query( join '&', sort(@query_vals) );
        }
    }
    else {
        $self->query('');
    }
    $self->query( $self->remove_lang( $self->query, $self->lang_code ) );

    $pathname = $self->pathname;
    $pathname =~ s/\/+$//;
    $self->pathname($pathname);

    $self->redis_url( $self->host . $self->pathname . $self->query );

    $self;
}

sub lang_code {
    my $self = shift;
    if ( $self->path_lang && $self->path_lang ne '' ) {
        $self->path_lang;
    }
    else {
        $self->settings->{default_lang};
    }
}

sub path_lang {
    my $self = shift;
    if ( !$self->{path_lang} ) {
        my $url = $self->env->{SERVER_NAME} . $self->env->{REQUEST_URI};
        my $reg = $self->settings->{url_pattern_reg};
        if (   $url =~ /$reg/
            && $+{lang}
            && Plack::Middleware::WOVN::Lang->get_lang( $+{lang} ) )
        {
            $self->{path_lang}
                = Plack::Middleware::WOVN::Lang->get_code( $+{lang} );
        }
        else {
            $self->{path_lang} = '';
        }
    }
    $self->{path_lang};
}

sub browser_lang {
    my $self = shift;
    if ( !$self->{browser_lang} ) {
        if ( ( $self->env->{HTTP_COOKIE} || '' )
            =~ /wovn_selected_lang\s*=\s*(?<lang>[^;\s]+)/ )
        {
            $self->{browser_lang} = $+{lang};
        }
        else {
            $self->{browser_lang} = '';
        }
    }
    $self->{browser_lang};
}

sub redirect {
    my ( $self, $lang ) = @_;
    $lang = $self->browser_lang unless defined $lang;
    my $redirect_headers = {
        'location'       => $self->redirect_location($lang),
        'content-length' => 0,
    };
    $redirect_headers;
}

sub redirect_location {
    my ( $self, $lang ) = @_;
    if ( $lang eq $self->settings->{default_lang} ) {
        return $self->protocol . '://' . $self->url;
    }
    else {
        my $location = $self->url;
        if ( $self->settings->{url_pattern} eq 'query' ) {
            if ( $location !~ /\?/ ) {
                $location = "$location?wovn=$lang";
            }
            elsif ( $self->env->{REQUEST_URI} !~ /(\?|&)wovn=/ ) {
                $location = "$location&wovn=$lang";
            }
        }
        elsif ( $self->settings->{url_pattern} eq 'subdomain' ) {
            $location = lc($lang) . ".$location";
        }
        else {
            $location =~ s/(\/|$)/\/$lang\//;
        }
        return $self->protocol . "://$location";
    }
}

sub request_out {
    my ( $self, $def_lang ) = @_;
    $def_lang = $self->settings->{default_lang} unless defined $def_lang;

    if ( $self->settings->{url_pattern} eq 'query' ) {
        $self->env->{REQUEST_URI}
            = $self->remove_lang( $self->env->{REQUEST_URI} )
            if exists $self->env->{REQUEST_URI};
        $self->env->{QUERY_STRING}
            = $self->remove_lang( $self->env->{QUERY_STRING} )
            if exists $self->env->{QUERY_STRING};
        $self->env->{ORIGINAL_FULLPATH}
            = $self->remove_lang( $self->env->{ORIGINAL_FULLPATH} )
            if exists $self->env->{ORIGINAL_FULLPATH};
    }
    elsif ( $self->settings->{url_pattern} eq 'subdomain' ) {
        $self->env->{HTTP_HOST}
            = $self->remove_lang( $self->env->{HTTP_HOST} );
        $self->env->{SERVER_NAME}
            = $self->remove_lang( $self->env->{SERVER_NAME} );
        $self->env->{HTTP_REFERER}
            = $self->remove_lang( $self->env->{HTTP_REFERER} )
            if exists $self->env->{HTTP_REFERER};
    }
    else {
        $self->env->{REQUEST_URI}
            = $self->remove_lang( $self->env->{REQUEST_URI} );
        $self->env->{REQUEST_PATH}
            = $self->remove_lang( $self->env->{REQUEST_PATH} )
            if exists $self->env->{REQUEST_PATH};
        $self->env->{PATH_INFO}
            = $self->remove_lang( $self->env->{PATH_INFO} );
        $self->env->{ORIGINAL_FULLPATH}
            = $self->remove_lang( $self->env->{ORIGINAL_FULLPATH} )
            if exists $self->env->{ORIGINAL_FULLPATH};
    }
    $self->env;
}

sub remove_lang {
    my ( $self, $uri, $lang ) = @_;
    $lang = $self->path_lang unless defined $lang;

    if ( $self->settings->{url_pattern} eq 'query' ) {
        $uri =~ s/(^|\?|&)wovn=$lang(&|$)/$1/;
        $uri =~ s/(\?|&)+$//;
    }
    elsif ( $self->settings->{url_pattern} eq 'subdomain' ) {
        $uri =~ s/(^|(\/\/))$lang\./$1/i;
    }
    else {
        $uri =~ s/\/$lang(\/|$)/\//;
    }
    $uri;
}

sub out {
    my ( $self, $headers ) = @_;
    my $host      = $self->host;
    my $lang_code = $self->lang_code;

    if ( $headers->{Location} && $headers->{Location} =~ /\/\/$host/ ) {
        if ( $self->settings->{url_pattern} eq 'query' ) {
            if ( $headers->{Location} =~ /\?/ ) {
                $headers->{Location} .= '&';
            }
            else {
                $headers->{Location} .= '?';
            }
            $headers->{Location} .= "wovn=$lang_code";
        }
        elsif ( $self->settings->{url_pattern} eq 'subdomain' ) {
            $headers->{Location} =~ s/\/\/([^.]+)/\/\/$lang_code\.$1/;
        }
        else {
            $headers->{Location} =~ s/(\/\/[^\/]+)/$1\/$lang_code/;
        }
    }
    $headers;
}

1;

__END__

=head1 NAME

Plack::Middleware::WOVN::Headers - Rewrites headers of PSGI response.

=head1 SEE ALSO

L<Plack::Middleware::WOVN>

=cut


