# 🌟 Podlite is a lightweight block-based markup language designed for flexibility and ease of use 🌟

[![Podlite](https://github.com/podlite/podlite-specs/blob/main/assets/bigtitle-social-logo.png)](https://podlite.org)

This module is a source filter that allows you to use Podlite markup language in your Perl programs.

## Installation

```bash
perl Makefile.PL
make
make test
make install
```

## Synopsis

```perl
use Podlite;

my $x = 1;

=head1 DESCRIPTION
=para This documentation block will be filtered out during compilation,
but you can still use it for generating documentation.

my $y = 2;
print "Sum: ", $x + $y, "\n";
```

## Features

- **Source filtering** - Strips Podlite markup during compilation
- **Line number preservation** - Accurate error reporting
- **Data blocks** - Access embedded data via `*DATA` filehandle

## Quick Examples

### Task List
```perl
=head1 TODO

=item [x] Implement basic functionality
=item [x] Write documentation
=item [ ] Add test suite
=item [ ] Publish to CPAN
```

### Table with Caption
```perl
=begin table :caption<Performance Benchmarks>
Operation      Time (ms)   Memory (MB)
Parse          45          12
Render         23          8
Export         67          15
=end table
```

### Notification Block
```perl
=begin nested :notify<warning> :caption<Important Note>
This feature is experimental and may change in future releases.
=end nested
```

### Code Block with Language
```perl
=begin code :lang<perl>
sub calculate {
    my ($x, $y) = @_;
    return $x + $y;
}
=end code
```

### Markdown Block
```perl
use Podlite;

my $version = "1.0";

=begin markdown
# Project Documentation

Mix **markdown** formatting with Podlite!

## Features
- Easy to read
- Easy to write
- Works seamlessly with Perl code

Example code:
\```perl
my $result = 2 + 2;
\```
=end markdown

print "Version: $version\n";
```

## Documentation

For complete documentation, run:

```bash
perldoc Podlite
```

Or see the [Podlite Specification Summary](SPECIFICATION_SUMMARY.md) for a comprehensive reference.

## Podlite Ecosystem

### Specification
- [Official Specification (HTML)](https://podlite.org/specification)
- [Specification Source](https://github.com/podlite/podlite-specs)
- [Discussions](https://github.com/podlite/podlite-specs/discussions)

### Implementation
- [Main Implementation](https://github.com/podlite/podlite)
- [Changelog](https://github.com/podlite/podlite/releases)
- [Issues](https://github.com/podlite/podlite/issues)

### Publishing System
- [Podlite-web](https://github.com/podlite/podlite-web)
- [How-to article](https://zahatski.com/2022/8/23/1/start-you-own-blog-site-with-podlite-for-web)
- [Changelog](https://github.com/podlite/podlite-web/releases)
- [Practical case: Raku knowledge base](https://raku-knowledge-base.podlite.org/)

### Desktop Viewer/Editor
- [Podlite-desktop](https://github.com/podlite/podlite-desktop)
- [Releases](https://github.com/podlite/podlite-desktop/releases)
- Available in stores:
  - [Linux (Snapcraft)](https://snapcraft.io/podlite)
  - [Windows Store](https://www.microsoft.com/store/apps/9NVNT9SNQJM8)
  - [Mac App Store](https://apps.apple.com/us/app/podlite/id1526511053)

### Online Resources
- [Official Website](https://podlite.org)
- [pod6.in](https://pod6.in/) - Online Pod6/Podlite converter
- [Roadmap](https://podlite.org/#Roadmap)
- [Project Updates](https://podlite.org/contents)
- [GitHub Organization](https://github.com/podlite/) 🤩
- [Funding Development](https://opencollective.com/podlite)

## Author

Aliaksandr Zahatski <zag@cpan.org>

## Credits

Damian Conway - for inspiration and source filter techniques

## License

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
