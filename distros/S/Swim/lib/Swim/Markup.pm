package Swim::Markup;
use Pegex::Base;
extends 'Swim::Tree';

has option => {};

sub BUILD {
    $_[0]->{option} ||= {};
}

sub final {
    my ($self, $tree) = @_;
    $self->{stack} = [];
    $self->{bullet} = [];
    my $out = $self->render($tree);
    if ($self->option->{'complete'}) {
        if ($self->can('render_complete')) {
            $out = $self->render_complete($out);
        }
    }
    $out;
}

sub render {
    my ($self, $node) = @_;
    my $out;
    if (not ref $node) {
        $out = $self->render_text($node);
    }
    elsif (ref($node) eq 'HASH') {
        $out = $self->render_node($node);
    }
    else {
        my $separator = $self->get_separator($node);
        $out = join $separator, grep $_, map { $self->render($_) } @$node;
    }
    return $out;
}

sub render_node {
    my ($self, $hash) = @_;
    my ($name, $node) = each %$hash;
    my $number = $name =~ s/(\d)$// ? $1 : 0;
    my $method = "render_$name";
    push @{$self->{stack}}, $name;
    my $out = $self->$method($node, $number);
    pop @{$self->{stack}};
    $out;
}

sub render_pfunc {
    my ($self, $node) = @_;
    if ($node =~ /^([\-\w]+)(?:[\ \:]|\z)((?s:.*)?)$/) {
        my ($name, $args) = ($1, $2);
        my $out = $self->_render_func(phrase => $name, $args);
        return $out if defined $out;
    }
    return "<$node>";
}

sub render_bfunc {
    my ($self, $content) = @_;
    my ($name, $args) = @$content;
    $args = '' unless defined $args;
    my $out = $self->_render_func(block => $name, $args);
    return $out if defined $out;
    if ($args) {
        chomp $args;
        return "<<<$name\n$args\n>>>\n";
    }
    else {
        return "<<<$name>>>\n";
    }
}

sub _render_func {
    my ($self, $type, $name, $args) = @_;
    (my $method = "${type}_func_$name") =~ s/-/_/g;
    (my $plugin = "Swim::Plugin::$name") =~ s/-/::/g;
    while (1) {
        if ($self->can($method)) {
            my $out = $self->$method($args);
            return $out if defined $out;
        }
        last if $plugin eq "Swim::Plugin";
        eval "require $plugin";
        $plugin =~ s/(.*)::.*/$1/;
    }
    return;
}

my $phrase_types = {
    map { ($_, 1) } qw(
        code
        bold
        emph
        del
        under
        hyper
        link
        pfunc
        text
    ) };

#------------------------------------------------------------------------------
# Separator controls
#------------------------------------------------------------------------------
use constant default_separator => '';
use constant top_block_separator => '';

sub get_separator {
    my ($self, $node) = @_;
    $self->at_top_level ? $self->top_block_separator : $self->default_separator;
}

sub at_top_level {
    @{$_[0]->{stack}} == 0
}

sub node_is_block {
    my ($self, $node) = @_;
    my ($type) = keys %$node;
    return($phrase_types->{$type} ? 0 : 1);
}

1;
