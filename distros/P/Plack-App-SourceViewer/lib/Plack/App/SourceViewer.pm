package Plack::App::SourceViewer;
use strict;
use warnings;
use parent qw/Plack::Component/;
use Plack::App::File;
use Plack::Util;
use Syntax::Highlight::Engine::Kate;
use Plack::Util::Accessor qw/
    root
    encoding
    content_type
    ext_lang_map
    css
/;

our $VERSION = '0.02';

my %EXT_LANG_MAP = (
    '.pm'   => 'Perl',
    '.pl'   => 'Perl',
    '.psgi' => 'Perl',
    '.t'    => 'Perl',
);

our $DEFAULT_CSS = <<'_CSS_';
body { font-size: 80%; font-family: "Consolas","Bitstream Vera Sans Mono","Courier New",Courier,monospace; }
table { margin: 12px 0 32px 0; border-collapse: collapse; }
td { white-space: nowrap; }
.line-count { text-align: right; padding-right: 8px; }
.alert       { color: #0000ff; }
.basen       { color: #007f00; }
.bstring     { color: #c9a7ff; }
.char        { color: #ff00ff; }
.comment     { color: #7f7f7f; font-style: italic; }
.datatype    { color: #0000ff; }
.decval      { color: #00007f; }
.error       { color: #ff0000; font-weight: bold; font-style: italic; }
.float       { color: #00007f; }
.function    { color: #007f00; }
.istring     { color: #ff0000; }
.keyword     { font-weight: bold; }
//.normal      { color: #0000ff; }
.operator    { color: #eea000; }
.others      { color: #b03060; }
.regionmaker { color: #96b9ff; font-style: italic; }
.reserved    { color: #9b30ff; font-weight: bold; }
.string      { color: #ff0000; }
.variable    { color: #0000ff; font-weight: bold; }
.warning     { color: #0000ff; font-weight: bold; font-style: italic; }
_CSS_

our $SCRIPT = <<'_SCRIPT_';
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js"></script>
<script>
$(function(){
    if ( location.hash.match(/\#L(\d+)$/) ) {
        var line = RegExp.$1;
        highlighter(line);
        window.scrollTo(0, $(window).scrollTop() - 100);
    }
    if ( location.hash.match(/\#L(\d+)\-L(\d+)$/) ) {
        var start = parseInt(RegExp.$1);
        var end   = parseInt(RegExp.$2);
        if (start > end) {
            var tmp = start; start = end; end = tmp;
        }
        for (var i = start; i <= end; i++) {
            highlighter(i);
        }
        window.location.hash = 'L' + start;
        window.scrollTo(0, $(window).scrollTop() - 100);
        window.location.hash = 'L' + start + '-L' + end;
    }
    if ( location.hash.match(/\#L(\d+,[\d\,]+)$/) ) {
        var ft   = RegExp.$1;
        var list = ft.split(',');
        for (var i in list) {
            highlighter(list[i]);
        }
        window.location.hash = 'L' + list.shift();
        window.scrollTo(0, $(window).scrollTop() - 100);
        window.location.hash = 'L' + ft;
    }
    function highlighter(line) {
        if ($('#L'+line).length) {
            $('#L'+line).css('background-color', '#ffffcc');
        }
    }
});
</script>
_SCRIPT_

sub prepare_app {
    my $self = shift;

    $self->ext_lang_map({
        %EXT_LANG_MAP,
        %{$self->ext_lang_map || +{}},
    });

    if (!$self->css) {
        $self->css($DEFAULT_CSS);
    }

    if (!$self->root) {
        $self->root(['.']);
    }
    elsif (ref $self->root ne 'ARRAY') {
        $self->root([$self->root]);
    }
}

sub call {
    my ($self, $env) = @_;

    my $res;

    for my $root (@{ $self->root }) {
        $self->{file}{$root} ||= Plack::App::File->new({
            root         => $root,
            encoding     => $self->encoding,
            content_type => $self->content_type,
        });
        $res = $self->{file}{$root}->call($env);
        if ($res && $res->[0] == 200) {
            $self->_filter_response($env, $res);
            last;
        }
    }

    return $res;
}

sub _filter_response {
    my ($self, $env, $res) = @_;

    my $path  = $env->{PATH_INFO};
    my ($ext) = ($path =~ m!.+(\..+)$!);
    my $length;
    my $body;

    my $body_sub = sub { $body .= Plack::Util::encode_html($_[0]) };
    if ( my $lang = $self->ext_lang_map->{$ext} ) {
        $self->{highlighter}{$lang} ||= $self->_highlighter($lang);
        $body_sub = sub { chomp $_[0]; $body .=  $self->{highlighter}{$lang}->highlightText($_[0]) };
    }

    Plack::Util::foreach($res->[2], $body_sub);
    $body =~ s/\x0D\x0A|\x0D|\x0A/\n/g;

    $res->[2] = [];
    $length += $self->_body($res->[2], <<"_HTML_");
<!DOCTYPE HTML><html>
<head>
<title>@{[Plack::Util::encode_html($path)]}</title>
<meta name="viewport" content="width=device-width, initial-scale=1;">
<style>@{[$self->css]}</style>
</head>
<body>
<table>
_HTML_
    my $line_count = 1;
    for my $line ( split /\n/, $body ) {
        $length += $self->_body(
            $res->[2],
            qq|<tr id="L$line_count"><td class="line-count">$line_count</td><td>$line</td></tr>\n|
        );
        $line_count++;
    }
    $length += $self->_body(
        $res->[2],
        "</table>$SCRIPT</body></html>",
    );

    my $h = Plack::Util::headers($res->[1]);
    $h->set('Content-Type', 'text/html');
    $h->set('Content-Length', $length);
}

sub _body {
    my ($self, $array, $html) = @_;

    push @{$array}, $html;
    return length $html;
}

sub _highlighter {
    my ($self, $language) = @_;

    return Syntax::Highlight::Engine::Kate->new(
        language      => $language,
        substitutions => {
            "<"  => "&lt;",
            ">"  => "&gt;",
            "&"  => "&amp;",
            " "  => "&nbsp;",
            "\t" => "&nbsp;&nbsp;",
        },
        format_table => {
             Alert        => [ qq|<span class="alert">|,       "</span>" ],
             BaseN        => [ qq|<span class="basen">|,       "</span>" ],
             BString      => [ qq|<span class="bstring">|,     "</span>" ],
             Char         => [ qq|<span class="cahr">|,        "</span>" ],
             Comment      => [ qq|<span class="comment"><i>|,  "</span>" ],
             DataType     => [ qq|<span class="datatype">|,    "</span>" ],
             DecVal       => [ qq|<span class="decval">|,      "</span>" ],
             Error        => [ qq|<span class="error">|,       "</span>" ],
             Float        => [ qq|<span class="float">|,       "</span>" ],
             Function     => [ qq|<span class="function">|,    "</span>" ],
             IString      => [ qq|<span class="istring">|,     "</span>" ],
             Keyword      => [ qq|<span class="keyword">|,     "</span>" ],
             Normal       => [ "",                             ""        ],
             Operator     => [ qq|<span class="operator">|,    "</span>" ],
             Others       => [ qq|<span class="others">|,      "</span>" ],
             RegionMarker => [ qq|<span class="regionmaker">|, "</span>" ],
             Reserved     => [ qq|<span class="reserved">|,    "</span>" ],
             String       => [ qq|<span class="string">|,       "</span>"],
             Variable     => [ qq|<span class="variable">|,    "</span>" ],
             Warning      => [ qq|<span class="warning">|,     "</span>" ],
        },
    );
}

1;

__END__

=encoding UTF-8

=head1 NAME

Plack::App::SourceViewer - The Source Code Viewer for Plack


=head1 SYNOPSIS

    use Plack::App::SourceViewer;
    my $app = Plack::App::SourceViewer->new(root => "./lib")->to_app;
 
    # Or map the path to a specific file
    use Plack::Builder;
    builder {
        mount "/source" => Plack::App::SourceViewer->new(root => './lib')->to_app;
        mount "/"       => sub { [200, [], ["OK"]] };
    };

=head1 DESCRIPTION

Plack::App::SourceViewer provides the viewer of source code as HTML.


=head1 METHODS

=head2 prepare_app

=head2 call


=head1 REPOSITORY

=begin html

<a href="http://travis-ci.org/bayashi/Plack-App-SourceViewer"><img src="https://secure.travis-ci.org/bayashi/Plack-App-SourceViewer.png?_t=1457227925"/></a> <a href="https://coveralls.io/r/bayashi/Plack-App-SourceViewer"><img src="https://coveralls.io/repos/bayashi/Plack-App-SourceViewer/badge.png?_t=1457227925&branch=master"/></a>

=end html

Plack::App::SourceViewer is hosted on github: L<http://github.com/bayashi/Plack-App-SourceViewer>

I appreciate any feedback :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<Syntax::Highlight::Engine::Kate>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
