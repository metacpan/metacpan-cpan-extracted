use warnings;
use strict;

package TestApp::UI;
use base qw/Template::Declare/;
use Template::Declare::Tags;

template content => sub {
    with( id => 'body' ), div {
        outs('This is my content');
    };

};

template content_curly => sub {
    div {
        { id is 'body' }
        outs('This is my content');
    }
};

template content_explicit => sub {
    div {
        attr { id is 'body' }
        outs('This is my content');
    }

};

template content_mixed1 => sub {
    div {
        { class is 'text' }
        attr { style => 'red', id is 'body' }
        outs('This is my red body text');
    }
};

template content_mixed2 => sub {
    with( class => 'text' ), div {
        { id is 'body' }
        attr { style => 'red' };    # Semicolon is intentional here
        outs('This is my red body text');
    }
};

template content_withs => sub {
    with( class => 'text', id => 'body', style => 'red' ), div {
        outs('This is my red body text');
    }
};

template content_curlies => sub {
    div {
        { class is 'text', id is 'body', style is 'red' }
        outs('This is my red body text');
    }
};

template content_attrs => sub {
    div {
        attr { class => 'text', id => 'body', style => 'red' }
        outs('This is my red body text');
    }
};

use Test::More tests => 39;
require "t/utils.pl";

Template::Declare->init(dispatch_to => ['TestApp::UI']);

for (qw(content content_curly content_explicit)) {
Template::Declare->buffer->clear;
    ok_content( show_page($_), $_ );
}

for (
    qw(content_mixed1 content_mixed2 content_attrs content_withs content_curlies)
  )
{
Template::Declare->buffer->clear;
    ok_multicontent( show_page($_), $_ );
}

sub ok_multicontent {
    my $simple = shift;
    my $test   = shift;
    like( $simple, qr{This is my red body text},                        $test );
    like( $simple, qr{^<div (.*?)>This is my red body text\s*</div>$}m, $test );
    like( $simple, qr{class="text"},                                    $test );
    like( $simple, qr{style="red"},                                     $test );
    like( $simple, qr{id="body"},                                       $test );

    #diag ($simple);
    ok_lint($simple);
}

sub ok_content {
    my $simple = shift;
    my $test   = shift;

    like( $simple, qr{This is my content},                         $test );
    like( $simple, qr{<div id="body">This is my content\s*</div>}, $test );

    #diag ($simple);
    ok_lint($simple);
}

1;
