# NAME

Perl::Critic::Moose - Policies for Perl::Critic concerned with using Moose

# VERSION

version 1.05

# DESCRIPTION

Some [Perl::Critic](https://metacpan.org/pod/Perl::Critic) policies that will help you keep your code in good shape
with regards to [Moose](https://metacpan.org/pod/Moose).

The included policies are:

- [Perl::Critic::Policy::Moose::ProhibitDESTROYMethod](https://metacpan.org/pod/Perl::Critic::Policy::Moose::ProhibitDESTROYMethod)

    Use `DEMOLISH()` instead of `DESTROY()`. \[Severity: 3\]

- [Perl::Critic::Policy::Moose::ProhibitMultipleWiths](https://metacpan.org/pod/Perl::Critic::Policy::Moose::ProhibitMultipleWiths)

    Compose your roles to enjoy safe composition. \[Severity: 4\]

- [Perl::Critic::Policy::Moose::ProhibitNewMethod](https://metacpan.org/pod/Perl::Critic::Policy::Moose::ProhibitNewMethod)

    Don't override the built-in constructors. \[Severity: 4\]

- [Perl::Critic::Policy::Moose::RequireCleanNamespace](https://metacpan.org/pod/Perl::Critic::Policy::Moose::RequireCleanNamespace)

    Require removing implementation details from you packages. \[Severity: 3\]

- [Perl::Critic::Policy::Moose::RequireMakeImmutable](https://metacpan.org/pod/Perl::Critic::Policy::Moose::RequireMakeImmutable)

    Increase performance by freezing your class structures with
    `__PACKAGE__->meta()->make_immutable()`. \[Severity: 3\]

- [Perl::Critic::Policy::Moose::ProhibitLazyBuild](https://metacpan.org/pod/Perl::Critic::Policy::Moose::ProhibitLazyBuild)

    Prevent the use of ` lazy_build ` which creates mutability
    problems and pollutes namespaces. \[Severity: 2\]

# AFFILIATION

This module has no functionality, but instead contains documentation for this
distribution and acts as a means of pulling other modules into a bundle. All
of the Policy modules contained herein will have an "AFFILIATION" section
announcing their participation in this grouping.

# CONFIGURATION AND ENVIRONMENT

All policies included are in the "moose" theme. See the [Perl::Critic](https://metacpan.org/pod/Perl::Critic)
documentation for how to make use of this.

# BUGS AND LIMITATIONS

Please report any bugs or feature requests to
`bug-perl-critic-moose@rt.cpan.org`, or through the web interface at
[http://rt.cpan.org](http://rt.cpan.org).

Bugs may be submitted through [the RT bug tracker](http://rt.cpan.org/Public/Dist/Display.html?Name=Perl-Critic-Moose)
(or [bug-perl-critic-moose@rt.cpan.org](mailto:bug-perl-critic-moose@rt.cpan.org)).

I am also usually active on IRC as 'drolsky' on `irc://irc.perl.org`.

# AUTHORS

- Elliot Shank <perl@galumph.com>
- Dave Rolsky <autarch@urth.org>

# CONTRIBUTORS

- Jeffrey Ryan Thalhammer <jeff@thaljef.org>
- Karen Etheridge <ether@cpan.org>
- Kieren Diment <kieren.diment@hiivesystems.com>
- Noel Maddy <zhtwnpanta@gmail.com>
- Shawn Moore <cpan@sartak.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2008 - 2016 by Elliot Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
