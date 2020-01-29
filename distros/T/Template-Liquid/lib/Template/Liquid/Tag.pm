package Template::Liquid::Tag;
our $VERSION = '1.0.12';
use strict;
use warnings;
use base 'Template::Liquid::Document';
sub tag             { return $_[0]->{'tag_name'}; }
sub end_tag         { return $_[0]->{'end_tag'} || undef; }
sub conditional_tag { return $_[0]->{'conditional_tag'} || undef; }

# Should be overridden by child classes
sub new {
    return
        Template::Liquid::Error->new(
                         {type    => 'Subclass',
                          message => 'Please define a constructor in ' . $_[0]
                         }
        );
}

sub push_block {
    return
        Template::Liquid::Error->new(
         {type => 'Subclass',
          message =>
              'Please define a push_block method (for conditional tags) in ' .
              $_[0]
         }
        );
}
1;

=pod

=encoding UTF-8

=head1 NAME

Template::Liquid::Tag - Documentation for Template::Liquid's Standard Tagsets

=head1 Description

Tags are used for the logic in your L<template|Template::Liquid>. For a list of
standard tags, see the L<Liquid|Template::Liquid/"Standard Tagset">
documentation.

=head1 Extending the Basic Liquid Syntax with Custom Tags

To create a new tag, simply inherit from
L<Template::Liquid::Tag|Template::Liquid::Tag> and register your block
L<globally|Template::Liquid/"Template::Liquid::register_tag( ... )">.

For a complete example of this, keep reading. To see real world examples, check
out L<Template::LiquidX::Tag::Include> and L<Template::LiquidX::Tag::Dump> on
CPAN.

Your constructor should expect the following arguments:

=over 4

=item C<$class>

...you know what to do with this.

=item C<$args>

This is a hash ref which contains these values (at least)

=over 4

=item C<attrs>

The attributes within the tag. For example, given C<{% for x in (1..10)%}>, you
would find C<x in (1..10)> in the C<attrs> value.

=item C<parent>

The direct parent of this new node.

=item C<markup>

The tag as it appears in the template. For example, given C<{% for x in
(1..10)%}>, the full C<markup> would be C<{% for x in (1..10)%}>.

=item C<tag_name>

The name of the current tag. For example, given C<{% for x in (1..10)%}>, the
C<tag_name> would be C<for>.

=item C<template>

A quick link back to the top level template object.

=back

=back

Your object should at least contain the C<parent> and C<template> values handed
to you in C<$args>. For completeness, you should also include a C<name>
(defined any way you want) and the C<$markup> and C<tag_name> from the C<$args>
variable.

Enough jibba jabba... the next few sections show actual code...

=head2

    package Template::LiquidX::Tag::Random;
    use base 'Template::Liquid::Tag';
    sub import { Template::Liquid::register_tag('random') }

    sub new {
        my ($class, $args) = @_;
        $args->{'attrs'} ||= 50;
        my $s = bless {
                          max      => $args->{'attrs'},
                          name     => 'rand-' . $args->{'attrs'},
                          tag_name => $args->{'tag_name'},
                          parent   => $args->{'parent'},
                          template => $args->{'template'},
                          markup   => $args->{'markup'}
        }, $class;
        return $s;
    }

    sub render {
        my ($s) = @_;
        return int rand $s->{template}{context}->get($s->{'max'});
    }
    1;

Using this new tag is as simple as...

    use Template::Liquid;
    use Template::LiquidX::Tag::Random;

    print Template::Liquid->parse('{% random max %}')->render(max => 30);

This will print a random integer between C<0> and C<30>.

=head2 User-defined, Balanced (Block-like) Tags

If you just want a quick sample, you'll find an example C<{^% dump var %}> tag
bundled as a separate dist named C<Template::LiquidX::Tag::Dump> on CPAN.

Block-like tags are very similar to L<simple|Template::Liquid::Tag/"Create Your
Own Tags">. Inherit from L<Template::Liquid::Tag|Template::Liquid::Tag> and
register your block L<globally|Template::Liquid/"register_tag">.

The only difference is you define an C<end_tag> in your object.

Here's an example...

    package Template::LiquidX::Tag::Random;
    use base 'Template::Liquid::Tag';
    sub import { Template::Liquid::register_tag('random') }

    sub new {
        my ($class, $args) = @_;
        raise Template::Liquid::Error {
                   type    => 'Syntax',
                   message => 'Missing argument list in ' . $args->{'markup'},
                   fatal   => 1
            }
            if !defined $args->{'attrs'} || $args->{'attrs'} !~ m[\S$]o;
        my $s = bless {odds     => $args->{'attrs'},
                       name     => 'Rand-' . $args->{'attrs'},
                       tag_name => $args->{'tag_name'},
                       parent   => $args->{'parent'},
                       template => $args->{'template'},
                       markup   => $args->{'markup'},
                       end_tag  => 'end' . $args->{'tag_name'}
        }, $class;
        return $s;
    }

    sub render {
        my $s      = shift;
        my $return = '';
        if (!int rand $s->{template}{context}->get($s->{'odds'})) {
            for my $node (@{$s->{'nodelist'}}) {
                my $rendering = ref $node ? $node->render() : $node;
                $return .= defined $rendering ? $rendering : '';
            }
        }
        $return;
    }
    1;

Using this example tag...

    use Template::Liquid;
    use Template::LiquidX::Tag::Random;

    print Template::Liquid->parse(q[{% random 2 %}Now, that's money well spent!{% endrandom %}])->render();

In this example, we expect a single argument. During the render stage, we
resolve the variable (this allows for constructs like: C<{% random value
%}...>) and depending on a call to C<rand($odds)> the tag either renders to an
empty string or we continue to render the child nodes. Here, our C<random> tag
prints only 50% of the time, C<{% random 1 %}> would work every time.

The biggest changes between this and the L<random tag|Template::Liquid/"Create
Your Own Tags"> we build above are in the constructor.

The extra C<end_tag> attribute in the object's reference lets the parser know
that this is a block that will slurp until the end tag is found. In our
example, we use C<'end' . $args->{'tag_name'}> because you may eventually
subclass this tag and let it inherit this constructor. Now that we're sure the
parser knows what to look for, we go ahead and continue
L<parsing|Template::Liquid/"parse"> the list of tokens. The parser will shove
child nodes (L<tags|Template::Liquid::Tag>,
L<variables|Template::Liquid::Variable>, and simple strings) onto your stack
until the C<end_tag> is found.

In the render step, we must return the stringification of all child nodes
pushed onto the stack by the parser.

=head2 Creating Your Own Conditional Tag Blocks

The internals are still kinda rough around this bit so documenting it is on my
TODO list. If you're a glutton for punishment, I guess you can skim the source
for the L<if tag|Template::Liquid::Tag::If> and its subclass, the L<unless
tag|Template::Liquid::Tag::Unless>.

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
