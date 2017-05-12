package Plack::Middleware::WOVN::Store;
use strict;
use warnings;
use utf8;
use parent 'Class::Accessor::Fast';

use JSON;
use LWP::UserAgent;

use Plack::Middleware::WOVN::Lang;

__PACKAGE__->mk_accessors(qw/ config_loaded /);

my $default_settings = {
    user_token      => '',
    secret_key      => '',
    url_pattern     => 'path',
    url_pattern_reg => "/(?<lang>[^/.?]+)",
    query           => [],
    api_url         => 'https://api.wovn.io/v0/values',
    default_lang    => 'en',
    supported_langs => ['en'],
    test_mode       => 0,
    test_url        => '',
};

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new();

    my $args     = shift             || {};
    my $settings = $args->{settings} || {};

    $self->{settings} = +{ %$default_settings, %$settings };

    $self;
}

sub is_valid_settings {
    my $self            = shift;
    my $settings        = $self->{settings};
    my $user_token      = $settings->{user_token} || '';
    my $secret_key      = $settings->{secret_key};
    my $url_pattern     = $settings->{url_pattern};
    my $query           = $settings->{query};
    my $api_url         = $settings->{api_url};
    my $default_lang    = $settings->{default_lang};
    my $supported_langs = $settings->{supported_langs};

    my $valid = 1;
    my @errors;

    if ( length $user_token < 5 || length $user_token > 6 ) {
        $valid = 0;
        push @errors, "User token $user_token is not valid.";
    }
    if ( !defined $secret_key || $secret_key eq '' ) {
        $valid = 0;
        $secret_key = '' unless defined $secret_key;
        push @errors, "Secret key $secret_key is not valid.";
    }
    if ( !defined $url_pattern || $url_pattern eq '' ) {
        $valid = 0;
        $url_pattern = '' unless defined $url_pattern;
        push @errors, "Url pattern $url_pattern is not valid.";
    }
    if ( !$query || ref $query ne 'ARRAY' ) {
        $valid = 0;
        $query = '' unless defined $query;
        push @errors, "query config $query is not valid.";
    }
    if ( !defined $api_url || $api_url eq '' ) {
        $valid = 0;
        push @errors, 'API url is not configured.';
    }
    if ( !defined $default_lang || $default_lang eq '' ) {
        $valid = 0;
        $default_lang = '' unless defined $default_lang;
        push @errors, "Default lang $default_lang is not valid.";
    }
    if (   !$supported_langs
        || ref $supported_langs ne 'ARRAY'
        || @$supported_langs < 1 )
    {
        $valid = 0;
        push @errors, 'Supported langs configuration is not valid.';
    }

    if (@errors) {

        # output error logs?
    }

    $valid;
}

sub settings {
    my $self     = shift;
    my $settings = $self->{settings};

    if ( !$self->config_loaded ) {
        $settings->{default_lang} = Plack::Middleware::WOVN::Lang->get_code(
            $settings->{default_lang} );
        if ( !exists $settings->{supported_langs} ) {
            $settings->{supported_langs} = [ $settings->{default_lang} ];
        }
        if ( $settings->{url_pattern} eq 'path' ) {
            $settings->{url_pattern_reg} = "/(?<lang>[^/.?]+)";
        }
        elsif ( $settings->{url_pattern} eq 'query' ) {
            $settings->{url_pattern_reg}
                = "((\\?.*&)|\\?)wovn=(?<lang>[^&]+)(&|\$)";
        }
        elsif ( $settings->{url_pattern} eq 'subdomain' ) {
            $settings->{url_pattern_reg} = "^(?<lang>[^.]+)\.";
        }
        if ( !$settings->{test_mode} || $settings->{test_mode} ne 'on' ) {
            $settings->{test_mode} = 0;
        }
        else {
            $settings->{test_mode} = 1;
        }

        $self->config_loaded(1);
    }

    $settings;
}

sub get_values {
    my ( $self, $url ) = @_;
    $url =~ s/\/+$//;

    my $api_url    = $self->{settings}{api_url};
    my $user_token = $self->{settings}{user_token};

    my $ua  = LWP::UserAgent->new;
    my $res = $ua->get("$api_url?token=$user_token&url=$url");

    my $values = {};
    if ( $res->is_success ) {
        $values = eval { JSON::decode_json( $res->content ) } || {};
    }

    $values;
}

1;

__END__

=head1 NAME

Plack::Middleware::WOVN::Store - Retrieves data from WOVN API server.

=head1 SEE ALSO

L<Plack::Middleware::WOVN>

=cut

