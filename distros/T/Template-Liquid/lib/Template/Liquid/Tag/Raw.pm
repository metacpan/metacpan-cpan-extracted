package Template::Liquid::Tag::Raw;
our $VERSION = '1.0.20';
use strict;
use warnings;
require Template::Liquid::Error;
use base 'Template::Liquid::Tag';
sub import { Template::Liquid::register_tag('raw') }

sub new {
    my ($class, $args) = @_;
    raise Template::Liquid::Error {type     => 'Context',
                                   template => $args->{template},
                                   message  => 'Missing template argument',
                                   fatal    => 1
        }
        if !defined $args->{'template'};
    raise Template::Liquid::Error {type     => 'Context',
                                   template => $args->{template},
                                   message  => 'Missing parent argument',
                                   fatal    => 1
        }
        if !defined $args->{'parent'};
    my $s = bless {name     => '?-' . int rand(time),
                   blocks   => [],
                   tag_name => $args->{'tag_name'},
                   template => $args->{'template'},
                   parent   => $args->{'parent'},
                   markup   => $args->{'markup'},
                   end_tag  => 'end' . $args->{'tag_name'}
    }, $class;
    return $s;
}

sub render {
    my ($s) = @_;
    my $var = $s->{'variable_name'};
    my $val = '';
    return _dump_nodes(@{$s->{'nodelist'}});
}

sub _dump_nodes {
    my $ret = '';
    for my $node (@_) {
        my $rendering = ref $node ? $node->{'markup'} : $node;
        $ret .= defined $rendering ? $rendering : '';
        $ret .= _dump_nodes(@{$node->{'nodelist'}})
            if ref $node && $node->{'nodelist'};
        $ret .= ref $node &&
            defined $node->{'markup_2'} ? $node->{'markup_2'} : '';
    }
    return $ret;
}
1;

=pod

=encoding UTF-8

=begin stopwords

Lütke jadedPixel

=end stopwords

=head1 NAME

Template::Liquid::Tag::Raw - General Purpose Content Container

=head1 Synopsis

    {% raw %}
    In Handlebars, {{ this }} will be HTML-escaped, but {{{ that }}} will not.
    {% endraw %}

=head1 Description

C<raw> is a simple tag. Child nodes are rendered as they appear in the
template. Code inside a C<raw> tag is dumped as-is during rendering. So,
this...

    {% raw %}
    {% for article in articles %}
        <div class='post' id='{{ article.id }}'>
            <p class='title'>{{ article.title | capitalize }}</p>
            {% comment %}
                Unless we're viewing a single article, we will truncate
                article.body at 50 words and insert a 'Read more' link.
            {% endcomment %}
            ...
        </div>
    {% endfor %}
    {% endraw %}

...would print...

    {% for article in articles %}
        <div class='post' id='{{ article.id }}'>
            <p class='title'>{{ article.title | capitalize }}</p>
            {% comment %}
                Unless we're viewing a single article, we will truncate
                article.body at 50 words and insert a 'Read more' link.
            {% endcomment %}
            ...
        </div>
    {% endfor %}

=head1 See Also

Liquid for Designers: http://wiki.github.com/tobi/liquid/liquid-for-designers

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

The original Liquid template system was developed by jadedPixel
(http://jadedpixel.com/) and Tobias LÃ¼tke (http://blog.leetsoft.com/).

=head1 License and Legal

Copyright (C) 2012-2022 by Sanko Robinson E<lt>sanko@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify it under
the terms of The Artistic License 2.0.  See the F<LICENSE> file included with
this distribution or http://www.perlfoundation.org/artistic_license_2_0.  For
clarification, see http://www.perlfoundation.org/artistic_2_0_notes.

When separated from the distribution, all original POD documentation is covered
by the Creative Commons Attribution-Share Alike 3.0 License.  See
http://creativecommons.org/licenses/by-sa/3.0/us/legalcode.  For clarification,
see http://creativecommons.org/licenses/by-sa/3.0/us/.

=cut
