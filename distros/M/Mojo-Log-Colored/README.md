# NAME

Mojo::Log::Colored - Colored Mojo logging

<div>
    <p>
    <a href="https://travis-ci.org/simbabque/Mojo-Log-Colored"><img src="https://travis-ci.org/simbabque/Mojo-Log-Colored.svg?branch=master"></a>
    <a href='https://coveralls.io/github/simbabque/Mojo-Log-Colored?branch=master'><img src='https://coveralls.io/repos/github/simbabque/Mojo-Log-Colored/badge.svg?branch=master' alt='Coverage Status' /></a>
    </p>
</div>

# SYNOPSIS

    use Mojo::Log::Colored;

    # Log to STDERR
    $app->log(
        Mojo::Log::Colored->new(
            
            # optionally set the colors
            colors => {
                debug => "bold bright_white",
                info  => "bold bright_blue",
                warn  => "bold green",
                error => "bold yellow",
                fatal => "bold yellow on_red",
            }
        )
    );   
    

# DESCRIPTION

Mojo::Log::Colored is a logger for Mojolicious with colored output for the terminal. It lets you define colors
for each log level based on [Term::ANSIColor](https://metacpan.org/pod/Term::ANSIColor) and comes with sensible default colors. The full lines in the log
will be colored.

Since this inherits from [Mojo::Log](https://metacpan.org/pod/Mojo::Log) you can still give it a `file`, but the output would also be colored.
That does not make a lot of sense, so you don't want to do that. Use this for development, not production.

# ATTRIBUTES

[Mojo::Log::Colored](https://metacpan.org/pod/Mojo::Log::Colored) implements the following attributes.

## colors

    my $colors = $log->colors;
    $log->colors(
        {
            debug => "bold bright_white",
            info  => "bold bright_blue",
            warn  => "bold green",
            error => "bold yellow",
            fatal => "bold yellow on_red",
        }
    );

Takes a hash reference with the five log levels as keys and strings of colors as values. Refer to
[Term::ANSIColor](https://metacpan.org/pod/Term::ANSIColor) for more information about what kind of color you can use.

You can turn off coloring for specific levels by omitting them from the config hash.

    $log->colors(
        {
            fatal => "bold green on_red",
        }
    );

The above will only color fatal messages. All other levels will be in your default terminal color.

## format

    my $cb = $log->format;
    $log   = $log->format( sub { ... } );

A callback for formatting log messages. Cannot be passed to `new` at construction! See [Mojo::Log](https://metacpan.org/pod/Mojo::Log) for more information.

# METHODS

[Mojo::Log::Colored](https://metacpan.org/pod/Mojo::Log::Colored) inherits all methods from [Mojo::Log](https://metacpan.org/pod/Mojo::Log) and does not implement new ones.

# SEE ALSO

[Mojo::Log](https://metacpan.org/pod/Mojo::Log), [Term::ANSIColor](https://metacpan.org/pod/Term::ANSIColor)

# ACKNOWLEDGEMENTS

This plugin was inspired by lanti asking about a way to easier find specific errors
in the Mojo log during unit test runs on [Stack Overflow](https://stackoverflow.com/q/44965998/1331451).

# LICENSE

Copyright (C) simbabque.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

simbabque <simbabque@cpan.org>
