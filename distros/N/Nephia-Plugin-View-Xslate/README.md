# NAME

Nephia::Plugin::View::Xslate - A plugin for Nephia that provides template mechanism

# SYNOPSIS

    use Nephia plugins => [
        'View::Xslate' => +{
            syntax => 'Kolon',
            path   => [ qw/ view / ],
        },
    ];
    

    app {
        [200, [], render('index.html', { name => 'myapp' })];
    };

# DESCRIPTION

Nephia::Plugin::View::Xslate provides render DSL for rendering template.

# DSL

## render $template\_file \[, $hashref\];

Returns rendered content.

# LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

ytnobody <ytnobody@gmail.com>
