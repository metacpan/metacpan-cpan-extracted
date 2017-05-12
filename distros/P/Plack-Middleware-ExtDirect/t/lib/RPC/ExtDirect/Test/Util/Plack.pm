package RPC::ExtDirect::Test::Util::Plack;

use strict;
use warnings;
no  warnings 'uninitialized';

use Test::More;

use Plack::Builder;
use Plack::Test;
use HTTP::Request;
use HTTP::Request::Common;

use RPC::ExtDirect::Test::Util;

use base 'Exporter';

our @EXPORT = qw/
    run_tests
/;

### EXPORTED PUBLIC PACKAGE SUBROUTINE ###
#
# Run the test battery from the passed definitions
#

sub run_tests {
    my ($tests, @run_only) = @_;
    
    my $cmp_pkg   = 'RPC::ExtDirect::Test::Util';
    my $num_tests = @run_only || @$tests;
    
    plan tests => 5 * $num_tests;
    
    TEST:
    for my $test ( @$tests ) {
        my $name   = $test->{name};
        my $config = $test->{config};
        my $input  = $test->{input};
        my $output = $test->{output};
        
        next TEST if @run_only && !grep { lc $name eq lc $_ } @run_only;

        my $url           = $input->{plack_url} || $input->{url};
        my $method        = $input->{method};
        my $input_content = $input->{plack_content} || $input->{content}
                            || { type => 'raw_get', arg => [$url] };
        
        my $req = prepare_input 'Plack', $input_content;
        
        if ( exists $config->{'-cgi_env'} ) {
            my $cookie = $config->{'-cgi_env'}->{HTTP_COOKIE};
            
            $req->header('Cookie', $cookie) if $cookie;
        }
        
        my $test_app = builder {
            enable 'ExtDirect', %$config;
            sub {
                [ 200, [ 'Content-type', 'text/plain' ], [ 'ok' ] ]
            };
        };

        my $test_client = sub {
            my ($cb) = @_;
            
            local $RPC::ExtDirect::Test::Pkg::PollProvider::WHAT_YOURE_HAVING
                = $config->{password};

            my $res = $cb->($req);

            if ( ok $res, "$name not empty" ) {
                my $want_status = $output->{status};
                my $have_status = $res->code;
                
                is $have_status, $want_status, "$name: HTTP status";
                
                my $want_type = $output->{content_type};
                my $have_type = $res->content_type;
                
                like $have_type, $want_type, "$name: content type";

                my $want_len = defined $output->{plack_content_length} 
                             ? $output->{plack_content_length}
                             : $output->{content_length};
                my $have_len = $res->content_length;

                is $have_len, $want_len, "$name: content length";

                my $cmp_fn = $output->{comparator};
                my $want   = $output->{plack_content} || $output->{content};
                my $have   = $res->content;
                
                $cmp_pkg->$cmp_fn($have, $want, "$name: content");
            };
        };

        test_psgi app => $test_app, client => $test_client;
    };
}

### NON EXPORTED PUBLIC PACKAGE SUBROUTINE ###
#
# Return a new HTTP::Request object for a raw GET call
#

sub raw_get {
    # This can be called either as a class method, or a plain sub
    shift if $_[0] eq __PACKAGE__;
    
    my ($url) = @_;
    
    return HTTP::Request::Common::GET $url;
}

### NON EXPORTED PUBLIC PACKAGE SUBROUTINE ###
#
# Return a new HTTP::Request object for a raw POST call
#

sub raw_post {
    # This can be called either as a class method, or a plain sub
    shift if $_[0] eq __PACKAGE__;
    
    my ($url, $content) = @_;
    
    return HTTP::Request::Common::POST $url,
                Content_Type => 'application/json',
                Content      => $content
           ;
}

### NON EXPORTED PUBLIC PACKAGE SUBROUTINE ###
#
# Return a new HTTP::Request object for a form call
#

sub form_post {
    # This can be called either as a class method, or a plain sub
    shift if $_[0] eq __PACKAGE__;
    
    my ($url, @fields) = @_;

    return HTTP::Request::Common::POST $url, Content => [ @fields ];
}

### NON EXPORTED PUBLIC PACKAGE SUBROUTINE ###
#
# Return a new HTTP::Request object for a form call
# with file uploads
#

sub form_upload {
    # This can be called either as a class method, or a plain sub
    shift if $_[0] eq __PACKAGE__;
    
    my ($url, $files, @fields) = @_;

    my $type = 'application/octet-stream';

    return HTTP::Request::Common::POST $url,
           Content_Type => 'form-data',
           Content      => [ @fields,
                             map {
                                    (   upload => [
                                            "t/data/cgi-data/$_",
                                            $_,
                                            'Content-Type' => $type,
                                        ]
                                    )
                                 } @$files
                           ]
    ;
}

1;
