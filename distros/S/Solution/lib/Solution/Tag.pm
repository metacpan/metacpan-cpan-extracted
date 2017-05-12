package Solution::Tag;
{
    use strict;
    use warnings;
    our @ISA = qw[Solution::Document];
    our $VERSION = '0.9.1';
    sub tag             { return $_[0]->{'tag_name'}; }
    sub end_tag         { return $_[0]->{'end_tag'} || undef; }
    sub conditional_tag { return $_[0]->{'conditional_tag'} || undef; }

    # Should be overridden by child classes
    sub new {
        return Solution::StandardError->new(
                                   'Please define a constructor in ' . $_[0]);
    }

    sub push_block {
        return Solution::StandardError->(
                'Please define a push_block method (for conditional tags) in '
                    . $_[0]);
    }
}
1;

=pod

=head1 NAME

Solution::Tag - Documentation for Solution's Standard and Custom Tagset

=head1 Description

Tags are used for the logic in your L<template|Solution::Template>. New tags
are very easy to code, so I hope to get many contributions to the standard tag
library after releasing this code.

=head1 Standard Tagset

Expanding the list of supported tags is easy but here's the current standard
set:

=head2 C<comment>

Comment tags are simple blocks that do nothing during the
L<render|Solution::Template/"render"> stage. Use these to temporarily disable
blocks of code or do insert documentation into your source code.

    This is a {% comment %} secret {% endcomment %}line of text.

For more, see L<Solution::Tag::Comment|Solution::Tag::Comment>.

=head2 C<if> / C<elseif> / C<else>

    {% if post.body contains search_string %}
        <div class="post result" id="p-{{post.id}}">
            <p class="title">{{ post.title }}</p>
            ...
        </div>
    {% endunless %}

=head2 C<unless> / C<elseif> / C<else>

This is sorta the opposite of C<if>.

    {% unless some.value == 3 %}
        Well, the value sure ain't three.
    {% elseif some.value > 1 %}
        It's greater than one.
    {% else %}
       Well, is greater than one but not equal to three.
       Psst! It's {{some.value}}.
    {% endunless %}

For more, see L<Solution::Tag::Unless|Solution::Tag::Unless>.

=head2 C<case>

TODO

=head2 C<cycle>

TODO

=head2 C<for>

TODO

=head2 C<assign>

TODO

=head2 C<capture>

TODO

=head2 C<include>

TODO

=head1 Extending Solution with Custom Tags

To create a new tag, simply inherit from L<Solution::Tag|Solution::Tag> and
register your block L<globally|Solution/"Solution->register_tag( ... )"> or
locally with L<Solution::Template|Solution::Template/"register_tag">.

Your constructor should expect the following arguments:

=over 4

=item C<$class>

...you know what to do with this.

=item C<$args>

This is a hash ref which contains these values (at least)

=over 4

=item C<attrs>

The attributes within the tag. For example, given C<{% for x in (1..10)%}>,
you would find C<x in (1..10)> in the C<attrs> value.

=item C<parent>

The direct parent of this new node.

=item C<markup>

The tag as it appears in the template. For example, given
C<{% for x in (1..10)%}>, the full C<markup> would be
C<{% for x in (1..10)%}>.

=item C<tag_name>

The name of the current tag. For example, given C<{% for x in (1..10)%}>, the
C<tag_name> would be C<for>.

=item C<template>

A quick link back to the top level template object.

=back

=back

Your object should at least contain the C<parent> and C<template> values
handed to you in C<$args>. For completeness, you should also include a C<name>
(defined any way you want) and the C<$markup> and C<tag_name> from the
C<$args> variable.

Enough jibba jabba... here's some functioning code...

    package SolutionX::Tag::Random;
    use strict;
    use warnings;
    our @ISA = qw[Solution::Tag];
    Solution->register_tag('random') if $Solution::VERSION;

    sub new {
        my ($class, $args) = @_;
        $args->{'attrs'} ||= 50;
        my $self = bless {
                          max      => $args->{'attrs'},
                          name     => 'rand-' . $args->{'attrs'},
                          tag_name => $args->{'tag_name'},
                          parent   => $args->{'parent'},
                          template => $args->{'template'},
                          markup   => $args->{'markup'}
        }, $class;
        return $self;
    }

    sub render {
        my ($self) = @_;
        return int rand $self->resolve($self->{'max'});
    }
    1;

Using this new tag is as simple as...

    use Solution;
    use SolutionX::Tag::Random;

    print Solution::Template->parse('{% random max %}')->render({max => 30});

This will print a random integer between C<0> and C<30>.

=head2 Creating Your Own Tag Blocks

If you just want a quick sample, see C<examples/custom_tag.pl>. There you'll
find an example C<{^% dump var %}> tag named C<SolutionX::Tag::Dump>.

Block-like tags are very similar to
L<simple|Solution::Tag/"Create Your Own Tags">. Inherit from
L<Solution::Tag|Solution::Tag> and register your block
L<globally|Solution/"register_tag"> or locally with
L<Solution::Template|Solution::Template/"register_tag">.

The only difference is you define an C<end_tag> in your object.

Here's an example...

    package SolutionX::Tag::Large::Hadron::Collider;
    use strict;
    use warnings;
    our @ISA = qw[Solution::Tag];
    Solution->register_tag('lhc') if $Solution::VERSION;

    sub new {
        my ($class, $args) = @_;
        my $self = bless {
                          odds     => $args->{'attrs'},
                          name     => 'LHC-' . $args->{'attrs'},
                          tag_name => $args->{'tag_name'},
                          parent   => $args->{'parent'},
                          template => $args->{'template'},
                          markup   => $args->{'markup'},
                          end_tag  => 'end' . $args->{'tag_name'}
        }, $class;
        return $self;
    }

    sub render {
        my ($self) = @_;
        return if int rand $self->resolve($self->{'odds'});
        return join '', @{$self->{'nodelist'}};
    }
    1;

Using this example tag...

    use Solution;
    use SolutionX::Tag::Large::Hadron::Collider;

    warn Solution::Template->parse(q[{% lhc 2 %}Now, that's money well spent!{% endlhc %}])->render();

Just like the real thing, our C<lhc> tag works only 50% of the time.

The biggest changes between this and the
L<random tag|Solution/"Create Your Own Tags"> we build above are in the
constructor.

The extra C<end_tag> attribute in the object's reference lets the parser know
that this is a block that will slurp until the end tag is found. In our
example, we use C<'end' . $args->{'tag_name'}> because you may eventually
subclass this tag and let it inherit this constructor. Now that we're sure the
parser knows what to look for, we go ahead and continue
L<parsing|Solution::Template/"parse"> the list of tokens. The parser will shove
child nodes (L<tags|Solution::Tag>, L<variables|Solution::Variable>, and
simple strings) onto your stack until the C<end_tag> is found.

In the render step, we must return the stringification of all child nodes
pushed onto the stack by the parser.

=head2 Creating Your Own Conditional Tag Blocks

The internals are still kinda rough around this bit so documenting it is on my
TODO list. If you're a glutton for punishment, I guess you can skim the source
for the L<if tag|Solution::Tag::If> and its subclass, the
L<unless tag|Solution::Tag::Unless>.

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

When separated from the distribution, all original POD documentation is
covered by the Creative Commons Attribution-Share Alike 3.0 License.  See
http://creativecommons.org/licenses/by-sa/3.0/us/legalcode.  For
clarification, see http://creativecommons.org/licenses/by-sa/3.0/us/.

=cut
