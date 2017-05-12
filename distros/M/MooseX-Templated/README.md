
[![Build Status](https://travis-ci.org/sillitoe/moosex-templated.svg?branch=master)](https://travis-ci.org/sillitoe/moosex-templated)
[![Coverage Status](https://coveralls.io/repos/github/sillitoe/moosex-templated/badge.svg?branch=master)](https://coveralls.io/github/sillitoe/moosex-templated?branch=master)

MooseX-Templated
=================

MooseX::Templated provides template-based rendering for Moose objects

**Include this role within your class**

    package Farm::Cow;

    use Moose;

    with 'MooseX::Templated';

    has 'spots'   => ( is => 'rw' );
    has 'hobbies' => ( is => 'rw', default => sub { ['mooing', 'chewing'] } );

    sub make_a_happy_noise { "Mooooooo" }

**Add the template as a local method..**

    sub _template { <<'_TT2' }

    This cow has [% self.spots %] spots - it likes
    [% self.hobbies.join(" and ") %].
    [% self.make_a_happy_noise %]!

    _TT2

**..or as a separate file**

    # lib/Farm/Cow.tt

**Object can now be rendered**

    $cow = Farm::Cow->new( spots => '8' );

    print $cow->render();

    # This cow has 8 spots - it likes
    # mooing and chewing.
    # Mooooooo!

# Configuration

Various options can be provided to override default (template system, file location, etc):

    # lib/Farm/Cow.pm

    with 'MooseX::Templated' => {
      template_suffix => '.tt2',
      template_root   => '__LIB__/../root',
    };

    # now looks for
    # root/Farm/Cow.tt2

# CPAN

Full documentation on CPAN

[MooseX::Templated](https://metacpan.org/pod/MooseX::Templated)

# LICENCE AND COPYRIGHT

Copyright (c) 2016, Ian Sillitoe. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See [perlartistic](https://metacpan.org/pod/perlartistic).
