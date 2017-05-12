# NAME

Sledge::Template::Xslate - Text::Xslate template system for Sledge

# VERSION

This document describes Sledge::Template::Xslate version 0.09

# SYNOPSIS

    package MyApp::Pages;
    use strict;
    use Sledge::Pages::Compat;
    use Sledge::Template::Xslate ({
      syntax => 'TTerse',
      module => ['Text::Xslate::Bridge::TT2Like'],
      input_layer => ':utf8',# Please set input_layer if you want to use utf-8.
      # You can set more option.
    });

    # ...

# DESCRIPTION

Sledge::Template::Xslate is Text::Xslate template system for Sledge.

# AUTHOR

Kenta Sato  `<kenta.sato.1990@gmail.com>`

# SEE ALSO

Sledge( Repository - http://sourceforge.jp/projects/sledge/ )
Sledge::Template
[Text::Xslate](http://search.cpan.org/perldoc?Text::Xslate)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
