#!perl -w
use strict;
use warnings;
use utf8;

use Plack::Builder;

my $valid_html = q{
<html>
<head><title>hoge</title></head>
<body bgcolor="#000" style="color: #FFF"><h1>fuga</h1></body>
</html>
};

my $error_html = q{
<html>
<head><title>hoge</title></head>
<body bgcolor="#000" style="color: #FFF"><h1>fuga</h1><fuga>hoge</fuga></body>
</html>
};

builder {
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
};
