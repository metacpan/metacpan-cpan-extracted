#---------------------------------------------------------------------
package Pod::Loom::Template::Default;
#
# Copyright 2009 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created:  6 Oct 2009
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Default template for Pod::Loom
#---------------------------------------------------------------------

use 5.008;
our $VERSION = '0.05';
# This file is part of Pod-Loom 0.08 (March 23, 2014)

use Moose;
extends 'Pod::Loom::Template';

use Pod::Loom::Template '%E';
#=====================================================================


has qw(sort_attr   is ro), isa => 'Int | ArrayRef[Str]';
has qw(sort_diag   is ro), isa => 'Int | ArrayRef[Str]';
has qw(sort_method is ro), isa => 'Int | ArrayRef[Str]';
has qw(sort_sub    is ro), isa => 'Int | ArrayRef[Str]';

sub collect_commands
{
  [ qw(head1 attr method sub diag) ];
} # end collect_commands

#---------------------------------------------------------------------
# Don't forget to update DESCRIPTION and sort_method if changing this:
our @sections =
  (qw(NAME VERSION SYNOPSIS DESCRIPTION ATTRIBUTES METHODS SUBROUTINES
      * DIAGNOSTICS),
   'CONFIGURATION AND ENVIRONMENT',
   qw(DEPENDENCIES INCOMPATIBILITIES),
   'BUGS AND LIMITATIONS',
   'AUTHOR', 'COPYRIGHT AND LICENSE', 'DISCLAIMER OF WARRANTY');

sub _build_sections { \@sections };
#---------------------------------------------------------------------


has qw(abstract is ro  isa Str);
has qw(module   is ro  isa Str);

sub section_NAME
{
  my ($self, $title) = @_;

  my ($module, $abstract) = $self->required_attr($title, qw(module abstract));

  "=head1 $title\n\n$module - $abstract\n";
} # end section_NAME
#---------------------------------------------------------------------


has qw(version      is ro  isa Str);
has qw(version_desc is ro  isa Str);

sub section_VERSION
{
  my ($self, $title) = @_;

  if ($self->version_desc) {
    return "=head1 $title\n\n$E{$self->version_desc}\n";
  }

  my $version = $self->version;

  return "=head1 $title\n\nversion $version\n" if defined $version;

  '';                           # Otherwise, omit VERSION
} # end section_VERSION
#---------------------------------------------------------------------


sub section_ATTRIBUTES
{
  my $self = shift;

  $self->joined_section(attr => 'head2', @_);
} # end section_ATTRIBUTES
#---------------------------------------------------------------------


sub section_METHODS
{
  my $self = shift;

  $self->joined_section(method => 'head2', @_);
} # end section_METHODS

#---------------------------------------------------------------------


sub section_SUBROUTINES
{
  my $self = shift;

  $self->joined_section(sub => 'head2', @_);
} # end section_SUBROUTINES

#---------------------------------------------------------------------
sub override_section
{
  my ($self, $title) = @_;

  return ($title eq 'ATTRIBUTES' or
          $title eq 'DIAGNOSTICS' or
          $title eq 'METHODS' or
          $title eq 'SUBROUTINES');
} # end override_section
#---------------------------------------------------------------------


sub section_DIAGNOSTICS
{
  my $self = shift;

  $self->joined_section(diag => 'item', @_);
} # end section_DIAGNOSTICS
#---------------------------------------------------------------------


sub section_CONFIGURATION_AND_ENVIRONMENT
{
  my ($self, $title) = @_;

  my ($module) = $self->required_attr($title, 'module');

  return <<"END CONFIGURATION";
\=head1 $title

$module requires no configuration files or environment variables.
END CONFIGURATION
} # end section_CONFIGURATION_AND_ENVIRONMENT
#---------------------------------------------------------------------


sub section_INCOMPATIBILITIES
{
  my ($self, $title) = @_;

  "=head1 $title\n\nNone reported.\n";
} # end section_INCOMPATIBILITIES
#---------------------------------------------------------------------


sub section_BUGS_AND_LIMITATIONS
{
  my ($self, $title) = @_;

  "=head1 $title\n\nNo bugs have been reported.\n";
} # end section_BUGS_AND_LIMITATIONS
#---------------------------------------------------------------------


has qw(dist    is ro  isa Str);
has qw(authors is ro  isa ArrayRef[Str]);
has qw(bugtracker is ro  isa Maybe[HashRef]);
has qw(repository is ro  isa Maybe[Str]);

sub section_AUTHOR
{
  my ($self, $title) = @_;

  my ($dist, $authors) = $self->required_attr($title, qw(dist authors));

  my $pod = "=head1 $title\n\n";

  foreach my $authorCredit (@$authors) {
    if ($authorCredit =~ /(.*\S)\s*(<.*>)$/) {
      my ($author, $email) = ($1, $2);
      $email =~ s/@/ AT /g;
      $pod .= "$author  S<C<< $email >>>\n";
    } else {
      $pod .= "$authorCredit\n";
    }
  } # end foreach $authorCredit in @$authors

  my $bugs = $self->bugtracker || {
    mailto => "bug-$dist\@rt.cpan.org",
    web    => "http://rt.cpan.org/Public/Bug/Report.html?Queue=$dist",
  };

  if (my $mailto = $bugs->{mailto} or $bugs->{web}) {
    $pod .= "\nPlease report any bugs or feature requests\n";

    if ($mailto) {
      $mailto =~ s/@/ AT /g;
      $pod .= "to S<C<< <$mailto> >>>";
    }

    if ($bugs->{web}) {
      $pod .= "\nor " if $mailto;
      $pod .= "through the web interface at\nL<< $bugs->{web} >>";
    }
    $pod .= ".\n";
  } # end if bugtracker

  my $repo = $self->repository;
  if ($repo) {
    $repo = "L<< $repo >>" if $repo =~ /^https?:/;

    $pod .= <<"END REPOSITORY";
\nYou can follow or contribute to ${dist}'s development at
$repo.
END REPOSITORY
  } # end if $self->repository

  return $pod;
} # end section_AUTHOR
#---------------------------------------------------------------------


has qw(license_notice is ro  isa Str);

sub section_COPYRIGHT_AND_LICENSE
{
  my ($self, $title) = @_;

  my ($notice) = $self->required_attr($title, 'license_notice');

  #FIXME other license
  "=head1 $title\n\n$notice";
} # end section_COPYRIGHT_AND_LICENSE
#---------------------------------------------------------------------


sub section_DISCLAIMER_OF_WARRANTY
{
  my ($self, $title) = @_;

  return <<"END DISCLAIMER";
\=head1 $title

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
END DISCLAIMER
} # end section_DISCLAIMER_OF_WARRANTY

#=====================================================================
# Package Return Value:

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Pod::Loom::Template::Default - Default template for Pod::Loom

=head1 VERSION

This document describes version 0.05 of
Pod::Loom::Template::Default, released March 23, 2014
as part of Pod-Loom version 0.08.

=head1 DESCRIPTION

Pod::Loom::Template::Default is the default template for Pod::Loom.
It places the sections in this order:

  +  NAME
  +  VERSION
     SYNOPSIS
     DESCRIPTION
  ++ ATTRIBUTES
  ++ METHODS
  ++ SUBROUTINES
     *
  ++ DIAGNOSTICS
  +  CONFIGURATION AND ENVIRONMENT
     DEPENDENCIES
  +  INCOMPATIBILITIES
  +  BUGS AND LIMITATIONS
  +  AUTHOR
  +  COPYRIGHT AND LICENSE
  +  DISCLAIMER OF WARRANTY

Sections marked with C<+> will be provided by this template if they do
not appear in the original document.  Sections marked C<++> will be
appended to even if they do appear in the original document (if the
document contains any entries that belong in that section).

See L<Pod::Loom::Template/"Controlling the template"> for details on
how to rearrange sections and sort entries.

=head1 ATTRIBUTES

=head2 abstract

The abstract for the module.  Required by NAME.


=head2 authors

An arrayref of author names (with optional email address in C<< <> >>).
Required by AUTHOR.


=head2 bugtracker

An optional hashref giving the location of the distribution's public
bugtracker.  If not specified, defaults to the CPAN RT.  If present,
may have keys C<web> and C<mailto>.


=head2 dist

The name of the distribution that contains this module.
Required by AUTHOR.


=head2 license_notice

The complete text of the COPYRIGHT AND LICENSE section.
Required by COPYRIGHT AND LICENSE.


=head2 module

The name of the module.
Required by NAME and CONFIGURATION AND ENVIRONMENT.


=head2 repository

An optional string giving the location of the distribution's public
source code repository.


=head2 sort_attr

This should be 0, 1, or an arrayref.  If non 0, attributes will be
sorted.  An arrayref lists the attributes that should come first, with
the remaining attributes in alphabetical order.
See L<Pod::Loom::Template/"Pod::Loom-sort_COMMAND">.


=head2 sort_diag

Just like C<sort_attr>, but for diagnostic messages.


=head2 sort_method

Just like C<sort_attr>, but for methods.


=head2 sort_sub

Just like C<sort_attr>, but for subroutines.


=head2 version

The version number of the module.  Used by VERSION.


=head2 version_desc

The complete text of the VERSION section. Used by VERSION.

=head1 METHODS

=head2 section_NAME

  <module> - <abstract>


=head2 section_VERSION

  <version_desc>

Or, if L</"version_desc"> is not set:

  version <version>

If neither version_desc nor L</"version"> is set, no VERSION section
will be added.


=head2 section_ATTRIBUTES

If the original document contains any C<=attr> commands, they will be
converted to C<=head2> commands in this section.  If there are no
attributes, no ATTRIBUTES section will be added.


=head2 section_METHODS

This is just like ATTRIBUTES, except it gathers C<=method> entries.


=head2 section_SUBROUTINES

This is just like ATTRIBUTES, except it gathers C<=sub> entries.


=head2 section_DIAGNOSTICS

If the original document contains any C<=diag> commands, they will be
converted to an C<=item> list in this section.  If there are no
diagnostics, no DIAGNOSTICS section will be added.


=head2 section_CONFIGURATION_AND_ENVIRONMENT

 <module> requires no configuration files or environment variables.


=head2 section_INCOMPATIBILITIES

 None reported.


=head2 section_BUGS_AND_LIMITATIONS

 No bugs have been reported.


=head2 section_AUTHOR

First, it lists the authors from the L</"authors"> attribute
(converting @ to AT in email addresses).  Then it directs bug reports
to the distribution's queue at rt.cpan.org (using the L</"dist"> attribute):

  Please report any bugs or feature requests to
  S<C<< <bug-<dist> AT rt.cpan.org> >>>,
  or through the web interface at
  L<http://rt.cpan.org/Public/Bug/Report.html?Queue=<dist>>

And, if L</"repository"> is set:

  You can follow or contribute to <dist>'s development at
  <repository>.


=head2 section_COPYRIGHT_AND_LICENSE

  <license_notice>


=head2 section_DISCLAIMER_OF_WARRANTY

See L</"DISCLAIMER OF WARRANTY">.

=head1 CONFIGURATION AND ENVIRONMENT

Pod::Loom::Template::Default requires no configuration files or environment variables.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-Pod-Loom AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=Pod-Loom >>.

You can follow or contribute to Pod-Loom's development at
L<< https://github.com/madsen/pod-loom >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Christopher J. Madsen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
