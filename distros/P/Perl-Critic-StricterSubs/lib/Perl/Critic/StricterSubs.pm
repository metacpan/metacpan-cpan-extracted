package Perl::Critic::StricterSubs;

use strict;
use warnings;

#-----------------------------------------------------------------------------

our $VERSION = 0.06;

#-----------------------------------------------------------------------------

1;

#-----------------------------------------------------------------------------

__END__

=pod

=for stopwords distro hoc strictersubs Mathworks ACKNOWLEDGEMENTS

=head1 NAME

Perl::Critic::StricterSubs - Perl::Critic plugin for stricter subroutine checks

=head1 AFFILIATION

This module has no functionality, but instead contains documentation
for this distribution and acts as a means of pulling other modules
into a bundle.  All of the Policy modules contained herein will have
an "AFFILIATION" section announcing their participation in this
grouping.

=head1 DESCRIPTION

As a dynamic language, Perl doesn't require you to define subroutines
until run-time.  Although this is a powerful feature, it can also be a
major source of bugs.  For example, you might mistype the name of a
subroutine, or call a subroutine from another module without including
that module or importing that subroutine.  And unless you have very
good test coverage, you might not know about these bugs until you have
already launched your code.

The L<Perl::Critic::Policy|Perl::Critic::Policy> modules in this distribution are aimed at
reducing errors caused by invoking subroutines that are not defined.
Each Policy can be used separately.  But when applied together, they
enforce a specific and deliberate coding style that minimizes the
chance of writing code that makes calls to undefined subroutines.

This coding style will not appeal to everyone.  Some folks will surely
find this coding style to be too verbose or too restrictive.  In
particular, importing via L<Exporter|Exporter> tags and pattern matching is
purposely not supported.  But hopefully, these Policies will encourage
you to consciously consider the inherent trade-offs of your current
coding style.

=head1 LIMITATIONS

L<Perl::Critic|Perl::Critic> is a static analyzer, so the Policies in this distro
only pertain to static subroutines.  That is, subroutine calls that
typically look like one of these:

  foo();
  Bar::baz( $string );
  Quux->new( @args );

At present, L<Perl::Critic|Perl::Critic> cannot not know the class ancestry of any
particular object reference.  Thus, the Policies in this distro do not
cover object methods, such as these:

  $object->foo();

Still, it is difficult for L<Perl::Critic|Perl::Critic> to know precisely which
static subroutines will be defined at run time.  Therefore, these
Policies are expected to report some false violations.  So you
probably don't want to use these Policies with Test::Perl::Critic or
other frameworks that expect 100% violation-free code.  Instead, I
suggest using these Policies with the L<perlcritic|perlcritic> command to perform
ad hoc analysis of your code.

=head1 INCLUDED POLICIES

The following Policy modules are shipped in this distribution.  See
the documentation within each module for details on its specific
behavior.

=head2 L<Perl::Critic::Policy::Modules::RequireExplicitInclusion|Perl::Critic::Policy::Modules::RequireExplicitInclusion>

If you refer to symbols in another package, you must explicitly
include that module.  [Severity: 4]

=head2 L<Perl::Critic::Policy::Subroutines::ProhibitCallsToUndeclaredSubs|Perl::Critic::Policy::Subroutines::ProhibitCallsToUndeclaredSubs>

Unqualified subroutines must always be declared or explicitly imported
within the file. [Severity: 4]

=head2 L<Perl::Critic::Policy::Subroutines::ProhibitCallsToUnexportedSubs|Perl::Critic::Policy::Subroutines::ProhibitCallsToUnexportedSubs>

Only allow calls to external subroutines that are named in C<@EXPORT>
or C<@EXPORT_OK>. [Severity: 4]

=head2 L<Perl::Critic::Policy::Subroutines::ProhibitExportingUndeclaredSubs|Perl::Critic::Policy::Subroutines::ProhibitExportingUndeclaredSubs>

All subroutines named for C<@EXPORT> or C<@EXPORT_OK> must be defined
in the file.  [Severity: 4]

=head2 L<Perl::Critic::Policy::Subroutines::ProhibitQualifiedSubDeclarations|Perl::Critic::Policy::Subroutines::ProhibitQualifiedSubDeclarations>

Do not declare subroutines with fully-qualified names [Severity: 3]


=head1 CONFIGURATION

After installing the C<Perl-Critic-StricterSubs> distro, all the
included Policies available to the L<Perl::Critic|Perl::Critic> engine.  The
Policies in this distro all belong to the "strictersubs" theme, so
you can disable all of them at once using either of these methods:

  # In your .perlcriticrc file...
  theme = not strictersubs

  # With the perlcritic command-line...
  $> perlcritic --theme='not stricter_subs' MyModule.pm

See L<Perl::Critic/"CONFIGURATION"> section for more information about
configuring the L<Perl::Critic|Perl::Critic> engine.

Each Policy in this distro may support additional configuration
settings that can be accessed through your F<.perlcriticrc> file.  See
the perldoc in each Policy for more details.

=head1 ACKNOWLEDGEMENTS

DEVELOPMENT of the C<Perl-Critic-StricterSubs> distribution was
financed by a grant from The Mathworks (L<http://mathworks.com>).
The Perl::Critic team sincerely thanks The Mathworks for their
generous support of the Perl community and open-source software.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2007-2022 Jeffrey Ryan Thalhammer.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

######################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 70
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=70 ft=perl expandtab :
