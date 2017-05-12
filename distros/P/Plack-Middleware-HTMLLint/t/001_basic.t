#!perl -w
use strict;
use Test::More;

#use Plack::Middleware::HTMLLint;

use Plack::Builder;
use Plack::Test;
use HTTP::Request;

my $valid_html = q{
<html>
<head><title>hoge</title></head>
<body bgcolor="#000">fuga</body>
</html>
};

my $error_html = q{
<html>
<head><title>hoge</title></head>
<body bgcolor="#000">fuga<hoge></hoge></body>
</html>
};

my $broken_error_html = q{
<html>
<head><title>hoge</title></head>
fuga<hoge></hoge>
</html>
};

my $error_html_res = q{
<html>
<head><title>hoge</title></head>
<body bgcolor="#000"><div style="border: double 3px; background-color: rgba(255, 0, 0, 0.2); margin: 3px; padding: 2px;"><h4 style="color: red">HTML&nbsp;Error</h4><dl><dt style="margin-left: 0.25em">elem-unknown</dt><dd style="padding-top: 0.25em; border-bottom: 1px solid #cccc00"> (4:26) Unknown element &lt;hoge&gt;</dd></dl></div>fuga<hoge></hoge></body>
</html>
};

my $error_html_res_streaming = q{
<html>
<head><title>hoge</title></head>
<body bgcolor="#000">fuga<hoge></hoge><div style="border: double 3px; background-color: rgba(255, 0, 0, 0.2); margin: 3px; padding: 2px;"><h4 style="color: red">HTML&nbsp;Error</h4><dl><dt style="margin-left: 0.25em">elem-unknown</dt><dd style="padding-top: 0.25em; border-bottom: 1px solid #cccc00"> (4:26) Unknown element &lt;hoge&gt;</dd></dl></div></body>
</html>
};

my $broken_error_html_res = q{
<html>
<head><title>hoge</title></head>
fuga<hoge></hoge>
</html>
<div style="border: double 3px; background-color: rgba(255, 0, 0, 0.2); margin: 3px; padding: 2px;"><h4 style="color: red">HTML&nbsp;Error</h4><dl><dt style="margin-left: 0.25em">elem-unknown</dt><dd style="padding-top: 0.25em; border-bottom: 1px solid #cccc00"> (4:5) Unknown element &lt;hoge&gt;</dd><dt style="margin-left: 0.25em">doc-tag-required</dt><dd style="padding-top: 0.25em; border-bottom: 1px solid #cccc00"> (5:1) &lt;body&gt; tag is required</dd></dl></div>
};
chomp $broken_error_html_res;

my $normal_handler = builder {
    enable 'HTMLLint';
    mount '/text' => sub {
        return [200, ['Content-Type' => 'text/plain'], [ 'OK' ]];
    };
    mount '/valid_html' => sub {
        return [200, ['Content-Type' => 'text/html'], [$valid_html]];
    };
    mount '/error_html' => sub {
        return [200, ['Content-Type' => 'text/html'], [$error_html]];
    };
    mount '/broken_error_html' => sub {
        return [200, ['Content-Type' => 'text/html'], [$broken_error_html]];
    };
};

my $streaming_handler = builder {
    enable 'HTMLLint';
    mount '/text' => sub {
        return sub {
            my $responder = shift;
            my $writer = $responder->([200, ['Content-Type' => 'text/plain']]);
            $writer->write("OK");
            $writer->close;
        };
    };
    mount '/valid_html' => sub {
        return sub {
            my $responder = shift;
            my $writer = $responder->([200, ['Content-Type' => 'text/html']]);
            foreach my $line (split /\n/, $valid_html) {
                $writer->write($line);
                $writer->write("\n");
            }
            $writer->close;
        };
    };
    mount '/error_html' => sub {
        return sub {
            my $responder = shift;
            my $writer = $responder->([200, ['Content-Type' => 'text/html']]);
            foreach my $line (split /\n/, $error_html) {
                $writer->write($line);
                $writer->write("\n");
            }
            $writer->close;
        };
    };
    mount '/broken_error_html' => sub {
        return sub {
            my $responder = shift;
            my $writer = $responder->([200, ['Content-Type' => 'text/html']]);
            foreach my $line (split /\n/, $broken_error_html) {
                $writer->write($line);
                $writer->write("\n");
            }
            $writer->close;
        };
    };
};

subtest 'normal' => sub {
    test_psgi(
        client => sub {
            my $cb = shift;
            my $res;

            $res = $cb->( HTTP::Request->new(GET => 'http://example.com/text') );
            is $res->content, 'OK', 'plain text is not modified.';

            $res = $cb->( HTTP::Request->new(GET => 'http://example.com/valid_html') );
            is $res->content, $valid_html, 'valid html is not modified.';

            $res = $cb->( HTTP::Request->new(GET => 'http://example.com/error_html') );
            isnt $res->content, $error_html, 'error html is modified.';
            is $res->content,   $error_html_res, 'error html has error message.';

            $res = $cb->( HTTP::Request->new(GET => 'http://example.com/broken_error_html') );
            isnt $res->content, $broken_error_html, 'broken error html is modified.';
            is $res->content,   $broken_error_html_res, 'broken error html has error message.';
        },
        app    => $normal_handler,
    );
};

subtest 'streaming' => sub {
    test_psgi(
        client => sub {
            my $cb = shift;
            my $res;

            $res = $cb->( HTTP::Request->new(GET => 'http://example.com/text') );
            is $res->content, 'OK', 'plain text is not modified.';

            $res = $cb->( HTTP::Request->new(GET => 'http://example.com/valid_html') );
            is $res->content, $valid_html, 'valid html is not modified.';

            $res = $cb->( HTTP::Request->new(GET => 'http://example.com/error_html') );
            isnt $res->content, $error_html, 'error html is modified.';
            is $res->content,   $error_html_res_streaming, 'error html has error message.';

            $res = $cb->( HTTP::Request->new(GET => 'http://example.com/broken_error_html') );
            isnt $res->content, $broken_error_html, 'broken error html is modified.';
            is $res->content,   $broken_error_html_res, 'broken error html has error message.';
        },
        app    => $streaming_handler,
    );
};

done_testing;
