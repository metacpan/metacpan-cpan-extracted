package Swim::HTML;
use Pegex::Base;
extends 'Swim::Markup';

use HTML::Escape;

use constant top_block_separator => "\n";

my $document_title = '';
my $info = {
    verse => {
        tag => 'p',
        style => 'block',
        transform => 'transform_verse',
        attrs => ' class="verse"',
    },
};

sub render_text {
    my ($self, $text) = @_;
    $text =~ s/\n/ /g;
    escape_html($text);
}

sub render_para {
    my ($self, $node) = @_;
    my $out = $self->render($node);
    chomp $out;
    my $spacer = $out =~ /\n/ ? "\n" : '';
    "<p>$spacer$out$spacer</p>\n";
}

sub render_rule {
    "<hr/>\n";
}

sub render_blank {
    "<br/>\n";
}

sub render_list {
    my ($self, $node) = @_;
    my $out = $self->render($node);
    chomp $out;
    "<ul>\n$out\n</ul>\n";
}

sub render_item {
    my ($self, $node) = @_;
    my $out = $self->render($node);
    $out =~ s/(.)(<(?:ul|pre|p)(?: |>))/$1\n$2/;
    my $spacer = $out =~ /\n/ ? "\n" : '';
    "<li>$out$spacer</li>\n";
}

sub render_olist {
    my ($self, $node) = @_;
    my $out = $self->render($node);
    chomp $out;
    "<ol>\n$out\n</ol>\n";
}

sub render_oitem {
    my ($self, $node) = @_;
    $self->render_item($node);
}

sub render_data {
    my ($self, $node) = @_;
    my $out = "<dl>\n";
    for my $item (@$node) {
        my ($term, $def, $rest) = @$item;
        $term = $self->render($term);
        $out .= "<dt>$term</dt>\n";
        if (length $def or $rest) {
            $out .= "<dd>";
            if (length $def) {
                $out .= $self->render($def) . "\n";
            }
            if ($rest) {
                $out .= $self->render($rest) . "\n";
            }
            $out .= "<dd>\n";
        }
    }
    $out . "</dl>\n";
}

sub render_pref {
    my ($self, $node) = @_;
    my $out = escape_html($node);
    "<pre><code>$out\n</code></pre>\n";
}

sub render_pfunc {
    my ($self, $node) = @_;
    if ($node =~ /^(\w[\-\w]*) ?((?s:.*)?)$/) {
        my ($name, $args) = ($1, $2);
        $name =~ s/-/_/g;
        my $method = "phrase_func_$name";
        if ($self->can($method)) {
            my $out = $self->$method($args);
            return $out if defined $out;
        }
    }
    "&lt;$node&gt;";
}

sub render_title {
    my ($self, $node) = @_;
    my ($name, $abstract) = ref $node ? @$node : (undef, $node);

    $name = $self->render($name);
    if (defined $abstract) {
        $abstract = $self->render($abstract);
        $document_title = "$name - $abstract";
        "<h1 class=\"title\">$name</h1>\n\n<p>$abstract</p>\n";
    }
    else {
        $document_title = "$name";
        my $spacer = $name =~ /\n/ ? "\n" : '';
        "<h1 class=\"title\">$spacer$name$spacer</h1>\n";
    }
}

sub render_head {
    my ($self, $node, $number) = @_;
    my $out = $self->render($node);
    chomp $out;
    "<h$number>$out</h$number>\n";
}

sub render_comment {
    my ($self, $node) = @_;
    my $out = escape_html($node);
    if ($out =~ /\n/) {
        "<!--\n$out\n-->\n";
    }
    else {
        "<!-- $out -->\n";
    }
}

sub render_code {
    my ($self, $node) = @_;
    my $out = $self->render($node);
    "<code>$out</code>";
}

sub render_bold {
    my ($self, $node) = @_;
    my $out = $self->render($node);
    "<strong>$out</strong>";
}

sub render_emph {
    my ($self, $node) = @_;
    my $out = $self->render($node);
    "<em>$out</em>";
}

sub render_del {
    my ($self, $node) = @_;
    my $out = $self->render($node);
    "<del>$out</del>";
}

sub render_under {
    my ($self, $node) = @_;
    my $out = $self->render($node);
    "<u>$out</u>";
}

sub render_hyper {
    my ($self, $node) = @_;
    my ($link, $text) = @{$node}{qw(link text)};
    $text = $link if not length $text;
    "<a href=\"$link\">$text</a>";
}

sub render_link {
    my ($self, $node) = @_;
    my ($link, $text) = @{$node}{qw(link text)};
    $text = $link if not length $text;

    # XXX Temporary hack for inline grant blog
    # We can solve this in a formal and extensible way later.
    if (defined $ENV{SWIM_LINK_FORMAT_HACK}) {
        $link = "https://metacpan.org/pod/$link";
    }

    "<a href=\"$link\">$text</a>";
}

sub render_complete {
    my ($self, $out) = @_;
    chomp $out;
    <<"..."
<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="content-type" content="text/html;charset=UTF-8" />
  <title>$document_title</title>
  <link href="//swimtext.org/assets/default.css" rel="stylesheet" type="text/css">
</head>
<body>
<div class="swim content">

$out

</div>
</body>
</html>
...
}

#------------------------------------------------------------------------------
sub format_phrase_func_html {
    my ($self, $tag, $class, $attrib, $content) = @_;
    my $attribs = '';
    if (@$class) {
        $attribs = ' class="' . join(' ', @$class) . '"';
    }
    if (@$attrib) {
        $attribs = ' ' . join(' ', map {
            /=".*"$/ ? $_ : do { s/=(.*)/="$1"/; $_ }
        } @$attrib);
    }
    length($content)
    ? "<$tag$attribs>$content</$tag>"
    : "<$tag$attribs/>";
}

sub phrase_func_bold {
    my ($self, $args) = @_;
    my ($success, $class, $attrib, $content) =
        $self->parse_phrase_func_args_html($args);
    return unless $success;
    $self->format_phrase_func_html('strong', $class, $attrib, $content);
}

sub parse_phrase_func_args_html {
    my ($self, $args) = @_;
    my ($class, $attrib, $content) = ([], [], '');
    $args =~ s/^ //;
    if ($args =~ /\A((?:\\:|[^\:])*):((?s:.*))\z/) {
        $attrib = $1;
        $content = $2;
        $attrib =~ s/\\:/:/g;
        ($class, $attrib) = $self->parse_attrib($attrib);
    }
    else {
        $content = $args;
    }
    return 1, $class, $attrib, $content;
}

sub parse_attrib {
    my ($self, $text) = @_;
    my ($class, $attrib) = ([], []);
    while (length $text) {
        if ($text =~ s/^\s*(\w[\w\-]*)(?=\s|\z)\s*//) {
            push @$class, $1;
        }
        elsif ($text =~ s/^\s*(\w[\w\-]*="[^"]*")(?=\s|\z)s*//) {
            push @$attrib, $1;
        }
        elsif ($text =~ s/^\s*(\w[\w\-]*=\S+)(?=\s|\z)s*//) {
            push @$attrib, $1;
        }
        else {
            last;
        }
    }
    return $class, $attrib;
}

1;
