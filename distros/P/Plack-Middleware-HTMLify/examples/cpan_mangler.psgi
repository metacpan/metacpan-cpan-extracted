#!/usr/bin/env perl

use strict;
use warnings;

use HTML::Entities;
use Plack::App::Proxy;
use Plack::Builder;

my $pod_highlight = q[
<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.3.2/jquery.min.js"></script>
<script type="text/javascript" src="http://alexgorbatchev.com.s3.amazonaws.com/pub/sh/3.0.83/scripts/shCore.js"></script>
<script type="text/javascript" src="http://alexgorbatchev.com.s3.amazonaws.com/pub/sh/3.0.83/scripts/shBrushPerl.js"></script>
<script type="text/javascript" src="http://alexgorbatchev.com.s3.amazonaws.com/pub/sh/3.0.83/scripts/shBrushJScript.js"></script>
<link href="http://alexgorbatchev.com.s3.amazonaws.com/pub/sh/3.0.83/styles/shCore.css" rel="stylesheet" type="text/css" />
<link href="http://alexgorbatchev.com.s3.amazonaws.com/pub/sh/3.0.83/styles/shThemeDefault.css" rel="stylesheet" type="text/css" />

<script type="text/javascript">
$(document).ready(function() {
$("pre").wrap('<div style="padding: 1px 10px; background-color: #fff; border: 1px solid #999;" />').addClass("brush: pl");
SyntaxHighlighter.defaults['gutter'] = false;
SyntaxHighlighter.defaults['toolbar'] = false;
SyntaxHighlighter.all();
});
</script>

];

my $source_highlight = q[
<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.3.2/jquery.min.js"></script>
<script type="text/javascript" src="http://alexgorbatchev.com.s3.amazonaws.com/pub/sh/3.0.83/scripts/shCore.js"></script>
<script type="text/javascript" src="http://alexgorbatchev.com.s3.amazonaws.com/pub/sh/3.0.83/scripts/shBrushPerl.js"></script>
<script type="text/javascript" src="http://alexgorbatchev.com.s3.amazonaws.com/pub/sh/3.0.83/scripts/shBrushJScript.js"></script>
<link href="http://alexgorbatchev.com.s3.amazonaws.com/pub/sh/3.0.83/styles/shCore.css" rel="stylesheet" type="text/css" />
<link href="http://alexgorbatchev.com.s3.amazonaws.com/pub/sh/3.0.83/styles/shThemeDefault.css" rel="stylesheet" type="text/css" />

<script type="text/javascript">
$(document).ready(function() {
SyntaxHighlighter.defaults['toolbar'] = false;
SyntaxHighlighter.all();
});
</script>
];

my $app = builder {
    mount "/source" => builder {
        enable 'HTMLify',
            set_head => $source_highlight,
            set_body_start => qq[<pre class="brush: pl">],
            set_body_end => qq[</pre>];
            ;
        enable 'SimpleContentFilter', filter => sub {
            encode_entities($_);
        };
        Plack::App::Proxy->new( remote => 'http://cpansearch.perl.org/src/' )->to_app;
    };
    mount "/" => builder {
        enable 'SimpleContentFilter', filter => sub {
            s{</head>}{$pod_highlight</head>}i;
            s{/src/}{/source/}gi;
        };
        Plack::App::Proxy->new( remote => 'http://search.cpan.org/' )->to_app;
    };
};

$app;