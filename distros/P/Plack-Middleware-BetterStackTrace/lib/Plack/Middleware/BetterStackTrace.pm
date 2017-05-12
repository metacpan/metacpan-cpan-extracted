# vim: set expandtab ts=4 sw=4 nowrap ft=perl ff=unix :
package Plack::Middleware::BetterStackTrace;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.02";

use parent qw/Plack::Middleware/;

use JSON;
use Try::Tiny;
use Data::Dumper;
use Text::Xslate;
use Plack::Request;
use Term::ANSIColor;
use Text::Xslate::Util;
use Devel::StackTrace::WithLexicals;
use Plack::Util::Accessor qw( force no_print_errors );

my $dumper = sub {
    my $value = shift;
    $value = $$value if ref $value eq 'SCALAR' or ref $value eq 'REF';
    my $d = Data::Dumper->new([$value]);
    $d->Indent(1)->Terse(1)->Deparse(1);
    chomp(my $dump = $d->Dump);
    $dump;
};

sub call {
    my ($self, $env) = @_;

    my $trace;
    local $SIG{__DIE__} = sub {
        $|     = 1;
        $trace = Devel::StackTrace::WithLexicals->new(
            indent => 1, message => munge_error($_[0], [caller]),
            ignore_package => __PACKAGE__,
        );
        die @_;
    };

    my $caught;
    my $res = try {
        $self->app->($env);
    }
    catch {
        $caught = $_;
        [
            500, [ "Content-Type", "text/plain; charset=utf-8" ],
            [ no_trace_error(utf8_safe($caught)) ]
        ];
    };

    if (
        $trace
        && ($caught
            || ($self->force && ref $res eq 'ARRAY' && $res->[0] == 500))
      ) {
        my $text = render_text(
            $trace, $env,
            application_caller_subroutine =>
              $self->{application_caller_subroutine} || '',
        );
        my $html = render_html(
            $trace, $env,
            application_caller_subroutine =>
              $self->{application_caller_subroutine} || '',
        );
        $env->{'plack.stacktrace.text'} = $text;
        $env->{'plack.stacktrace.html'} = $html;
        $env->{'psgi.errors'}->print($text) unless $self->no_print_errors;
        my $accept_mime_types = $env->{HTTP_ACCEPT} || '*/*';
        if ($accept_mime_types =~ /html/) {
            $res = [
                500, [ 'Content-Type' => 'text/html; charset=utf-8' ],
                [ utf8_safe($html) ]
            ];
        } else {
            $res = [
                500, [ 'Content-Type' => 'text/plain; charset=utf-8' ],
                [ utf8_safe($text) ]
            ];
        }
    } ## end if ($trace && ($caught || ($self...)))

    # break $trace here since $SIG{__DIE__} holds the ref to it, and
    # $trace has refs to Standalone.pm's args ($conn etc.) and
    # prevents garbage collection to be happening.
    undef $trace;

    return $res;
} ## end sub call

sub no_trace_error {
    my $msg = shift;
    chomp($msg);

    return <<EOF;
The application raised the following error:

  $msg

and the StackTrace middleware couldn't catch its stack trace, possibly because your application overrides \$SIG{__DIE__} by itself, preventing the middleware from working correctly. Remove the offending code or module that does it: known examples are CGI::Carp and Carp::Always.
EOF
}

sub munge_error {
    my ($err, $caller) = @_;
    return $err if ref $err;

    # Ugly hack to remove " at ... line ..." automatically appended by perl
    # If there's a proper way to do this, please let me know.
    $err =~ s/ at \Q$caller->[1]\E line $caller->[2]\.\n$//;

    return $err;
}

sub utf8_safe {
    my $str = shift;

    # NOTE: I know messing with utf8:: in the code is WRONG, but
    # because we're running someone else's code that we can't
    # guarnatee which encoding an exception is encoded, there's no
    # better way than doing this. The latest Devel::StackTrace::AsHTML
    # (0.08 or later) encodes high-bit chars as HTML entities, so this
    # path won't be executed.
    if (utf8::is_utf8($str)) {
        utf8::encode($str);
    }

    $str;
}

sub frame_filter {
    my ($trace, $tx, %opt) = @_;

    my @frames = $trace->frames();
    my @filtered_frames;

    my $context = 'application';

    for my $i (0 .. $#frames) {
        my $frame = $frames[$i];
        my $next_frame = ($i == $#frames - 1) ? undef : $frames[ $i + 1 ];

        my @method_name = split('::', $frame->subroutine);
        my $method_name = pop(@method_name);
        my $module_name = join('::', @method_name);

        if ($module_name) {
            $method_name = '::' . $method_name;
        }

        if (   $next_frame
            && $next_frame->subroutine eq $opt{application_caller_subroutine}) {
            $context = 'dunno';
        }

        my @args = $next_frame ? $next_frame->args : undef;

        push @filtered_frames,
          +{
            context     => $context,
            subroutine  => $frame->subroutine,
            module_name => $module_name,
            method_name => $method_name,
            filename    => $frame->filename,
            line        => $frame->line,
            info_html   => $tx->render(
                'variables_info',
                +{
                    frame                     => $frame,
                    args                      => \@args,
                    html_formatted_code_block => context_html($frame),
                }
            ),
          };
    } ## end for my $i (0 .. $#frames)

    \@filtered_frames;
} ## end sub frame_filter

sub context_html {
    my $frame   = shift;
    my $file    = $frame->filename;
    my $linenum = $frame->line;
    my $code    = '<div class="code">';
    if (-f $file) {
        my $start = $linenum - 3;
        my $end   = $linenum + 3;
        $start = $start < 1 ? 1 : $start;
        open my $fh, '<', $file
          or die "cannot open $file:$!";
        my $cur_line = 0;
        while (my $line = <$fh>) {
            ++$cur_line;
            last if $cur_line > $end;
            next if $cur_line < $start;
            $line =~ s|\t|        |g;
            my @tag =
              $cur_line == $linenum
              ? (q{<pre class="highlight">}, '</pre>')
              : ('<pre>', '</pre>');
            $code .= sprintf(
                '%s%5d: %s%s', $tag[0], $cur_line,
                Text::Xslate::Util::html_escape($line),
                $tag[1],
            );
        }
        close $file;
    }
    $code .= '</div>';
    $code;
} ## end sub context_html

sub render_text {
    my ($trace, $psgi_env, %opt) = @_;

    my $text   = '';
    my $first  = 1;
    my @frames = $trace->frames;
    for my $frame ($trace->frames()) {
        if ($frame->subroutine eq $opt{application_caller_subroutine}) {
            last;
        }

        $text .= $frame->as_string($first, \%opt) . "\n";
        $first = 0;
    }
    $text;
}

sub render_html {
    my ($trace, $psgi_env, %opt) = @_;

    my $message = $trace->frame(0)->as_string(1);

    # Remove escape sequence
    $message = Term::ANSIColor::colorstrip($message);

    my $tx = Text::Xslate->new(
        syntax => 'TTerse',
        path   => +{
            base           => base_html(),
            variables_info => variables_info_html(),
        },
        function => {
            dump => $dumper,
        }
    );

    my $request = Plack::Request->new($psgi_env);
    my $backtrace_frames = frame_filter($trace, $tx, %opt);

    return $tx->render(
        'base',
        +{
            backtrace_frames => $backtrace_frames,
            request          => $request,
            message          => $message,
        }
    );
} ## end sub render_html

sub base_html {
    <<'EOTMPL' }
<!DOCTYPE html>
<html>
<head>
    <title>[% message %][% IF request.request_uri %] at [% request.request_uri %][% END %]</title>
    <style>
    /* Basic reset */
    * {
        margin: 0;
        padding: 0;
    }

    table {
        width: 100%;
        border-collapse: collapse;
    }

    th, td {
        vertical-align: top;
        text-align: left;
    }

    textarea {
        resize: none;
    }

    body {
        font-size: 10pt;
    }

    body, td, input, textarea {
        font-family: helvetica neue, lucida grande, sans-serif;
        line-height: 1.5;
        color: #333;
        text-shadow: 0 1px 0 rgba(255, 255, 255, 0.6);
    }

    html {
        background: #f0f0f5;
    }

    /* ---------------------------------------------------------------------
     * Basic layout
     * --------------------------------------------------------------------- */

    /* Small */
    @media screen and (max-width: 1100px) {
        html {
            overflow-y: scroll;
        }

        body {
            margin: 0 20px;
        }

        header.exception {
            margin: 0 -20px;
        }

        nav.sidebar {
            padding: 0;
            margin: 20px 0;
        }

        ul.frames {
            max-height: 200px;
            overflow: auto;
        }
    }

    /* Wide */
    @media screen and (min-width: 1100px) {
        header.exception {
           position: fixed;
           top: 0;
           left: 0;
           right: 0;
        }

        nav.sidebar,
        .frame_info {
            position: fixed;
            top: 95px;
            bottom: 0;

            box-sizing: border-box;

            overflow-y: auto;
            overflow-x: hidden;
        }

        nav.sidebar {
            width: 40%;
            left: 20px;
            top: 115px;
            bottom: 20px;
        }

        .frame_info {
            right: 0;
            left: 40%;

            padding: 20px;
            padding-left: 10px;
            margin-left: 30px;
        }
    }

    nav.sidebar {
        background: #d3d3da;
        border-top: solid 3px #a33;
        border-bottom: solid 3px #a33;
        border-radius: 4px;
        box-shadow: 0 0 6px rgba(0, 0, 0, 0.2), inset 0 0 0 1px rgba(0, 0, 0, 0.1);
    }

    /* ---------------------------------------------------------------------
     * Header
     * --------------------------------------------------------------------- */

    header.exception {
        padding: 18px 20px;

        height: 59px;
        min-height: 59px;

        overflow: hidden;

        background-color: #20202a;
        color: #aaa;
        text-shadow: 0 1px 0 rgba(0, 0, 0, 0.3);
        font-weight: 200;
        box-shadow: inset 0 -5px 3px -3px rgba(0, 0, 0, 0.05), inset 0 -1px 0 rgba(0, 0, 0, 0.05);

        -webkit-text-smoothing: antialiased;
    }

    /* Heading */
    header.exception h2 {
        font-weight: 200;
        font-size: 11pt;
    }

    header.exception h2,
    header.exception p {
        line-height: 1.4em;
        overflow: hidden;
        white-space: pre;
        text-overflow: ellipsis;
    }

    header.exception h2 strong {
        font-weight: 700;
        color: #d55;
    }

    header.exception p {
        font-weight: 200;
        font-size: 20pt;
        color: white;
    }

    header.exception:hover {
        height: auto;
        z-index: 2;
    }

    header.exception:hover h2,
    header.exception:hover p {
        padding-right: 20px;
        overflow-y: auto;
        word-wrap: break-word;
        height: auto;
        max-height: 7em;
    }

    @media screen and (max-width: 1100px) {
        header.exception {
            height: auto;
        }

        header.exception h2,
        header.exception p {
            padding-right: 20px;
            overflow-y: auto;
            word-wrap: break-word;
            height: auto;
            max-height: 7em;
        }
    }

    /* ---------------------------------------------------------------------
     * Navigation
     * --------------------------------------------------------------------- */

    nav.tabs {
        border-bottom: solid 1px #ddd;

        background-color: #eee;
        text-align: center;

        padding: 6px;

        box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.1);
    }

    nav.tabs a {
        display: inline-block;

        height: 22px;
        line-height: 22px;
        padding: 0 10px;

        text-decoration: none;
        font-size: 8pt;
        font-weight: bold;

        color: #999;
        text-shadow: 0 1px 0 rgba(255, 255, 255, 0.6);
    }

    nav.tabs a.selected {
        color: white;
        background: rgba(0, 0, 0, 0.5);
        border-radius: 16px;
        box-shadow: 1px 1px 0 rgba(255, 255, 255, 0.1);
        text-shadow: 0 0 4px rgba(0, 0, 0, 0.4), 0 1px 0 rgba(0, 0, 0, 0.4);
    }

    /* ---------------------------------------------------------------------
     * Sidebar
     * --------------------------------------------------------------------- */

    ul.frames {
        box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
    }

    /* Each item */
    ul.frames li {
        background-color: #f8f8f8;
        background: -webkit-linear-gradient(top, #f8f8f8 80%, #f0f0f0);
        background: -moz-linear-gradient(top, #f8f8f8 80%, #f0f0f0);
        background: linear-gradient(top, #f8f8f8 80%, #f0f0f0);
        box-shadow: inset 0 -1px 0 #e2e2e2;
        padding: 7px 20px;

        cursor: pointer;
        overflow: hidden;
    }

    ul.frames .name,
    ul.frames .location {
        overflow: hidden;
        height: 1.5em;

        white-space: nowrap;
        word-wrap: none;
        text-overflow: ellipsis;
    }

    ul.frames .method {
        color: #966;
    }

    ul.frames .location {
        font-size: 0.85em;
        font-weight: 400;
        color: #999;
    }

    ul.frames .line {
        font-weight: bold;
    }

    /* Selected frame */
    ul.frames li.selected {
        background: #38a;
        box-shadow: inset 0 1px 0 rgba(0, 0, 0, 0.1), inset 0 2px 0 rgba(255, 255, 255, 0.01), inset 0 -1px 0 rgba(0, 0, 0, 0.1);
    }

    ul.frames li.selected .name,
    ul.frames li.selected .method,
    ul.frames li.selected .location {
        color: white;
        text-shadow: 0 1px 0 rgba(0, 0, 0, 0.2);
    }

    ul.frames li.selected .location {
        opacity: 0.6;
    }

    /* Iconography */
    ul.frames li {
        padding-left: 60px;
        position: relative;
    }

    ul.frames li .icon {
        display: block;
        width: 20px;
        height: 20px;
        line-height: 20px;
        border-radius: 15px;

        text-align: center;

        background: white;
        border: solid 2px #ccc;

        font-size: 9pt;
        font-weight: 200;
        font-style: normal;

        position: absolute;
        top: 14px;
        left: 20px;
    }

    ul.frames .icon.application {
        background: #808090;
        border-color: #555;
    }

    ul.frames .icon.application:before {
        content: 'A';
        color: white;
        text-shadow: 0 0 3px rgba(0, 0, 0, 0.2);
    }

    /* Responsiveness -- flow to single-line mode */
    @media screen and (max-width: 1100px) {
        ul.frames li {
            padding-top: 6px;
            padding-bottom: 6px;
            padding-left: 36px;
            line-height: 1.3;
        }

        ul.frames li .icon {
            width: 11px;
            height: 11px;
            line-height: 11px;

            top: 7px;
            left: 10px;
            font-size: 5pt;
        }

        ul.frames .name,
        ul.frames .location {
            display: inline-block;
            line-height: 1.3;
            height: 1.3em;
        }

        ul.frames .name {
            margin-right: 10px;
        }
    }

    /* ---------------------------------------------------------------------
     * Monospace
     * --------------------------------------------------------------------- */

    pre, code, .repl input, .repl .prompt span, textarea {
        font-family: menlo, lucida console, monospace;
        font-size: 8pt;
    }

    /* ---------------------------------------------------------------------
     * Display area
     * --------------------------------------------------------------------- */

    .trace_info {
        background: #fff;
        padding: 6px;
        border-radius: 3px;
        margin-bottom: 2px;
        box-shadow: 0 0 10px rgba(0, 0, 0, 0.03), 1px 1px 0 rgba(0, 0, 0, 0.05), -1px 1px 0 rgba(0, 0, 0, 0.05), 0 0 0 4px rgba(0, 0, 0, 0.04);
    }

    /* Titlebar */
    .trace_info .title {
        background: #f1f1f1;

        box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.3);
        overflow: hidden;
        padding: 6px 10px;

        border: solid 1px #ccc;
        border-bottom: 0;

        border-top-left-radius: 2px;
        border-top-right-radius: 2px;
    }

    .trace_info .title .name,
    .trace_info .title .location {
        font-size: 9pt;
        line-height: 26px;
        height: 26px;
        overflow: hidden;
    }

    .trace_info .title .location {
        float: left;
        font-weight: bold;
        font-size: 10pt;
    }

    .trace_info .title .location a {
        color:inherit;
        text-decoration:none;
        border-bottom:1px solid #aaaaaa;
    }

    .trace_info .title .location a:hover {
        border-color:#666666;
    }

    .trace_info .title .name {
        float: right;
        font-weight: 200;
    }

    .code, .console, .unavailable {
        background: #fff;
        padding: 5px;

        box-shadow: inset 3px 3px 3px rgba(0, 0, 0, 0.1), inset 0 0 0 1px rgba(0, 0, 0, 0.1);
    }

    .code {
        margin-bottom: -1px;
    }

    .code {
        padding: 10px 0;
        overflow: auto;
    }

    /* Source unavailable */
    p.unavailable {
        padding: 20px 0 40px 0;
        text-align: center;
        color: #b99;
        font-weight: bold;
    }

    p.unavailable:before {
        content: '\00d7';
        display: block;

        color: #daa;

        text-align: center;
        font-size: 40pt;
        font-weight: normal;
        margin-bottom: -10px;
    }

    @-webkit-keyframes highlight {
        0%   { background: rgba(220, 30, 30, 0.3); }
        100% { background: rgba(220, 30, 30, 0.1); }
    }
    @-moz-keyframes highlight {
        0%   { background: rgba(220, 30, 30, 0.3); }
        100% { background: rgba(220, 30, 30, 0.1); }
    }
    @keyframes highlight {
        0%   { background: rgba(220, 30, 30, 0.3); }
        100% { background: rgba(220, 30, 30, 0.1); }
    }

    .code .highlight {
        background: rgba(220, 30, 30, 0.1);
        -webkit-animation: highlight 400ms linear 1;
        -moz-animation: highlight 400ms linear 1;
        animation: highlight 400ms linear 1;
    }

    /* REPL shell */
    .console {
        padding: 0 1px 10px 1px;
        border-bottom-left-radius: 2px;
        border-bottom-right-radius: 2px;
    }

    .console pre {
        padding: 10px 10px 0 10px;
        max-height: 400px;
        overflow-x: none;
        overflow-y: auto;
        margin-bottom: -3px;
        word-wrap: break-word;
        white-space: pre-wrap;
    }

    /* .prompt > span + input */
    .console .prompt {
        display: table;
        width: 100%;
    }

    .console .prompt span,
    .console .prompt input {
        display: table-cell;
    }

    .console .prompt span {
        width: 1%;
        padding-right: 5px;
        padding-left: 10px;
    }

    .console .prompt input {
        width: 99%;
    }

    /* Input box */
    .console input,
    .console input:focus {
        outline: 0;
        border: 0;
        padding: 0;
        background: transparent;
        margin: 0;
    }

    /* Hint text */
    .hint {
        margin: 15px 0 20px 0;
        font-size: 8pt;
        color: #8080a0;
        padding-left: 20px;
    }

    .hint:before {
        content: '\25b2';
        margin-right: 5px;
        opacity: 0.5;
    }

    /* ---------------------------------------------------------------------
     * Variable infos
     * --------------------------------------------------------------------- */

    .sub {
        padding: 10px 0;
        margin: 10px 0;
    }

    .sub:before {
        content: '';
        display: block;
        width: 100%;
        height: 4px;

        border-radius: 2px;
        background: rgba(0, 150, 200, 0.05);
        box-shadow: 1px 1px 0 rgba(255, 255, 255, 0.7), inset 0 0 0 1px rgba(0, 0, 0, 0.04), inset 2px 2px 2px rgba(0, 0, 0, 0.07);
    }

    .sub h3 {
        color: #39a;
        font-size: 1.1em;
        margin: 10px 0;
        text-shadow: 0 1px 0 rgba(255, 255, 255, 0.6);

        -webkit-font-smoothing: antialiased;
    }

    .sub .inset {
        overflow-y: auto;
    }

    .sub table {
        table-layout: fixed;
    }

    .sub table td {
        border-top: dotted 1px #ddd;
        padding: 7px 1px;
    }

    .sub table td.name {
        width: 150px;

        font-weight: bold;
        font-size: 0.8em;
        padding-right: 20px;

        word-wrap: break-word;
    }

    .sub table td pre {
        max-height: 15em;
        overflow-y: auto;
    }

    .sub table td pre {
        width: 100%;

        word-wrap: break-word;
        white-space: normal;
    }

    /* "(object doesn't support inspect)" */
    .sub .unsupported {
      font-family: sans-serif;
      color: #777;
    }

    /* ---------------------------------------------------------------------
     * Scrollbar
     * --------------------------------------------------------------------- */

    nav.sidebar::-webkit-scrollbar,
    .inset pre::-webkit-scrollbar,
    .console pre::-webkit-scrollbar,
    .code::-webkit-scrollbar {
        width: 10px;
        height: 10px;
    }

    .inset pre::-webkit-scrollbar-thumb,
    .console pre::-webkit-scrollbar-thumb,
    .code::-webkit-scrollbar-thumb {
        background: #ccc;
        border-radius: 5px;
    }

    nav.sidebar::-webkit-scrollbar-thumb {
        background: rgba(0, 0, 0, 0.0);
        border-radius: 5px;
    }

    nav.sidebar:hover::-webkit-scrollbar-thumb {
        background-color: #999;
        background: -webkit-linear-gradient(left, #aaa, #999);
    }

    .console pre:hover::-webkit-scrollbar-thumb,
    .inset pre:hover::-webkit-scrollbar-thumb,
    .code:hover::-webkit-scrollbar-thumb {
        background: #888;
    }
    </style>

    [%# IE8 compatibility crap %]
    <script>
    (function() {
        var elements = ["section", "nav", "header", "footer", "audio"];
        for (var i = 0; i < elements.length; i++) {
            document.createElement(elements[i]);
        }
    })();
    </script>

    <script>
      if (window.Turbolinks) {
          for(var i=0; i < document.styleSheets.length; i++) {
              if(document.styleSheets[i].href)
                  document.styleSheets[i].disabled = true;
          }
          document.addEventListener("page:restore", function restoreCSS(e) {
              for(var i=0; i < document.styleSheets.length; i++) {
                  document.styleSheets[i].disabled = false;
              }
              document.removeEventListener("page:restore", restoreCSS, false);
          });
      }
    </script>
</head>
<body>
    <div class="top">
        <header class="exception">
            <h2><strong>Exception Occurs</strong>[% IF request.request_uri %] <span>at [% request.request_uri %]</span>[% END %]</h2>
            <p>[% message %]</p>
        </header>
    </div>

    <section class="backtrace">
        <nav class="sidebar">
            <nav class="tabs">
                <a href="#" id="application_frames">Application Frames</a>
                <a href="#" id="all_frames">All Frames</a>
            </nav>
            <ul class="frames">
                [% FOREACH frame IN backtrace_frames %]
                    <li class="[% frame.context %]" data-context="[% frame.context %]" data-index="[% loop.index %]">
                        <span class='stroke'></span>
                        <i class="icon [% frame.context %]"></i>
                        <div class="info">
                            <div class="name">
                                [% next_frame = loop.peek_next %]
                                [% IF next_frame AND next_frame.subroutine %]
                                    <strong>[% next_frame.module_name %]</strong><span class='method'>[% next_frame.method_name %]</span>
                                [% END %]
                            </div>
                            <div class="location">
                                <span class="filename">[% frame.filename || '(no file)' %]</span>[% IF frame.line %], line <span class="line">[% frame.line %]</span>[% END %]
                            </div>
                        </div>
                    </li>
                [% END %]
            </ul>
        </nav>

        [% FOREACH frame IN backtrace_frames %]
            <div class="frame_info" id="frame_info_[% loop.index %]" style="display:none;">
                [% frame.info_html | raw %]
            </div>
        [% END %]
    </section>
</body>
<script>
(function() {
    var previousFrame = null;
    var previousFrameInfo = null;
    var allFrames = document.querySelectorAll("ul.frames li");
    var allFrameInfos = document.querySelectorAll(".frame_info");

    function apiCall(method, opts, cb) {
        // TODO: implement it
        return;
        var OID = '';
        var req = new XMLHttpRequest();
        req.open("POST", "/__better_errors/" + OID + "/" + method, true);
        req.setRequestHeader("Content-Type", "application/json");
        req.send(JSON.stringify(opts));
        req.onreadystatechange = function() {
            if(req.readyState == 4) {
                var res = JSON.parse(req.responseText);
                cb(res);
            }
        };
    }

    function escapeHTML(html) {
        return html.replace(/&/, "&amp;").replace(/</g, "&lt;");
    }

    function REPL(index) {
        this.index = index;

        this.previousCommands = [];
        this.previousCommandOffset = 0;
    }

    REPL.all = [];

    REPL.prototype.install = function(containerElement) {
        this.container = containerElement;

        this.promptElement  = this.container.querySelector(".prompt span");
        this.inputElement   = this.container.querySelector("input");
        this.outputElement  = this.container.querySelector("pre");

        this.inputElement.onkeydown = this.onKeyDown.bind(this);

        this.setPrompt(">>");

        REPL.all[this.index] = this;
    }

    REPL.prototype.focus = function() {
        this.inputElement.focus();
    };

    REPL.prototype.setPrompt = function(prompt) {
        this._prompt = prompt;
        this.promptElement.innerHTML = escapeHTML(prompt);
    };

    REPL.prototype.getInput = function() {
        return this.inputElement.value;
    };

    REPL.prototype.setInput = function(text) {
        this.inputElement.value = text;

        if(this.inputElement.setSelectionRange) {
            // set cursor to end of input
            this.inputElement.setSelectionRange(text.length, text.length);
        }
    };

    REPL.prototype.writeRawOutput = function(output) {
        this.outputElement.innerHTML += output;
        this.outputElement.scrollTop = this.outputElement.scrollHeight;
    };

    REPL.prototype.writeOutput = function(output) {
        this.writeRawOutput(escapeHTML(output));
    };

    REPL.prototype.sendInput = function(line) {
        var self = this;
        apiCall("eval", { "index": this.index, source: line }, function(response) {
            if(response.error) {
                self.writeOutput(response.error + "\n");
            }
            self.writeOutput(self._prompt + " ");
            self.writeRawOutput(response.highlighted_input + "\n");
            self.writeOutput(response.result);
            self.setPrompt(response.prompt);
        });
    };

    REPL.prototype.onEnterKey = function() {
        var text = this.getInput();
        if(text != "" && text !== undefined) {
            this.previousCommandOffset = this.previousCommands.push(text);
        }
        this.setInput("");
        this.sendInput(text);
    };

    REPL.prototype.onNavigateHistory = function(direction) {
        this.previousCommandOffset += direction;

        if(this.previousCommandOffset < 0) {
            this.previousCommandOffset = -1;
            this.setInput("");
            return;
        }

        if(this.previousCommandOffset >= this.previousCommands.length) {
            this.previousCommandOffset = this.previousCommands.length;
            this.setInput("");
            return;
        }

        this.setInput(this.previousCommands[this.previousCommandOffset]);
    };

    REPL.prototype.onKeyDown = function(ev) {
        if(ev.keyCode == 13) {
            this.onEnterKey();
        } else if(ev.keyCode == 38) {
            // the user pressed the up arrow.
            this.onNavigateHistory(-1);
            return false;
        } else if(ev.keyCode == 40) {
            // the user pressed the down arrow.
            this.onNavigateHistory(1);
            return false;
        }
    };

    function switchTo(el) {
        if(previousFrameInfo) previousFrameInfo.style.display = "none";
        previousFrameInfo = el;

        el.style.display = "block";

        var replInput = el.querySelector('.console input');
        if (replInput) replInput.focus();
    }

    function selectFrameInfo(index) {
        var el = allFrameInfos[index];
        if(el) {
            if (el.loaded) {
                return switchTo(el);
            }

            el.loaded = true;

            /*
            var repl = el.querySelector(".repl .console");
            if(repl) {
                new REPL(index).install(repl);
            }
            */

            switchTo(el);
        }
    }

    for(var i = 0; i < allFrames.length; i++) {
        (function(i, el) {
            var el = allFrames[i];
            el.onclick = function() {
                if(previousFrame) {
                    previousFrame.className = "";
                }
                el.className = "selected";
                previousFrame = el;

                selectFrameInfo(el.attributes["data-index"].value);
            };
        })(i);
    }

    // Click the first application frame
    (
      document.querySelector(".frames li.application") ||
      document.querySelector(".frames li")
    ).onclick();

    var applicationFramesButton = document.getElementById("application_frames");
    var allFramesButton = document.getElementById("all_frames");

    applicationFramesButton.onclick = function() {
        allFramesButton.className = "";
        applicationFramesButton.className = "selected";
        for(var i = 0; i < allFrames.length; i++) {
            if(allFrames[i].attributes["data-context"].value == "application") {
                allFrames[i].style.display = "block";
            } else {
                allFrames[i].style.display = "none";
            }
        }
        return false;
    };

    allFramesButton.onclick = function() {
        applicationFramesButton.className = "";
        allFramesButton.className = "selected";
        for(var i = 0; i < allFrames.length; i++) {
            allFrames[i].style.display = "block";
        }
        return false;
    };

    applicationFramesButton.onclick();
})();
</script>
</html>
EOTMPL

sub variables_info_html {
    <<'EOTMPL' }
<header class="trace_info">
    <div class="title">
        <h2 class="name">[% frame.subroutine %]</h2>
        <div class="location"><span class="filename">[% frame.filename %]</span></div>
    </div>

    [% html_formatted_code_block | raw %]

    <!--div class="repl">
        <div class="console">
            <pre></pre>
            <div class="prompt"><span>&gt;&gt;</span> <input/></div>
        </div>
    </div-->
</header>

<!--div class="hint">
    TODO: Live Shell (REPL) is not implemented yet.
</div-->

<div class="variable_info"></div>

[% IF frame.lexicals %]
<div class="sub">
    <h3>Lexicals</h3>
    <div class='inset variables'>
        <table class="var_table">
            [% FOREACH key IN frame.lexicals.keys() %]
                <tr><td class="name">[% key %]</td><td><pre>[% frame.lexicals.$key | dump %]</pre></td></tr>
            [% end %]
        </table>
    </div>
</div>
[% END %]

[% IF args %]
<div class="sub">
    <h3>Args</h3>
    <div class='inset variables'>
        <table class="var_table">
            [% FOREACH arg IN args %]
                <tr><td class="name">$_[[% loop.index %]]</td><td><pre>[% arg | dump %]</pre></td></tr>
            [% end %]
        </table>
    </div>
</div>
[% END %]
EOTMPL

1;
__END__

=encoding utf-8

=head1 NAME

Plack::Middleware::BetterStackTrace - Displays better stack trace when your app dies

=head1 SYNOPSIS

  enable 'BetterStackTrace',
      application_caller_subroutine => 'Amon2::Web::handle_request';

=head1 DESCRIPTION

This middleware catches exceptions (run-time errors) happening in your
application and displays nice stack trace screen. The stack trace is
also stored in the environment as a plaintext and HTML under the key
C<plack.stacktrace.text> and C<plack.stacktrace.html> respectively, so
that middleware futher up the stack can reference it.

You're recommended to use this middleware during the development and
use L<Plack::Middleware::HTTPExceptions> in the deployment mode as a
replacement, so that all the exceptions thrown from your application
still get caught and rendered as a 500 error response, rather than
crashing the web server.

Catching errors in streaming response is not supported.

This module is based on L<Plack::Middleware::StackTrace> and Better Errors for Ruby L<https://github.com/charliesome/better_errors>.

=head1 LICENSE

Perl

Copyright (C) Tasuku SUENAGA a.k.a. gunyarakun.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

HTML/CSS/JavaScript

Copyright (C) 2012 Charlie Somerville

MIT License

=head1 AUTHOR

Tasuku SUENAGA a.k.a. gunyarakun E<lt>tasuku-s-github@titech.acE<gt>

=head1 TODO

- REPL
- JSON response

=head1 SEE ALSO

L<Plack::Middleware::StackTrace> L<Devel::StackTrace::AsHTML> L<Plack::Middleware> L<Plack::Middleware::HTTPExceptions>

=cut
