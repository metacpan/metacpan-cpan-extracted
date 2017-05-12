package Pinwheel::Helpers::Tag;

use strict;
use warnings;

use Exporter;

require Pinwheel::Controller;
use Pinwheel::View::String;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    content_tag
    link_to
    link_to_if
    link_to_unless
    link_to_unless_current
);


sub content_tag
{
    my ($tag, $content, $block, $s, $key, $value);

    $tag = shift(@_);
    if (@_ && ref($_[-1]) eq 'CODE') {
        $block = pop(@_);
        $content = &$block();
        $content =~ s/^\s*(.*?)\s*$/$1/;
        $content = [$content];
    } elsif (@_ & 1) {
        $content = shift(@_);
    }

    $s = [["<$tag"]];
    while (@_ > 1) {
        $key = shift;
        $value = shift;
        if (ref($value) eq 'ARRAY') {
            $value = [grep { defined($_) && length($_) } @$value];
            $value = scalar(@$value) ? join(' ', @$value) : undef;
        }
        next if !defined($value);
        push @$s, [" $key=\""], $value, ['"'];
    }
    if (defined($content)) {
        push @$s, ['>'], $content, ["</$tag>\n"];
    } else {
        push @$s, [" />\n"];
    }
    return Pinwheel::View::String->new($s);
}

sub _link_to_href
{
    my ($route_name, $route_params);
    my ($params) = @_;

    if (scalar(@$params) > 1 and ref(@$params[1]) eq 'HASH') {
        $route_name = shift(@$params);
        $route_params = shift(@$params);
        return Pinwheel::Controller::url_for($route_name, %$route_params);
    } else {
        return shift(@$params);
    }
}

sub link_to
{
    my ($content, $href);

    $content = shift(@_);
    $href = _link_to_href(\@_);

    return content_tag('a', $content, href => $href, @_);
}

sub link_to_if
{
    my ($condition, @params) = @_;
    if ($condition) {
        return link_to(@params);
    } else {
        return $params[0];
    }
}

sub link_to_unless
{
    my ($condition, @params) = @_;
    return link_to_if(!$condition, @params);
}

sub link_to_unless_current
{
    my ($content, $href);

    $content = shift(@_);
    $href = _link_to_href(\@_);

    return link_to_unless((Pinwheel::Controller::url_for() eq $href), $content, $href, @_);
}

1;
