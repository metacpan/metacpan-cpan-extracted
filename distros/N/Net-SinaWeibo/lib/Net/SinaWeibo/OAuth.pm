package Net::SinaWeibo::OAuth;
BEGIN {
  $Net::SinaWeibo::OAuth::VERSION = '0.003';
}
# ABSTRACT: Internal OAuth wrapper round OAuth::Lite::Consumer
use strict;
use warnings;
use Carp;
use Data::Dumper;
use base 'OAuth::Lite::Consumer';
use OAuth::Lite::AuthMethod qw(:all);
use List::MoreUtils qw(any);
use HTTP::Request::Common;
use JSON;
use OAuth::Lite::Util qw(normalize_params);
use constant {
    SINA_SITE               =>  'http://api.t.sina.com.cn',
    SINA_REQUEST_TOKEN_PATH => '/oauth/request_token',
    SINA_AUTHORIZATION_PATH => '/oauth/authorize',
    SINA_ACCESS_TOKEN_PATH  => '/oauth/access_token',
    SINA_FORMAT             => 'json',
};
__PACKAGE__->mk_accessors(qw(
    last_api
    last_api_error
    last_api_error_code
    last_api_error_subcode
));
sub new {
    my ($class,%args) = @_;
    my $tokens = delete $args{tokens};
    my $self = $class->SUPER::new(
        site => SINA_SITE,
        request_token_path => SINA_REQUEST_TOKEN_PATH,
        access_token_path  => SINA_ACCESS_TOKEN_PATH,
        authorize_path     => SINA_AUTHORIZATION_PATH,
        %args
        );
    if ($tokens->{request_token} && $tokens->{request_token_secret}) {
        $self->request_token(OAuth::Lite::Token->new(
            token  => $tokens->{request_token},
            secret => $tokens->{request_token_secret},
            ));
    }
    if ($tokens->{access_token} && $tokens->{access_token_secret}) {
        $self->access_token(OAuth::Lite::Token->new(
            token  => $tokens->{access_token},
            secret => $tokens->{access_token_secret},
            ));
    }
    if ($tokens->{verifier}) {
        $self->verifier($tokens->{verifier});
    }
    $self;
}

sub make_restricted_request {
    my ($self,$url,$method,%params) = @_;
    my %multi_parts = ();
    if ($method eq 'POST') {
        foreach my $param (keys %params) {
            next unless substr($param,0,1) eq '@';
            $multi_parts{substr($param,1) } = [delete $params{$param}];
        }
    }
    my $res = $self->request(
        method => $method,
        url => SINA_SITE.'/'.$url.'.'.SINA_FORMAT,
        token => $self->access_token,
        params => \%params,
        multi_parts => { %multi_parts }
        );
    my $content = $res->decoded_content || $res->content;
    unless ($res->is_success) {
        $self->_api_error($content,$res->code);
        croak $content;
    }
    decode_json($content);
}
sub _api_error {
    my ($self,$error,$http_code) = @_;
    eval {
        my $error = decode_json($error);
        $self->last_api_error($error);
        $self->last_api_error_code($error->{error_code}) if $error->{error_code};
        if ($error->{error} =~ /^(\d+):.*/) {
            $self->last_api_error_subcode($1);
        }
        else {
            $self->last_api_error_subcode(0);
        }
    };
    if ($@) {
        $self->last_api_error($error);
        $self->last_api_error_code($http_code);
        $self->last_api_error_subcode(0);
    }
}

sub load_tokens {
    my $class  = shift;
    my $file   = shift;
    my %tokens = ();
    return %tokens unless -f $file;

    open(my $fh, $file) || die "Couldn't open $file: $!\n";
    while (<$fh>) {
        chomp;
        next if /^#/;
        next if /^\s*$/;
        next unless /=/;
        s/(^\s*|\s*$)//g;
        my ($key, $val) = split /\s*=\s*/, $_, 2;
        $tokens{$key} = $val;
    }
    close($fh);
    return %tokens;
}

sub save_tokens {
    my $class  = shift;
    my $file   = shift;
    my %tokens = @_;

    my $max    = 0;
    foreach my $key (keys %tokens) {
        $max   = length($key) if length($key)>$max;
    }

    open(my $fh, ">$file") || die "Couldn't open $file for writing: $!\n";
    foreach my $key (sort keys %tokens) {
        my $pad = " "x($max-length($key));
        print $fh "$key ${pad}= ".$tokens{$key}."\n";
    }
    close($fh);
}
sub get_request_token {
    my $self = shift;
    my $res = $self->_get_request_token(@_);
    unless ($res->is_success) {
        return $self->error($res->status_line.',res:'.($res->decoded_content||$res->content));
    }
    my $token = OAuth::Lite::Token->from_encoded($res->decoded_content||$res->content);
    # workaround for SinaWeibo BUG!!
    # return $self->error(qq/oauth_callback_confirmed is not true/)
    #     unless $token && $token->callback_confirmed;
    $self->request_token($token);
    $token;
}

sub get_authorize_url {
    my ($self,%args) = @_;
    my $token = $args{token} || $self->request_token;
    unless ($token) {
        $token = $self->get_request_token(callback_url => $args{callback_url});
        Carp::croak "Can't find request token,err:".$self->errstr unless $token;
    }
    my $url = $args{url} || $self->authorization_url;
    my %params = ();
    $params{oauth_token} = ( eval { $token->isa('OAuth::Lite::Token') } )
        ? $token->token
        : $token;
    $params{oauth_callback} = $args{callback_url} if exists $args{callback_url};
    $url = URI->new($url);
    $url->query_form(%params);
    $url->as_string;
}
# override method to support multipart-form
sub gen_oauth_request {

    my ($self, %args) = @_;

    my $method  = $args{method} || $self->{http_method};
    my $url     = $args{url};
    my $content = $args{content};
    my $token   = $args{token};
    my $extra   = $args{params} || {};
    my $realm   = $args{realm}
                || $self->{realm}
                || $self->find_realm_from_last_response
                || '';
    my $multi_parts  = $args{multi_parts} || {};

    if (ref $extra eq 'ARRAY') {
        my %hash;
        for (0...scalar(@$extra)/2-1) {
            my $key = $extra->[$_ * 2];
            my $value = $extra->[$_ * 2 + 1];
            $hash{$key} ||= [];
            push @{ $hash{$key} }, $value;
        }
        $extra = \%hash;
    }
    my $headers = $args{headers} || {};

    croak 'headers is not valid HASH REF.' unless ref $headers eq 'HASH';

    my @send_data_methods = qw/POST PUT/;
    my @non_send_data_methods = qw/GET HEAD DELETE/;

    my $is_send_data_method = any { $method eq $_ } @send_data_methods;

    my $origin_url = $url;
    my $copied_params = {};
    for my $param_key ( keys %$extra ) {
        next if $param_key =~ /^x?oauth_/;
        $copied_params->{$param_key} = $extra->{$param_key};
    }
    if ( keys %$copied_params > 0 ) {
        my $data = normalize_params($copied_params);
        $url = sprintf q{%s?%s}, $url, $data unless $is_send_data_method;
    }

    my $header = $self->gen_auth_header($method, $origin_url,
        { realm => $realm, token => $token, extra => $extra });

    $headers->{Authorization} = $header;
    if ($method eq 'GET') {
        GET $url,%$headers;
    }
    elsif ($method eq 'POST') {
        if ( keys %$multi_parts) {
            POST $url,{ %$copied_params, %$multi_parts },'Content-Type' => 'form-data',%$headers;
        }
        else {
            POST $url,$copied_params,%$headers;
        }
    }
    else {
        Carp::croak 'unsupported http_method:'.$method;
    }
}
1;


=pod

=head1 NAME

Net::SinaWeibo::OAuth - Internal OAuth wrapper round OAuth::Lite::Consumer

=head1 VERSION

version 0.003

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Pan Fan(nightsailer) <nightsailer@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Pan Fan(nightsailer).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

