#!/usr/bin/perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');

use OAuth::Lite::Consumer;
use OAuth::Lite::AuthMethod qw(:all);
use Data::Dumper;
use Perl6::Say;

my $consumer_key       = 'key';
my $consumer_secret    = 'secret';
my $site               = q{http://localhost};
my $request_token_path = q{/oauth/request_token};
my $access_token_path  = q{/oauth/access_token};
my $authorize_path     = q{http://localhost/authorize};
my $resource_url       = q{http://localhost/oauth/echo};


my $consumer  = OAuth::Lite::Consumer->new(
    consumer_key       => $consumer_key,
    consumer_secret    => $consumer_secret,
    site               => $site,
    request_token_path => $request_token_path,
    access_token_path  => $access_token_path,
    authorize_path     => $authorize_path,
    #signature_method   => 'PLAINTEXT',
    #auth_method        => POST_BODY,
);

my $request_token = $consumer->get_request_token();
say Dumper($request_token);

say Dumper($consumer->oauth_res);

my $access_token = $consumer->get_access_token( token => $request_token );
say Dumper($consumer->oauth_res);

my $res = $consumer->request(
    token   => $access_token,
    url     => $resource_url,
    params  => { file => 'hoge.jpg', size => 'small' },
);

say Dumper($res);

