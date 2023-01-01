package MooseX::Types::Perl 0.101344;
# ABSTRACT: Moose types that check against Perl syntax

use MooseX::Types -declare => [ qw(
  DistName

  ModuleName
  PackageName

  Identifier
  SafeIdentifier

  LaxVersionStr
  StrictVersionStr
  VersionObject
) ];

#pod =head1 SYNOPSIS
#pod
#pod   use MooseX::Types::Perl qw(
#pod     DistName
#pod
#pod     ModuleName
#pod     PackageName
#pod
#pod     Identifier
#pod     SafeIdentifier
#pod
#pod     LaxVersionStr
#pod     StrictVersionStr
#pod     VersionObject
#pod   );
#pod
#pod =head1 DESCRIPTION
#pod
#pod This library provides L<Moose types|MooseX::Types> for checking things (mostly
#pod strings) against syntax that is, or is a reasonable subset of, Perl syntax.
#pod
#pod =cut

use MooseX::Types::Moose qw(Object Str);
use Params::Util qw(_CLASS);
use version 0.82;

#pod =head1 TYPES
#pod
#pod =head2 ModuleName
#pod
#pod =head2 PackageName
#pod
#pod These types are identical, and expect a string that could be a package or
#pod module name.  That's basically a bunch of identifiers stuck together with
#pod double-colons.  One key quirk is that parts of the package name after the
#pod first may begin with digits.
#pod
#pod The use of an apostrophe as a package separator is not permitted.
#pod
#pod =cut

subtype ModuleName,  as Str, where { ! /\P{ASCII}/ && _CLASS($_) };
subtype PackageName, as Str, where { ! /\P{ASCII}/ && _CLASS($_) };

#pod =head2 DistName
#pod
#pod The DistName type checks for a string like C<MooseX-Types-Perl>, the sort of
#pod thing used to name CPAN distributions.  In general, it's like the more familiar
#pod L<ModuleName>, but with hyphens instead of double-colons.
#pod
#pod In reality, a few distribution names may not match this pattern -- most
#pod famously, C<CGI.pm> is the name of the distribution that contains CGI.  These
#pod exceptions are few and far between, and deciding what a C<LaxDistName> type
#pod would look like has not seemed worth it, yet.
#pod
#pod =cut

subtype DistName,
  as Str,
  where   {
    return if /:/;
    (my $str = $_) =~ s/-/::/g;
    $str !~ /\P{ASCII}/ && _CLASS($str)
  },
  message {
    /::/
    ? "$_ looks like a module name, not a dist name"
    : "$_ is not a valid dist name"
  };

# LaxDistName -- how does this work, other than "like some characters, okay?"

#pod =head2 Identifier
#pod
#pod An L<Identifier|perldata/Variable names> is something that could be used as a
#pod symbol name or other identifier (filehandle, directory handle, subroutine name,
#pod format name, or label).  It's what you put after the sigil (dollar sign, at
#pod sign, percent sign) in a variable name.  Generally, it's a bunch of
#pod alphanumeric characters not starting with a digit.
#pod
#pod Although Perl identifiers may contain non-ASCII characters in some
#pod circumstances, this type does not allow it.  A C<UnicodeIdentifier> type may be
#pod added in the future.
#pod
#pod =cut

subtype Identifier,
  as Str,
  where { / \A [_a-z] [_a-z0-9]* \z /xi; };

#pod =head2 SafeIdentifier
#pod
#pod SafeIdentifiers are just like Identifiers, but omit the single-letter variables
#pod underscore, a, and b, as these have special significance.
#pod
#pod =cut

subtype SafeIdentifier,
  as Identifier,
  where { ! / \A [_ab] \z /x; };

#pod =head2 LaxVersionStr
#pod
#pod =head2 StrictVersionStr
#pod
#pod Lax and strict version strings use the L<is_lax|version/is_lax> and
#pod L<is_strict|version/is_strict> methods from C<version> to check if the given
#pod string would be a valid lax or strict version.  L<version::Internals> covers
#pod the details but basically:  lax versions are everything you may do, and strict
#pod omit many of the usages best avoided.
#pod
#pod =cut

subtype LaxVersionStr,
  as Str,
  where { version::is_lax($_) },
  message { "$_ is not a valid lax version string" };

subtype StrictVersionStr,
  as LaxVersionStr,
  where { version::is_strict($_) },
  message { "$_ is not a valid strict version string" };

#pod =head2 VersionObject
#pod
#pod Just for good measure, this type is included to check if a value is a version
#pod object.  Coercions from LaxVersionStr (and thus StrictVersionStr) are provided.
#pod
#pod =cut

subtype VersionObject,
  as Object,
  where { $_->isa('version') };

coerce VersionObject,
  from LaxVersionStr,
  via { version->parse($_) };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Types::Perl - Moose types that check against Perl syntax

=head1 VERSION

version 0.101344

=head1 SYNOPSIS

  use MooseX::Types::Perl qw(
    DistName

    ModuleName
    PackageName

    Identifier
    SafeIdentifier

    LaxVersionStr
    StrictVersionStr
    VersionObject
  );

=head1 DESCRIPTION

This library provides L<Moose types|MooseX::Types> for checking things (mostly
strings) against syntax that is, or is a reasonable subset of, Perl syntax.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 TYPES

=head2 ModuleName

=head2 PackageName

These types are identical, and expect a string that could be a package or
module name.  That's basically a bunch of identifiers stuck together with
double-colons.  One key quirk is that parts of the package name after the
first may begin with digits.

The use of an apostrophe as a package separator is not permitted.

=head2 DistName

The DistName type checks for a string like C<MooseX-Types-Perl>, the sort of
thing used to name CPAN distributions.  In general, it's like the more familiar
L<ModuleName>, but with hyphens instead of double-colons.

In reality, a few distribution names may not match this pattern -- most
famously, C<CGI.pm> is the name of the distribution that contains CGI.  These
exceptions are few and far between, and deciding what a C<LaxDistName> type
would look like has not seemed worth it, yet.

=head2 Identifier

An L<Identifier|perldata/Variable names> is something that could be used as a
symbol name or other identifier (filehandle, directory handle, subroutine name,
format name, or label).  It's what you put after the sigil (dollar sign, at
sign, percent sign) in a variable name.  Generally, it's a bunch of
alphanumeric characters not starting with a digit.

Although Perl identifiers may contain non-ASCII characters in some
circumstances, this type does not allow it.  A C<UnicodeIdentifier> type may be
added in the future.

=head2 SafeIdentifier

SafeIdentifiers are just like Identifiers, but omit the single-letter variables
underscore, a, and b, as these have special significance.

=head2 LaxVersionStr

=head2 StrictVersionStr

Lax and strict version strings use the L<is_lax|version/is_lax> and
L<is_strict|version/is_strict> methods from C<version> to check if the given
string would be a valid lax or strict version.  L<version::Internals> covers
the details but basically:  lax versions are everything you may do, and strict
omit many of the usages best avoided.

=head2 VersionObject

Just for good measure, this type is included to check if a value is a version
object.  Coercions from LaxVersionStr (and thus StrictVersionStr) are provided.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Ricardo Signes

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Ricardo Signes <rjbs@semiotic.systems>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
