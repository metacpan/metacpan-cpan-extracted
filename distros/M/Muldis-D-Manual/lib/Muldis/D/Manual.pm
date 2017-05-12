use 5.006;
use strict;
use warnings;
package Muldis::D::Manual;
our $VERSION = '0.009000';
$VERSION = eval $VERSION;
# Note that Perl code only exists at all in this file in order to help
# the CPAN indexer handle the distribution properly.
1;
__END__

=pod

=encoding utf8

=head1 NAME

Muldis::D::Manual -
Muldis D language and implementations manual

=head1 VERSION

This document is Muldis::D::Manual version 0.9.0.

=head1 PREFACE

This is the root document of the Muldis D language and implementations
manual; the documents that comprise the remaining parts of the manual, in
their suggested reading order (but that all follow the root), are listed in
the other sections below in this document.

=head1 DESCRIPTION

This distribution holds a collection of documents, some POD and some not,
which together constitute a manual or cookbook of sorts for using and
understanding the B<Muldis D> language and its implementations.  Generally
speaking, this distribution is meant as a catch-all for any useful
documentation that is neither part of the Muldis D language specification
itself nor part of an implementation's own formal API documentation.

So the sorts of things you would find here include archived copies of
presentations / slideshows related to Muldis D, or reams of Muldis D code
examples, or comparisons of Muldis D with other languages such as SQL or
Perl, or guides on how to migrate code between Muldis D and other
languages, or some rationale documents, or whatever.

Generally speaking, this distribution does not contain any executable code,
although it does contain some utilities to make working with Muldis D
easier, such as an Input Method to help type symbols Muldis D uses, or a
Codeless Language Module for BBEdit that does syntax coloring and function
searching of Muldis D code.

Some of the content is in the C<archives/> and C<util/> subdirectories of
this distribution.  Some of the existing, and possibly most of the
forthcoming, content is in POD files under C<lib/>, which are linked to in
L</SECTIONS>.  Other forthcoming content may be under C<examples/>.

=head1 SECTIONS

=over

=item L<Muldis::D::Manual::CD>

Simple CD database example - Muldis D code examples.

=item L<Muldis::D::Manual::TemporalExtras>

Legacy temporal data types, operators, and syntax removed from Muldis D.

=back

=head1 SEE ALSO

The separate all-documentation distribution L<Muldis::D> is the formal
definition of the Muldis D language, whose spec and implementations this
Muldis D Manual is concerned with.  The Muldis D language in turn has as a
primary influence the work of Christopher J. Date and Hugh Darwen whose
home website is L<http://www.thethirdmanifesto.com/>.

The separate distribution L<Muldis::Rosetta> is the feature implementation
of Muldis D, and documents in the Manual may be more likely to be talking
about it than any other implementation-specific topic, in the short term.

=head1 AUTHOR

Darren Duncan (C<darren@DarrenDuncan.net>)

=head1 LICENSE AND COPYRIGHT

This file is part of the Muldis D language and implementations manual.

Muldis D Manual is Copyright © 2008-2010, Muldis Data Systems, Inc.

L<http://www.muldis.com/>

Muldis D Manual is free documentation for software; you can redistribute it
and/or modify it under the terms of the GNU General Public License (GPL) as
published by the Free Software Foundation (L<http://www.fsf.org/>); either
version 3 of the License, or (at your option) any later version.  You
should have received copies of the GPL as part of the Muldis::D::Manual
distribution, in the file named "LICENSE/GPL"; if not, see
L<http://www.gnu.org/licenses/>.

Any versions of Muldis D Manual that you modify and distribute must carry
prominent notices stating that you changed the files and the date of any
changes, in addition to preserving this original copyright notice and other
credits.

While it is by no means required, the copyright holder of Muldis D Manual
would appreciate being informed any time you create a modified version of
Muldis D Manual that you are willing to distribute, because that is a
practical way of suggesting improvements to the standard version.

=head1 TRADEMARK POLICY

MULDIS and MULDIS MULTIVERSE OF DISCOURSE are trademarks of Muldis Data
Systems, Inc. (L<http://www.muldis.com/>).  The trademarks apply to
computer database software and related services.  See
L<http://www.muldis.com/trademark_policy.html> for the full written details
of Muldis Data Systems' trademark policy.

The word MULDIS is intended to be used as the distinguishing brand name for
all the products and services of Muldis Data Systems.  So we would greatly
appreciate it if in general you do not incorporate the word MULDIS into the
name or logo of your website, business, product or service, but rather use
your own distinct name (exceptions appear below).  It is, however, always
okay to use the word MULDIS only in descriptions of your website, business,
product or service to provide accurate information to the public about
yourself.

If you do incorporate the word MULDIS into your names anyway, either
because you have permission from us or you have some other good reason,
then:  You must make clear that you are not Muldis Data Systems and that
you do not represent Muldis Data Systems.  A simple or conspicuous
disclaimer on your home page and product or service documentation is an
excellent way of doing that.

Please respect the conventions of the Perl community by not using the
namespace C<Muldis::> at all for your own works, unless you have explicit
permission to do so from Muldis Data Systems; that namespace is mainly just
for our official works.  You can always use either the C<MuldisX::>
namespace for related unofficial works, or some other namespace that is
completely different.  Also as per conventions, its fine to use C<Muldis>
within a Perl package name where that word is nested under some other
project-specific namespace (for example, C<Foo::Storage::Muldis_Rosetta> or
C<Bar::Interface::Muldis_Rosetta>), and the package serves to interact with
a Muldis Data Systems work or service.

If you have made a language variant or extension based on the B<Muldis D>
language, then please follow the naming conventions described in the
VERSIONING (L<Muldis::D/VERSIONING>) documentation of the official
B<Muldis D> language spec.

If you would like to use (or have already used) the word MULDIS for any use
that ought to require permission, please contact Muldis Data Systems and
we'll discuss a way to make that happen.

=head1 ACKNOWLEDGEMENTS

None yet.

=head1 FORUMS

Several public email-based forums exist whose main topic is
the L<Muldis D|Muldis::D> language and its implementations, especially
the L<Muldis Rosetta|Muldis::Rosetta> reference implementation, but also
the L<Set::Relation> module.  They exist so that users of Muldis D or
Muldis Rosetta can help each other, or so that help coming from the
projects' developers can be said once to many people, rather than
necessarily to each individually.  All of these you can reach via
L<http://mm.darrenduncan.net/mailman/listinfo>; go there to manage your
subscriptions to, or view the archives of, the following:

=over

=item C<muldis-db-announce@mm.darrenduncan.net>

This low-volume list is mainly for official announcements from Muldis D or
Muldis Rosetta developers, though developers of related projects can also
post their announcements here.  This is not a discussion list.

=item C<muldis-db-users@mm.darrenduncan.net>

This list is for general discussion among people who are using Muldis D or
any of its implementations, especially the Muldis Rosetta reference
implementation.  This is the best place to ask for basic help in getting
Muldis Rosetta installed on your machine or to make it do what you want.
If you are in doubt on which list to use, then use this one by default.
You could also submit feature requests for Muldis Rosetta or report
perceived bugs here, if you don't want to use CPAN's RT system.

=item C<muldis-d-language@mm.darrenduncan.net>

This list is mainly for discussion among people who are designing the
Muldis D language specification, or who are implementing or adapting Muldis
D in some form, or who are writing Muldis D documentation, tests, or
examples.  It is not the main forum for any Muldis D implementations, nor
is it the place for non-implementers to get help in using said.

=item C<muldis-db-devel@mm.darrenduncan.net>

This list is for discussion among people who are designing or implementing
the Muldis Rosetta DBMS framework core, or who are implementing Muldis
Rosetta Engines, or who are writing Muldis Rosetta core documentation,
tests, or examples.  It is not the main forum for the Muldis D language
itself, nor is it the place for non-implementers to get help in using said.

=back

An official IRC channel for Muldis D and its implementations is also
intended, but not yet started.

Alternately, you can purchase more advanced commercial support for various
Muldis D implementations, particularly Muldis Rosetta, from its author by
way of Muldis Data Systems; see L<http://www.muldis.com/> for details.

=cut
