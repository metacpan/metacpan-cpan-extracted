---
name: getty-perl-pod
description: Use when writing or editing POD in a distribution whose dist.ini uses [@Author::GETTY] — the =attr/=method/=opt shortcut commands, the # ABSTRACT line, and which sections Pod::Weaver generates so you must not write them.
user-invocable: false
---

# POD under `[@Author::GETTY]`

Documentation in a `[@Author::GETTY]` distribution is written with shortcut commands
that `Pod::Elemental::Transformer::Author::GETTY` turns into plain `=head1`/`=head2`
at build time, and Pod::Weaver adds the boilerplate sections. The source stays short
and the docs stay next to the code they describe.

Outside a bundle-managed distribution none of this is processed — write plain POD
there, and do not scatter these commands or `# ABSTRACT` into files Dist::Zilla never
sees.

## `# ABSTRACT`

Every file the bundle processes carries `# ABSTRACT: <one line>` directly under
`package`, before any `use`; an executable in `bin/` carries it under the shebang.
It becomes the NAME section. One line, no trailing period, says what the module *is*.

```perl
package Kubernetes::REST;
# ABSTRACT: A simple, typed client for the Kubernetes API
```

## Shortcut commands

The command stays exactly where you put it — nothing is collected into a separate
section. Place it **directly after** the code it documents and close with `=cut`.

| Command | Becomes | For |
|---|---|---|
| `=synopsis` | `=head1 SYNOPSIS` | |
| `=description` | `=head1 DESCRIPTION` | |
| `=seealso` | `=head1 SEE ALSO` | |
| `=attr name` | `=head2 name` | an attribute, after its `has` |
| `=method name` | `=head2 name` | a method, after its `sub` |
| `=func name` | `=head2 name` | an exported function |
| `=opt --flag` | `=head2 --flag` | a CLI option |
| `=env NAME` | `=head2 NAME` | an environment variable |
| `=hook name` | `=head2 name` | a hook / callback |
| `=example Title` | `=head2 Title` | a worked example |

`=resource` and `=event` appear in the Pod::Weaver bundle's documentation but the
transformer does not handle them — do not use them until it does.

```perl
has server => ( is => 'ro', required => 1, coerce => ... );

=attr server

Required. L<Kubernetes::REST::Server> instance or hashref with the connection
configuration.

    server => { endpoint => 'https://kubernetes.local:6443' }

=cut

sub list { ... }

=method list

    my $pods = $api->list('Pod', namespace => 'default');

Returns ...

=cut
```

An attribute's entry says: required or default, what it accepts (including coercions),
and one short usage line when the shape is not obvious. A method's entry opens with an
indented call example, then what it returns and what it croaks on.

## Generated — never write these

NAME (from `# ABSTRACT`), VERSION (from `$VERSION`), SUPPORT, CONTRIBUTING, AUTHORS,
LICENSE AND COPYRIGHT. A hand-written `=head1 AUTHOR`, `SUPPORT` or `COPYRIGHT` ends up
duplicated in the built POD.

SYNOPSIS, DESCRIPTION, OVERVIEW and STABILITY are yours to write — as `=synopsis` /
`=description` or as plain `=head1 OVERVIEW` / `=head1 STABILITY`; Pod::Weaver orders
them after VERSION.
