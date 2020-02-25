package Template::Liquid::Tag::Comment;
our $VERSION = '1.0.17';
use strict;
use warnings;
require Template::Liquid::Error;
BEGIN { use base 'Template::Liquid::Tag'; }
sub import { Template::Liquid::register_tag('comment') }

sub new {
    my ($class, $args) = @_;
    raise Template::Liquid::Error {type    => 'Context',
                                   message => 'Missing template argument',
                                   fatal   => 1
        }
        if !defined $args->{'template'};
    raise Template::Liquid::Error {type => 'Context',
                             message => 'Missing parent argument', fatal => 1}
        if !defined $args->{'parent'};
    if ($args->{'attrs'}) {
        raise Template::Liquid::Error {
                       type    => 'Syntax',
                       message => 'Bad argument list in ' . $args->{'markup'},
                       fatal   => 1
        };
    }
    my $s = bless {name     => '#-' . $1,
                   nodelist => [],
                   tag_name => $args->{'tag_name'},
                   end_tag  => 'end' . $args->{'tag_name'},
                   template => $args->{'template'},
                   parent   => $args->{'parent'},
                   markup   => $args->{'markup'}
    }, $class;
    return $s;
}
sub render { }
1;

=pod

=encoding UTF-8

=head1 NAME

Template::Liquid::Tag::Comment - General Purpose Content Eater

=head1 Synopsis

    I love you{% comment %} and your sister {% endcomment %}.

=head1 Description

C<comment> is the simplest tag. Child nodes are not rendered so it effectivly
swallows content.

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

Code inside a C<comment> tag is not executed during rendering. So, this...

    {% assign str = 'Initial value' %}
    {% comment %}
        {% assign str = 'Different value' %}
    {% endcomment %}
    {{ str }}

...would print C<Initial value>.

=head1 See Also

Liquid for Designers: http://wiki.github.com/tobi/liquid/liquid-for-designers

L<Template::Liquid|Template::Liquid/"Create your own filters">'s docs on custom
filter creation

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

The original Liquid template system was developed by jadedPixel
(http://jadedpixel.com/) and Tobias Lütke (http://blog.leetsoft.com/).

=head1 License and Legal

Copyright (C) 2009-2012 by Sanko Robinson E<lt>sanko@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify it under
the terms of The Artistic License 2.0.  See the F<LICENSE> file included with
this distribution or http://www.perlfoundation.org/artistic_license_2_0.  For
clarification, see http://www.perlfoundation.org/artistic_2_0_notes.

When separated from the distribution, all original POD documentation is covered
by the Creative Commons Attribution-Share Alike 3.0 License.  See
http://creativecommons.org/licenses/by-sa/3.0/us/legalcode.  For clarification,
see http://creativecommons.org/licenses/by-sa/3.0/us/.

=cut
