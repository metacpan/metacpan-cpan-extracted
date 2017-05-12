package Pinwheel::View::Data;

use strict;
use warnings;

use Carp;
use PPI;


sub parse_template
{
    my ($s, $name) = @_;
    my ($pkgname, $vars, $perlvars, $ctxvars);

    $pkgname = $name;
    $pkgname =~ s!\..*!!;
    $pkgname =~ s!(^|/)([^a-zA-Z])!$1_$2!g;
    $pkgname =~ s![^a-z0-9/]+!_!g;
    $pkgname =~ s!/!::!;
    $pkgname = 'Template::' . $pkgname;

    $vars = find_parameters($s);
    # Can't override the $h helpers variable
    delete $vars->{'$h'};
    $vars->{'$dummy'} = 1;
    $vars = [keys %$vars];
    $perlvars = join(', ', @$vars);
    $ctxvars = join(', ', map { "'" . substr($_, 1) . "'" } @$vars);

    eval qq{
        package Pinwheel::View::Data::$pkgname;
        use strict;
        use warnings;
        our \$h;
        *AUTOLOAD = *Pinwheel::View::Data::Builder::AUTOLOAD;
        *TAG = *Pinwheel::View::Data::Builder::TAG;
        sub _render_
        {
            my ($perlvars) = \@_;
#line 1 "$name"
            $s;
        }
    };
    croak $@ if $@;

    return eval qq{
        sub {
            my (\$locals, \$globals, \$fn) = \@_;
            my (\$vars, \@values);

            \$vars = \{dummy => undef, \%\$globals, \%\$locals\};
            foreach (($ctxvars)) \{
                croak("Missing parameter '\$_'") if !exists(\$vars->\{\$_\});
            \}
            \$Pinwheel::View::Data::$pkgname\::h = \$fn;
            \@values = \@\$vars\{($ctxvars)\};
            Pinwheel::View::Data::Wrapper->new(Pinwheel::View::Data::$pkgname\::_render_(\@values));
        }
    };
}

sub find_parameters
{
    my ($s) = @_;
    my ($d, $global, $subs, $declared, $undeclared);

    $d = PPI::Document->new(\$s);
    $global = $d->clone;
    $global->prune('PPI::Statement::Sub');
    $subs = $d->find('PPI::Statement::Sub') || [];

    $undeclared = {};
    $declared = find_undeclared($global, {}, $undeclared);
    find_undeclared($_, $declared, $undeclared) foreach (@$subs);

    return $undeclared;
}

sub find_undeclared
{
    my ($d, $declared, $undeclared) = @_;
    my ($nodes, $n, $var);

    $nodes = $d->find(sub {
        $_[1]->isa('PPI::Token::Symbol') ||
        $_[1]->isa('PPI::Statement::Variable')
    });
    $nodes = [] if !$nodes;

    $declared = {%$declared};
    foreach $n (@$nodes) {
        if ($n->isa('PPI::Statement::Variable')) {
            foreach (@{$n->find('PPI::Token')}) {
                if ($_->isa('PPI::Token::Operator') && $_->content eq '=') {
                    last;
                } elsif ($_->isa('PPI::Token::Symbol')) {
                    $declared->{$_->content} = 1;
                }
            }
        } elsif (!$n->isa('PPI::Token::Magic')) {
            $var = $n->content;
            $undeclared->{$var} = 1 if ($var =~ /^\$/ && !$declared->{$var});
        }
    }

    return $declared;
}

sub _clear_templates
{
    my ($pkg, $dir, $name);

    $pkg = \%::;
    $pkg = $pkg->{'Pinwheel::'}{'View::'}{'Data::'}{'Template::'};
    foreach $dir (keys %$pkg) {
        foreach $name (keys %{$pkg->{$dir}}) {
            foreach (keys %{$pkg->{$dir}{$name}}) {
                delete $pkg->{$dir}{$name}{$_};
            }
            delete $pkg->{$dir}{$name};
        }
        delete $pkg->{$dir};
    }
}



package Pinwheel::View::Data::Builder;

use strict;
use warnings;

our $AUTOLOAD;

my @stack;


sub AUTOLOAD
{
    my ($name, $fn);

    $name = $AUTOLOAD;
    $name =~ s/.*://;

    $fn = sub { TAG($name, @_) };

    no strict 'refs';
    *$AUTOLOAD = $fn;
    goto &$fn;
}

sub TAG
{
    my ($name, $content, $attrs, $data);

    $name = shift @_;
    $content = pop @_ if (@_ & 1);
    $attrs = [@_] if @_;

    push @stack, [] if (scalar(@stack) == 0);
    if (ref($content)) {
        push @stack, [];
        &$content;
        $content = pop @stack;
    }
    $data = [$name, $attrs, $content];
    push @{$stack[-1]}, $data;

    return $data;

}



package Pinwheel::View::Data::Wrapper;

use strict;
use warnings;

use Carp;
use Data::Dumper qw();


sub new
{
    my ($class, $raw) = @_;
    return bless({raw => $raw}, $class);
}

sub to_string
{
    my ($self, $format) = @_;

    if ($format =~ /^(xml|atom|rss)$/) {
        return $self->to_xml();
    } elsif ($format eq 'json') {
        return $self->to_json();
    } elsif ($format eq 'yaml') {
        return $self->to_yaml();
    } elsif ($format eq 'html') {
        return $self->to_html();
    } else {
        croak "Unsupported format";
    }
}

sub to_json
{
    my ($self) = @_;

    return '{' . _to_json(@{$self->{raw}}) . '}';
}

sub to_yaml
{
    my ($self) = @_;

    return _to_yaml(@{$self->{raw}}, 0) . "\n";
}

sub to_xml
{
    my ($self) = @_;

    return "<?xml version=\"1.0\"?>\n" . _to_xml(@{$self->{raw}});
}

## JSON with HTML syntax highlighting
sub to_html
{
    my ($self) = @_;

    return "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1//EN\" \"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd\">\n".
           "<html><head>".
           "<style type=\"text/css\">\n".
           "  .code { font-family: monospace; white-space: normal }\n".
           "  .indent { padding-left: 25px }\n".
           "  .key { color: #000; }\n".
           "  .null { color: #F00; }\n".
           "  .literal { color: #00F; }\n".
           "</style>".
           "</head><body>\n".
           "<div class=\"code\">{" .
            _to_html(@{$self->{raw}}) .
            "</div>}</div>\n".
           "</body></html>";
}

sub _to_json
{
    my ($tag, $attrs, $content, $ignore_tag) = @_;
    my ($is_list, $s, $i, $n, @values);

    $tag =~ s/:/\$/;
    $is_list = ($tag =~ s/_$//);
    $s = '"' . $tag . '":' unless $ignore_tag;

    if ($attrs) {
        $n = @$attrs;
        for ($i = 0; $i < $n; $i += 2) {
            push @values, [$attrs->[$i], undef, $attrs->[$i + 1]];
        }
        if (!defined($content)) {
            $content = [];
        } elsif (!ref($content)) {
            $content = [['$t', undef, $content]];
        }
        $content = [@values, @$content];
    }

    if (!defined($content)) {
        $s .= 'null';
    } elsif (ref($content)) {
        $s .= $is_list ? '[' : '{';
        $i = -1;
        foreach (@$content) {
            $s .= ',' if (++$i);
            $s .= _to_json(@$_, $is_list);
        }
        $s .= $is_list ? ']' : '}';
    } elsif ($content =~ /^-?[0-9]+(?:\.[0-9]+)?$/) {
        $s .= $content;
    } else {
        $content = _json_escape($content) if $content =~ /[\\"\x00-\x1f]/;
        $s .= '"' . $content . '"';
    }

    return $s;
}

sub _json_escape
{
    my ($s) = @_;

    $s =~ s/\\/\\\\/g;
    $s =~ s/\n/\\n/g;
    $s =~ s/"/\\"/g;
    return $s unless $s =~ /[\x00-\x1f]/;

    $s =~ s/([\x00-\x1f])/sprintf('\u%04x', ord($1))/ge;
    return $s;
}

sub _to_yaml
{
    my ($tag, $attrs, $content, $depth, $ignore_tag) = @_;
    my ($is_list, $s, $i, $n, @values, $indent);

    $tag =~ s/:/\$/;
    $is_list = ($tag =~ s/_$//);

    if ($attrs) {
        $n = @$attrs;
        for ($i = 0; $i < $n; $i += 2) {
            push @values, [$attrs->[$i], undef, $attrs->[$i + 1]];
        }
        if (!defined($content)) {
            $content = [];
        } elsif (!ref($content)) {
            $content = [['$t', undef, $content]];
        }
        $content = [@values, @$content];
    }

    if (!$ignore_tag) {
        $s = $tag . ':';
        $s .= ' ' unless (ref($content) && @$content > 0);
    }

    if (!defined($content)) {
        $s .= '~';
    } elsif (ref($content) && @$content == 0) {
        $s .= $is_list ? '[]' : '{}';
    } elsif (ref($content)) {
        $depth += 1;
        $indent = "\n" . ('  ' x $depth) . ($is_list ? '- ' : '');
        $i = -1;
        foreach (@$content) {
            $s .= $indent if (++$i || !$ignore_tag);
            $s .= _to_yaml(@$_, $depth, $is_list);
        }
    } elsif ($content =~ /^-?[0-9]+(?:\.[0-9]+)?$/) {
        # Could check /^[\x20-\x22\x24-\x39\x3b-\x7e]+$/ instead, but for
        # visual consistency with JSON just omit quotes from data that looks
        # numeric.
        $s .= $content;
    } elsif ($content =~ /[\x00-\x08\x0a-\x1f"\\\x7f\xe2\xed]/) {
        $s .= '"' . _yaml_escape($content) . '"';
    } else {
        $s .= '"' . $content . '"';
    }

    return $s;
}

sub _yaml_escape
{
    my ($s) = @_;

    $s =~ s/([\\"])/\\$1/g;
    return $s unless $s =~ /[\x00-\x08\x0a-\x1f\x7f\xe2\xed]/;

    $s =~ s/([\x00-\x08\x0a-\x1f\x7f])/sprintf('\x%02x', ord($1))/ge;
    $s =~ s/\xe2\x80([\xa8\xa9])/sprintf('\u20%02x', ord($1) - 128)/ge;
    $s =~ s/\xed([\xa0-\xbf])([\x80-\xbf])/
            sprintf('\ud%03x', ((ord($1) & 63) << 6) | (ord($2) & 63))/ge;
    return $s;
}

sub _to_xml
{
    my ($tag, $attrs, $content) = @_;
    my ($s, $i, $n, $value);

    $tag =~ s/_$//;
    $s = '<' . $tag;

    $n = $attrs ? @$attrs : 0;
    for ($i = 0; $i < $n; $i += 2) {
        $value = $attrs->[$i + 1];
        $value = '' if !defined($value);
        $value = _xml_escape($value) if $value =~ /[&<>'"]/;
        $s .= ' ' . $attrs->[$i] . '="' . $value . '"';
    }

    if (!defined($content)) {
        $s .= '/>';
    } elsif (ref($content)) {
        $s .= '>';
        $s .= _to_xml(@$_) foreach (@$content);
        $s .= '</' . $tag . '>';
    } else {
        $content = _xml_escape($content) if $content =~ /[&<>'"]/;
        $s .= '>' . $content . '</' . $tag . '>';
    }

    return $s;
}

sub _xml_escape
{
    my ($s) = @_;

    $s =~ s/&/&amp;/g;
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;
    $s =~ s/'/&#39;/g;
    $s =~ s/\"/&quot;/g;

    return $s;
}

sub _to_html
{
    my ($tag, $attrs, $content, $ignore_tag) = @_;
    my ($is_list, $s);

    $tag =~ s/:/\$/;
    $is_list = ($tag =~ s/_$//);

    $s = "<div class=\"indent\">";
    $s .= "<span class=\"key\">\"" . $tag . "\"</span>: " unless ($ignore_tag);

    if ($attrs) {
        my $n = @$attrs;
        my @values = ();
        for (my $i = 0; $i < $n; $i += 2) {
            push @values, [$attrs->[$i], undef, $attrs->[$i + 1]];
        }
        if (!defined($content)) {
            $content = [];
        } elsif (!ref($content)) {
            $content = [['$t', undef, $content]];
        }
        $content = [@values, @$content];
    }

    if (!defined($content)) {
        $s .= '<span class="null">null</span>';
    } elsif (ref($content)) {
        my $i = 0;
        $s .= $is_list ? '[' : "{";
        foreach (@$content) {
            $s .= _to_html(@$_, $is_list);
            $s .= "," unless (++$i == @$content);
            $s .= "</div>";
        }
        $s .= $is_list ? ']' : "}";
    } else {
        unless ($content =~ /^-?[0-9]+(?:\.[0-9]+)?$/) {
            $content = _json_escape($content) if $content =~ /[\\"\x00-\x1f]/;
            $content = "\"$content\"";
        }
        $s .= '<span class="literal">' . _html_escape($content) . "</span>";
    }

    return $s;
}

sub _html_escape
{
    my ($s) = @_;
    return $s unless ($s =~ /[&<>'"\x80-\xff]/);
    $s =~ s/&/&amp;/g;
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;
    $s =~ s/'/&#39;/g;
    $s =~ s/\"/&quot;/g;
    $s =~ s/([\xc0-\xef][\x80-\xbf]+)/_make_utf8_entity($1)/ge;
    return $s;
}

sub _make_utf8_entity
{
    my ($i, @bytes) = split(//, shift());
    $i = ord($i) & ((ord($i) < 0xe0) ? 0x1f : 0x0f);
    $i = ($i << 6) + (ord($_) & 0x3f) foreach @bytes;
    return "&#$i;";
}


1;
