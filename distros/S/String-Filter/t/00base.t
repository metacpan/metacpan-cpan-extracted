use strict;
use warnings;

use HTML::Entities qw(encode_entities);
use Test::More;
use URI::Escape qw(uri_escape);

use_ok('String::Filter');

my $sf = String::Filter->new(
    rules        => [
        'http://[A-Za-z0-9_\-\~\.\%\?\#\@/]+' => sub {
            my $url = shift;
            qq{<a href="@{[encode_entities($url)]}">@{[encode_entities($url)]}</a>};
        },
        '(?:^|\s)\@[A-Za-z0-9_]+' => sub {
            $_[0] =~ /^(.*?\@)(.*)$/;
            my ($prefix, $user) = ($1, $2);
            qq{$prefix<a href="http://twitter.com/@{[encode_entities($user)]}">$user</a>};
        },
        '(?:^|\s)#[A-Za-z0-9_]+' => sub {
            $_[0] =~ /^(.?)(#.*)$/;
            my ($prefix, $hashtag) = ($1, $2);
            qq{$prefix<a href="http://twitter.com/search?q=@{[encode_entities(uri_escape($hashtag))]}"><b>@{[encode_entities($hashtag)]}</b></a>};
        },
    ],
    default_rule => sub {
        my $text = shift;
        encode_entities($text);
    },
);
is(
    $sf->filter('@kazuho @kazuho foo@bar http://hello.com/ yesyes <b> #hash'),
    '@<a href="http://twitter.com/kazuho">kazuho</a> @<a href="http://twitter.com/kazuho">kazuho</a> foo@bar <a href="http://hello.com/">http://hello.com/</a> yesyes &lt;b&gt; <a href="http://twitter.com/search?q=%23hash"><b>#hash</b></a>',
);

done_testing;
