package Perl::Critic::Community;

use strict;
use warnings;

our $VERSION = 'v1.0.1';

1;

=head1 NAME

Perl::Critic::Community - Community-inspired Perl::Critic policies

=head1 SYNOPSIS

  $ perlcritic --theme community script.pl
  $ perlcritic --theme community lib/
  
  # .perlcriticrc
  theme = community
  severity = 1

=head1 DESCRIPTION

A set of L<Perl::Critic> policies to enforce the practices generally
recommended by subsets of the Perl community, particularly on
L<IRC|perlcommunity/IRC>. Formerly known as L<Perl::Critic::Freenode>. Because
this policy "theme" is designed to be used with zero configuration on the
command line, some duplication will occur if it is used in combination with
core L<Perl::Critic> policies.

=head1 AFFILIATION

This module has no functionality, but instead contains documentation for this
distribution and acts as a means of pulling other modules into a bundle. All of
the Policy modules contained herein will have an "AFFILIATION" section
announcing their participation in this grouping.

=head1 POLICIES

=over

=item L<Perl::Critic::Policy::Community::AmpersandSubCalls>

Don't use C<&> to call subroutines

=item L<Perl::Critic::Policy::Community::ArrayAssignAref>

Don't assign an anonymous arrayref to an array

=item L<Perl::Critic::Policy::Community::BarewordFilehandles>

Don't use bareword filehandles other than built-ins

=item L<Perl::Critic::Policy::Community::ConditionalDeclarations>

Don't declare variables conditionally

=item L<Perl::Critic::Policy::Community::ConditionalImplicitReturn>

Don't end a subroutine with a conditional block

=item L<Perl::Critic::Policy::Community::DeprecatedFeatures>

Avoid features that have been deprecated or removed from Perl

=item L<Perl::Critic::Policy::Community::DiscouragedModules>

Various modules discouraged from use

=item L<Perl::Critic::Policy::Community::DollarAB>

Don't use C<$a> or C<$b> as variable names outside C<sort()>

=item L<Perl::Critic::Policy::Community::Each>

Don't use C<each()> to iterate through a hash

=item L<Perl::Critic::Policy::Community::EmptyReturn>

Don't use C<return> with no arguments

=item L<Perl::Critic::Policy::Community::IndirectObjectNotation>

Don't call methods indirectly

=item L<Perl::Critic::Policy::Community::LexicalForeachIterator>

Don't use undeclared foreach loop iterators

=item L<Perl::Critic::Policy::Community::LoopOnHash>

Don't loop over hashes

=item L<Perl::Critic::Policy::Community::ModPerl>

Don't use C<mod_perl> to write web applications

=item L<Perl::Critic::Policy::Community::MultidimensionalArrayEmulation>

Don't use multidimensional array emulation

=item L<Perl::Critic::Policy::Community::OpenArgs>

Always use the three-argument form of C<open()>

=item L<Perl::Critic::Policy::Community::OverloadOptions>

Don't use L<overload> without specifying a bool overload and enabling fallback

=item L<Perl::Critic::Policy::Community::PackageMatchesFilename>

Module files should declare a package matching the filename

=item L<Perl::Critic::Policy::Community::POSIXImports>

Don't use L<POSIX> without specifying an import list

=item L<Perl::Critic::Policy::Community::PreferredAlternatives>

Various modules with preferred alternatives

=item L<Perl::Critic::Policy::Community::Prototypes>

Don't use function prototypes

=item L<Perl::Critic::Policy::Community::StrictWarnings>

Always use L<strict> and L<warnings>, or a module that imports these

=item L<Perl::Critic::Policy::Community::Threads>

Interpreter-based threads are officially discouraged

=item L<Perl::Critic::Policy::Community::Wantarray>

Don't write context-sensitive functions using C<wantarray()>

=item L<Perl::Critic::Policy::Community::WarningsSwitch>

Scripts should not use the C<-w> switch on the shebang line

=item L<Perl::Critic::Policy::Community::WhileDiamondDefaultAssignment>

Don't use C<while> with implicit assignment to C<$_>

=back

=head1 CONFIGURATION AND ENVIRONMENT

All policies included are in the "community" theme. See the L<Perl::Critic>
documentation for how to make use of this.

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 CONTRIBUTORS

=over

=item Graham Knop (haarg)

=item H.Merijn Brand (Tux)

=item John SJ Anderson (genehack)

=item Matt S Trout (mst)

=item William Taylor (willt)

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2015, Dan Book.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Perl::Critic>
