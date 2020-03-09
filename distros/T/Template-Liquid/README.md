[![Build Status](https://travis-ci.org/sanko/template-liquid.svg?branch=master)](https://travis-ci.org/sanko/template-liquid) [![MetaCPAN Release](https://badge.fury.io/pl/Template-Liquid.svg)](https://metacpan.org/release/Template-Liquid)
# NAME

Template::Liquid - A Simple, Stateless Template System

# Synopsis

    use Template::Liquid;
    my $template = Template::Liquid->parse(
        '{% for x in (1..3) reversed %}{{ x }}, {% endfor %}{{ some.text }}');
    print $template->render(some => {text => 'Contact!'}); # 3, 2, 1, Contact!

# Description

The original Liquid template engine was crafted for very specific requirements:

- It has to have simple markup and beautiful results.

    Template engines which don't produce good looking results are no fun to use.

- It needs to be non-evaling and secure.

    Liquid templates are made so that users can edit them. You don't want to run
    code on your server which your users wrote.

- It has to be stateless.

    The compile and render steps have to be separate so the expensive parsing and
    compiling can be done once; later on, you can just render it by passing in a
    hash with local variables and objects.

- It needs to be able to style email as well as HTML.

# Getting Started

It's very simple to get started. Templates are built and used in two steps:
Parse and Render.

If you're in a hurry, you could just...

    use Template::Liquid;
    print Template::Liquid->parse('Hi, {{name}}!')->render(name => 'Sanko');

But because Liquid is stateless, you can split that part. Keep reading.

## Parse

    use Template::Liquid;
    my $sol = Template::Liquid->new();    # Create a Template::Liquid object
    $sol->parse('Hi, {{name}}!');         # Parse and compile the template

...or...

    use Template::Liquid;
    my $sol = Template::Liquid->parse('Hi, {{name}}!'); # Obj is auto-created

The `parse` step creates a fully compiled template which can be re-used as
often as you like. You can store it in memory or in a cache for faster
rendering later. Templates are simple, blessed references so you could do...

    use Template::Liquid;
    use Data::Dump qw[pp];
    my $greet = Template::Liquid->parse('Hi, {{name}}!');
    my $dump = pp($greet);

...store `$dump` somewhere (a file, database, etc.) and then eval the
structure later without doing the 'expensive' parsing step again.

## Render

To complete our `$sol` examples from the previous section, rendering a
template is as easy as...

    $sol->render(name => 'Sanko');    # Returns 'Hi, Sanko!'
    $sol->render(name => 'Megatron'); # Returns 'Hi, Megatron!'

All parameters you want Template::Liquid to work with must be passed to the
`render` method. Template::Liquid is a closed ecosystem; it does not know
about your local, instance, global, or environment variables. If your template
requires any of those, you must pass them along:

    use Template::Liquid;
    print Template::Liquid->parse(
                              '@INC: {%for item in inc%}{{item}}, {%endfor%}')
        ->render(inc => \@INC);

# Standard Liquid Tags

[Expanding the list of supported tags](#extending-template-liquid) is easy
but here's the current standard set:

## `comment`

Comment tags are simple blocks that do nothing during the [render](#render)
stage. Use these to temporarily disable blocks of code or to insert
documentation.

    This is a {% comment %} secret {% endcomment %}line of text.

...renders to...

    This is a line of text.

For more, see [Template::Liquid::Tag::Comment](https://metacpan.org/pod/Template%3A%3ALiquid%3A%3ATag%3A%3AComment).

## `raw`

Raw temporarily disables tag processing. This is useful for generating content
(eg, Mustache, Handlebars) which uses conflicting syntax.

    {% raw %}
        In Handlebars, {{ this }} will be HTML-escaped, but {{{ that }}} will not.
    {% endraw %}

...renders to...

    In Handlebars, {{ this }} will be HTML-escaped, but {{{ that }}} will not.

For more, see [Template::Liquid::Tag::Raw](https://metacpan.org/pod/Template%3A%3ALiquid%3A%3ATag%3A%3ARaw).

## `if` / `elseif` / `else`

    {% if post.body contains search_string %}
        <div class="post result" id="p-{{post.id}}">
            <p class="title">{{ post.title }}</p>
            ...
        </div>
    {% endunless %}

For more, see [Template::Liquid::Tag::If](https://metacpan.org/pod/Template%3A%3ALiquid%3A%3ATag%3A%3AIf) and
[Template::Liquid::Condition](https://metacpan.org/pod/Template%3A%3ALiquid%3A%3ACondition). .

## `unless` / `elseif` / `else`

This is sorta the opposite of `if`.

    {% unless some.value == 3 %}
        Well, the value sure ain't three.
    {% elseif some.value > 1 %}
        It's greater than one.
    {% else %}
       Well, is greater than one but not equal to three.
       Psst! It's {{some.value}}.
    {% endunless %}

For more, see [Template::Liquid::Tag::Unless](https://metacpan.org/pod/Template%3A%3ALiquid%3A%3ATag%3A%3AUnless)
and [Template::Liquid::Condition](https://metacpan.org/pod/Template%3A%3ALiquid%3A%3ACondition).

## `case`

If you need more conditions, you can use the case statement:

    {% case condition %}
        {% when 1 %}
            hit 1
        {% when 2 or 3 %}
            hit 2 or 3
        {% else %}
            ... else ...
    {% endcase %}

For more, see [Template::Liquid::Tag::Case](https://metacpan.org/pod/Template%3A%3ALiquid%3A%3ATag%3A%3ACase).

## `cycle`

Often you have to alternate between different colors or similar tasks. Liquid
has built-in support for such operations, using the cycle tag.

    {% cycle 'one', 'two', 'three' %}
    {% cycle 'one', 'two', 'three' %}
    {% cycle 'one', 'two', 'three' %}
    {% cycle 'one', 'two', 'three' %}

...will result in...

    one
    two
    three
    one

If no name is supplied for the cycle group, then it's assumed that multiple
calls with the same parameters are one group.

If you want to have total control over cycle groups, you can optionally specify
the name of the group. This can even be a variable.

    {% cycle 'group 1': 'one', 'two', 'three' %}
    {% cycle 'group 1': 'one', 'two', 'three' %}
    {% cycle 'group 2': 'one', 'two', 'three' %}
    {% cycle 'group 2': 'one', 'two', 'three' %}

...will result in...

    one
    two
    one
    two

For more, see [Template::Liquid::Tag::Cycle](https://metacpan.org/pod/Template%3A%3ALiquid%3A%3ATag%3A%3ACycle).

## `increment`

Creates a new number variable, and increases its value by one every time it is
called. The initial value is `0`.

    {% increment my_counter %}
    {% increment my_counter %}
    {% increment my_counter %}

...would become...

    0
    1
    2

## `decrement`

Creates a new number variable, and decreases its value by one every time it is
called. The initial value is `-1`.

    {% decrement variable %}
    {% decrement variable %}
    {% decrement variable %}

...would become...

    -1
    -2
    -3

For more, see
[Template::Liquid::Tag::Decrement](https://metacpan.org/pod/Template%3A%3ALiquid%3A%3ATag%3A%3ADecrement).

## `for`

Liquid allows for loops over collections:

    {% for item in array %}
        {{ item }}
    {% endfor %}

Please see see [Template::Liquid::Tag::For](https://metacpan.org/pod/Template%3A%3ALiquid%3A%3ATag%3A%3AFor).

## `assign`

You can store data in your own variables, to be used in output or other tags as
desired. The simplest way to create a variable is with the assign tag, which
has a pretty straightforward syntax:

    {% assign name = 'freestyle' %}

    {% for t in collections.tags %}{% if t == name %}
        <p>Freestyle!</p>
    {% endif %}{% endfor %}

Another way of doing this would be to assign true / false values to the
variable:

    {% assign freestyle = false %}

    {% for t in collections.tags %}{% if t == 'freestyle' %}
        {% assign freestyle = true %}
    {% endif %}{% endfor %}

    {% if freestyle %}
        <p>Freestyle!</p>
    {% endif %}

If you want to combine a number of strings into a single string and save it to
a variable, you can do that with the capture tag.

For more, see [Template::Liquid::Tag::Assign](https://metacpan.org/pod/Template%3A%3ALiquid%3A%3ATag%3A%3AAssign).

## `capture`

This tag is a block which "captures" whatever is rendered inside it, then
assigns the captured value to the given variable instead of rendering it to the
screen.

    {% capture attribute_name %}{{ item.title | handleize }}-{{ i }}-color{% endcapture %}

    <label for="{{ attribute_name }}">Color:</label>
    <select name="attributes[{{ attribute_name }}]" id="{{ attribute_name }}">
        <option value="red">Red</option>
        <option value="green">Green</option>
        <option value="blue">Blue</option>
    </select>

For more, see [Template::Liquid::Tag::Capture](https://metacpan.org/pod/Template%3A%3ALiquid%3A%3ATag%3A%3ACapture).

# Standard Liquid Filters

Please see [Template::Liquid::Filters](https://metacpan.org/pod/Template%3A%3ALiquid%3A%3AFilters).

# Whitespace Control

In Liquid, you can include a hyphen in your tag syntax `{{-`, `-}}`, `{%-`,
and `-%}` to strip whitespace from the left or right side of a rendered tag.

See https://shopify.github.io/liquid/basics/whitespace/

# Extending Template::Liquid

Extending the Template::Liquid template engine for your needs is almost too
simple. Keep reading.

## Custom Tags

See the section entitled [Extending Template::Liquid with Custom
Tags](https://metacpan.org/pod/Template%3A%3ALiquid%3A%3ATag#Extending-Template::Liquid-with-Custom-Tags) in
[Template::Liquid::Tag](https://metacpan.org/pod/Template%3A%3ALiquid%3A%3ATag) for more information.

Also check out the examples of [Template::LiquidX::Tag::Dump](https://metacpan.org/pod/Template%3A%3ALiquidX%3A%3ATag%3A%3ADump) and
[Template::LiquidX::Tag::Include](https://metacpan.org/pod/Template%3A%3ALiquidX%3A%3ATag%3A%3AInclude) now on CPAN.

To assist with custom tag creation, Template::Liquid provides several basic tag
types for subclassing and exposes the following methods:

### `Template::Liquid::register_tag( ... )`

This registers a package which must contain (directly or through inheritance)
both a `parse` and `render` method.

    # Register a new tag which Template::Liquid will look for in the calling package
    Template::Liquid::register_tag( 'newtag' );

    # Or simply say...
    Template::Liquid::register_tag( 'newtag' );
    # ...and Template::Liquid will assume the new tag is in the calling package

Pre-existing tags are replaced when new tags are registered with the same name.
You may want to do this to override some functionality.

## Custom Filters

Filters are simple subs called when needed. They are not passed any state data
by design and must return the modified content.

### `Template::Liquid::register_filter( ... )`

This registers a package which Template::Liquid will assume contains one or
more filters.

    # Register a package as a filter
    Template::Liquid::register_filter( 'Template::Solution::Filter::Amalgamut' );

    # Or simply say...
    Template::Liquid::register_filter( );
    # ...and Template::Liquid will assume the filters are in the calling package

# Why should I use Template::Liquid?

- You want to allow your users to edit the appearance of your
application, but don't want them to run insecure code on your server.
- You want to render templates directly from the database.
- You like Smarty-style template engines.
- You need a template engine which does HTML just as well as email.
- You don't like the markup language of your current template engine.
- You wasted three days reinventing this wheel when you could have been
doing something productive like volunteering or catching up on past seasons of
_Doctor Who_.

# Why shouldn't I use Template::Liquid?

- You've found or written a template engine which fills your needs
better than Liquid or Template::Liquid ever could.
- You are uncomfortable with text that you didn't copy and paste
yourself. Everyone knows computers cannot be trusted.

# Template::LiquidX or Solution?

I'd really rather use Solution::{Package} for extentions but Template::LiquidX
really is a better choice.

As I understand it, the original project's name, Liquid, is a reference to the
classical states of matter (the engine itself being stateless). I wanted to use
[solution](http://en.wikipedia.org/wiki/Solution) because it's liquid but with
bits of other stuff floating in it. (Pretend you majored in chemistry instead
of mathematics or computer science.) Liquid tempates will _always_ work with
Template::Liquid but (due to Template::LiquidX's expanded syntax)
Template::LiquidX templates _may not_ be compatible with Liquid or
Template::Liquid.

# Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

The original Liquid template system was developed by
[jadedPixel](http://jadedpixel.com/) and [Tobias
Lütke](http://blog.leetsoft.com/).

# License and Legal

Copyright (C) 2009-2016 by Sanko Robinson <sanko@cpan.org>

This program is free software; you can redistribute it and/or modify it under
the terms of [The Artistic License
2.0](http://www.perlfoundation.org/artistic_license_2_0). See the `LICENSE`
file included with this distribution or [notes on the Artistic License
2.0](http://www.perlfoundation.org/artistic_2_0_notes) for clarification.

When separated from the distribution, all original POD documentation is covered
by the [Creative Commons Attribution-Share Alike 3.0
License](http://creativecommons.org/licenses/by-sa/3.0/us/legalcode). See the
[clarification of the
CCA-SA3.0](http://creativecommons.org/licenses/by-sa/3.0/us/).
