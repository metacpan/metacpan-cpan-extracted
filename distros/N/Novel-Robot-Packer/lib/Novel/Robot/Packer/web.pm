package Novel::Robot::Packer::web;
use strict;
use warnings;
use utf8;

use base 'Novel::Robot::Packer';
use Template;

sub suffix {
    'html';
}

sub main {
    my ($self, $book, %opt) = @_;
    mkdir($opt{output});
    $self->process_template_index($book, %opt);
    $self->process_template_chapter($book, $_, %opt) for @{$book->{floor_list}};
    return $opt{output};
}

sub process_template_index {
    my ($self, $book, %opt) = @_;

    $_->{fid}  = sprintf("%04d", $_->{id}) for @{$book->{floor_list}};
    my $n = $#{$book->{floor_list}} + 1 + 1;
    my $m = "%0".(int(log($n)/log(10))+1)."d";
    $_->{tid}  = sprintf($m, $_->{id}) for @{$book->{floor_list}};

    my $toc = qq{<div id="toc"><ul>
    [% FOREACH r IN floor_list %][% IF r.content %]
    <li>[% r.tid %]. <a href="[% r.fid %].html" time="[% r.time %]">[% r.title %]</a></li>
    [% END %][% END %]
    </ul>
    </div>} ;

    my $txt =<<__HTML__;
        <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
        <html>

        <head>
        <title> [% writer %] 《 [% book %] 》</title>
        <meta http-equiv="content-type" content="text/html; charset=utf-8">
        <style type="text/css">
body {
	font-size: medium;
	font-family: Verdana, Arial, Helvetica, sans-serif;
	margin: 1em 8em 1em 8em;
	text-indent: 2em;
	line-height: 145%;
}
#title, .chapter {
	border-bottom: 0.2em solid #ee9b73;
	margin: 0.8em 0.2em 0.8em 0.2em;
	text-indent: 0em;
	font-size: x-large;
    font-weight: bold;
    padding-bottom: 0.25em;
}
#title, ol { line-height: 150%; }
#title { text-align: center; }
        </style>
        </head>

        <body>
        <div id="title"><a href="[% writer_url %]">[% writer %]</a> 《 <a href="[% url %]">[% book %]</a> 》</div>
        $toc
</body>
</html>
__HTML__
    my $tt=Template->new();
    $tt->process(\$txt, $book, "$opt{output}/index.html", { binmode => ':utf8' })  || die $tt->error(), "\n";
}

sub process_template_chapter {
    my ($self, $book, $chap, %opt) = @_;

    $chap->{next_fid}  = sprintf("%04d", $chap->{id}+1);
    $chap->{prev_fid}  = $chap->{id}==1?'index' : sprintf("%04d", $chap->{id}-1);
    $chap->{writer} = $book->{writer};
    $chap->{book} = $book->{book};

    my $txt =<<__HTML__;
        <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
        <html>

        <head>
        <title> [% writer %] 《 [% book %] 》[% title %]</title>
        <meta http-equiv="content-type" content="text/html; charset=utf-8">
        <style type="text/css">
body {
	font-size: medium;
	font-family: Verdana, Arial, Helvetica, sans-serif;
	margin: 1em 8em 1em 8em;
	text-indent: 2em;
	line-height: 145%;
}
#title {
	border-bottom: 0.2em solid #ee9b73;
	margin: 0.8em 0.2em 0.8em 0.2em;
	text-indent: 0em;
	font-size: x-large;
    font-weight: bold;
    padding-bottom: 0.25em;
}

#footer {
	border-top: 0.2em solid #ee9b73;
	margin: 0.8em 0.2em 0.8em 0.2em;
	text-indent: 0em;
    padding-top: 0.25em;
}
#title, ol { line-height: 150%; }
#title { text-align: center; }
.container {right: 0; text-align: center;}

.container .left, .container .center, .container .right { display: inline-block; }

.container .left { float: left; }
.container .center { margin: 0 auto; }
.container .right { float: right; }
.clear { clear: both; }
        </style>
        </head>

        <body>
<div id="title">[% tid %]. <a href="[% url %]">[% title %]</a></div>
<div class="content">[% content %]</div>
<div id="footer" class="container">
     <div class="left">
     <a href="[% prev_fid %].html">上一章</a>
     </div>
     <div class="center">
     <a href="index.html">返回</a>
     </div>
     <div class="right">
     <a href="[% next_fid %].html">下一章</a>
     </div>
</div>
</body>
</html>
__HTML__
    my $tt=Template->new();
    $tt->process(\$txt, $chap, "$opt{output}/$chap->{fid}.html", { binmode => ':utf8' })  || die $tt->error(), "\n";
}

1;
