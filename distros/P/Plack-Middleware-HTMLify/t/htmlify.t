use strict;
use Data::Dump qw(dump);
use Test::More;
use Plack::Builder;
use Plack::Test;
use Plack::Middleware::HTMLify;

my $html;
my $test_name;

my $app = sub {
    return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello World' ] ];
};

my @builders = (
    # test for: default settings
    sub {
        $app = builder {
            enable "HTMLify";
            $html = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html lang="en">
<body>
Hello World
</body>
</html>';
            $test_name = "default settings";
            $app;
        };
    },
    # test for: set_doctype
    sub {
        $app = builder {
            enable "HTMLify",
                set_doctype=> '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">';
            $html = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<body>
Hello World
</body>
</html>';
            $test_name = "set_doctype";
            $app;
        };
    },
    # test for: set_body_start
    sub {
        $app = builder {
            enable "HTMLify",
                set_body_start => 'Body start test.';
            $html = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html lang="en">
<body>
Body start test.
Hello World
</body>
</html>';
            $test_name = "set_body_start";
            $app;
        };
    },
    # test for: set_body_end
    sub {
        $app = builder {
            enable "HTMLify",
                set_body_end => 'Body end test.';
            $html = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html lang="en">
<body>
Hello World
Body end test.
</body>
</html>';
            $test_name = "set_body_end";
            $app;
        };
    },
    # test for: set_head
    sub {
        $app = builder {
            enable "HTMLify",
                set_head => '<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js"></script>
<script type="text/javascript">$(document).ready(function() { $(body).css(\'color\', \'red\')});</script>';
            $html = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html lang="en">
<head>
<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js"></script>
<script type="text/javascript">$(document).ready(function() { $(body).css(\'color\', \'red\')});</script>
</head>
<body>
Hello World
</body>
</html>';
            $test_name = "set_head";
            $app;
        };
    }
);

foreach my $builder (@builders) {
    $app = sub {
        return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello World' ] ];
    };
    &$builder;
    test_psgi
        app => $app,
        client => sub {
            my $cb = shift;
            my $res = $cb->(HTTP::Request->new(GET => 'http://localhost/'));
            is $res->decoded_content, $html, $test_name;
        };
}

done_testing;