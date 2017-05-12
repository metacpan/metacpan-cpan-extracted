package Parse::BBCode;
$Parse::BBCode::VERSION = '0.15';
use strict;
use warnings;
use Parse::BBCode::Tag;
use Parse::BBCode::HTML qw/ &defaults &default_escapes &optional /;
use base 'Class::Accessor::Fast';
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(qw/
    tags allowed compiled plain strict_attributes close_open_tags error
    tree escapes direct_attribute params url_finder text_processor linebreaks
    smileys attribute_parser strip_linebreaks attribute_quote /);
#use Data::Dumper;
use Carp;
my $scalar_util = eval "require Scalar::Util; 1";

my %defaults = (
    strict_attributes   => 1,
    direct_attribute    => 1,
    linebreaks          => 1,
    smileys             => 0,
    url_finder          => 0,
    strip_linebreaks    => 1,
    attribute_quote     => '"',
);
sub new {
    my ($class, $args) = @_;
    $args ||= {};
    my %args = %$args;
    unless ($args{tags}) {
        $args{tags} = { $class->defaults };
    }
    else {
        $args{tags} = { %{ $args{tags} } };
    }
    unless ($args{escapes}) {
        $args{escapes} = {$class->default_escapes };
    }
    else {
        $args{escapes} = { %{ $args{escapes} } }
    }
    my $self = $class->SUPER::new({
        %defaults,
        %args
    });
    $self->set_allowed([ grep { length } keys %{ $self->get_tags } ]);
    $self->_compile_tags;
    return $self;
}

my $re_split = qr{ % (?:\{ (?:[a-zA-Z\|]+) \})? (?:attr|[Aas]) }x;
my $re_cmp = qr{ % (?:\{ ([a-zA-Z\|]+) \})? (attr|[Aas]) }x;

sub forbid {
    my ($self, @tags) = @_;
    my $allowed = $self->get_allowed;
    my $re = join '|', map { quotemeta } @tags;
    @$allowed = grep { ! m/^(?:$re)\z/ } @$allowed;
}

sub permit {
    my ($self, @tags) = @_;
    my $allowed = $self->get_allowed;
    my %seen;
    @$allowed = grep {
        !$seen{$_}++ && $self->get_tags->{$_};
    } (@$allowed, @tags);
}

sub _compile_tags {
    my ($self) = @_;
#    unless ($self->get_compiled) {
    {
        my $defs = $self->get_tags;

        # get definition for how text should be rendered which is not in tags
        my $plain;
        if (exists $defs->{""}) {
            $plain = delete $defs->{""};
            if (ref $plain eq 'CODE') {
                $self->set_plain($plain);
            }
        }
        else {
            my $url_finder = $self->get_url_finder;
            my $linebreaks = $self->get_linebreaks;
            my $smileys = $self->get_smileys;
            if ($url_finder) {
                my $result = eval { require URI::Find; 1 };
                unless ($result) {
                    undef $url_finder;
                }
            }
            my $escape = \&Parse::BBCode::escape_html;
            my $post_processor_1 = $escape;
            my $post_processor;
            my $text_processor = $self->get_text_processor;
            if ($text_processor) {
                $post_processor_1 = $text_processor;
            }
            if ($smileys and ref($smileys->{icons}) eq 'HASH') {
                $smileys = {
                    icons => $smileys->{icons},
                    base_url => $smileys->{base_url} || '/smileys/',
                    format => $smileys->{format} || '<img src="%s" alt="%s">',
                };
                my $re = join '|', map { quotemeta $_ } sort { length $b <=> length $a }
                    keys %{ $smileys->{icons} };
                my $code = sub {
                    my ($text, $post_processor) = @_;
                    my $out = '';
                    while ($text =~ s/\A (^|.*?[\s]) ($re) (?=[\s]|$)//xsm) {
                        my ($pre, $emo) = ($1, $2);
                        my $url = "$smileys->{base_url}$smileys->{icons}->{$emo}";
                        my $emo_escaped = Parse::BBCode::escape_html($emo);
                        my $image_tag = sprintf $smileys->{format}, $url, $emo_escaped;
                        $out .= $post_processor_1->($pre) . $image_tag;
                    }
                    $out .= $post_processor_1->($text);
                    return $out;
                };
                $post_processor = $code;
            }
            else {
                $post_processor = $post_processor_1;
            }

            if ($url_finder) {
                my $url_find_sub;
                if (ref($url_finder) eq 'CODE') {
                    $url_find_sub = $url_finder;
                }
                else {
                    unless (ref($url_finder) eq 'HASH') {
                        $url_finder = {
                            max_length => 50,
                            format => '<a href="%s" rel="nofollow">%s</a>',
                        };
                    }
                    my $max_url = $url_finder->{max_length} || 0;
                    my $format = $url_finder->{format};
                    my $finder = URI::Find->new(sub {
                        my ($url) = @_;
                        my $title = $url;
                        if ($max_url and length($title) > $max_url) {
                            $title = substr($title, 0, $max_url) . "...";
                        }
                        my $escaped = Parse::BBCode::escape_html($url);
                        my $escaped_title = Parse::BBCode::escape_html($title);
                        my $href = sprintf $format, $escaped, $title;
                        return $href;
                    });
                    $url_find_sub = sub {
                        my ($ref_content, $post, $info) = @_;
                        $finder->find($ref_content, sub { $post->($_[0], $info) });
                    };
                }
                $plain = sub {
                    my ($parser, $attr, $content, $info) = @_;
                    unless ($info->{classes}->{url}) {
                        $url_find_sub->(\$content, $post_processor, $info);
                    }
                    else {
                        $content = $post_processor->($content);
                    }
                    $content =~ s/\r?\n|\r/<br>\n/g if $linebreaks;
                    $content;
                };
            }
            else {
                $plain = sub {
                    my ($parser, $attr, $content, $info) = @_;
                    my $text = $post_processor->($content, $info);
                    $text =~ s/\r?\n|\r/<br>\n/g if $linebreaks;
                    $text;
                };
            }
            $self->set_plain($plain);
        }

        # now compile the rest of definitions
        for my $key (keys %$defs) {
            my $def = $defs->{$key};
            #warn __PACKAGE__.':'.__LINE__.": $key: $def\n";
            if (not ref $def) {
                my $new_def = $self->_compile_def($def);
                $defs->{$key} = $new_def;
            }
            elsif (not exists $def->{code} and exists $def->{output}) {
                my $new_def = $self->_compile_def($def);
                $defs->{$key} = $new_def;
            }
            $defs->{$key}->{class} ||= 'inline';
            $defs->{$key}->{classic} = 1 unless defined $defs->{$key}->{classic};
            $defs->{$key}->{close} = 1 unless defined $defs->{$key}->{close};
        }
        $self->set_compiled(1);
    }
}

sub _compile_def {
    my ($self, $def) = @_;
    my $esc = $self->get_escapes;
    my $parse = 0;
    my $new_def = {};
    my $output = $def;
    my $close = 1;
    my $class = 'inline';
    if (ref $def eq 'HASH') {
        $new_def = { %$def };
        $output = delete $new_def->{output};
        $parse = $new_def->{parse};
        $close = $new_def->{close} if exists $new_def->{close};
        $class = $new_def->{class} if exists $new_def->{class};
    }
    else {
    }
    # we have a string, compile
    #warn __PACKAGE__.':'.__LINE__.": $key => $output\n";
    if ($output =~ s/^(inline|block|url)://) {
        $class = $1;
    }
    my @parts = split m!($re_split)!, $output;
    #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\@parts], ['parts']);
    my @compiled;
    for my $p (@parts) {
        if ($p =~ m/$re_cmp/) {
            my ($escape, $type) = ($1, $2);
            $escape ||= 'parse';
            my @escapes = split /\|/, $escape;
            if (grep { $_ eq 'parse' } @escapes) {
                $parse = 1;
            }
            push @compiled, [\@escapes, $type];
        }
        else {
            push @compiled, $p;
        }
        #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\@compiled], ['compiled']);
    }
    my $code = sub {
        my ($self, $attr, $string, $fallback, $tag) = @_;
        my $out = '';
        for my $c (@compiled) {

            # just text
            unless (ref $c) {
                $out .= $c;
            }
            # tag attribute or content
            else {
                my ($escapes, $type) = @$c;
                my @escapes = @$escapes;
                my $var = '';
                my $attributes = $tag->get_attr;
                if ($type eq 'attr' and @$attributes > 1) {
                    my $name = shift @escapes;
                    for my $item (@$attributes[1 .. $#$attributes]) {
                        if ($item->[0] eq $name) {
                            $var = $item->[1];
                            last;
                        }
                    }
                }
                elsif ($type eq 'a') {
                    $var = $attr;
                }
                elsif ($type eq 'A') {
                    $var = $fallback;
                }
                elsif ($type eq 's') {
                    if (ref $string eq 'SCALAR') {
                        # this text is already finished and escaped
                        $string = $$string;
                    }
                    $var = $string;
                }
                for my $e (@escapes) {
                    my $sub = $esc->{$e};
                    if ($sub) {
                        $var = $sub->($self, $c, $var);
                        unless (defined $var) {
                            # if escape returns undef, we return it unparsed
                            return $tag->get_start
                                . (join '', map {
                                    $self->_render_tree($_);
                                } @{ $tag->get_content })
                                . $tag->get_end;
                        }
                    }
                }
                $out .= $var;
            }
        }
        return $out;
    };
    $new_def->{parse} = $parse;
    $new_def->{code} = $code;
    $new_def->{close} = $close;
    $new_def->{class} = $class;
    return $new_def;
}

sub _render_text {
    my ($self, $tag, $text, $info) = @_;
    #warn __PACKAGE__.':'.__LINE__.": text '$text'\n";
    defined (my $code = $self->get_plain) or return $text;
    return $code->($self, $tag, $text, $info);
}

sub parse {
    my ($self, $text, $params) = @_;
    my $parse_attributes = $self->get_attribute_parser ? $self->get_attribute_parser : $self->can('parse_attributes');
    $self->set_error(undef);
    my $defs = $self->get_tags;
    my $tags = $self->get_allowed || [keys %$defs];
    my @classic_tags = grep { $defs->{$_}->{classic} } @$tags;
    my @short_tags = grep { $defs->{$_}->{short} } @$tags;
    my $re_classic = join '|', map { quotemeta } sort {length $b <=> length $a } @classic_tags;
    #$re_classic = qr/$re_classic/i;
    my $re_short = join '|', map { quotemeta } sort {length $b <=> length $a } @short_tags;
    #$re_short = qr/$re_short/i;
    #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$re], ['re']);
    my @tags;
    my $out = '';
    my @opened;
    my $current_open_re = '';
    my $callback_found_text = sub {
        my ($text) = @_;
        if (@opened) {
            my $o = $opened[-1];
            $o->add_content($text);
        }
        else {
            if (@tags and !ref $tags[-1]) {
                # text tag, concatenate
                $tags[-1] .= $text;
            }
            else {
                push @tags, $text;
            }
        }
        #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\@opened], ['opened']);
    };
    my $callback_found_tag;
    my $in_url = 0;
    $callback_found_tag = sub {
        my ($tag) = @_;
        #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$tag], ['tag']);
        #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\@opened], ['opened']);
        if (@opened) {
            my $o = $opened[-1];
            my $class = $o->get_class;
            #warn __PACKAGE__.':'.__LINE__.": tag $tag\n";
            if (ref $tag and $class =~ m/inline|url/ and $tag->get_class eq 'block') {
                $self->_add_error('block_inline', $tag);
                pop @opened;
                #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$o], ['o']);
                if ($self->get_close_open_tags) {
                    # we close the tag for you
                    $self->_finish_tag($o, '[/' . $o->get_name . ']', 1);
                    $callback_found_tag->($o);
                    $callback_found_tag->($tag);
                }
                else {
                    # nope, no automatic closing, invalidate all
                    # open inline tags before
                    my @red = $o->_reduce;
                    $callback_found_tag->($_) for @red;
                    $callback_found_tag->($tag);
                }
            }
            elsif (ref $tag) {
                my $def = $defs->{lc $tag->get_name};
                my $parse = $def->{parse};
                if ($parse) {
                    $o->add_content($tag);
                }
                else {
                    my $content = $tag->get_content;
                    my $string = '';
                    for my $c (@$content) {
                        if (ref $c) {
                            $string .= $c->raw_text( auto_close => 0 );
                        }
                        else {
                            $string .= $c;
                        }
                    }
                    $tag->set_content([$string]);
                    $o->add_content($tag);
                }
            }
            else {
                $o->add_content($tag);
            }
        }
        elsif (ref $tag) {
            my $def = $defs->{lc $tag->get_name};
            my $parse = $def->{parse};
            if ($parse) {
                push @tags, $tag;
            }
            else {
                my $content = $tag->get_content;
                my $string = '';
                for my $c (@$content) {
                    if (ref $c) {
                        $string .= $c->raw_text( auto_close => 0 );
                    }
                    else {
                        $string .= $c;
                    }
                }
                $tag->set_content([$string]);
                push @tags, $tag;
            }
        }
        else {
            push @tags, $tag;
        }
        $current_open_re = join '|', map {
            quotemeta $_->get_name
        } @opened;

    };
    my @class = 'block';
    while (defined $text and length $text) {
        $in_url = grep { $_->get_class eq 'url' } @opened;
        #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$in_url], ['in_url']);
        #warn __PACKAGE__.':'.__LINE__.": ============= match $text\n";
        my $tag;
        my ($before, $tag1, $tag2, $after);
        if ($re_classic and $re_short) {
            ($before, $tag1, $tag2, $after) = split m{
                (?:
                    \[ ($re_short)   (?=://)
                    |
                    \[ ($re_classic) (?=\b|\]|\=)
                )
            }ix, $text, 2;
        }
        elsif (! $re_classic and $re_short) {
            ($before, $tag1, $after) = split m{
                    \[ ($re_short)   (?=://)
            }ix, $text, 2;
        }
        elsif ($re_classic and !$re_short) {
            ($before, $tag2, $after) = split m{
                    \[ ($re_classic) (?=\b|\]|\=)
            }ix, $text, 2;
        }
        { no warnings;
#            warn __PACKAGE__.':'.__LINE__.": $before, $tag1, $tag2, $after)\n";
        #warn __PACKAGE__.':'.__LINE__.": RE: $current_open_re\n";
        }
        #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\@opened], ['opened']);
        if (length $before) {
            # look if it contains a closing tag
            #warn __PACKAGE__.':'.__LINE__.": BEFORE $before\n";
            while (length $current_open_re and $before =~ s# (.*?) (\[ / ($current_open_re) \]) ##ixs) {
                # found closing tag
                my ($content, $end, $name) = ($1, $2, $3);
                #warn __PACKAGE__.':'.__LINE__.": found closing tag $name!\n";
                my $f;
                # try to find the matching opening tag
                my @not_close;
                while (@opened) {
                    my $try = pop @opened;
                    $current_open_re = join '|', map {
                        quotemeta $_->get_name
                    } @opened;
                    if ($try->get_name eq lc $name) {
                        $f = $try;
                        last;
                    }
                    elsif (!$try->get_close) {
                        $self->_finish_tag($try, '');
                        unshift @not_close, $try;
                    }
                    else {
                        # unbalanced
                        $self->_add_error('unclosed', $try);
                        if ($self->get_close_open_tags) {
                            # close
                            $f = $try;
                            unshift @not_close, $try;
                            if (@opened) {
                                $opened[-1]->add_content('');
                            }
                            $self->_finish_tag($try, '[/'. $try->get_name() .']', 1);
                        }
                        else {
                            # just add unparsed text
                            $callback_found_tag->($_) for $try->_reduce;
                        }
                    }
                }
                if (@not_close) {
                    $not_close[-1]->add_content($content);
                }
                for my $n (@not_close) {
                    $f->add_content($n);
                    #$callback_found_tag->($n);
                }
                # add text before closing tag as content to the current open tag
                if ($f) {
                    unless (@not_close) {
                        #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$f], ['f']);
                        $f->add_content( $content );
                    }
                    # TODO
                    $self->_finish_tag($f, $end);
                    #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$f], ['f']);
                    $callback_found_tag->($f);
                }
            }
#            warn __PACKAGE__." === before='$before' ($tag)\n";
            $callback_found_text->($before);
        }

        if (defined $tag1) {
            $in_url = grep { $_->get_class eq 'url' } @opened;
            # short tag
#            $callback_found_text->($before) if length $before;
            if ($after =~ s{ :// ([^\[]+) \] }{}x) {
                my $content = $1;
                my ($attr, $title) = split /\|/, $content, 2;
                my $tag = $self->new_tag({
                        name    => lc $tag1,
                        attr    => [[$attr]],
                        attr_raw => $attr,
                        content => [(defined $title and length $title) ? $title : ()],
                        start   => "[$tag1://$content]",
                        close   => 0,
                        class   => $defs->{lc $tag1}->{class},
                        single  => $defs->{lc $tag1}->{single},
                        in_url  => $in_url,
                        type    => 'short',
                    });
                if ($in_url and $tag->get_class eq 'url') {
                    $callback_found_text->($tag->get_start);
                }
                else {
                    $callback_found_tag->($tag);
                }
            }
            else {
                $callback_found_text->("[$tag1");
            }
            $text = $after;
            next;
        }
        $tag = $tag2;


        $in_url = grep { $_->get_class eq 'url' } @opened;

        if ($after) {
            # found start of a tag
            #warn __PACKAGE__.':'.__LINE__.": find attribute for $tag\n";
            my ($ok, $attributes, $attr_string, $end) = $self->$parse_attributes(
                text => \$after,
                tag => lc $tag,
            );
            if ($ok) {
                my $attr = $attr_string;
                $attr = '' unless defined $attr;
                #warn __PACKAGE__.':'.__LINE__.": found attribute for $tag: $attr\n";
                my $close = $defs->{lc $tag}->{close};
                my $def = $defs->{lc $tag};
                my $open = $self->new_tag({
                        name    => lc $tag,
                        attr    => $attributes,
                        attr_raw => $attr_string,
                        content => [],
                        start   => "[$tag$attr]",
                        close   => $close,
                        class   => $defs->{lc $tag}->{class},
                        single  => $defs->{lc $tag}->{single},
                        in_url  => $in_url,
                        type    => 'classic',
                    });
                my $success = 1;
                my $nested_url = $in_url && $open->get_class eq 'url';
                {
                    my $last = $opened[-1];
                    if ($last and not $last->get_close and not $close) {
                        $self->_finish_tag($last, '');
                        # tag which should not have closing tag
                        pop @opened;
                        $callback_found_tag->($last);
                    }
                }
                if ($open->get_single && !$nested_url) {
                    $self->_finish_tag($open, '');
                    $callback_found_tag->($open);
                }
                elsif (!$nested_url) {
                    push @opened, $open;
                    my $def = $defs->{lc $tag};
                    #warn __PACKAGE__.':'.__LINE__.": $tag $def\n";
                    my $parse = $def->{parse};
                    if ($parse) {
                        $current_open_re = join '|', map {
                            quotemeta $_->get_name
                        } @opened;
                    }
                    else {
                        #warn __PACKAGE__.':'.__LINE__.": noparse, find content\n";
                        # just search for closing tag
                        if ($after =~ s# (.*?) (\[ / $tag \]) ##ixs) {
                            my $content = $1;
                            my $end = $2;
                            #warn __PACKAGE__.':'.__LINE__.": CONTENT $content\n";
                            my $finished = pop @opened;
                            $finished->set_content([$content]);
                            $self->_finish_tag($finished, $end);
                            $callback_found_tag->($finished);
                        }
                        else {
                            #warn __PACKAGE__.':'.__LINE__.": nope '$after'\n";
                        }
                    }
                }
                else {
                    $callback_found_text->($open->get_start);
                }

            }
            else {
                # unclosed tag
                $callback_found_text->("[$tag$attr_string$end");
            }
        }
        elsif ($tag) {
            #warn __PACKAGE__.':'.__LINE__.": end\n";
            $callback_found_text->("[$tag");
        }
        $text = $after;
        #sleep 1;
        #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\@tags], ['tags']);
    }
#    warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\@opened], ['opened']);
    if ($self->get_close_open_tags) {
        while (my $opened = pop @opened) {
            $self->_add_error('unclosed', $opened);
            $self->_finish_tag($opened, '[/' . $opened->get_name . ']', 1);
            $callback_found_tag->($opened);
        }
    }
    else {
        while (my $opened = shift @opened) {
            my @text = $opened->_reduce;
            push @tags, @text;
        }
    }
    if ($scalar_util) {
        Scalar::Util::weaken($callback_found_tag);
    }
    else {
        # just to make sure no memleak if there's no Scalar::Util
        undef $callback_found_tag;
    }
    #warn __PACKAGE__.':'.__LINE__.": !!!!!!!!!!!! left text: '$text'\n";
    #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\@tags], ['tags']);
    my $tree = $self->new_tag({
        name => '',
        content => [@tags],
        start => '',
        class => 'block',
        attr => [[]],
    });
    $tree->_init_info({});
    return $tree;
}

sub new_tag {
    my $self = shift;
    Parse::BBCode::Tag->new(@_)
}

sub _add_error {
    my ($self, $error, $tag) = @_;
    my $errors = $self->get_error || {};
    push @{ $errors->{$error} }, $tag;
    $self->set_error($errors);
}

sub error {
    my ($self, $type) = @_;
    my $errors = $self->get_error || {};
    if ($type and $errors->{$type}) {
        return $errors->{$type};
    }
    elsif (keys %$errors) {
        return $errors;
    }
    return 0;
}

sub render {
    my ($self, $text, $params) = @_;
    if (@_ < 2) {
        croak ("Missing input - Usage: \$parser->render(\$text)");
    }
    #warn __PACKAGE__.':'.__LINE__.": @_\n";
    #sleep 2;
    my $tree = $self->parse($text, $params);
    my $out = $self->render_tree($tree, $params);
    if ($self->get_error) {
        $self->set_tree($tree);
    }
    return $out;
}

sub render_tree {
    my ($self, $tree, $params) = @_;
    $params ||= {};
    $self->set_params($params);
    my $rendered = $self->_render_tree($tree);
    $self->set_params(undef);
    return $rendered;
}

sub _render_tree {
    my ($self, $tree, $outer, $info) = @_;
    my $out = '';
    $info ||= {
        stack   => [],
        tags    => {},
        classes => {},
    };
    my $defs = $self->get_tags;
    if (ref $tree) {
        my $name = $tree->get_name;
        my %tags = %{ $info->{tags} };
        $tags{$name}++;
        my @stack = @{ $info->{stack} };
        push @stack, $name;
        my %classes = %{ $info->{classes} };
        $classes{ $tree->get_class || '' }++;
        my %info = (
            tags => \%tags,
            stack => [@stack],
            classes => \%classes,
        );
        my $code = $defs->{$name}->{code};
        my $parse = $defs->{$name}->{parse};
        my $attr = $tree->get_attr || [];
        $attr = $attr->[0]->[0];
        my $content = $tree->get_content;
        my $fallback;
        my $string = '';
        if (($tree->get_type || 'classic') eq 'classic') {
            $fallback = (defined $attr and length $attr) ? $attr : $content;
        }
        else {
            $fallback = $attr;
            $string = @$content ? '' : $attr;
        }
        if (ref $fallback) {
            # we have recursive content, we don't want that in
            # an attribute
            $fallback = join '', grep {
                not ref $_
            } @$fallback;
        }
        if ($self->get_strip_linebreaks and ($tree->get_class || '') eq 'block') {
            if (@$content == 1 and not ref $content->[0] and defined $content->[0]) {
                $content->[0] =~ s/^\r?\n//;
                $content->[0] =~ s/\r?\n\z//;
            }
            elsif (@$content > 1) {
                if (not ref $content->[0] and defined $content->[0]) {
                    $content->[0] =~ s/^\r?\n//;
                }
                if (not ref $content->[-1] and defined $content->[-1]) {
                    $content->[-1] =~ s/\r?\n\z//;
                }
            }
        }
        if (not exists $defs->{$name}->{parse} or $parse) {
            for my $c (@$content) {
                $string .= $self->_render_tree($c, $tree, \%info);
            }
        }
        else {
            $string = join '', @$content;
        }
        if ($code) {
            my $o = $code->($self, $attr, \$string, $fallback, $tree, \%info);
            $out .= $o;
        }
        else {
            $out .= $string;
        }
    }
    else {
        #warn __PACKAGE__.':'.__LINE__.": ==== $tree\n";
        $out .= $self->_render_text($outer, $tree, $info);
    }
    return $out;
}


sub escape_html {
    my ($str) = @_;
    return '' unless defined $str;
    $str =~ s/&/&amp;/g;
    $str =~ s/"/&quot;/g;
    $str =~ s/'/&#39;/g;
    $str =~ s/>/&gt;/g;
    $str =~ s/</&lt;/g;
    return $str;
}

sub parse_attributes {
    my ($self, %args) = @_;
    my $text = $args{text};
    my $tagname = $args{tag};
    my $attribute_quote = $self->get_attribute_quote;
    my $attr_string = '';
    my $attributes = [];
    if (
        ($self->get_direct_attribute and $$text =~ s/^(=[^\]]*)?]//)
            or
        ($$text =~ s/^( [^\]]*)?\]//)
    ) {
        my $attr = $1;
        my $end = ']';
        $attr = '' unless defined $attr;
        $attr_string = $attr;
        unless (length $attr) {
            return (1, [], $attr_string, $end);
        }
        if ($self->get_direct_attribute) {
            $attr =~ s/^=//;
        }
        if ($self->get_strict_attributes and not length $attr) {
            return (0, [], $attr_string, $end);
        }
        my @array;
        if (length($attribute_quote) == 1) {
            if ($attr =~ s/^(?:$attribute_quote(.+?)$attribute_quote(?:\s+|$)|(.*?)(?:\s+|$))//) {
                my $val = defined $1 ? $1 : $2;
                push @array, [$val];
            }
            while ($attr =~ s/^([a-zA-Z0-9_]+)=(?:$attribute_quote(.+?)$attribute_quote(?:\s+|$)|(.*?)(?:\s+|$))//) {
                my $name = $1;
                my $val = defined $2 ? $2 : $3;
                push @array, [$name, $val];
            }
        }
        else {
            if ($attr =~ s/^(?:(["'])(.+?)\1|(.*?)(?:\s+|$))//) {
                my $val = defined $2 ? $2 : $3;
                push @array, [$val];
            }
            while ($attr =~ s/^([a-zA-Z0-9_]+)=(?:(["'])(.+?)\2|(.*?)(?:\s+|$))//) {
                my $name = $1;
                my $val = defined $3 ? $3 : $4;
                push @array, [$name, $val];
            }
        }
        if ($self->get_strict_attributes and length $attr and $attr =~ tr/ //c) {
            return (0, [], $attr_string, $end);
        }
        $attributes = [@array];
        return (1, $attributes, $attr_string, $end);
    }
    return (0, $attributes, $attr_string, '');
}

# TODO add callbacks
sub _finish_tag {
    my ($self, $tag, $end, $auto_closed) = @_;
    #warn __PACKAGE__.':'.__LINE__.": _finish_tag(@_)\n";
    #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$tag], ['tag']);
    unless ($tag->get_finished) {
        $tag->set_end($end);
        $tag->set_finished(1);
        $tag->set_auto_closed($auto_closed || 0);
    }
    return 1;
}

__END__

=pod

=head1 NAME

Parse::BBCode - Module to parse BBCode and render it as HTML or text

=head1 SYNOPSIS

Parse::BBCode parses common bbcode like

    [b]bold[/b] [size=10]big[/size]

short tags like

    [foo://test]

and custom bbcode tags.

For the documentation of short tags, see L<"SHORT TAGS">.

To parse a bbcode string, set up a parser with the default HTML defintions
of L<Parse::BBCode::HTML>:

    # render bbcode to HTML
    use Parse::BBCode;
    my $p = Parse::BBCode->new();
    my $code = 'some [b]b code[/b]';
    my $rendered = $p->render($code);

    # parse bbcode, manipulate tree and render
    use Parse::BBCode;
    my $p = Parse::BBCode->new();
    my $code = 'some [b]b code[/b]';
    my $tree = $p->parse($code);
    # do something with $tree
    my $rendered = $p->render_tree($tree);

Or if you want to define your own tags:

    my $p = Parse::BBCode->new({
            tags => {
                # load the default tags
                Parse::BBCode::HTML->defaults,

                # add/override tags
                url => 'url:<a href="%{link}A">%{parse}s</a>',
                i   => '<i>%{parse}s</i>',
                b   => '<b>%{parse}s</b>',
                noparse => '<pre>%{html}s</pre>',
                code => sub {
                    my ($parser, $attr, $content, $attribute_fallback) = @_;
                    if ($attr eq 'perl') {
                        # use some syntax highlighter
                        $content = highlight_perl($content);
                    }
                    else {
                        $content = Parse::BBCode::escape_html($$content);
                    }
                    "<tt>$content</tt>"
                },
                test => 'this is klingon: %{klingon}s',
            },
            escapes => {
                klingon => sub {
                    my ($parser, $tag, $text) = @_;
                    return translate_into_klingon($text);
                },
            },
        }
    );
    my $code = 'some [b]b code[/b]';
    my $parsed = $p->render($code);

=head1 DESCRIPTION

If you set up the Parse::BBCode object without arguments, the default tags
are loaded, and any text outside or inside of parseable tags will go through
a default subroutine which escapes HTML and replaces newlines with <br>
tags. If you need to change this you can set the options 'url_finder',
'text_processor' and 'linebreaks'.

=head2 METHODS

=over 4

=item new

Constructor. Takes a hash reference with options as an argument.

    my $parser = Parse::BBCode->new({
        tags => {
            url => ...,
            i   => ...,
        },
        escapes => {
            link => ...,
        },
        close_open_tags   => 1, # default 0
        strict_attributes => 0, # default 1
        direct_attributes => 1, # default 1
        url_finder        => 1, # default 0
        smileys           => 0, # default 0
        linebreaks        => 1, # default 1
    );

=over 4

=item tags

See L<"TAG DEFINITIONS">

=item escapes

See L<"ESCAPES">

=item url_finder

See L<"URL FINDER">

=item smileys

If you want to replace smileys with an icon:

    my $parser = Parse::BBCode->new({
            smileys => {
                base_url => '/your/url/to/icons/',
                icons => { qw/ :-) smile.png :-( sad.png / },
                # sprintf format:
                # first argument url
                # second argument original text smiley (HTML escaped)
                format => '<img src="%s" alt="%s">',
                # if you need the url and text in a different order
                # see perldoc -f sprintf, e.g.
                # format => '<img alt="%2$s" src="%1$s">',
            },
        });

This subroutine will be applied during the url_finder (or first, if
url_finder is 0), and the rest will get processed by the text
procesor (default escaping html and replacing linebreaks).

Smileys are only replaced if surrounded by whitespace or start/end of line/text.

    [b]bold<hr> :-)[/b] :-(

In this example both smileys will be replaced. The first smiley is at the end
of the text because the text inside [b][/b] is processed on its own.

Open to any suggestions here.

=item linebreaks

The default text processor replaces linebreaks with <br>\n.
If you don't want this, set 'linebreaks' to 0.

=item text_processor

If you need to add any customized text processing (like smiley parsing, for
example), you can pass a subroutine here. Note that this subroutine also
needs to do HTML escaping itself!

See L<"TEXT PROCESSORS">

=item close_open_tags

Default: 0

If set to true (1), it will close open tags at the end or before block tags.

=item strict_attributes

Default: 1

If set to true (1), tags with invalid attributes are left unparsed. If set to
false (0), the attribute for this tags will be empty.

An invalid attribute:

    [foo=bar far boo]...[/foo]

I might add an option to define your own attribute validation. Contact me if
you'd like to have this.

=item direct_attributes

Default: 1

Normal tag syntax is:

  [tag=val1 attr2=val2 ...]

If set to 0, tag syntax is

  [tag attr2=val2 ...]

=item attribute_quote

You can change how the attribute values shuold be quoted.
Default is a double quote (which is still optional):

  my $parser = Parse::BBCode->new(
      attribute_quote => '"',
      ...
  );
  [tag="foo" attr="bar" attr2=baz]...[/tag]

If you set it to single quote:

  my $parser = Parse::BBCode->new(
      attribute_quote => "'",
      ...
  );
  [tag='foo' attr=bar attr2='baz']...[/tag]

You can also set it to both: C<'">. Then both quoting types are
allowed:

  my $parser = Parse::BBCode->new(
      attribute_quote => q/'"/,
      ...
  );
  [tag='foo' attr="bar" attr2=baz]...[/tag]

=item attribute_parser

You can pass a subref that overrides the default attribute parsing.
See L<"ATTRIBUTE PARSING">

=item strip_linebreaks

Default: 1

Strips linebreaks at start/end of block tags

=back

=item render

Input: The text to parse, optional hashref

Returns: the rendered text

    my $rendered = $parser->render($bbcode);

You can pass an optional hashref with information you need inside
of your self-defined rendering subs.
For example if you want to display code in a codebox with a link to
download the code you need the id of the article (in a forum) and the number
of the code tag.

    my $parsed = $parser->render($bbcode, { article_id => 23 });
    # in the rendering sub:
        my ($parser, $attr, $content, $attribute_fallback, $tag, $info) = @_;
        my $article_id = $parser->get_params->{article_id};
        my $code_id = $tag->get_num;
        # write downloadlink like
        # download.pl?article_id=$article_id;code_id=$code_id
        # in front of the displayed code

See examples/code_download.pl for a complete example of how to set up
the rendering and how to extract the code from the tree. If run as a CGI
skript it will give you a dialogue to save the code into a file, including
a reasonable default filename.

=item parse

Input: The text to parse.

Returns: the parsed tree (a L<Parse::BBCode::Tag> object)

    my $tree = $parser->parse($bbcode);

=item render_tree

Input: the parse tree

Returns: The rendered text

    my $parsed = $parser->render_tree($tree);

You can pass an optional hashref, for explanation see L<"render">

=item forbid

    $parser->forbid(qw/ img url /);

Disables the given tags.

=item permit

    $parser->permit(qw/ img url /);

Enables the given tags if they are in the tag definitions.

=item escape_html

Utility to substitute

    <>&"'

with their HTML entities.

    my $escaped = Parse::BBCode::escape_html($text);

=item error

If the given bbcode is invalid (unbalanced or wrongly nested classes),
currently Parse::BBCode::render() will either leave the invalid tags
unparsed, or, if you set the option C<close_open_tags>, try to add closing
tags.
If this happened C<error()> will return the invalid tag(s), otherwise false.
To get the corrected bbcode (if you set C<close_open_tags>) you can get
the tree and return the raw text from it:

    if ($parser->error) {
        my $tree = $parser->get_tree;
        my $corrected = $tree->raw_text;
    }

=item parse_attributes

You can inherit from Parse::BBCode and define your own attribute
parsing. See L<"ATTRIBUTE PARSING">.

=item new_tag

Returns a L<Parse::BBCode::Tag> object.
It just does:
    shift;
    Parse::BBCode::Tag->new(@_);

If you want your own tag class, inherit from Parse::BBCode and
let it return Parse::BBCode::YourTag->new

=back


=head2 TAG DEFINITIONS

Here is an example of all the current definition possibilities:

    my $p = Parse::BBCode->new({
            tags => {
                i   => '<i>%s</i>',
                b   => '<b>%{parse}s</b>',
                size => '<font size="%a">%{parse}s</font>',
                url => 'url:<a href="%{link}A">%{parse}s</a>',
                wikipedia => 'url:<a href="http://wikipedia.../?search=%{uri}A">%{parse}s</a>',
                noparse => '<pre>%{html}s</pre>',
                quote => 'block:<blockquote>%s</blockquote>',
                code => {
                    code => sub {
                        my ($parser, $attr, $content, $attribute_fallback) = @_;
                        if ($attr eq 'perl') {
                            # use some syntax highlighter
                            $content = highlight_perl($$content);
                        }
                        else {
                            $content = Parse::BBCode::escape_html($$content);
                        }
                        "<tt>$content</tt>"
                    },
                    parse => 0,
                    class => 'block',
                },
                hr => {
                    class => 'block',
                    output => '<hr>',
                    single => 1,
                },
            },
        }
    );

The following list explains the above tag definitions:

=over 4

=item C<%s>

    i => '<i>%s</i>'

    [i] italic <html> [/i]
    turns out as
    <i> italic &lt;html&gt; </i>

So C<%s> stands for the tag content. By default, it is parsed itself,
so that you can nest tags.

=item C<%{parse}s>

    b   => '<b>%{parse}s</b>'

    [b] bold <html> [/b]
    turns out as
    <b> bold &lt;html&gt; </b>

C<%{parse}s> is the same as C<%s> because 'parse' is the default.

=item C<%a>

    size => '<font size="%a">%{parse}s</font>'

    [size=7] some big text [/size]
    turns out as
    <font size="7"> some big text </font>

So %a stands for the tag attribute. By default it will be HTML
escaped.

=item url tag, C<%A>, C<%{link}A>

    url => 'url:<a href="%{link}a">%{parse}s</a>'

the first thing you can see is the C<url:> at the beginning - this
defines the url tag as a tag with the class 'url', and urls must not
be nested. So this class definition is mainly there to prevent
generating wrong HTML. if you nest url tags only the outer one will
be parsed.

another thing you can see is how to apply a special escape. The attribute
defined with C<%{link}a> is checked for a valid URL.
C<javascript:> will be filtered.

    [url=/foo.html]a link[/url]
    turns out as
    <a href="/foo.html">a link</a>

Note that a tag like

    [url]http://some.link.example[/url]

will turn out as

    <a href="">http://some.link.example</a>

In the cases where the attribute should be the same as the
content you should use C<%A> instead of C<%a> which takes
the content as the attribute as a fallback. You probably
need this in all url-like tags:

    url => 'url:<a href="%{link}A">%{parse}s</a>',

=item C<%{uri}A>

You might want to define your own urls, e.g. for wikipedia
references:

    wikipedia => 'url:<a href="http://wikipedia/?search=%{uri}A">%{parse}s</a>',

C<%{uri}A> will uri-encode the searched term:

    [wikipedia]Harold & Maude[/wikipedia]
    [wikipedia="Harold & Maude"]a movie[/wikipedia]
    turns out as
    <a href="http://wikipedia/?search=Harold+%26+Maude">Harold &amp; Maude</a>
    <a href="http://wikipedia/?search=Harold+%26+Maude">a movie</a>

=item Don't parse tag content

Sometimes you need to display verbatim bbcode. The simplest
form would be a noparse tag:

    noparse => '<pre>%{html}s</pre>'

    [noparse] [some]unbalanced[/foo] [/noparse]

With this definition the output would be

    <pre> [some]unbalanced[/foo] </pre>

So inside a noparse tag you can write (almost) any invalid bbcode.
The only exception is the noparse tag itself:

    [noparse] [some]unbalanced[/foo] [/noparse] [b]really bold[/b] [/noparse]

Output:

    [some]unbalanced[/foo] <b>really bold</b> [/noparse]

Because the noparse tag ends at the first closing tag, even if you
have an additional opening noparse tag inside.

The C<%{html}s> defines that the content should be HTML escaped.
If you don't want any escaping you can't say C<%s> because the default
is 'parse'. In this case you have to write C<%{noescape}>.

=item Block tags

    quote => 'block:<blockquote>%s</blockquote>',

To force valid html you can add classes to tags. The default
class is 'inline'. To declare it as a block add C<'block:"> to the start
of the string.
Block tags inside of inline tags will either close the outer tag(s) or
leave the outer tag(s) unparsed, depending on the option C<close_open_tags>.

=item Define subroutine for tag

All these definitions might not be enough if you want to define
your own code, for example to add a syntax highlighter.

Here's an example:

    code => {
        code => sub {
            my ($parser, $attr, $content, $attribute_fallback, $tag, $info) = @_;
            if ($attr eq 'perl') {
                # use some syntax highlighter
                $content = highlight_perl($$content);
            }
            else {
                $content = Parse::BBCode::escape_html($$content);
            }
            "<tt>$content</tt>"
        },
        parse => 0,
        class => 'block',
    },

So instead of a string you define a hash reference with a 'code'
key and a sub reference.
The other key is C<parse> which is 0 by default. If it is 0 the
content in the tag won't be parsed, just as in the noparse tag above.
If it is set to 1 you will get the rendered content as an argument to
the subroutine.

The first argument to the subroutine is the Parse::BBCode object itself.
The second argument is the attribute, the third is the already rendered tag
content as a scalar reference and the fourth argument is the attribute
fallback which is set to the content if the attribute is empty. The fourth
argument is just for convenience.
The fifth argument is the tag object (Parse::BBCode::Tag) itself, so if
necessary you can get the original tag content by using:

    my $original = $tag->raw_text;

The sixth argument is an info hash. It contains:

    my $info = {
        tags => $tags,
        stack => $stack,
        classes => $classes,
    };

The variable $tags is a hashref which contains all tag names which are
outside the current tag, with a count. This is convenient if you have
to check if the current processed tag is inside a certain tag and you
want to behave differently, like

    if ($info->{tags}->{special}) {
        # we are somewhere inside [special]...[/special]
    }

The variable $stack contains an array ref with all outer tag names.
So while processing the tag 'i' in

    [quote][quote][b]bold [i]italic[/i][/b][/quote][/quote]

it contains
    [qw/ quote quote b i /]

The variable $classes contains a hashref with all tag classes and their
counts outside of the current processed tag.
For example if you want to process URIs with URI::Find, and you are
already in a tag with the class 'url' then you don't want to use URI::Find
here.

    unless ($info->{classes}->{url}) {
        # not inside of a url class tag ([url], [wikipedia, etc.)
        # parse text for urls with URI::Find
    }

=item Single-Tags

Sometimes you might want single tags like for a horizontal line:

    hr => {
        class => 'block',
        output => '<hr>',
        single => 1,
    },

The hr-Tag is a block tag (should not be inside inline tags),
and it has no closing tag (option C<single>)

    [hr]
    Output:
    <hr>

=back

=head1 ESCAPES

    my $p = Parse::BBCode->new({
        ...
        escapes => {
            link => sub {
            },
        },
    });

You can define or override escapes. Default escapes are html, uri, link, email,
htmlcolor, num.
An escape functions as a validator and filter. For example, the 'link' escape
looks if it got a valid URI (starting with C</> or C<\w+://>) and html-escapes
it. It returns the empty string if the input is invalid.

See L<Parse::BBCode::HTML/default_escapes> for the detailed list of escapes.

=head1 URL FINDER

Usually one wants to also create hyperlinks from any url found in the
bbcode, not only in url tags.
The following code will use L<URI::Find> to search for all types of
urls (unless inside of a url tag itself), create a link in the given
format and html-escape the rest.
If the url is longer than 50 chars, it will cut the link title and append three dots.
If you set max_length to 0, the title won't be cut.

    my $p = Parse::BBCode->new({
            url_finder => {
                max_length  => 50,
                # sprintf format:
                format      => '<a href="%s" rel="nofollow">%s</a>',
            },
            tags => ...
        });

Note: If you use the special tag '' in the tag definitions you will
overwrite the url finder and have to do that yourself.

Alternative:

    my $p = Parse::BBCode->new({
            url_finder => 1,
            ...

This will use the default like shown above (max length 50 chars).

Default is 0.

=head1 ATTRIBUTES

There are two types of tags. The default (option direct_attributes=1):

    [foo=bar a=b c=d]
    [foo="text with space" a=b c=d]

The parsed attribute structure will look like:

    [ ['bar'], ['a' => 'b'], ['c' => 'd'] ]

Another bbcode variant doesn't use direct attributes:

    [foo a=b c=d]

The resulting attribute structure will have an empty first element:

    [ [''], ['a' => 'b'], ['c' => 'd'] ]

=head1 ATTRIBUTE PARSING

If you have bbcode attributes that don't fit into the two standard
syntaxes you can inherit from Parse::BBCode and overwrite the
parse_attributes method, or you can pass an option attribute_parser
contaning a subref.

Example:

    [size=10]big[/size] [foo|bar|boo]footext[/foo] end

The size tag should be parsed normally, the foo tag needs different parsing.

    sub parse_attributes {
        my ($self, %args) = @_;
        # $$text contains '|bar|boo]footext[/foo] end
        my $text = $args{text};
        my $tagname = $args{tag}; # 'foo'
        if ($tagname eq 'foo') {
            # work on $$text
            # result should be something like:
            # $$text should contain 'footext[/foo] end'
            my $valid = 1;
            my @attr = ( [''], [1 => 'bar'], [2 => 'boo'] );
            my $attr_string = '|bar|boo';
            return ($valid, [@attr], $attr_string, ']');
        }
        else {
            return shift->SUPER::parse_attributes(@_);
        }
    }
    my $parser = Parse::BBCode->new({
        ...
        attribute_parser => \&parse_attributes,
    });

If the attributes are not valid, return

    0, [ [''] ], '|bar|boo', ']'

If you don't find a closing square bracket, return:

    0, [ [''] ], '|bar|boo', ''

=head1 TEXT PROCESSORS

If you set url_finder and linebreaks to 1, the default text processor
will work like this:

    my $post_processor = \&sub_for_escaping_HTML;
    $text = code_to_replace_urls($text, $post_processor);
    $text =~ s/\r?\n|\r/<br>\n/g;
    return $text;

It will be applied to text outside of bbcode and inside of parseable
bbcode tags (and not to code tags or other tags with unparsed content).

If you need an additional post processor this usually cannot be done
after the HTML escaping and url finding. So if you write a text processor it
must do the HTML escaping itself.
For example if you want to replace smileys with image tags you cannot simply do:

    $text =~ s/ :-\) /<img src=...>/g;

because then the image tag would be HTML escaped after that.
On the other hand it's usually not possible to do something like
that *after* the HTML escaping since that might introduce text
sequences that look like a smiley (or whatever you want to replace).

So a simple example for a customized text processor would be:

    ...
    url_finder     => 1,
    linebreaks     => 1,
    text_processor => sub {
        # for $info hash description see render() method
        my ($text, $info) = @_;
        my $out = '';
        while ($text =~ s/(.*)( |^)(:\))(?= |$)//mgs) {
            # match a smiley and anything before
            my ($pre, $sp, $smiley) = ($1, $2, $3);
            # escape text and add smiley image tag
            $out .= Parse::BBCode::escape_html($pre) . $sp . '<img src=...>';
        }
        # leftover text
        $out .= Parse::BBCode::escape_html($text);
        return $out;
    },

This will result in:
Replacing urls, applying your text_processor to the rest of the text and
after that replace linebreaks with <br> tags.

If you want to completely define the plain text processor yourself (ignoring
the 'linebreak', 'url_finder', 'smileys' and 'text_processor' options) you define the
special tag with the empty string:

    my $p = Parse::BBCode->new({
        tags => {
            '' => sub {
                my ($parser, $attr, $content, $info) = @_;
                return frobnicate($content);
                # remember to escape HTML!
            },
            ...

=head1 SHORT TAGS

It can be very convenient to have short tags like [foo://id].
This is not really a part of BBCode, but I consider it as quite similar,
so I added it to this module.
For example to link to threads, cpan modules or wikipedia articles:

    [thread://123]
    [thread://123|custom title]
    # can be implemented so that it links to thread 123 in the forum
    # and additionally fetch the thread title.

    [cpan://Module::Foo|some useful module]

    [wikipedia://Harold & Maude]

You can define a short tag by adding the option C<short>. The tag will
work as a classic tag and short tag. If you only want to support the
short version, set the option C<classic> to 0.

    my $p = Parse::BBCode->new({
            tags => {
                Parse::BBCode::HTML->defaults,
                wikipedia => {
                    short   => 1,
                    output  => '<a href="http://wikipedia/?search=%{uri}A">%{parse}s</a>',
                    class   => 'url',
                    classic => 0, # don't support classic [wikipedia]...[/wikipedia]
                },
                thread => {
                    code => sub {
                        my ($parser, $attr, $content, $attribute_fallback) = @_;
                        my $id = $attribute_fallback;
                        if ($id =~ tr/0-9//c) {
                            return '[thread]' . encode_entities($id) . '[/thread]';
                        }
                        my $name;
                        if ($attr) {
                            # custom title will be in $attr
                            # [thread=123]custom title[/thread]
                            # [thread://123|custom title]
                            # already escaped
                            $name = $$content;
                        }
                        return qq{<a href="/thread/$id">$name</a>};
                    },
                    short   => 1,
                    classic => 1, # default is 1
                },
            },
        }
    );




=head1 WHY ANOTHER BBCODE PARSER

I wrote this module because L<HTML::BBCode> is not extendable (or
I didn't see how) and L<BBCode::Parser> seemed good at the first
glance but has some issues, for example it says that the following bbode

    [code] foo [b] [/code]

is invalid, while I think you should be able to write unbalanced code
in code tags.
Also BBCode::Parser dies if you have invalid code or not-permitted tags,
but in a forum you'd rather show a partly parsed text then an error
message.

What I also wanted is an easy syntax to define own tags, ideally - for
simple tags - as plain text, so you can put it in a configuration file.
This allows forum admins to add tags easily. Some forums might want
a tag for linking to perlmonks.org, other forums need other tags.

Another goal was to always output a result and don't die. I might add an
option which lets the parser die with unbalanced code.

=head1 WHY BBCODE?

Some forums and blogs prefer a kind of pseudo HTML for user comments.
The arguments against bbcode is usually: "Why should people learn an
additional markup language if they can just use HTML?" The problem is
that many people don't know HTML.

BBCode is often a bit shorter, for example if you have a code tag
with an attribute that tells the parser what language the content is in.

    [code=perl]...[/code]
    <code language="perl">...</code>

Also, forum HTML is usually not real HTML. It is usually a subset and
sometimes with additional tags.
So in the backend you need to parse it anyway to turn it into real HTML.

BBCode is widely known and used.
Unfortunately though, there is no specification; some forums only allow
attributes in double quotes, some forums implement only one attribute that
can be seperated by spaces, which makes it difficult to parse if you
want to support more than one attribute.

I tried to support the most common syntax (attributes without quotes, in
single or double quotes) and tags.
If you need additional tags it's relatively easy to implement them.
For example in my forum I implemented a [more] tag that hides long
text or code in thread view. Without Javascript you will see the expanded
content when clicking on the single article, or with Javascript the
content will be added inline via Ajax.

=head1 TODO

=over 4

=item BBCode to Textile|Markdown

There is a L<Parse::BBCode::Markdown> module which is only
roughly tested.

=item API

The main syntax is likely to stay, only the API for callbacks
might change. At the moment it is not possible to add callbacks
to the parsing process, only for the rendering phase.

=back

=head1 REQUIREMENTS

perl >= 5.8.0, L<Class::Accessor::Fast>, L<URI::Escape>

=head1 SEE ALSO

L<BBCode::Parser> - a parser which supplies the parsed tree if necessary. Too
strict though for using in forums where people write unbalanced bbcode

L<HTML::BBCode> - simple processor, no parse tree, good enough for processing
usual bbcode with the most common tags

L<HTML::BBReverse> - really simple proccessor, just replaces start and end tags
independently by their HTML aequivalents, so not very useful in many cases

See C<examples/compare.html> for a feature comparison of the
modules and feel free to report mistakes.

See C<examples/bench.pl> for a benchmark of the modules.

=head1 BUGS

Please report bugs at http://rt.cpan.org/NoAuth/Bugs.html?Dist=Parse-BBCode
or https://github.com/perlpunk/Parse-BBCode/issues

=head1 AUTHOR

Tina Mueller

=head1 CREDITS

Thanks to Moritz Lenz for his suggestions about the implementation
and the test cases.

Viacheslav Tikhanovskii

Sascha Kiefer

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Tina Mueller

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself, either Perl version 5.6.1 or, at your option,
any later version of Perl 5 you may have available.

=cut
