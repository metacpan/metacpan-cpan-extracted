package Swim::Pod;
use Pegex::Base;
extends 'Swim::Markup';

sub get_separator {
    my ($self, $node) = @_;
    $node = $node->[0] while ref($node) eq 'ARRAY';
    return '' unless ref $node;
    $self->node_is_block($node) ? "\n" : '';
}

sub render_text {
    my ($self, $text) = @_;
    $text =~ s/\n/ /g;
    return $text;
}

sub render_comment {
    my ($self, $node) = @_;
    if ($node !~ /\n/) {
        "=for comment $node\n";
    }
    elsif ($node !~ /\n\n/) {
        "=for comment\n$node\n";
    }
    else {
        "=begin comment\n$node\n=end\n";
    }
}

sub render_para {
    my ($self, $node) = @_;
    my $out = $self->render($node);
    if ($self->option->{'wrap'}) {
        require Text::Autoformat;
        if ($out !~ /^=for /) {
            $out = Text::Autoformat::autoformat(
                $out, {
                    right => 78,
                    # XXX Seems to have a bug where it removes lines after
                    # paragraphs:
                    # ignore => sub { $_ =~ qr!\bhttps?://! },
                }
            );
            # Attempt to repair places where Text::Autoformat cuts http links:
            while (
                $out =~
                    s{\ *\n?(L<http.*)\n([^>]*>)([.,!?:]?)(?:\ *\n?)}
                    {\n$1$2$3\n}g
            ) {};
            while (
                $out =~
                    s{([LC]<[^>]*)\n(\S[^>]*)}
                    {$1$2}g
            ) {};
        }
        chomp $out;
        return $out;
    }
    return "$out\n";
}

sub render_blank { '' }

sub render_title {
    my ($self, $node, $number) = @_;
    my ($name, $abstract) = ref $node ? @$node : (undef, $node);
    my $label = $self->option->{'pod-upper-head'} ? 'NAME' : 'Name';
    $name = $self->render($name);
    if (defined $abstract) {
        $abstract = $self->render($abstract);
        "=head1 $label\n\n$name - $abstract\n";
    }
    else {
        "=head1 $name\n";
    }
}

sub render_head {
    my ($self, $node, $number) = @_;
    my $out = $self->render($node);
    $out = uc($out) if $number eq '1' and $self->option->{'pod-upper-head'};
    "=head$number $out\n";
}

sub render_pref {
    my ($self, $node) = @_;
    my $out = $node;
    chomp $out;
    $out =~ s/^(.)/    $1/gm;
    "$out\n";
}

sub render_bold {
    my ($self, $node) = @_;
    my $out = $self->render($node);
    $self->render_phrase(B => $out);
}

sub render_emph {
    my ($self, $node) = @_;
    my $out = $self->render($node);
    $self->render_phrase(I => $out);
}

sub render_del {
    my ($self, $node) = @_;
    my $out = $self->render($node);
    "--$out--";
}

sub render_under {
    my ($self, $node) = @_;
    my $out = $self->render($node);
    "_${out}_";
}

sub render_code {
    my ($self, $node) = @_;
    my $out = $self->render($node);
    $self->render_phrase(C => $out);
}

sub render_hyper {
    my ($self, $node) = @_;
    my ($link, $text) = @{$node}{qw(link text)};
    (length $text == 0)
    ? $self->render_phrase(L => $link)
    : $self->render_phrase(L => "$text|$link");
}

sub render_link {
    my ($self, $node) = @_;
    my ($link, $text) = @{$node}{qw(link text)};
    $link = $self->custom_link($link)
        if defined $self->meta and
            defined $self->meta->{'pod-custom-link'};
    (length $text == 0)
    ? $self->render_phrase(L => $link)
    : $self->render_phrase(L => "$text|$link");
}

sub custom_link {
    my ($self, $link) = @_;
    my $customs = $self->meta->{'pod-custom-link'};
    ref($customs) =~ 'ARRAY'
        or die "Meta 'pod-custom-array' must be an array of hashes";
    for my $custom (@$customs) {
        my $regex = $custom->{match}
            or die "No 'match' regex for 'pod-custom-link' meta";
        my $format = $custom->{format}
            or die "No 'format' string for 'pod-custom-link' meta";
        my @captures = ($link =~ m/$regex/g) or next;
        return sprintf $format, @captures;
    }
    return $link;
}

sub render_phrase {
    my ($self, $code, $text) = @_;
    ($text !~ /[<>]/) ? "$code<$text>" :
    ($text !~ /(<< | >>)/) ? "$code<< $text >>" :
    ($text !~ /(<<< | >>>)/) ? "$code<<< $text >>>" :
    ($text !~ /(<<<< | >>>>)/) ? "$code<<<< $text >>>>" :
    ($text !~ /(<<<<< | >>>>>)/) ? "$code<<<<< $text >>>>>" :
    $text;
}

sub render_list {
    my ($self, $node) = @_;
    my $out = $self->render($node);
    "=over\n\n$out\n=back\n";
}

sub render_item {
    my ($self, $node) = @_;
    my $item = shift @$node;
    my $out = "=item * " . $self->render($item) . "\n";
    $out .= "\n" . $self->render($node) if @$node;
    $out;
}

sub render_olist {
    my ($self, $node) = @_;
    my $number = $self->{number} ||=[];
    push @$number, 1;
    my $out = $self->render($node);
    pop @$number;
    "=over\n\n$out\n=back\n";
}

sub render_oitem {
    my ($self, $node) = @_;
    my $item = shift @$node;
    my $out = "=item $self->{number}[-1].\n\n" . $self->render($item) . "\n";
    $self->{number}[-1]++;
    $out .= "\n" . $self->render($node) if @$node;
    $out;
}

sub render_data {
    my ($self, $node) = @_;
    my $out = "=over\n\n";
    for my $item (@$node) {
        my ($term, $def, $rest) = @$item;
        $term = $self->render($term);
        $out .= "=item $term\n\n";
        if (length $def) {
            $out .= $self->render($def) . "\n\n";
        }
        if ($rest) {
            $out .= $self->render($rest) . "\n";
        }
    }
    $out . "=back\n";
}

sub render_complete {
    require Swim;
    my ($self, $out) = @_;
    chomp $out;
    <<"..."
=pod

=for comment
DO NOT EDIT. This Pod was generated by Swim v$Swim::VERSION.
See http://github.com/ingydotnet/swim-pm#readme

=encoding utf8

$out

=cut
...
}

sub phrase_func_image {
    my ($self, $args) = @_;
    sprintf qq{=for html\n<p><img src="%s" /></p>\n\n}, $args;
}

1;
