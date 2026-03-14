# Term::ANSIColor::Gradients

A curated library of ANSI 256-color palettes for terminal display, organized
into sub-modules by category.  Comes with a CLI tool for browsing, previewing,
and exporting gradients.

## Modules

- Term::ANSIColor::Gradients::Classic — basic single-hue ramps (GREY, RED, BLUE, etc.)
- Term::ANSIColor::Gradients::Extended — heatmaps, scientific, sparkline, and artistic palettes
- Term::ANSIColor::Gradients::Scientific — perceptual maps (Viridis, Plasma, Inferno, Magma, ...)
- Term::ANSIColor::Gradients::Sequential — single-hue sequential ramps (BLUES, PURPLES, GOLDS, ...)
- Term::ANSIColor::Gradients::Diverging — bi-directional palettes through a neutral midpoint
- Term::ANSIColor::Gradients::Accessibility — colorblind-safe palettes (Okabe-Ito, Wong, ...)
- Term::ANSIColor::Gradients::Artistic — decorative palettes (AURORA, NEON, CANDY, ...)
- Term::ANSIColor::Gradients::Utils — internal color conversion and contrast utilities

Each data module exports a `%GRADIENTS` hash (palette name to array-ref of
ANSI 256-color indices) and a `%CONTRAST` hash (same keys, complementary-hue
contrast palette for each gradient, computed once at load time).

## Synopsis

    use Term::ANSIColor::Gradients::Classic ;
    use Term::ANSIColor ;

    for my $idx (@{$Term::ANSIColor::Gradients::Classic::GRADIENTS{GREY}}) {
        print colored('█', "ansi$idx") ;
    }
    print "\n" ;

    # complementary contrast palette
    for my $idx (@{$Term::ANSIColor::Gradients::Classic::CONTRAST{GREY}}) {
        print colored('█', "ansi$idx") ;
    }
    print "\n" ;

    # list all group names
    use Term::ANSIColor::Gradients qw(list_groups) ;
    my @groups = list_groups() ;

## CLI

    ansicolors_gradients [OPTIONS]

With no options, lists all available gradient names.

Options:

    --gradient RE     regexp matched against gradient names (case-insensitive);
                      use 'all' to display every gradient
    --bar N           characters per color stop (default: 1)
    --char CHAR       character for the color bar (default: █)
    --reverse         reverse the gradient direction
    --fit-width       scale gradient to fit terminal width
    --intensity N     shift brightness by N steps (1 unit = 0.05 HSV value);
                      positive lightens, negative darkens; hue is preserved
    --contrast        show complementary-hue contrast bar and indices
    --format FORMAT   text (default), perl, json, markdown, html
    --load FILE       merge additional gradients from a JSON file
    --help            show help

Examples:

    ansicolors_gradients
    ansicolors_gradients --gradient FIRE
    ansicolors_gradients --gradient '^SCI_'
    ansicolors_gradients --gradient blue --contrast
    ansicolors_gradients --gradient all --bar 2
    ansicolors_gradients --gradient SCI_VIRIDIS --reverse --intensity -4
    ansicolors_gradients --gradient OCEAN --fit-width --char ░
    ansicolors_gradients --gradient DIV --format json

## Installation

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

## License

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself (Artistic License 2.0 or GPL 3.0).

## Author

Nadim Khemir <nadim.khemir@gmail.com>
