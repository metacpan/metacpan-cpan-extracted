package Novel::Robot::Packer::html;
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
    $self->process_template($book, %opt);
    return $opt{output};
}


sub process_template {
    my ($self, $book, %opt) = @_;

    my $toc = $opt{with_toc} ? qq{<div id="toc"><ul>
    [% FOREACH r IN floor_list %]
    [% IF r.content %] <li>[% r.id %]. <a href="#toc[% r.id %]">[% r.writer %] [% r.title %]</a></li> [% END %] 
    [% END %]
    </ul>
    </div>} : '';

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
<div id="content">
    [% FOREACH r IN floor_list %]
    [% IF r.content %]
<div class="floor">
<div class="chapter">[% r.id %]. <a name="toc[% r.id %]">[% r.writer %] [% r.title %]</a>  [% r.time %]</div>
<div class="content">[% r.content %]</div>
</div>[% END %]
[% END %]
</div>
</body>
</html>
__HTML__
    my $tt=Template->new();
    $tt->process(\$txt, $book, $opt{output}, { binmode => ':utf8' })  || die $tt->error(), "\n";
}

1;
