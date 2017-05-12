package TM::Serializable::LTM;

use Class::Trait 'base';
use Class::Trait 'TM::Serializable';
##use base qw (TM::Serializable);

use Data::Dumper;

=pod

=head1 NAME

TM::Serializable::LTM - Topic Maps, trait for parsing of LTM instances.

=head1 SYNOPSIS

  # this is not an end-user package
  # see the source of TM::Materialized::LTM

=head1 DESCRIPTION

This package provides parsing functionality for LTM 1.3 instances with the exceptions listed
below. LTM 1.3 is backwards compatible with version 1.2.  As LTM 1.3 is not yet public, please
contact the author (Lars M. Garshol) for a copy.

=begin html

<BLOCKQUOTE>
<A HREF="http://www.ontopia.net/download/ltm.html">http://www.ontopia.net/download/ltm.html</A>
</BLOCKQUOTE>

=end html

=begin man

   http://www.ontopia.net/download/ltm.html

=end man

=head2 Deviations from the LTM Specification

=over

=item B<comments>:

The parser does NOT recognizes nested comments. Any closest following */ sequence terminates a
comment. The parser does also not distinguish between comments within or outside strings.

Justification: Speed of parsing and complexity of the parser.

=item B<scope>:

Only exactly ONE topic can be specified for a scope.

Justification: Multiple topics per scope are allowed by the standard, but are undefined in their
semantics. The underlying TM representation does NOT allow for multiple topics per scope.

=item B<variants>

Variants are currently not supported. This also includes I<sort names> and I<display names>.

Justification: Will be added later.

=item B<syntax>

Any number of statements are allowed in LTM files (also 0).

Justification: There is no reason to do otherwise.

=item B<TOPICMAP directive>

This is currently not implemented.

Justification: There are better ways to do that.

=item B<MERGEMAP directive>

The HyTime, ISO13250 format is not implemented as there is currently no driver in the TM suite. 

Justification: As long as there is no interest (read: bribe money), it never will.

=item B<BASEURI directive>

BASEURI is currently not honored for all local URIs.

Justification: I do not understand its purpose.

=item B<encoding>

This is currently ignored.

Justification: Will be added later.

=item B<Subject Locators>

It is a violation to use more than one subject locator per topic.

Justification: This is enforced by the underlying model.

=item B<Source Locators>

No source locators are created.

Justification: There is no such concept (thankfully) in the TM suite.

=item B<role type>:

If a role is not specified, it will remain default to C<thing> and not - as the specification
mandates - will be substituted by the topic type.

Justification: First, a topic might have several types (which one to use?), secondly there might be
several topics in a member and thirdly, a role should generally NOT be the type of a member.

=back

=head2 Notes

=over

=item B<Merging>

The parser (like any other in the TM suite) does NOT perform merging automatically.
You have to trigger that explicitely with the method C<consolidate>.

=item B<MERGEMAP directive>

The strings determining the format are checked case-insensitive, so ASTMA and AsTMa are treated
equally.

The location of the map can be defined via any URI handled by LWP::Simple.
If no scheme is provided I<file:> will be assumed.

=back

=head1 INTERFACE

=head2 Methods

=over

=item B<deserialize>

This method tries to parse the passed in text stream as LTM instance. It will raise an exception on
the first parse error.

=cut

sub deserialize {
  my $self    = shift;
  my $content = shift;

  use TM::LTM::Parser;
  my $ap = new TM::LTM::Parser (store => $self);
  $ap->parse ($content);                                                 # we parse content into the ap object component 'store'
}

=pod

=item B<serialize>

This is not implemented.

=cut

sub serialize {
  $TM::log->logdie ( scalar __PACKAGE__ .": not implemented" );
}

=pod

=back

=head1 SEE ALSO

L<TM>

=head1 AUTHOR INFORMATION

Copyright 200[1-6], Robert Barta <drrho@cpan.org>, All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.  http://www.perl.com/perl/misc/Artistic.html

=cut

our $VERSION  = '0.3';
our $REVISION = '$Id: LTM.pm,v 1.3 2006/12/29 09:33:43 rho Exp $';

1;

__END__
