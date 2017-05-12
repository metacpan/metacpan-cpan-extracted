# NAME

Pod::Markdown::Passthrough - A passthrough mode for Pod::Markdown.

# SYNOPSIS

    use Pod::Markdown::Passthrough;

    my $parser = Pod::Markdown::Passthrough->new();
    $parser->parse_from_file($file_containing_markdown);
    # Outputs the raw contents of $file_containing_markdown.
    print $parser->as_markdown;

# DESCRIPTION

Pod::Markdown::Passthrough is a child class of Pod::Markdown which makes the
assumption that the source file is already markdown, and performs no processing
of it at all.

github-aware CPAN module authoring tools such as [Minilla](https://metacpan.org/pod/Minilla) build README.md
from the module POD, but sometimes you want the README.md to be something
specific, and independent of the module POD.

For example, using [Minilla](https://metacpan.org/pod/Minilla), add the following two lines to `minil.toml` to
have the build process leave README.md untouched.

    readme_from="README.md"
    markdown_maker="Pod::Markdown::Passthrough"

# CAVEATS

- Only the `parse_from_file()` and `as_markdown()` methods of
[Pod::Markdown](https://metacpan.org/pod/Pod::Markdown) are replaced, so calling any other methods on the object is
_very unlikely_ to do what you'd expect.

# LICENSE

Copyright (C) Dave Webb.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Dave Webb <github@d5ve.com>
