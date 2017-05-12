[![Build Status](https://travis-ci.org/moznion/Pod-Text-Color-Delight.png?branch=master)](https://travis-ci.org/moznion/Pod-Text-Color-Delight)
# NAME

Pod::Text::Color::Delight - Delight Light Highlight the POD

# SYNOPSIS

    use Pod::Text::Color::Delight;

    my $parser = Pod::Text::Color::Delight->new;
    $parser->parse_from_filehandle("/path/to/your.pod");

# DESCRIPTION

Pod::Text::Color::Delight is a subclass of [Pod::Text::Color](https://metacpan.org/pod/Pod::Text::Color) that highlights the pod text by using ANSI color escape.

Highlight of this module is a little radical in comparison with parent. On default setting, this module highlights headlines, links, and other several elements.
Additionally, this module also highlights Perl code (e.g. SYNOPSIS).

And you can configure the color settings for each elements as you like. Please look ["CONFIGURATION AND ENVIRONMENT"](#configuration-and-environment).

Basic usage is the same as [Pod::Text::Color](https://metacpan.org/pod/Pod::Text::Color). So please refer it.

# BASIC USAGE

Use this module with perldoc -M option

    $ perldoc -MPod::Text::Color::Delight Foo::Bar # delight!!

Also you can use this module with `PERLDOC` environment variable

    $ export PERLDOC="-MPod::Text::Color::Delight"
    $ perldoc Foo::Bar # delight!!

# CONFIGURATION AND ENVIRONMENT

You can configure colors as you like!
What is necessary is just to put a `.pod_text_color_delight` (this is configuration file) on your home directory.

The example of a configuration file should look at <a href="https://github.com/moznion/Pod-Text-Color-Delight/blob/master/sample/configurations">samples</a>.

If you specify not supported color or not specify color to element, the element will not be highlighted.



If you want to force the default settings, please set true value into __POD\_TEXT\_COLOR\_DELIGHT\_DEFAULT__ of environment variable.

# REQUIREMENTS

This module requires the terminal which is able to use 256 colors. If you use the terminal that does not meet the conditions,
this module will not highlight texts completely.

# SEE ALSO

[Pod::Text](https://metacpan.org/pod/Pod::Text), [Pod::Text::Color](https://metacpan.org/pod/Pod::Text::Color)

# LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

moznion <moznion@gmail.com>
