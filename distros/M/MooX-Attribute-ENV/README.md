# NAME

MooX::Attribute::ENV - Allow Moo attributes to get their values from %ENV

# PROJECT STATUS

| OS      |  Build status |
|:-------:|--------------:|
| Linux   | [![Build Status](https://travis-ci.org/mohawk2/moox-attribute-env.svg?branch=master)](https://travis-ci.org/mohawk2/moox-attribute-env) |

[![CPAN version](https://badge.fury.io/pl/moox-attribute-env.svg)](https://metacpan.org/pod/MooX::Attribute::ENV) [![Coverage Status](https://coveralls.io/repos/github/mohawk2/moox-attribute-env/badge.svg?branch=master)](https://coveralls.io/github/mohawk2/moox-attribute-env?branch=master)

# SYNOPSIS

    package MyMod;
    use Moo;
    use MooX::Attribute::ENV;
    # look for $ENV{attr_val} and $ENV{ATTR_VAL}
    has attr => (
      is => 'ro',
      env_key => 'attr_val',
    );
    # looks for $ENV{otherattr} and $ENV{OTHERATTR}, then any default
    has otherattr => (
      is => 'ro',
      env => 1,
      default => 7,
    );
    # looks for $ENV{xxx_prefixattr} and $ENV{XXX_PREFIXATTR}
    has prefixattr => (
      is => 'ro',
      env_prefix => 'xxx',
    );
    # looks for $ENV{MyMod_packageattr} and $ENV{MYMOD_PACKAGEATTR}
    has packageattr => (
      is => 'ro',
      env_package_prefix => 1,
    );

    $ perl -MMyMod -E 'say MyMod->new(attr => 2)->attr'
    # 2
    $ ATTR_VAL=3 perl -MMyMod -E 'say MyMod->new->attr'
    # 3
    $ OTHERATTR=4 perl -MMyMod -E 'say MyMod->new->otherattr'
    # 4

# DESCRIPTION

This is a [Moo](https://metacpan.org/pod/Moo) extension. It allows other attributes for ["has" in Moo](https://metacpan.org/pod/Moo#has). If
any of these are given, then instead of the normal value-setting "chain"
for attributes of given, default; the chain will be given, environment,
default.

The environment will be searched for either the given case, or upper case,
version of the names discussed below.

When a prefix is mentioned, it will be prepended to the mentioned name,
with a `_` in between.

# ADDITIONAL ATTRIBUTES

## env

Boolean. If true, the name is the attribute, no prefix.

## env\_key

String. If true, the name is the given value, no prefix.

## env\_prefix

String. The prefix is the given value.

## env\_package\_prefix

Boolean. If true, use as the prefix the current package-name, with `::`
replaced with `_`.

# AUTHOR

Ed J, porting John Napiorkowski's excellent [MooseX::Attribute::ENV](https://metacpan.org/pod/MooseX::Attribute::ENV).

# LICENCE

The same terms as Perl itself.
