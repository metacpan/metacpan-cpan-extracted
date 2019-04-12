# NAME

MooX::StrictHas - Forbid "has" attributes lazy\_build and auto\_deref

# PROJECT STATUS

| OS      |  Build status |
|:-------:|--------------:|
| Linux   | [![Build Status](https://travis-ci.com/mohawk2/moox-stricthas.svg?branch=master)](https://travis-ci.org/mohawk2/moox-stricthas) |

[![CPAN version](https://badge.fury.io/pl/moox-stricthas.svg)](https://metacpan.org/pod/MooX::StrictHas) [![Coverage Status](https://coveralls.io/repos/github/mohawk2/moox-stricthas/badge.svg?branch=master)](https://coveralls.io/github/mohawk2/moox-stricthas?branch=master)

# SYNOPSIS

    package MyMod;
    use Moo;
    use MooX::StrictHas;
    has attr => (
      is => 'ro',
      auto_deref => 1, # blows up, not implemented in Moo
    );
    has attr2 => (
      is => 'ro',
      lazy_build => 1, # blows up, not implemented in Moo
    );
    has attr2 => (
      is => 'ro',
      does => "Thing", # blows up, not implemented in Moo
    );

# DESCRIPTION

This is a [Moo](https://metacpan.org/pod/Moo) extension, intended to aid those porting modules from
[Moose](https://metacpan.org/pod/Moose) to Moo. It forbids two attributes for ["has" in Moo](https://metacpan.org/pod/Moo#has), which Moo
does not implement, but silently accepts:

- auto\_deref

    This is not considered best practice - just dereference in your using code.

- does

    Unsupported; use `isa` instead.

- lazy\_build

    Use `is => 'lazy'` instead.

# AUTHOR

Ed J

# LICENCE

The same terms as Perl itself.
