use warnings;
use strict;

package Marked::Down;
use base qw/Template::Declare/;
use Template::Declare::Tags;

template simple => sub {
    html
    { 
        head { }
        body
        {
            h1 { "*content* negative *zero*" };
            p { outs "should *also* uppercase" };
            p { outs_raw "should *never* uppercase" };
            p { attr { id => "foo*bar*baz" } "attrs shouldn't be markdowned" };
        }
    }
};

package main;
use Template::Declare;
use Test::More tests => 8;

Template::Declare->init(dispatch_to => ['Marked::Down']);
my $simple = Template::Declare->show('simple');
like($simple, qr/\*content\* negative \*zero\*/, "no postprocessing yet");
like($simple, qr/should \*also\* uppercase/, "no postprocessing yet");
like($simple, qr/should \*never\* uppercase/, "no postprocessing yet");
like($simple, qr/foo\*bar\*baz/, "no postprocessing yet");

Template::Declare->init(dispatch_to => ['Marked::Down'], postprocessor => \&postprocessor);
$simple = Template::Declare->show('simple');
like($simple, qr/(?<!\*)CONTENT negative ZERO(?!\*)/, "postprocessor transformed h1 { ... }");
like($simple, qr/should ALSO uppercase/, "postprocessor transformed outs");
like($simple, qr/should \*never\* uppercase/, "postprocessor did NOT transform outs_raw");
like($simple, qr/foo\*bar\*baz/, "attrs shouldn't be postprocessed");

sub postprocessor
{
    my $input = shift;
    $input =~ s/\*(.*?)\*/\U$1\E/g;
    return $input;
}

