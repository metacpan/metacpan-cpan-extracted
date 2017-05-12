use strict;
use warnings;
use Plack::Builder;

builder {
    enable 'Debug', panels =>['W3CValidate'];
    sub {
        return [ 200, [ 'Content-Type' => 'text/html' ], [
            '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',
            '<body>', 
                '<p>Hello World</p>',
                '<div>stuff',
                '<h4 sdasdasd> Nope</h3>',
            '</body>',
        ]];
    };
};

