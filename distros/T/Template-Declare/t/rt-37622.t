#!/usr/bin/env perl
package MyTemplates;
use strict;
use warnings;
use Template::Declare::Tags;
use base 'Template::Declare';

sub wrap (&) {
    my $code = shift;

    smart_tag_wrapper {
        my %p = @_;
        html {
            head {
                title { $p{title} }
            };

            $code->();

            div {
                outs 'footer';
            }
        }
    }
}

template 'test' => sub {
    with(title => 'Test'),
    wrap {
        h1 { "Hello, world!" }
    };
};

package main;
use Test::More tests => 2;

Template::Declare->init(dispatch_to => ['MyTemplates']);
my $output = Template::Declare->show('test');

unlike($output, qr{<html.*title="Test">});
like($output, qr{<title>\s*Test\s*</title>});

