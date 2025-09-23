# MooX::Role::SEOTags

A Moo role for generating SEO meta tags (OpenGraph, Twitter, and more) for your Perl web objects.

## Features
- Generates OpenGraph meta tags
- Generates Twitter card meta tags
- Generates standard SEO tags (title, description, canonical)
- Easy to consume in any Moo-based class

## Installation

    cpanm MooX::Role::SEOTags

## Usage

```
package MyWebPage;
use Moo;
with 'MooX::Role::SEOTags';

has 'og_title' => (is => 'ro', required => 1);
has 'og_type'  => (is => 'ro', required => 1);
has 'og_url'   => (is => 'ro', required => 1);
has 'og_image' => (is => 'ro'); # optional

# ...
```

See the module POD for full documentation.

## Author
Dave Cross <dave@perlhacks.com>

## License
This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
