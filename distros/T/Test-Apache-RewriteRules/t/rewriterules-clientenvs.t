use strict;
use warnings;
use FindBin;
use Path::Class;

use Test::More;
use Test::Fatal;

use Test::Apache::RewriteRules;
use Test::Apache::RewriteRules::ClientEnvs;

my $rewrite_conf = file("$FindBin::Bin/conf/rewrite.conf");

if (!Test::Apache::RewriteRules->available) {
    plan skip_all => "Can't exec httpd";
}

subtest 'useragent' => sub {
    my $rewrite = Test::Apache::RewriteRules->new;
       $rewrite->add_backend(name => 'BackendFoo');
       $rewrite->add_backend(name => 'BackendBar');
       $rewrite->rewrite_conf_f($rewrite_conf);
       $rewrite->start_apache;

    $rewrite->is_host_path(q</ua> => 'BackendFoo', q</>);

    with_docomo_browser {
        $rewrite->is_host_path(q</ua> => 'BackendFoo', q</> . Test::Apache::RewriteRules::ClientEnvs->user_agent_name('docomo')
        );
    };
    with_ezweb_browser {
        my $path = q</> . Test::Apache::RewriteRules::ClientEnvs->user_agent_name('ezweb');
        $path =~ s/ /%20/g;
        $rewrite->is_host_path(q</ua> => 'BackendFoo', $path);
    };
    with_softbank_browser {
        my $path = q</> . Test::Apache::RewriteRules::ClientEnvs->user_agent_name('softbank');
        $path =~ s/%%SBSerialNumber%%//g;
        $path =~ s/ /%20/g;
        $rewrite->is_host_path(q</ua> => 'BackendFoo', $path);
    };
    with_iphone_browser {
        my $path = q</> . Test::Apache::RewriteRules::ClientEnvs->user_agent_name('iphone');
        $path =~ s/ /%20/g;
        $rewrite->is_host_path(q</ua> => 'BackendFoo', $path);
    };
    with_ipod_browser {
        my $path = q</> . Test::Apache::RewriteRules::ClientEnvs->user_agent_name('ipod');
        $path =~ s/ /%20/g;
        $rewrite->is_host_path(q</ua> => 'BackendFoo', $path);
    };
    with_ipad_browser {
        my $path = q</> . Test::Apache::RewriteRules::ClientEnvs->user_agent_name('ipad');
        $path =~ s/ /%20/g;
        $rewrite->is_host_path(q</ua> => 'BackendFoo', $path);
    };
    with_android_browser {
        my $path = q</> . Test::Apache::RewriteRules::ClientEnvs->user_agent_name('android');
        $path =~ s/ /%20/g;
        $rewrite->is_host_path(q</ua> => 'BackendFoo', $path);
    };
    with_dsi_browser {
        my $path = q</> . Test::Apache::RewriteRules::ClientEnvs->user_agent_name('dsi');
        $path =~ s/ /%20/g;
        $rewrite->is_host_path(q</ua> => 'BackendFoo', $path);
    };
    with_wii_browser {
        my $path = q</> . Test::Apache::RewriteRules::ClientEnvs->user_agent_name('wii');
        $path =~ s/ /%20/g;
        $rewrite->is_host_path(q</ua> => 'BackendFoo', $path);
    };
    with_firefox_browser {
        my $path = q</> . Test::Apache::RewriteRules::ClientEnvs->user_agent_name('firefox');
        $path =~ s/ /%20/g;
        $rewrite->is_host_path(q</ua> => 'BackendFoo', $path);
    };
    with_opera_browser {
        my $path = q</> . Test::Apache::RewriteRules::ClientEnvs->user_agent_name('opera');
        $path =~ s/ /%20/g;
        $rewrite->is_host_path(q</ua> => 'BackendFoo', $path);
    };
    with_chrome_browser {
        my $path = q</> . Test::Apache::RewriteRules::ClientEnvs->user_agent_name('chrome');
        $path =~ s/ /%20/g;
        $rewrite->is_host_path(q</ua> => 'BackendFoo', $path);
    };
    with_safari_browser {
        my $path = q</> . Test::Apache::RewriteRules::ClientEnvs->user_agent_name('safari');
        $path =~ s/ /%20/g;
        $rewrite->is_host_path(q</ua> => 'BackendFoo', $path);
    };
    with_ie_browser {
        my $path = q</> . Test::Apache::RewriteRules::ClientEnvs->user_agent_name('ie');
        $path =~ s/ /%20/g;
        $rewrite->is_host_path(q</ua> => 'BackendFoo', $path);
    };
    with_googlebot_browser {
        my $path = q</> . Test::Apache::RewriteRules::ClientEnvs->user_agent_name('googlebot');
        $path =~ s/ /%20/g;
        $rewrite->is_host_path(q</ua> => 'BackendFoo', $path);
    };
    with_googlebot_mobile_browser {
        my $path = q</> . Test::Apache::RewriteRules::ClientEnvs->user_agent_name('googlebot_mobile');
        $path =~ s/ /%20/g;
        $rewrite->is_host_path(q</ua> => 'BackendFoo', $path);
    };

    $rewrite->stop_apache;
};

subtest 'request_method' => sub {
    my $rewrite = Test::Apache::RewriteRules->new;
       $rewrite->add_backend(name => 'BackendFoo');
       $rewrite->add_backend(name => 'BackendBar');
       $rewrite->rewrite_conf($rewrite_conf);
       $rewrite->start_apache;

    $rewrite->is_host_path(q</bmethod> => 'BackendFoo', q</method=GET>);
    $rewrite->is_redirect(q</pmethod> => q<http://hoge.test/method=GET>);
    with_request_method {
        $rewrite->is_host_path(q</bmethod> => 'BackendFoo', q</method=GET>);
        $rewrite->is_redirect(q</pmethod> => q<http://hoge.test/method=GET>);
    } 'GET';
    with_request_method {
        $rewrite->is_host_path(q</bmethod> => 'BackendFoo', q</method=POST>);
        $rewrite->is_redirect(q</pmethod> => q<http://hoge.test/method=POST>);
    } 'POST';

    $rewrite->stop_apache;
};

subtest 'with_cookie' => sub {
    my $rewrite = Test::Apache::RewriteRules->new;
       $rewrite->add_backend(name => 'BackendFoo');
       $rewrite->add_backend(name => 'BackendBar');
       $rewrite->rewrite_conf($rewrite_conf);
       $rewrite->start_apache;

    $rewrite->is_host_path(q</bcookie> => 'BackendFoo', q</>);
    with_http_cookie {
        $rewrite->is_host_path(q</bcookie> => 'BackendFoo', q</a=1>);
        with_http_cookie {
            $rewrite->is_host_path(q</bcookie> => 'BackendFoo', q</a=1;%20AbX=abacae>);
            with_http_cookie {
                $rewrite->is_host_path(q</bcookie> => 'BackendFoo', q</a=1;%20AbX=abacae;%20a=2>);
            } a => 2;
        } AbX => 'abacae';
        $rewrite->is_host_path(q</bcookie> => 'BackendFoo', q</a=1>);
    } a => 1;
    $rewrite->is_host_path(q</bcookie> => 'BackendFoo', q</>);

    $rewrite->stop_apache;
};

subtest 'with_http_header_field' => sub {
    my $rewrite = Test::Apache::RewriteRules->new;
       $rewrite->add_backend(name => 'BackendFoo');
       $rewrite->add_backend(name => 'BackendBar');
       $rewrite->rewrite_conf($rewrite_conf);
       $rewrite->start_apache;

    $rewrite->is_host_path(q</bxabc> => 'BackendFoo', q</>);
    with_http_header_field {
        $rewrite->is_host_path(q</bxabc> => 'BackendFoo', q</aba%20x>);
    } 'X-abc' => 'aba x';
    $rewrite->is_host_path(q</bcookie> => 'BackendFoo', q</>);

    $rewrite->stop_apache;
};

done_testing;
