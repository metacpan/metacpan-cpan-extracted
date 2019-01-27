# NAME

Pod::Markdown::Github - Convert POD to Github's specific markdown

# VERSION

Version 0.04

# SYNOPSIS

```
perl -MPod::Markdown::Github -e "Pod::Markdown::Github->filter('file.pod')"
```

# DESCRIPTION

Github flavored markdown allows for syntax highlighting using three
backticks.

This module inherits from [Pod::Markdown](https://metacpan.org/pod/Pod::Markdown) and adds those backticks and
an optional language identifier.

# SUBCLASSING

This module performs a very simple linguistic check to identify if it's
dealing with Perl code. To expand on this logic, or to add other languages
one may subclass this module and overwrite the `syntax` method.

```perl
package Pod::Markdown::Github::More;

sub syntax {
    my ( $self, $paragraph ) = @_;

    # analyze $paragraph and return language identifier
    return 'c' if $paragraph =~ /\#include/;
}
```

Github uses [Liguist](https://github.com/github/linguist) to perform language
detection and syntax highlighting, so the above may not be needed after all.

# AUTHORS

Stefan G. (minimal)

Ben Kaufman (whosgonna)

Nikolay Mishin (mishin)

# LICENCE

Perl
