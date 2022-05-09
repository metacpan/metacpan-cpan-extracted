# NAME

Term::hr - define a thematic change in the content of a terminal session

# SYNOPSIS

```perl
    use Term::hr {
      char      => '=',   # character to use
      fg        => 'fg',  # foreground color, fg = default fg color
      bg        => 'bg',  # background color, bg = default bg color
      bold      => 0,     # no bold attribute
      crlf      => 1,     # add a newline to the returned hr
      italic    => 0,     # no italic attribute
      post      => 0,     # post whitespace
      pre       => 0,     # pre whitespace
      reverse   => 0,     # reverse video attribute
      underline => 0,     # underline attribute
      width     => 80,    # total width of the hr
    };

    ...
    print hr();
    ...
```

# DESCRIPTION

![screenshot](/img/hr01.png)

Term::hr exports a single function into the callers namespace, `hr`.
It exposes a feature very similar to the HTML &lt;hr> tag; a simple way
to define a thematic change in content.

It gives you a way to divide output into sections when you or your program
produces a lot of output.

Normally one might want to define the looks of the hr a single time, in the
beginning of a program. That way, every invocation will be styled the same.

You can do that in the same statement as the use statement, as seen above.

There are however many reasons why you might want to setup a bunch of options as
your defaults, and later in your program modify them a bit to suit your needs.

Many different possibilities and combinations is allowed, see below.

# EXAMPLES

```perl
    use Term::hr;
    use Term::Size;

    my $hr = hr(
      {
        char   => '#',
        fg     => 197,
        bg     => 'bg',
        bold   => 1,
        italic => 1,
        width  => ((Term::Size::chars())[0] / 4),
        pre    => 1,
        post   => 1,
        crlf   => 1,
      },
    );

    print $hr;
```

Because the hr above was crafted with provided options at invocation time,
they are temporary. This means that the hr below will have all **module** default
options, except for the character.

```perl
    my $another_hr = hr('_');
    print $another_hr;
```

If you wanted to change the character, but keep all the other options
you crafted, set the options at use-time instead:

```perl
    use Term::hr {
      fg        => 196,  # foreground color, fg = default fg color
      bg        => 220,  # background color, bg = default bg color
    };

    # uses '=' as character
    print hr();

    # use another one
    my $hr = hr('_');
```

Combinations are possible, as well as unicode:

```perl
    use Term::hr {
      fg     => 197,
      bold   => 1,
      italic => 1,
      crlf   => 1,
    };

    print hr();
    print hr({char => '𝄘', italic => 0});
    print hr('𝄘');
    print hr({char => '𝄘', italic => 0, underline => 1,});
    print hr({char => '𝄘', reverse => 1, underline => 1,});

```

```bash

    $ ls; perl -MTerm::hr -E 'say hr({char=>"🌎",width=>15})'; date
```

Create a shell alias:

```bash
    $ alias hr"=perl -MTerm::hr -E 'say hr({fg=>196, char=> q[ ], bold=>1,underline=>1,italic=>1})'"
    $ cat /var/log/Xorg.0.log; hr; ls
```

# Options and attributes

These are options that can be passed to hr as a key-value hash.

## char

The character to use to build up the hr.
Defaults to '='.

## width, size

The total width of the hr, including pre and post.
Defaults to 80.

## fg

Foreground color.
Defaults to your default terminal foreground color.

## bg

Background color.
Defaults to your default terminal background color.

## crlf

If provided with a non-zero value, a newline will be added to the end of the hr.
Defaults to no newline added.

## pre

Amount of whitespace to add before the hr string.
Defaults to zero.

## post

Amount of whitespace to add after the hr string.
Defaults to zero.

## bold

If provided with a non-zero value, bold attribute will be added.
Defaults to zero.

## italic

If provided with a non-zero value, italic attribute will be added.
Defaults to zero.
## underline

If provided with a non-zero value, underline attribute will be added.
Defaults to zero.

## reverse

If provided with a non-zero value, reverse video attribute will be added.
Defaults to zero.

# AUTHOR

    Magnus Woldrich
    CPAN ID: WOLDRICH
    m@japh.se
    http://japh.se
    http://github.com/trapd00r

# COPYRIGHT

Copyright 2022 **THIS APPLICATION**s ["AUTHOR"](#author) and ["CONTRIBUTORS"](#contributors) as listed
above.

# LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
