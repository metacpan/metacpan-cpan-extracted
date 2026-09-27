# NAME

Task::Markdown::Pod - install the Markdown and DocBook to POD toolchain

# SYNOPSIS

```sh
cpanm Task::Markdown::Pod
```

# DESCRIPTION

This Task distribution installs the Perl modules used to convert Markdown
sidecars to POD, convert DocBook through Markdown into the documentation
pipeline, and integrate both operations with ExtUtils::MakeMaker.

It provides no runtime functions of its own.

# INSTALLED MODULES

- `Markdown::Pod::Embed`
- `Docbook::Convert`
- `ASPEER::MakeMaker::Markdown::Pod`

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Andrew Speer. It may be distributed
under the same terms as Perl itself.
