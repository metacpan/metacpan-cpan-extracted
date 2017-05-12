use strict; use warnings;
package Swim::Byte;

use base 'Swim::Markup';
# use XXX -with => 'YAML::XS';

sub render_node {
    my ($self, $hash) = @_;
    my ($tag, $node) = each %$hash;
    if ($self->can("render_$tag")) {
        my $method = "render_$tag";
        return $self->$method($node);
    }
    if (not defined $node) {
        "=$tag\n"
    }
    else {
        "+$tag\n" . $self->render($node) . "-$tag\n";
    }
}

sub render_text {
    my ($self, $node) = @_;
    return '' unless length $node;
    $node =~ s/\n/\\n/g;
    " $node\n";
}

sub render_title {
    my ($self, $node) = @_;
    my ($name, $abstract) = ref $node ? @$node : (undef, $node);
    $name = @$name > 1 ? $self->render($name) : $name->[0];
    if (defined $abstract) {
        $abstract = @$abstract > 1 ? $self->render($abstract) : $abstract->[0];
        "+title\n $name\n-title\n+para\n $abstract\n-para\n";
    }
    else {
        "+title\n $name\n-title\n";
    }
}

sub render_hyper {
    my ($self, $node) = @_;
    my ($link, $text) = @{$node}{qw(link text)};
    (length $text == 0)
    ? "=hyper $link\n"
    : "+hyper $link\n $text\n-hyper\n";
}

1;
