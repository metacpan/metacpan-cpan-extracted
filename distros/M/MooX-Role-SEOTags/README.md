# MooX::Role::SEOTags

![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/davorg-cpan/moox-role-seotags/perltest.yml)
![CPAN Version](https://img.shields.io/cpan/v/MooX-Role-SEOTags)

A Moo role for generating SEO meta tags (OpenGraph, Twitter, and more) for your Perl web objects.

## Features
- Generates OpenGraph meta tags
- Generates Twitter card meta tags
- Generates standard SEO tags (title, description, canonical)
- Easy to consume in any Moo-based class

For more explanation of the motivation behind this module, see the blog post
[Easy SEO for lazy programmers](https://perlhacks.com/2025/09/easy-seo-for-lazy-programmers/).

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

## Code, bugs and questions

This module is available [on CPAN](https://metacpan.org/pod/MooX::Role::SEOTags).

The code is available [on GitHub](https://github.com/davorg-cpan/webserver-dirindex).

For any questions, bug reports or suggestions, please use the
[issue tracker](https://github.com/davorg-cpan/webserver-dirindex).

## Author
Dave Cross <dave@perlhacks.com>

## License
This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
