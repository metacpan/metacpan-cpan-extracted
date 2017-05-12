# NAME

Nephia::Plugin::FillInForm - A plugin for Nephia that provides fill-in-form feature

# SYNOPSIS

    use Nephia plugins => [
        'FillInForm',
        'View::MicroTemplate' => { ... },
    ];
    path '/' => sub {
        my $params = param;
        fillin_form( $params ); # fill params in form
        render('template.html');
    };

# DESCRIPTION

Nephia::Plugin::FillInForm provides fill-in-form feature.

# DSL

## fillin\_form

    fillin_form( $hashref );

Fill spedified value in form.

# LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

ytnobody <ytnobody@gmail.com>
