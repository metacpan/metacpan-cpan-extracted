# NAME

Template::Plugin::Filter::Scss - CSS::Sass filter for Template Toolkit 

# SYNOPSIS

    [% USE Filter.Scss include_paths => '/home/user/sass', output_style => 'compressed' %]

    [% FILTER scss %]
        @import "compass/css3";
        .col305 {
            position: relative;
            display: inline-block;
            width: 305px;
            vertical-align: top;
            height: 400px;
            @include opacity(0);

            &-header {
                font-size: 12px;
            }
        }
    [% END %]

# OPTIONS 

- include\_paths (or include\_path)

    Optional. This is an arrayref or a string that holds the list a of path(s) to search when following Sass @import directives.

- output\_style

    Optional. This is a string, not case-sensitive.

    'NESTED'

    'COMPACT'

    'EXPANDED'

    'COMPRESSED'

    The default is 'NESTED'.

# SEE ALSO

CSS::Sass - Compile .scss files using libsass [http://search.cpan.org/~ocbnet/CSS-Sass/lib/CSS/Sass.pm](http://search.cpan.org/~ocbnet/CSS-Sass/lib/CSS/Sass.pm)

# LICENSE

Copyright (C) bbon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

bbon <bbon@mail.ru>
