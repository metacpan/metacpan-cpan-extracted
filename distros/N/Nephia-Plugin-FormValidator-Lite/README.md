[![Build Status](https://travis-ci.org/mackee/Nephia-Plugin-FormValidator-Lite.png?branch=master)](https://travis-ci.org/mackee/Nephia-Plugin-FormValidator-Lite)
# NAME

Nephia::Plugin::FormValidator::Lite - FormValidator::Lite plugin for Nephia

# SYNOPSIS

    use Nephia plugins => [qw/FormValidator::Lite/];
    post '/form' => sub {
        my $res = form(
            first_name => [qw/NOT_NULL/],
            last_kana => [qw/NOT_NULL/],
            mail => [qw/NOT_NULL EMAIL/],
        );

        # Alias name of params. This use in error messages.
        # Default is param key.
        $res->set_param_message(
            first_name => 'First name',
            last_name => 'Last name',
            mail => 'Mail address'
        );

        # check error
        if ($res->has_error) {
            return {
                template => 'index.html',
                error_message => $res->get_error_messages, # print errors
            };
        }
        else {
            my $req = req;
            return {
                template => 'confirm.html',
                form => {
                    name => $req->('param'),
                    name_kana => $req->('name_kana'),
                    mail => $req->('mail'),
                }
            };
        }
    };

    # in etc/conf/common.pl
    +{
        'Plugin::FormValidator::Lite' => {
            function_message => 'en',
            constants => [qw/Email/]
    }
};

# DESCRIPTION

Nephia::Plugin::FormValidator::Lite is a [FormValidator::Lite](http://search.cpan.org/perldoc?FormValidator::Lite) binding for Nephia.

# SEE ALSO

[Nephia](http://search.cpan.org/perldoc?Nephia)

[FormValidator::Lite](http://search.cpan.org/perldoc?FormValidator::Lite)

# LICENSE

Copyright (C) MACOPY.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

MACOPY <macopy123\[attttt\]gmai.com>
