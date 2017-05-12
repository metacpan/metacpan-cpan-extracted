package Railsish::ViewHelpers;
our $VERSION = '0.21';

use strict;
use warnings;
use Railsish::CoreHelpers;
use HTML::Entities;

use Exporter::Lite;
our @EXPORT = qw(render_stickies stylesheet_link_tag javascript_include_tag link_to);

sub stylesheet_link_tag {
    my (@css) = @_;

    my $out = "";
    for my $css (@css) {
	my $uri;
	if ($css =~ /^http:/) {
	    $uri = $css;
	}
	else {
            $uri = $css;
            $uri .= ".css" if $css !~ /\./;
            $uri = "/stylesheets/$uri" if $css !~ /^\//;
	}

	if ($uri) {
            $out .= qq{<link href="$uri" media="all" rel="stylesheet" type="text/css">\n}
	}
    }
    return $out;
};

sub javascript_include_tag {
    my @sources = @_;
    my $out = "";
    for my $source (@sources) {
        my $uri;
        if ($source =~ /^\w+:\/\//) {
            $uri = $source;
        }
        else {
            $uri = $source;
            $uri .= ".js" if $source !~ /\./;
            $uri = "/javascripts/$uri" if $source !~ /\//;
        }

        $out .= qq{<script type="text/javascript" src="$uri"></script>\n};
    }
    return $out;
}

sub link_to {
    my ($label, $url, @attr) = @_;

    my $attr = "";
    my %attr = ();
    if (@attr == 1 && ref($attr[0]) eq 'HASH') {
        %attr = %{$attr[0]};
    }
    elsif (@attr % 2 == 0) {
        %attr = (@attr);
    }

    if (%attr) {
        my $js;
        if ($attr{method} && $attr{method} eq 'delete') {
            $js = <<JS;
var f = document.createElement('form');
f.style.display = 'none'; this.parentNode.appendChild(f);
f.method = 'POST'; f.action = this.href;
var m = document.createElement('input');
m.setAttribute('type', 'hidden'); m.setAttribute('name', '_method');
m.setAttribute('value', 'delete'); f.appendChild(m);f.submit();
JS
        }

        if (my $confirm = delete $attr{confirm}) {
            $js ||= "return true;";
            $attr{onclick} ||= "";
            $attr{onclick} .= ";if(confirm(\"$confirm\")) { $js }; return false;";
        } elsif ($js) {
            $attr{onclick} ||= "";
            $attr{onclick} .= "$js";
        }

	$attr .= qq{ $_="@{[ encode_entities($attr{$_}, '<>&"') ]}"} for keys %attr;
    }
    qq{<a href="$url"$attr>@{[ encode_entities($label, '<>&') ]}</a>};
}

sub render_stickies {
    my $session = &Railsish::Controller::session;

    return "" unless @{$session->{notice_stickies}||[]} > 0;

    my $out = '<div id="notice_stickies" class="message notice">';
    while(my $stickie = pop @{$session->{notice_stickies}}) {
        $out .= "<p>" . $stickie->{text} . "</p>";
    }
    $out .= "</div>";

    return $out;
}

1;

__END__
=head1 NAME

Railsish::ViewHelpers

=head1 VERSION

version 0.21

=head1 AUTHOR

  Liu Kang-min <gugod@gugod.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Liu Kang-min <gugod@gugod.org>.

This is free software, licensed under:

  The MIT (X11) License

